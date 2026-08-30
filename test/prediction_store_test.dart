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
    );
    await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.down,
      horizon: PredictionHorizon.oneWeek,
      createdAt: DateTime(2026, 1, 2),
    );
    await store.addWaiting(
      companyId: 'nintendo',
      companyName: '任天堂',
      ticker: '7974',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.oneMonth,
      createdAt: DateTime(2026, 1, 3),
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
  });

  test('同一企業・同一期間のwaitingは重複不可、別期間は登録可能', () async {
    final store = PredictionStore.memory();
    final first = await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.oneWeek,
    );
    final duplicate = await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.down,
      horizon: PredictionHorizon.oneWeek,
    );
    final anotherHorizon = await store.addWaiting(
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.down,
      horizon: PredictionHorizon.oneMonth,
    );

    expect(first, isNotNull);
    expect(duplicate, isNull);
    expect(anotherHorizon, isNotNull);
    expect(store.waitingPredictions, hasLength(2));
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
