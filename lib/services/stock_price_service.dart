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
  const StockPriceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class StockPriceService {
  const StockPriceService(this.provider);
  final StockPriceProvider provider;

  factory StockPriceService.production() =>
      StockPriceService(YahooFinanceStockPriceProvider());

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

class YahooFinanceStockPriceProvider
    implements StockPriceProvider, HistoricalStockPriceProvider {
  YahooFinanceStockPriceProvider({
    http.Client? client,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;

  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) async {
    final symbol = ticker.endsWith('.T') ? ticker : '$ticker.T';
    final uri = Uri.https(
      'query1.finance.yahoo.com',
      '/v8/finance/chart/$symbol',
      const {'interval': '1m', 'range': '1d'},
    );
    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 KABUCA-Flutter',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StockPriceException('株価取得に失敗しました (${response.statusCode})');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      final results = chart?['result'] as List<dynamic>?;
      final result = results?.firstOrNull as Map<String, dynamic>?;
      final meta = result?['meta'] as Map<String, dynamic>?;
      final value = meta?['regularMarketPrice'];
      if (value is! num) {
        throw const StockPriceException('現在の株価が応答に含まれていません');
      }
      return StockQuote(
        ticker: ticker,
        price: value.toDouble(),
        fetchedAt: _now().toUtc(),
      );
    } on StockPriceException {
      rethrow;
    } catch (_) {
      throw const StockPriceException('現在の株価を取得できませんでした');
    }
  }

  @override
  Future<HistoricalStockPrice> fetchClosingPrice({
    required String ticker,
    required DateTime tradingDate,
    required DateTime sinceDate,
  }) async {
    final symbol = ticker.endsWith('.T') ? ticker : '$ticker.T';
    final start = DateTime.utc(
      sinceDate.year,
      sinceDate.month,
      sinceDate.day,
    ).subtract(const Duration(days: 2));
    final end = DateTime.utc(
      tradingDate.year,
      tradingDate.month,
      tradingDate.day,
    ).add(const Duration(days: 2));
    final uri =
        Uri.https('query1.finance.yahoo.com', '/v8/finance/chart/$symbol', {
          'interval': '1d',
          'period1': '${start.millisecondsSinceEpoch ~/ 1000}',
          'period2': '${end.millisecondsSinceEpoch ~/ 1000}',
          'events': 'splits',
        });
    try {
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'Mozilla/5.0 KABUCA-Flutter',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StockPriceException('終値取得に失敗しました (${response.statusCode})');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final chart = json['chart'] as Map<String, dynamic>?;
      final results = chart?['result'] as List<dynamic>?;
      final result = results?.firstOrNull as Map<String, dynamic>?;
      final timestamps = result?['timestamp'] as List<dynamic>?;
      final indicators = result?['indicators'] as Map<String, dynamic>?;
      final quotes = indicators?['quote'] as List<dynamic>?;
      final quote = quotes?.firstOrNull as Map<String, dynamic>?;
      final closes = quote?['close'] as List<dynamic>?;
      if (timestamps == null || closes == null) {
        throw const StockPriceException('指定日の終値が応答に含まれていません');
      }
      num? close;
      for (var index = 0; index < timestamps.length; index++) {
        final seconds = timestamps[index];
        if (seconds is! num || index >= closes.length) continue;
        final date = DateTime.fromMillisecondsSinceEpoch(
          seconds.toInt() * 1000,
          isUtc: true,
        ).add(const Duration(hours: 9));
        if (date.year == tradingDate.year &&
            date.month == tradingDate.month &&
            date.day == tradingDate.day &&
            closes[index] is num) {
          close = closes[index] as num;
          break;
        }
      }
      if (close == null) {
        throw const StockPriceException('指定日の終値を取得できませんでした');
      }
      final events = result?['events'] as Map<String, dynamic>?;
      final splits = events?['splits'] as Map<String, dynamic>?;
      return HistoricalStockPrice(
        ticker: ticker,
        tradingDate: tradingDate,
        close: close.toDouble(),
        fetchedAt: _now().toUtc(),
        splitDetected: splits?.isNotEmpty ?? false,
      );
    } on StockPriceException {
      rethrow;
    } catch (_) {
      throw const StockPriceException('過去の終値を取得できませんでした');
    }
  }
}
