import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import '../models/stock_quote.dart';
import '../models/historical_stock_price.dart';
import 'trading_calendar_service.dart';

abstract interface class StockPriceProvider {
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  });
}

abstract interface class HistoricalStockPriceProvider {
  Future<HistoricalStockPrice> fetchClosingPrice({
    required String ticker,
    required DateTime tradingDate,
    required DateTime sinceDate,
  });
}

abstract interface class PredictionStartPriceProvider {
  Future<HistoricalStockPrice> fetchStartingPrice({
    required String ticker,
    required String companyId,
    required DateTime tradingDate,
    required DateTime fallbackTradingDate,
  });
}

class StockPriceException implements Exception {
  const StockPriceException(
    this.message, {
    this.kind = StockPriceErrorKind.temporary,
    this.retryable = true,
  });
  final String message;
  final StockPriceErrorKind kind;
  final bool retryable;

  @override
  String toString() => message;
}

enum StockPriceErrorKind { configuration, dataNotFound, temporary, invalidData }

class StockPriceService {
  const StockPriceService(this.provider, {this.clock = DateTime.now});
  final StockPriceProvider provider;
  final DateTime Function() clock;

  factory StockPriceService.production() =>
      StockPriceService(BackendStockPriceProvider());

  Future<HistoricalStockPrice> fetchStartingPrice({
    required String ticker,
    required String companyId,
    required DateTime createdAt,
    required TradingCalendarService calendar,
  }) async {
    final source = provider;
    if (source is! PredictionStartPriceProvider) {
      throw const StockPriceException(
        '予想開始価格を取得できませんでした',
        kind: StockPriceErrorKind.configuration,
        retryable: false,
      );
    }
    final latest = calendar.latestClosedTradingDay(createdAt);
    final previous = calendar.previousTradingDay(latest);
    final price = await (source as PredictionStartPriceProvider).fetchStartingPrice(
      ticker: ticker,
      companyId: companyId,
      tradingDate: latest,
      fallbackTradingDate: previous,
    );
    final date = price.tradingDate;
    if (price.ticker != ticker ||
        !price.close.isFinite || price.close <= 0 ||
        (date != latest && date != previous) ||
        price.fetchedAt.isBefore(calendar.closingTime(date))) {
      throw const StockPriceException(
        '確定した終値を確認できませんでした',
        kind: StockPriceErrorKind.invalidData,
        retryable: false,
      );
    }
    return price;
  }

  Future<StockQuote> fetchCurrentPrice({
    required String ticker,
    required String companyId,
  }) async {
    final quote = await provider.fetchQuote(
      ticker: ticker,
      companyId: companyId,
    );
    if (!quote.price.isFinite || quote.price <= 0) {
      throw const StockPriceException(
        '有効な株価を取得できませんでした',
        kind: StockPriceErrorKind.invalidData,
        retryable: false,
      );
    }
    return quote;
  }

  Future<HistoricalStockPrice> fetchClosingPrice({
    required String ticker,
    required DateTime tradingDate,
    required DateTime sinceDate,
  }) async {
    final source = provider;
    if (source is! HistoricalStockPriceProvider) {
      throw const StockPriceException('過去の終値を取得できませんでした');
    }
    final historicalSource = source as HistoricalStockPriceProvider;
    final price = await historicalSource.fetchClosingPrice(
      ticker: ticker,
      tradingDate: tradingDate,
      sinceDate: sinceDate,
    );
    if (!price.close.isFinite || price.close <= 0) {
      throw const StockPriceException(
        '有効な終値を取得できませんでした',
        kind: StockPriceErrorKind.invalidData,
        retryable: false,
      );
    }
    return price;
  }
}

class BackendStockPriceProvider
    implements StockPriceProvider, HistoricalStockPriceProvider, PredictionStartPriceProvider {
  BackendStockPriceProvider({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 12),
    this.retryDelay = const Duration(milliseconds: 600),
  }) : _client = client ?? http.Client(),
       baseUrl = baseUrl ?? kabucaBackendBaseUrl;

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;
  final Duration retryDelay;

  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) async {
    final json = await _get(
      'api/market-data/quote',
      query: {'ticker': ticker},
      companyId: companyId,
      retryTransientRequest: true,
    );
    final price = json['price'];
    final fetchedAt = _dateValue(json['fetchedAt']);
    final responseTicker = json['ticker'];
    if (price is! num ||
        !price.isFinite ||
        price <= 0 ||
        fetchedAt == null ||
        responseTicker != ticker) {
      _debug('invalid quote ticker=$ticker companyId=$companyId');
      throw _invalidResponse();
    }
    return StockQuote(
      ticker: ticker,
      price: price.toDouble(),
      fetchedAt: fetchedAt.toUtc(),
    );
  }

  @override
  Future<HistoricalStockPrice> fetchStartingPrice({
    required String ticker,
    required String companyId,
    required DateTime tradingDate,
    required DateTime fallbackTradingDate,
  }) async => _historyResponse(
    await _get(
      'api/market-data/history',
      query: {
        'ticker': ticker,
        'tradingDate': _formatDate(tradingDate),
        'fallbackTradingDate': _formatDate(fallbackTradingDate),
      },
      companyId: companyId,
      retryTransientRequest: true,
    ),
    ticker,
  );

  @override
  Future<HistoricalStockPrice> fetchClosingPrice({
    required String ticker,
    required DateTime tradingDate,
    required DateTime sinceDate,
  }) async {
    final historical = await _get(
      'api/market-data/history',
      query: {'ticker': ticker, 'tradingDate': _formatDate(tradingDate)},
    );
    final splits = await _get(
      'api/market-data/splits',
      query: {
        'ticker': ticker,
        'from': _formatDate(sinceDate),
        'to': _formatDate(tradingDate),
      },
    );
    final hasSplit = splits['hasSplit'];
    if (hasSplit is! bool) throw _invalidResponse();
    return _historyResponse(historical, ticker, splitDetected: hasSplit);
  }

  static HistoricalStockPrice _historyResponse(
    Map<String, dynamic> historical,
    String ticker, {bool splitDetected = false}
  ) {
    final close = historical['close'];
    final responseDate = _dateValue(historical['tradingDate']);
    final fetchedAt = _dateValue(historical['fetchedAt']);
    if (close is! num ||
        responseDate == null ||
        fetchedAt == null ||
        historical['ticker'] != ticker) {
      throw _invalidResponse();
    }
    return HistoricalStockPrice(
      ticker: ticker,
      tradingDate: DateTime.utc(responseDate.year, responseDate.month, responseDate.day),
      close: close.toDouble(),
      fetchedAt: fetchedAt.toUtc(),
      splitDetected: splitDetected,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required Map<String, String> query,
    String? companyId,
    bool retryTransientRequest = false,
  }) async {
    final value = baseUrl.trim();
    if (value.isEmpty) {
      throw const StockPriceException(
        '株価データサービスが設定されていません',
        kind: StockPriceErrorKind.configuration,
        retryable: false,
      );
    }
    final base = Uri.tryParse(value.endsWith('/') ? value : '$value/');
    if (base == null ||
        !base.hasAuthority ||
        (base.scheme != 'https' && base.scheme != 'http')) {
      throw const StockPriceException(
        '株価データサービスの設定を確認できませんでした',
        kind: StockPriceErrorKind.configuration,
        retryable: false,
      );
    }
    final uri = base.resolve(path).replace(queryParameters: query);
    final context = 'ticker=${query['ticker']} companyId=$companyId url=$uri';
    final attempts = retryTransientRequest ? 2 : 1;
    for (var attempt = 0; attempt < attempts; attempt++) {
      final canRetry = attempt + 1 < attempts;
      try {
        _debug('request $context attempt=${attempt + 1}/$attempts');
        final response = await _client
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(timeout);
        final summary = response.body.replaceAll(RegExp(r'\s+'), ' ');
        _debug(
          'response $context status=${response.statusCode} '
          'body=${summary.length > 240 ? summary.substring(0, 240) : summary}',
        );
        // 429/502 already represent an exhausted upstream attempt in Backend.
        // Retry only transport/startup failures here, never missing/invalid data.
        if (canRetry &&
            (response.statusCode == 503 || response.statusCode == 504)) {
          await Future<void>.delayed(retryDelay);
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw _httpError(
            response.statusCode,
            isQuote: path.endsWith('/quote'),
          );
        }
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) throw _invalidResponse();
        return decoded;
      } on StockPriceException catch (error) {
        _debug(
          'failure $context exception=${error.runtimeType} kind=${error.kind}',
        );
        rethrow;
      } on FormatException catch (error) {
        _debug('failure $context exception=${error.runtimeType} timeout=false');
        throw _invalidResponse();
      } on TimeoutException catch (error) {
        _debug('failure $context exception=${error.runtimeType} timeout=true');
        if (!canRetry) {
          throw const StockPriceException('株価データサービスへの接続がタイムアウトしました');
        }
      } on http.ClientException catch (error) {
        _debug('failure $context exception=${error.runtimeType} timeout=false');
        if (!canRetry) throw const StockPriceException('株価データを取得できませんでした');
      } catch (error) {
        _debug('failure $context exception=${error.runtimeType} timeout=false');
        throw const StockPriceException('株価データを取得できませんでした');
      }
      await Future<void>.delayed(retryDelay);
    }
    throw StateError('unreachable');
  }

  static StockPriceException _httpError(
    int statusCode, {
    required bool isQuote,
  }) => switch (statusCode) {
    400 => const StockPriceException(
      '銘柄情報を確認できませんでした',
      kind: StockPriceErrorKind.invalidData,
      retryable: false,
    ),
    404 => StockPriceException(
      isQuote ? 'この企業の現在の株価データがありません' : '対象日の株価データがありません',
      kind: StockPriceErrorKind.dataNotFound,
      retryable: false,
    ),
    429 => const StockPriceException('株価データへのアクセスが集中しています'),
    502 || 503 || 504 => const StockPriceException('株価データを一時的に取得できません'),
    _ => const StockPriceException('株価データサービスでエラーが発生しました'),
  };

  static DateTime? _dateValue(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static void _debug(String message) {
    if (kDebugMode) debugPrint('[StockPrice] $message');
  }

  static StockPriceException _invalidResponse() => const StockPriceException(
    '株価データの形式が正しくありません',
    kind: StockPriceErrorKind.invalidData,
    retryable: false,
  );

  static String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
