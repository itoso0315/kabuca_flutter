import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stock_prediction.dart';

abstract interface class PredictionStorage {
  Future<List<StockPrediction>> readPredictions();
  Future<void> writePredictions(List<StockPrediction> predictions);
}

class SharedPreferencesPredictionStorage implements PredictionStorage {
  static const _key = 'predictions.items';

  @override
  Future<List<StockPrediction>> readPredictions() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? const [])
        .map(
          (value) => StockPrediction.fromJson(
            jsonDecode(value) as Map<String, Object?>,
          ),
        )
        .toList();
  }

  @override
  Future<void> writePredictions(List<StockPrediction> predictions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      predictions.map((prediction) => jsonEncode(prediction.toJson())).toList(),
    );
  }
}

class PredictionStore extends ChangeNotifier {
  PredictionStore._(this._storage, Iterable<StockPrediction> predictions)
    : _predictions = List.of(predictions);

  final PredictionStorage _storage;
  final List<StockPrediction> _predictions;

  List<StockPrediction> get predictions => List.unmodifiable(_predictions);
  List<StockPrediction> get waitingPredictions => _predictions
      .where((prediction) => prediction.status == PredictionStatus.waiting)
      .toList(growable: false);

  static Future<PredictionStore> load({PredictionStorage? storage}) async {
    final target = storage ?? SharedPreferencesPredictionStorage();
    return PredictionStore._(target, await target.readPredictions());
  }

  static PredictionStore memory({
    Iterable<StockPrediction> predictions = const [],
  }) => PredictionStore._(_MemoryPredictionStorage(), predictions);

  bool hasWaiting(String companyId, PredictionHorizon horizon) =>
      _predictions.any(
        (prediction) =>
            prediction.companyId == companyId &&
            prediction.horizon == horizon &&
            prediction.status == PredictionStatus.waiting,
      );

  StockPrediction? findById(String id) {
    final index = _predictions.indexWhere((item) => item.id == id);
    return index < 0 ? null : _predictions[index];
  }

  Future<StockPrediction?> complete({
    required String id,
    required double resultPrice,
    required DateTime resultPriceAt,
    required double changePercent,
    required bool isCorrect,
    required int awardedPoints,
  }) async {
    final index = _predictions.indexWhere((item) => item.id == id);
    if (index < 0 || _predictions[index].status != PredictionStatus.waiting) {
      return null;
    }
    final completed = _predictions[index].copyWith(
      status: PredictionStatus.completed,
      resultPrice: resultPrice,
      resultPriceAt: resultPriceAt,
      changePercent: changePercent,
      isCorrect: isCorrect,
      awardedPoints: awardedPoints,
      pointsClaimed: false,
    );
    _predictions[index] = completed;
    notifyListeners();
    await _storage.writePredictions(_predictions);
    return completed;
  }

  Future<StockPrediction?> markPointsClaimed(
    String id, {
    required bool claimed,
    DateTime? claimedAt,
  }) async {
    final index = _predictions.indexWhere((item) => item.id == id);
    if (index < 0 || _predictions[index].status != PredictionStatus.completed) {
      return null;
    }
    final updated = _predictions[index].copyWith(
      pointsClaimed: claimed,
      pointsClaimedAt: claimed ? claimedAt ?? DateTime.now().toUtc() : null,
    );
    final next = List<StockPrediction>.of(_predictions)..[index] = updated;
    await _storage.writePredictions(next);
    _predictions[index] = updated;
    notifyListeners();
    return updated;
  }

  Future<StockPrediction?> addWaiting({
    required String companyId,
    required String companyName,
    required String ticker,
    required PredictionDirection direction,
    required PredictionHorizon horizon,
    required double basePrice,
    required DateTime basePriceAt,
    required DateTime targetDate,
    DateTime? createdAt,
  }) async {
    if (hasWaiting(companyId, horizon)) return null;
    final timestamp = createdAt ?? DateTime.now();
    final prediction = StockPrediction(
      id: '${companyId}_${horizon.name}_${timestamp.microsecondsSinceEpoch}',
      companyId: companyId,
      companyName: companyName,
      ticker: ticker,
      direction: direction,
      horizon: horizon,
      createdAt: timestamp,
      status: PredictionStatus.waiting,
      basePrice: basePrice,
      basePriceAt: basePriceAt,
      targetDate: targetDate,
    );
    _predictions.add(prediction);
    notifyListeners();
    await _storage.writePredictions(_predictions);
    return prediction;
  }

  Future<void> resetDevelopmentData() async {
    _predictions.clear();
    notifyListeners();
    await _storage.writePredictions(_predictions);
  }
}

class _MemoryPredictionStorage implements PredictionStorage {
  List<StockPrediction> predictions = [];

  @override
  Future<List<StockPrediction>> readPredictions() async => List.of(predictions);

  @override
  Future<void> writePredictions(List<StockPrediction> value) async {
    predictions = List.of(value);
  }
}
