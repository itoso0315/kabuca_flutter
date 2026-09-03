import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  test('UP/DOWNと3期間を保存し、再生成後もwaiting予想を復元する', () async {
    final storage = _FakePredictionStorage();
    final store = await PredictionStore.load(storage: storage);

    await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.nextTradingDay,
      createdAt: DateTime(2026),
      basePrice: 3000,
      basePriceAt: DateTime.utc(2026),
      targetDate: DateTime.utc(2026, 1, 5),
    );
    await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.down,
      horizon: PredictionHorizon.oneWeek,
      createdAt: DateTime(2026, 1, 2),
      basePrice: 3001,
      basePriceAt: DateTime.utc(2026, 1, 2),
      targetDate: DateTime.utc(2026, 1, 9),
    );
    await store.addWaiting(
      companyId: 'nintendo',
      companyName: '任天堂',
      ticker: '7974',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.oneMonth,
      createdAt: DateTime(2026, 1, 3),
      basePrice: 10000,
      basePriceAt: DateTime.utc(2026, 1, 3),
      targetDate: DateTime.utc(2026, 2, 3),
    );

    expect(store.waitingPredictions, hasLength(3));
    expect(
      store.predictions.map((item) => item.direction),
      containsAll(PredictionDirection.values),
    );
    expect(
      store.predictions.map((item) => item.horizon),
      containsAll(PredictionHorizon.values),
    );

    final restored = await PredictionStore.load(storage: storage);
    expect(restored.waitingPredictions, hasLength(3));
    expect(
      restored.waitingPredictions.every(
        (item) => item.status == PredictionStatus.waiting,
      ),
      isTrue,
    );

    await restored.resetDevelopmentData();
    expect(restored.predictions, isEmpty);
    expect((await PredictionStore.load(storage: storage)).predictions, isEmpty);
  });

  test('同一企業・同一期間のwaitingは重複不可、別期間は登録可能', () async {
    final store = PredictionStore.memory();
    final first = await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.oneWeek,
      basePrice: 3000,
      basePriceAt: DateTime.utc(2026),
      targetDate: DateTime.utc(2026, 1, 8),
    );
    final duplicate = await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.down,
      horizon: PredictionHorizon.oneWeek,
      basePrice: 3000,
      basePriceAt: DateTime.utc(2026),
      targetDate: DateTime.utc(2026, 1, 8),
    );
    final anotherHorizon = await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.down,
      horizon: PredictionHorizon.oneMonth,
      basePrice: 3000,
      basePriceAt: DateTime.utc(2026),
      targetDate: DateTime.utc(2026, 2, 2),
    );

    expect(first, isNotNull);
    expect(duplicate, isNull);
    expect(anotherHorizon, isNotNull);
    expect(store.waitingPredictions, hasLength(2));
  });

  test('waitingはstreakへ影響せず不正解確定で0へリセットする', () async {
    final completed = StockPrediction(
      id: 'completed',
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.nextTradingDay,
      createdAt: DateTime.utc(2026, 9, 1),
      status: PredictionStatus.completed,
      resultPriceAt: DateTime.utc(2026, 9, 2),
      isCorrect: true,
      correctStreak: 3,
    );
    final waiting = StockPrediction(
      id: 'waiting',
      companyId: 'nintendo',
      companyName: '任天堂',
      ticker: '7974',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.nextTradingDay,
      createdAt: DateTime.utc(2026, 9, 2),
      status: PredictionStatus.waiting,
    );
    final store = PredictionStore.memory(predictions: [completed, waiting]);

    expect(store.currentCorrectStreak, 3);
    await store.complete(
      id: waiting.id,
      resultPrice: 900,
      resultPriceAt: DateTime.utc(2026, 9, 3),
      changePercent: -10,
      isCorrect: false,
      awardedPoints: 0,
      baseReward: 0,
      movementBonus: 0,
      streakBonus: 0,
      correctStreak: 0,
    );
    expect(store.currentCorrectStreak, 0);
  });
}

class _FakePredictionStorage implements PredictionStorage {
  List<StockPrediction> values = [];

  @override
  Future<List<StockPrediction>> readPredictions() async => List.of(values);

  @override
  Future<void> writePredictions(List<StockPrediction> predictions) async {
    values = List.of(predictions);
  }
}
