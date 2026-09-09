import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kabuca_flutter/config/backend_config.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';

void main() {
  final contractBody = File(
    'test/fixtures/market_data_quote.json',
  ).readAsStringSync();

  test('Backendと共有するquote契約を読み込める', () async {
    final provider = BackendStockPriceProvider(
      client: MockClient((_) async => http.Response(contractBody, 200)),
    );
    final quote = await StockPriceService(
      provider,
    ).fetchCurrentPrice(ticker: '7203', companyId: 'toyota');
    expect(quote.ticker, '7203');
    expect(quote.price, 2915.5);
    expect(quote.fetchedAt, DateTime.utc(2026, 9, 8, 6, 30));
  });

  for (final status in [503, 504]) {
    test('$statusから1回の再試行でquoteを取得できる', () async {
      var calls = 0;
      final provider = BackendStockPriceProvider(
        retryDelay: Duration.zero,
        client: MockClient(
          (_) async => ++calls == 1
              ? http.Response('service unavailable', status)
              : http.Response(contractBody, 200),
        ),
      );
      final quote = await provider.fetchQuote(
        ticker: '7203',
        companyId: 'toyota',
      );
      expect(quote.price, 2915.5);
      expect(calls, 2);
    });
  }

  test('503が続いてもHTTPリクエストは最大2回', () async {
    var calls = 0;
    final provider = BackendStockPriceProvider(
      retryDelay: Duration.zero,
      client: MockClient((_) async {
        calls++;
        return http.Response('{}', 503);
      }),
    );
    await expectLater(
      provider.fetchQuote(ticker: '7203', companyId: 'toyota'),
      throwsA(
        isA<StockPriceException>().having(
          (e) => e.retryable,
          'retryable',
          true,
        ),
      ),
    );
    expect(calls, 2);
  });

  test('timeoutを1回だけ再試行し、遅れて届くレスポンスも安全に無視する', () async {
    var calls = 0;
    final pending = <Completer<http.Response>>[];
    final provider = BackendStockPriceProvider(
      timeout: const Duration(milliseconds: 5),
      retryDelay: Duration.zero,
      client: MockClient((_) {
        calls++;
        final response = Completer<http.Response>();
        pending.add(response);
        return response.future;
      }),
    );
    await expectLater(
      provider.fetchQuote(ticker: '7203', companyId: 'toyota'),
      throwsA(
        isA<StockPriceException>().having(
          (e) => e.message,
          'message',
          contains('タイムアウト'),
        ),
      ),
    );
    expect(calls, 2);
    for (final response in pending) {
      response.complete(http.Response(contractBody, 200));
    }
    await Future<void>.delayed(Duration.zero);
  });

  test('通信切断後は1回だけ再試行できる', () async {
    var calls = 0;
    final provider = BackendStockPriceProvider(
      retryDelay: Duration.zero,
      client: MockClient((_) async {
        if (++calls == 1) throw http.ClientException('connection closed');
        return http.Response(contractBody, 200);
      }),
    );
    expect(
      (await provider.fetchQuote(ticker: '7203', companyId: 'toyota')).price,
      2915.5,
    );
    expect(calls, 2);
  });

  for (final status in [400, 404, 429, 502]) {
    test('$statusはFlutterで自動再試行しない', () async {
      var calls = 0;
      final provider = BackendStockPriceProvider(
        retryDelay: Duration.zero,
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', status);
        }),
      );
      await expectLater(
        provider.fetchQuote(ticker: '7203', companyId: 'toyota'),
        throwsA(isA<StockPriceException>()),
      );
      expect(calls, 1);
    });
  }

  final invalidPayloads = <String, String>{
    'malformed JSON': '{',
    'array': '[]',
    'null price': jsonEncode({...jsonDecode(contractBody), 'price': null}),
    'string price': jsonEncode({
      ...jsonDecode(contractBody),
      'price': '2915.5',
    }),
    'zero price': jsonEncode({...jsonDecode(contractBody), 'price': 0}),
    'malformed date': jsonEncode({
      ...jsonDecode(contractBody),
      'fetchedAt': 'bad-date',
    }),
    'wrong ticker type': jsonEncode({
      ...jsonDecode(contractBody),
      'ticker': 7203,
    }),
    'different company': jsonEncode({
      ...jsonDecode(contractBody),
      'ticker': '6758',
    }),
  };
  for (final entry in invalidPayloads.entries) {
    test('${entry.key}は再試行できない形式エラーにする', () async {
      var calls = 0;
      final provider = BackendStockPriceProvider(
        retryDelay: Duration.zero,
        client: MockClient((_) async {
          calls++;
          return http.Response(entry.value, 200);
        }),
      );
      await expectLater(
        provider.fetchQuote(ticker: '7203', companyId: 'toyota'),
        throwsA(
          isA<StockPriceException>()
              .having((e) => e.kind, 'kind', StockPriceErrorKind.invalidData)
              .having((e) => e.retryable, 'retryable', false),
        ),
      );
      expect(calls, 1);
    });
  }
  test('未指定時は本番Backend URLを使用する', () {
    final provider = BackendStockPriceProvider();

    expect(kabucaBackendBaseUrl, kabucaProductionBackendBaseUrl);
    expect(provider.baseUrl, 'https://kabuca-api.onrender.com');
  });

  test('dart-defineのcompile-time URLをProviderへ反映する', () {
    final provider = BackendStockPriceProvider();

    expect(provider.baseUrl, kabucaBackendBaseUrl);
  });

  test('明示したBackend URLはdefaultより優先される', () {
    final provider = BackendStockPriceProvider(
      baseUrl: 'https://staging.kabuca.example.com',
    );

    expect(provider.baseUrl, 'https://staging.kabuca.example.com');
  });

  test('Backend quoteレスポンスをStockQuoteへ変換する', () async {
    Uri? requested;
    final provider = BackendStockPriceProvider(
      baseUrl: 'https://kabuca.example.com/',
      client: MockClient((request) async {
        requested = request.url;
        return http.Response(
          '{"ticker":"7203","price":2915.5,'
          '"fetchedAt":"2026-08-30T06:30:00Z"}',
          200,
        );
      }),
    );

    final quote = await provider.fetchQuote(
      ticker: '7203',
      companyId: 'toyota',
    );
    expect(quote.ticker, '7203');
    expect(quote.price, 2915.5);
    expect(quote.fetchedAt, DateTime.utc(2026, 8, 30, 6, 30));
    expect(requested?.path, '/api/market-data/quote');
    expect(requested?.queryParameters['ticker'], '7203');
  });

  test('Backend終値とsplitレスポンスをHistoricalStockPriceへ変換する', () async {
    final requestedPaths = <String>[];
    final provider = BackendStockPriceProvider(
      baseUrl: 'https://kabuca.example.com/base',
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        if (request.url.path.endsWith('/history')) {
          return http.Response(
            '{"ticker":"7203","tradingDate":"2026-09-07",'
            '"close":3000,"fetchedAt":"2026-09-07T07:00:00Z"}',
            200,
          );
        }
        return http.Response(
          '{"ticker":"7203","hasSplit":true,"events":[]}',
          200,
        );
      }),
    );

    final value = await provider.fetchClosingPrice(
      ticker: '7203',
      tradingDate: DateTime(2026, 9, 7),
      sinceDate: DateTime(2026, 8, 30),
    );
    expect(value.close, 3000);
    expect(value.splitDetected, isTrue);
    expect(requestedPaths, [
      '/base/api/market-data/history',
      '/base/api/market-data/splits',
    ]);
  });

  test('Backend URL未設定は通信せず設定エラーにする', () async {
    final provider = BackendStockPriceProvider(
      baseUrl: '',
      client: MockClient((_) async => throw StateError('must not call')),
    );
    await expectLater(
      provider.fetchQuote(ticker: '7203', companyId: 'toyota'),
      throwsA(
        isA<StockPriceException>()
            .having(
              (error) => error.kind,
              'kind',
              StockPriceErrorKind.configuration,
            )
            .having((error) => error.retryable, 'retryable', isFalse),
      ),
    );
  });

  test('Backendのデータなしと一時エラーを区別する', () async {
    Future<StockPriceException> errorFor(int status) async {
      final provider = BackendStockPriceProvider(
        baseUrl: 'https://kabuca.example.com',
        client: MockClient((_) async => http.Response('{}', status)),
      );
      try {
        await provider.fetchQuote(ticker: '7203', companyId: 'toyota');
      } on StockPriceException catch (error) {
        return error;
      }
      throw StateError('expected error');
    }

    final notFound = await errorFor(404);
    expect(notFound.kind, StockPriceErrorKind.dataNotFound);
    expect(notFound.retryable, isFalse);
    final unavailable = await errorFor(503);
    expect(unavailable.kind, StockPriceErrorKind.temporary);
    expect(unavailable.retryable, isTrue);
  });
}
