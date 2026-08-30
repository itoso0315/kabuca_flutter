import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/stock_quote.dart';
import '../models/historical_stock_price.dart';

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
  const StockPriceService(this.provider);
  final StockPriceProvider provider;

  factory StockPriceService.production() =>
      StockPriceService(BackendStockPriceProvider());

  Future<StockQuote> fetchCurrentPrice({
    required String ticker,
    required String companyId,
  }) async {
    final quote = await provider.fetchQuote(
      ticker: ticker,
      companyId: companyId,
    );
    if (!quote.price.isFinite || quote.price <= 0) {
      throw const StockPriceException('有効な株価を取得できませんでした');
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
      throw const StockPriceException('有効な終値を取得できませんでした');
    }
    return price;
  }
}

class BackendStockPriceProvider
    implements StockPriceProvider, HistoricalStockPriceProvider {
  BackendStockPriceProvider({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 12),
  }) : _client = client ?? http.Client(),
       baseUrl =
           baseUrl ?? const String.fromEnvironment('KABUCA_BACKEND_BASE_URL');

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) async {
    final json = await _get('api/market-data/quote', query: {'ticker': ticker});
    final price = json['price'];
    final fetchedAt = json['fetchedAt'];
    if (price is! num || fetchedAt is! String) throw _invalidResponse();
    return StockQuote(
      ticker: json['ticker'] as String? ?? ticker,
      price: price.toDouble(),
      fetchedAt: DateTime.parse(fetchedAt).toUtc(),
    );
  }

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
    final close = historical['close'];
    final responseDate = historical['tradingDate'];
    final fetchedAt = historical['fetchedAt'];
    final hasSplit = splits['hasSplit'];
    if (close is! num ||
        responseDate is! String ||
        fetchedAt is! String ||
        hasSplit is! bool) {
      throw _invalidResponse();
    }
    return HistoricalStockPrice(
      ticker: historical['ticker'] as String? ?? ticker,
      tradingDate: DateTime.parse(responseDate),
      close: close.toDouble(),
      fetchedAt: DateTime.parse(fetchedAt).toUtc(),
      splitDetected: hasSplit,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required Map<String, String> query,
  }) async {
    final value = baseUrl.trim();
    if (value.isEmpty) {
      throw const StockPriceException(
        '株価データサービスが設定されていません',
        kind: StockPriceErrorKind.configuration,
        retryable: false,
      );
    }
    try {
      final base = Uri.parse(value.endsWith('/') ? value : '$value/');
      final uri = base.resolve(path).replace(queryParameters: query);
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _httpError(response.statusCode);
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw _invalidResponse();
      return decoded;
    } on StockPriceException {
      rethrow;
    } on TimeoutException {
      throw const StockPriceException('株価データサービスへの接続がタイムアウトしました');
    } catch (_) {
      throw const StockPriceException('株価データを取得できませんでした');
    }
  }

  static StockPriceException _httpError(int statusCode) => switch (statusCode) {
    400 => const StockPriceException(
      '銘柄情報を確認できませんでした',
      kind: StockPriceErrorKind.invalidData,
      retryable: false,
    ),
    404 => const StockPriceException(
      '対象日の株価データがありません',
      kind: StockPriceErrorKind.dataNotFound,
      retryable: false,
    ),
    429 || 502 || 503 => const StockPriceException('株価データを一時的に取得できません'),
    _ => const StockPriceException('株価データサービスでエラーが発生しました'),
  };

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
