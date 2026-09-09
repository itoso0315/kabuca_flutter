import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stock_prediction.dart';
import '../services/trading_calendar_service.dart';

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
  PredictionStore._(
    this._storage,
    Iterable<StockPrediction> predictions,
    DateTime Function()? now,
  ) : _predictions = List.of(predictions),
      _now = now ?? DateTime.now;

  final PredictionStorage _storage;
  final List<StockPrediction> _predictions;
  final DateTime Function() _now;
  Future<void> _mutationTail = Future<void>.value();

  DateTime get now => _now();

  // targetDate is a Japanese calendar date encoded as UTC midnight, not an
  // instant at UTC midnight. Use the same date convention as the resolver.
  bool isPending(StockPrediction prediction) =>
      prediction.status == PredictionStatus.waiting &&
      prediction.targetDate != null &&
      prediction.targetDate!.isAfter(JapanTime.dateOf(now));

  List<StockPrediction> get pendingPredictions =>
      _predictions.where(isPending).toList(growable: false);

  // Old waiting records without a target date stay visible on the result side.
  List<StockPrediction> get resultPredictions => _predictions
      .where((prediction) => !isPending(prediction))
      .toList(growable: false);

  int get unseenResultCount => resultPredictions
      .where((prediction) => !prediction.resultSeen)
      .map((prediction) => prediction.id)
      .toSet()
      .length;

  void refreshTime() => notifyListeners();

  List<StockPrediction> get predictions => List.unmodifiable(_predictions);
  List<StockPrediction> get waitingPredictions => _predictions
      .where((prediction) => prediction.status == PredictionStatus.waiting)
      .toList(growable: false);

  static Future<PredictionStore> load({
    PredictionStorage? storage,
    DateTime Function()? now,
  }) async {
    final target = storage ?? SharedPreferencesPredictionStorage();
    return PredictionStore._(target, await target.readPredictions(), now);
  }

  static PredictionStore memory({
    Iterable<StockPrediction> predictions = const [],
    DateTime Function()? now,
  }) => PredictionStore._(_MemoryPredictionStorage(), predictions, now);

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

  /// Legacy completed predictions have no correctStreak and intentionally do
  /// not seed the new KABU streak system.
  int get currentCorrectStreak {
    final resolved =
        _predictions
            .where(
              (prediction) =>
                  prediction.status == PredictionStatus.completed &&
                  prediction.correctStreak != null,
            )
            .toList()
          ..sort((a, b) {
            final aDate = a.resultPriceAt ?? a.createdAt;
            final bDate = b.resultPriceAt ?? b.createdAt;
            final dateOrder = aDate.compareTo(bDate);
            return dateOrder != 0
                ? dateOrder
                : a.createdAt.compareTo(b.createdAt);
          });
    return resolved.isEmpty ? 0 : resolved.last.correctStreak!;
  }

  Future<StockPrediction?> complete({
    required String id,
    required double resultPrice,
    required DateTime resultPriceAt,
    required double changePercent,
    required bool isCorrect,
    required int awardedPoints,
    required int baseReward,
    required int movementBonus,
    required int streakBonus,
    required int correctStreak,
  }) => _mutate(() async {
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
      baseReward: baseReward,
      movementBonus: movementBonus,
      streakBonus: streakBonus,
      correctStreak: correctStreak,
      pointsClaimed: false,
      // A result that finishes after its resolving row was seen is new again.
      resultSeen: false,
    );
    await _commit(List<StockPrediction>.of(_predictions)..[index] = completed);
    return completed;
  });

  Future<StockPrediction?> markPointsClaimed(
    String id, {
    required bool claimed,
    DateTime? claimedAt,
  }) => _mutate(() async {
    final index = _predictions.indexWhere((item) => item.id == id);
    if (index < 0 || _predictions[index].status != PredictionStatus.completed) {
      return null;
    }
    final updated = _predictions[index].copyWith(
      pointsClaimed: claimed,
      pointsClaimedAt: claimed ? claimedAt ?? DateTime.now().toUtc() : null,
    );
    final next = List<StockPrediction>.of(_predictions)..[index] = updated;
    await _commit(next);
    return updated;
  });

  /// Acknowledge only the state actually shown. If a waiting row completes
  /// while this write is queued, its newly available result stays unseen.
  Future<void> markResultsSeen(Iterable<StockPrediction> viewed) {
    final versions = {
      for (final prediction in viewed) prediction.id: prediction.status,
    };
    return _mutate(() async {
      var changed = false;
      final next = _predictions.map((prediction) {
        if (versions[prediction.id] != prediction.status ||
            prediction.resultSeen ||
            isPending(prediction)) {
          return prediction;
        }
        changed = true;
        return prediction.copyWith(resultSeen: true);
      }).toList();
      if (changed) await _commit(next);
    });
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
    DateTime? basePriceDate,
    DateTime? createdAt,
  }) => _mutate(() async {
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
      basePriceDate: basePriceDate,
      targetDate: targetDate,
    );
    await _commit([..._predictions, prediction]);
    return prediction;
  });

  Future<void> resetDevelopmentData() => _mutate(() => _commit([]));

  // Seen-state, resolution and reward writes must not overwrite each other's
  // fields when automatic checks and user actions happen at the same time.
  Future<T> _mutate<T>(Future<T> Function() action) {
    final result = _mutationTail.then((_) => action());
    _mutationTail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _commit(List<StockPrediction> next) async {
    await _storage.writePredictions(next);
    _predictions
      ..clear()
      ..addAll(next);
    notifyListeners();
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
