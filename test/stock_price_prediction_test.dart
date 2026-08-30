import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/models/stock_quote.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  test('StockQuoteの基準価格と取得時刻を予想に保存・復元できる', () async {
    final storage = _Storage();
    final store = await PredictionStore.load(storage: storage);
    final quote = await StockPriceService(
      _QuoteProvider(),
    ).fetchCurrentPrice(ticker: '7203', companyId: 'toyota');
    await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: quote.ticker,
      direction: PredictionDirection.down,
      horizon: PredictionHorizon.oneWeek,
      createdAt: quote.fetchedAt,
      basePrice: quote.price,
      basePriceAt: quote.fetchedAt,
      targetDate: DateTime.utc(2026, 9, 7),
    );
    final restored = await PredictionStore.load(storage: storage);
    expect(restored.predictions.single.basePrice, 12340);
    expect(restored.predictions.single.basePriceAt, quote.fetchedAt);
  });

  test('Task008 JSONは追加フィールドなしで読み込める', () {
    final prediction = StockPrediction.fromJson({
      'id': 'legacy',
      'companyId': 'toyota',
      'companyName': 'トヨタ自動車',
      'ticker': '7203',
      'direction': 'up',
      'horizon': 'oneWeek',
      'createdAt': '2026-08-30T00:00:00.000Z',
      'status': 'waiting',
    });
    expect(prediction.basePrice, isNull);
    expect(prediction.basePriceAt, isNull);
    expect(prediction.targetDate, isNull);
    expect(prediction.resultPrice, isNull);
    expect(prediction.resultPriceAt, isNull);
    expect(prediction.changePercent, isNull);
    expect(prediction.isCorrect, isNull);
    expect(prediction.awardedPoints, isNull);
  });
}

class _QuoteProvider implements StockPriceProvider {
  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) async => StockQuote(
    ticker: ticker,
    price: 12340,
    fetchedAt: DateTime.utc(2026, 8, 31, 6),
  );
}

class _Storage implements PredictionStorage {
  List<StockPrediction> values = [];

  @override
  Future<List<StockPrediction>> readPredictions() async => List.of(values);

  @override
  Future<void> writePredictions(List<StockPrediction> predictions) async {
    values = predictions
        .map((item) => StockPrediction.fromJson(item.toJson()))
        .toList();
  }
}
