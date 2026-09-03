import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/historical_stock_price.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/models/stock_quote.dart';
import 'package:kabuca_flutter/services/prediction_resolution_service.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  group('PredictionResolutionService', () {
    test('対象日到達後にUP的中を確定し、永続化と通知を一度だけ行う', () async {
      final storage = _PredictionMemoryStorage();
      final store = await PredictionStore.load(storage: storage);
      final prediction = await _addPrediction(
        store,
        direction: PredictionDirection.up,
      );
      final provider = _HistoricalProvider(close: 1100);
      final notifications = NotificationStore.memory();
      final service = PredictionResolutionService(
        predictionStore: store,
        stockPriceService: StockPriceService(provider),
        notificationStore: notifications,
        now: () => DateTime.utc(2026, 9, 2, 3),
      );

      final first = await service.resolveEligiblePredictions();
      final completed = store.findById(prediction.id)!;
      expect(first.single.status, PredictionResolutionStatus.completed);
      expect(completed.status, PredictionStatus.completed);
      expect(completed.resultPrice, 1100);
      expect(completed.changePercent, closeTo(10, 0.0001));
      expect(completed.isCorrect, isTrue);
      expect(completed.awardedPoints, 50);
      expect(completed.baseReward, 20);
      expect(completed.movementBonus, 30);
      expect(completed.streakBonus, 0);
      expect(completed.correctStreak, 1);
      expect(
        notifications.notifications.single.id,
        'prediction-result-${prediction.id}',
      );

      expect(await service.resolveEligiblePredictions(), isEmpty);
      expect(provider.historicalCalls, 1);
      expect(notifications.notifications, hasLength(1));
      final restored = await PredictionStore.load(storage: storage);
      expect(restored.findById(prediction.id)!.resultPrice, 1100);
      expect(restored.findById(prediction.id)!.correctStreak, 1);
      expect(restored.currentCorrectStreak, 1);
    });

    test('DOWN的中、不的中、同値を仕様どおり判定する', () async {
      Future<StockPrediction> resolve(
        PredictionDirection direction,
        double close,
      ) async {
        final store = PredictionStore.memory();
        await _addPrediction(store, direction: direction);
        final service = PredictionResolutionService(
          predictionStore: store,
          stockPriceService: StockPriceService(
            _HistoricalProvider(close: close),
          ),
          notificationStore: NotificationStore.memory(),
          now: () => DateTime.utc(2026, 9, 2),
        );
        await service.resolveEligiblePredictions();
        return store.predictions.single;
      }

      expect((await resolve(PredictionDirection.down, 900)).isCorrect, isTrue);
      final incorrect = await resolve(PredictionDirection.up, 900);
      expect(incorrect.isCorrect, isFalse);
      expect(incorrect.correctStreak, 0);
      final equal = await resolve(PredictionDirection.up, 1000);
      expect(equal.isCorrect, isFalse);
      expect(equal.awardedPoints, 0);
      expect(equal.correctStreak, 0);
    });

    test('未来、旧データ、取得失敗、分割検出はwaitingを維持する', () async {
      final futureStore = PredictionStore.memory();
      await _addPrediction(futureStore, target: DateTime.utc(2026, 9, 3));
      final futureProvider = _HistoricalProvider(close: 1100);
      final futureService = PredictionResolutionService(
        predictionStore: futureStore,
        stockPriceService: StockPriceService(futureProvider),
        notificationStore: NotificationStore.memory(),
        now: () => DateTime.utc(2026, 9, 2),
      );
      expect(
        (await futureService.resolveEligiblePredictions()).single.status,
        PredictionResolutionStatus.notEligible,
      );
      expect(futureProvider.historicalCalls, 0);

      final legacyStore = PredictionStore.memory(
        predictions: [_legacyPrediction()],
      );
      final legacyService = PredictionResolutionService(
        predictionStore: legacyStore,
        stockPriceService: StockPriceService(_HistoricalProvider(close: 1100)),
        notificationStore: NotificationStore.memory(),
      );
      expect(
        (await legacyService.resolveEligiblePredictions()).single.status,
        PredictionResolutionStatus.legacyData,
      );

      for (final provider in [
        _HistoricalProvider(close: 1100, fail: true),
        _HistoricalProvider(close: 1100, splitDetected: true),
      ]) {
        final store = PredictionStore.memory();
        await _addPrediction(store);
        final service = PredictionResolutionService(
          predictionStore: store,
          stockPriceService: StockPriceService(provider),
          notificationStore: NotificationStore.memory(),
          now: () => DateTime.utc(2026, 9, 2),
        );
        await service.resolveEligiblePredictions();
        expect(store.predictions.single.status, PredictionStatus.waiting);
      }
    });
  });
}

Future<StockPrediction> _addPrediction(
  PredictionStore store, {
  PredictionDirection direction = PredictionDirection.up,
  DateTime? target,
}) async => (await store.addWaiting(
  companyId: 'toyota',
  companyName: 'トヨタ自動車',
  ticker: '7203',
  direction: direction,
  horizon: PredictionHorizon.nextTradingDay,
  basePrice: 1000,
  basePriceAt: DateTime.utc(2026, 9, 1, 6),
  targetDate: target ?? DateTime.utc(2026, 9, 2),
  createdAt: DateTime.utc(2026, 9, 1),
))!;

StockPrediction _legacyPrediction() => StockPrediction(
  id: 'legacy',
  companyId: 'toyota',
  companyName: 'トヨタ自動車',
  ticker: '7203',
  direction: PredictionDirection.up,
  horizon: PredictionHorizon.nextTradingDay,
  createdAt: DateTime.utc(2026, 8, 1),
  status: PredictionStatus.waiting,
);

class _HistoricalProvider
    implements StockPriceProvider, HistoricalStockPriceProvider {
  _HistoricalProvider({
    required this.close,
    this.fail = false,
    this.splitDetected = false,
  });
  final double close;
  final bool fail;
  final bool splitDetected;
  int historicalCalls = 0;

  @override
  Future<HistoricalStockPrice> fetchClosingPrice({
    required String ticker,
    required DateTime tradingDate,
    required DateTime sinceDate,
  }) async {
    historicalCalls++;
    if (fail) throw const StockPriceException('failed');
    return HistoricalStockPrice(
      ticker: ticker,
      tradingDate: tradingDate,
      close: close,
      fetchedAt: DateTime.utc(2026, 9, 2),
      splitDetected: splitDetected,
    );
  }

  @override
  Future<StockQuote> fetchQuote({
    required String ticker,
    required String companyId,
  }) => throw UnimplementedError();
}

class _PredictionMemoryStorage implements PredictionStorage {
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
