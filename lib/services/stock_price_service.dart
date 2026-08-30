import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/stock_quote.dart';

abstract interface class StockPriceProvider {
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
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
}

class YahooFinanceStockPriceProvider implements StockPriceProvider {
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
}
