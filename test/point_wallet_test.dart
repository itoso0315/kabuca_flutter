import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/services/pack_exchange_service.dart';
import 'package:kabuca_flutter/services/prediction_reward_service.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/point_wallet.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  test('ポイント初期値は0で、残高と受取済みIDを再起動後も復元する', () async {
    final storage = _WalletStorage();
    final wallet = await PointWallet.load(storage: storage);
    expect(wallet.currentPoints, 0);

    expect(await wallet.claimPredictionReward('prediction-1', 80), isTrue);
    final restored = await PointWallet.load(storage: storage);
    expect(restored.currentPoints, 80);
    expect(restored.hasClaimedPrediction('prediction-1'), isTrue);
  });

  test('旧completed予想の報酬を一度だけ受け取りpointsClaimedを保存する', () async {
    final predictionStorage = _PredictionStorage();
    predictionStorage.values = [_completedPrediction(pointsClaimed: null)];
    final restoredStore = await PredictionStore.load(
      storage: predictionStorage,
    );
    final wallet = PointWallet.memory();
    final service = PredictionRewardService(
      predictionStore: restoredStore,
      pointWallet: wallet,
      now: () => DateTime.utc(2026, 9, 3),
    );

    expect(await service.claim('prediction-1'), RewardClaimResult.claimed);
    expect(wallet.currentPoints, 80);
    expect(restoredStore.findById('prediction-1')!.pointsClaimed, isTrue);
    expect(
      await service.claim('prediction-1'),
      RewardClaimResult.alreadyClaimed,
    );
    expect(wallet.currentPoints, 80);
  });

  test('0ptの外れ予想は受取できない', () async {
    final store = PredictionStore.memory(
      predictions: [_completedPrediction(points: 0, correct: false)],
    );
    final wallet = PointWallet.memory();
    final service = PredictionRewardService(
      predictionStore: store,
      pointWallet: wallet,
    );
    expect(await service.claim('prediction-1'), RewardClaimResult.unavailable);
    expect(wallet.currentPoints, 0);
  });

  test('受取を連続実行しても報酬は一度だけ加算する', () async {
    final store = PredictionStore.memory(predictions: [_completedPrediction()]);
    final wallet = PointWallet.memory();
    final service = PredictionRewardService(
      predictionStore: store,
      pointWallet: wallet,
    );

    final results = await Future.wait([
      service.claim('prediction-1'),
      service.claim('prediction-1'),
    ]);
    expect(
      results.where((item) => item == RewardClaimResult.claimed),
      hasLength(1),
    );
    expect(wallet.currentPoints, 80);
  });

  test('100ptで1パック交換し、残高とパック数を復元できる', () async {
    final walletStorage = _WalletStorage(
      const PointWalletSnapshot(balance: 150, claimedPredictionIds: {}),
    );
    final gameStorage = _GameStorage(packCount: 3);
    final wallet = await PointWallet.load(storage: walletStorage);
    final gameState = await GameState.load(storage: gameStorage);
    final service = PackExchangeService(
      pointWallet: wallet,
      gameState: gameState,
    );

    expect(await service.exchangeStandardPack(), PackExchangeResult.exchanged);
    expect(wallet.currentPoints, 50);
    expect(gameState.packCount, 4);
    expect(
      await service.exchangeStandardPack(),
      PackExchangeResult.insufficientPoints,
    );

    expect((await PointWallet.load(storage: walletStorage)).currentPoints, 50);
    expect((await GameState.load(storage: gameStorage)).packCount, 4);
  });

  test('パック追加失敗時は消費ポイントを戻す', () async {
    final wallet = PointWallet.memory(currentPoints: 100);
    final gameState = await GameState.load(storage: _FailingGameStorage());
    final service = PackExchangeService(
      pointWallet: wallet,
      gameState: gameState,
    );

    await expectLater(service.exchangeStandardPack(), throwsStateError);
    expect(wallet.currentPoints, 100);
    expect(gameState.packCount, 3);
  });

  test('交換を連続実行しても1回分だけ交換する', () async {
    final wallet = PointWallet.memory(currentPoints: 200);
    final gameState = GameState.memory();
    final service = PackExchangeService(
      pointWallet: wallet,
      gameState: gameState,
    );

    final results = await Future.wait([
      service.exchangeStandardPack(),
      service.exchangeStandardPack(),
    ]);
    expect(
      results.where((item) => item == PackExchangeResult.exchanged),
      hasLength(1),
    );
    expect(gameState.packCount, 4);
    expect(wallet.currentPoints, 100);
  });
}

StockPrediction _completedPrediction({
  int points = 80,
  bool correct = true,
  bool? pointsClaimed = false,
}) => StockPrediction(
  id: 'prediction-1',
  companyId: 'nintendo',
  companyName: '任天堂',
  ticker: '7974',
  direction: PredictionDirection.up,
  horizon: PredictionHorizon.oneWeek,
  createdAt: DateTime.utc(2026, 9, 1),
  status: PredictionStatus.completed,
  basePrice: 1000,
  basePriceAt: DateTime.utc(2026, 9, 1),
  targetDate: DateTime.utc(2026, 9, 2),
  resultPrice: correct ? 1080 : 920,
  resultPriceAt: DateTime.utc(2026, 9, 2),
  changePercent: correct ? 8 : -8,
  isCorrect: correct,
  awardedPoints: points,
  pointsClaimed: pointsClaimed,
);

class _WalletStorage implements PointWalletStorage {
  _WalletStorage([
    this.snapshot = const PointWalletSnapshot(
      balance: 0,
      claimedPredictionIds: {},
    ),
  ]);
  PointWalletSnapshot snapshot;

  @override
  Future<PointWalletSnapshot> read() async => snapshot;

  @override
  Future<void> write(PointWalletSnapshot value) async {
    snapshot = PointWalletSnapshot(
      balance: value.balance,
      claimedPredictionIds: Set.of(value.claimedPredictionIds),
    );
  }
}

class _PredictionStorage implements PredictionStorage {
  List<StockPrediction> values = [];
  @override
  Future<List<StockPrediction>> readPredictions() async => List.of(values);
  @override
  Future<void> writePredictions(List<StockPrediction> predictions) async {
    values = List.of(predictions);
  }
}

class _GameStorage implements GameStorage {
  _GameStorage({this.packCount});
  int? packCount;
  Map<String, int> cards = {};
  @override
  Future<Map<String, int>> readCardCounts() async => Map.of(cards);
  @override
  Future<int?> readPackCount() async => packCount;
  @override
  Future<void> writeCardCounts(Map<String, int> value) async => cards = value;
  @override
  Future<void> writePackCount(int value) async => packCount = value;
}

class _FailingGameStorage extends _GameStorage {
  _FailingGameStorage() : super(packCount: 3);
  @override
  Future<void> writePackCount(int value) async => throw StateError('failed');
}
