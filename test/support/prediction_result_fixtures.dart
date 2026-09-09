import 'dart:async';

import 'package:kabuca_flutter/models/historical_stock_price.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/models/stock_quote.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

final resultTestNow = DateTime.utc(2026, 9, 8, 7);

StockPrediction resultFixture({
  String id = 'due',
  DateTime? targetDate,
  PredictionStatus status = PredictionStatus.waiting,
  bool seen = false,
  bool legacy = false,
}) => StockPrediction(
  id: id,
  companyId: 'toyota',
  companyName: 'トヨタ自動車',
  ticker: '7203',
  direction: PredictionDirection.up,
  horizon: PredictionHorizon.oneWeek,
  createdAt: DateTime.utc(2026, 8, 31),
  status: status,
  targetDate: legacy ? null : targetDate ?? DateTime.utc(2026, 9, 7),
  basePrice: legacy ? null : 1000,
  basePriceAt: legacy ? null : DateTime.utc(2026, 8, 31, 7),
  resultPrice: status == PredictionStatus.completed ? 1100 : null,
  changePercent: status == PredictionStatus.completed ? 10 : null,
  isCorrect: status == PredictionStatus.completed ? true : null,
  awardedPoints: status == PredictionStatus.completed ? 50 : null,
  resultSeen: seen,
);

class ControlledClosingProvider
    implements StockPriceProvider, HistoricalStockPriceProvider {
  Completer<void>? gate;
  StockPriceException? error;
  DateTime? returnedDate;
  DateTime? fetchedAt;
  int calls = 0;
  final requestedDates = <DateTime>[];

  @override
  Future<HistoricalStockPrice> fetchClosingPrice({
    required String ticker,
    required DateTime tradingDate,
    required DateTime sinceDate,
  }) async {
    calls++;
    requestedDates.add(tradingDate);
    await gate?.future;
    if (error case final failure?) throw failure;
    return HistoricalStockPrice(
      ticker: ticker,
      tradingDate: returnedDate ?? tradingDate,
      close: 1100,
      fetchedAt: fetchedAt ?? resultTestNow,
      splitDetected: false,
    );
  }

  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) => throw UnimplementedError();
}

class RecordingPredictionStorage implements PredictionStorage {
  RecordingPredictionStorage(this.values);
  List<StockPrediction> values;
  bool failNextWrite = false;
  Completer<void>? writeGate;

  @override
  Future<List<StockPrediction>> readPredictions() async => List.of(values);

  @override
  Future<void> writePredictions(List<StockPrediction> predictions) async {
    await writeGate?.future;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('storage unavailable');
    }
    values = predictions
        .map((prediction) => StockPrediction.fromJson(prediction.toJson()))
        .toList();
  }
}
