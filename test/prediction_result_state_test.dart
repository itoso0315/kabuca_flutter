import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/services/prediction_resolution_service.dart';
import 'package:kabuca_flutter/services/prediction_reward_service.dart';
import 'package:kabuca_flutter/services/stock_price_service.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/point_wallet.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

import 'support/prediction_result_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('日本時間の予定日到来でpendingからresolvingへ移り、completedと旧形式は結果側に残る', () {
    var now = DateTime.utc(2026, 9, 7, 14, 59);
    final store = PredictionStore.memory(
      now: () => now,
      predictions: [
        resultFixture(targetDate: DateTime.utc(2026, 9, 8)),
        resultFixture(
          id: 'completed',
          status: PredictionStatus.completed,
          targetDate: DateTime.utc(2026, 9, 9),
        ),
        resultFixture(id: 'legacy', legacy: true),
      ],
    );
    expect(store.pendingPredictions.map((p) => p.id), ['due']);
    expect(store.resultPredictions.map((p) => p.id), ['completed', 'legacy']);
    now = DateTime.utc(2026, 9, 7, 15);
    expect(store.pendingPredictions, isEmpty);
    expect(store.resultPredictions, hasLength(3));
    expect(store.hasWaiting('toyota', PredictionHorizon.oneWeek), isTrue);
  });

  test('旧JSONのresultSeenはfalseで復元し、確認済み状態を本番保存形式で再読み込みできる', () async {
    final oldJson = resultFixture(status: PredictionStatus.completed).toJson()
      ..remove('resultSeen');
    SharedPreferences.setMockInitialValues({
      'predictions.items': [jsonEncode(oldJson)],
    });
    final store = await PredictionStore.load(now: () => resultTestNow);
    expect(store.unseenResultCount, 1);
    await store.markResultsSeen(store.resultPredictions);
    expect(store.unseenResultCount, 0);
    final restored = await PredictionStore.load(now: () => resultTestNow);
    expect(restored.predictions.single.resultSeen, isTrue);
    expect(restored.predictions.single.status, PredictionStatus.completed);
    expect(restored.predictions.single.awardedPoints, 50);
    expect(restored.unseenResultCount, 0);
  });

  test('resolving確認後も失敗では新着を増やさず、本当に結果確定した時だけ未確認に戻す', () async {
    var now = resultTestNow;
    final provider = ControlledClosingProvider()
      ..error = const StockPriceException('offline');
    final store = PredictionStore.memory(
      predictions: [resultFixture()],
      now: () => now,
    );
    final service = PredictionResolutionService(
      predictionStore: store,
      stockPriceService: StockPriceService(provider),
      notificationStore: NotificationStore.memory(),
      now: () => now,
    );
    await service.resolveEligiblePredictions(automatic: true);
    await service.resolveEligiblePredictions(automatic: true);
    expect(provider.calls, 1);
    expect(store.unseenResultCount, 1);
    await store.markResultsSeen(store.resultPredictions);
    await service.resolveEligiblePredictions();
    expect(provider.calls, 2);
    expect(store.pendingPredictions, isEmpty);
    expect(store.unseenResultCount, 0);
    now = now.add(const Duration(minutes: 1));
    provider.error = null;
    await service.resolveEligiblePredictions(automatic: true);
    expect(provider.calls, 3);
    expect(store.predictions.single.status, PredictionStatus.completed);
    expect(store.unseenResultCount, 1);
  });

  test('取引終了前、休場日、未反映、別日や取引中に取得した日足では確定しない', () async {
    Future<(PredictionStore, ControlledClosingProvider)> resolve({
      required DateTime now,
      required DateTime target,
      DateTime? returnedDate,
      DateTime? fetchedAt,
      StockPriceException? error,
    }) async {
      final provider = ControlledClosingProvider()
        ..returnedDate = returnedDate
        ..fetchedAt = fetchedAt
        ..error = error;
      final store = PredictionStore.memory(
        predictions: [resultFixture(targetDate: target)],
        now: () => now,
      );
      final service = PredictionResolutionService(
        predictionStore: store,
        stockPriceService: StockPriceService(provider),
        notificationStore: NotificationStore.memory(),
        now: () => now,
      );
      expect(
        (await service.resolveEligiblePredictions()).single.status,
        PredictionResolutionStatus.awaitingClose,
      );
      expect(store.pendingPredictions, isEmpty);
      expect(store.predictions.single.status, PredictionStatus.waiting);
      return (store, provider);
    }

    final (_, beforeClose) = await resolve(
      now: DateTime.utc(2026, 9, 8, 6, 29),
      target: DateTime.utc(2026, 9, 8),
    );
    expect(beforeClose.calls, 0);
    for (final holiday in [
      DateTime.utc(2026, 9, 6),
      DateTime.utc(2026, 9, 21),
    ]) {
      final (_, closed) = await resolve(
        now: DateTime.utc(2026, 9, 22, 7),
        target: holiday,
      );
      expect(closed.calls, 0);
    }
    await resolve(
      now: resultTestNow,
      target: DateTime.utc(2026, 9, 7),
      returnedDate: DateTime.utc(2026, 9, 4),
    );
    await resolve(
      now: resultTestNow,
      target: DateTime.utc(2026, 9, 8),
      fetchedAt: DateTime.utc(2026, 9, 8, 6, 29),
    );
    await resolve(
      now: resultTestNow,
      target: DateTime.utc(2026, 9, 8),
      error: const StockPriceException(
        'not yet',
        kind: StockPriceErrorKind.dataNotFound,
      ),
    );
  });

  test('重複する自動チェックは同じ順序付き処理を共有し、結果・通知・報酬は一度だけ', () async {
    final provider = ControlledClosingProvider()..gate = Completer<void>();
    final storage = RecordingPredictionStorage([
      resultFixture(id: 'second', targetDate: DateTime.utc(2026, 9, 8)),
      resultFixture(id: 'first', targetDate: DateTime.utc(2026, 9, 7)),
    ]);
    final store = await PredictionStore.load(
      storage: storage,
      now: () => resultTestNow,
    );
    final notifications = NotificationStore.memory();
    final service = PredictionResolutionService(
      predictionStore: store,
      stockPriceService: StockPriceService(provider),
      notificationStore: notifications,
      now: () => resultTestNow,
    );
    final first = service.resolveEligiblePredictions(automatic: true);
    final repeated = service.resolveEligiblePredictions(automatic: true);
    expect(repeated, same(first));
    expect(provider.calls, 1);
    provider.gate!.complete();
    await Future.wait([first, repeated]);
    await service.resolveEligiblePredictions(automatic: true);
    expect(provider.calls, 2);
    expect(provider.requestedDates, [
      DateTime.utc(2026, 9, 7),
      DateTime.utc(2026, 9, 8),
    ]);
    expect(store.findById('first')!.correctStreak, 1);
    expect(store.findById('second')!.correctStreak, 2);
    expect(notifications.notifications, hasLength(2));
    expect(store.unseenResultCount, 2);

    final wallet = PointWallet.memory();
    final rewards = PredictionRewardService(
      predictionStore: store,
      pointWallet: wallet,
    );
    expect(wallet.currentPoints, 0); // Resolution never auto-claims rewards.
    final claims = await Future.wait([
      rewards.claim('first'),
      rewards.claim('first'),
    ]);
    expect(
      claims.where((result) => result == RewardClaimResult.claimed),
      hasLength(1),
    );
    expect(wallet.currentPoints, 50);
    await service.resolveEligiblePredictions();
    expect(await rewards.claim('first'), RewardClaimResult.alreadyClaimed);
    expect(wallet.currentPoints, 50);
    final restored = await PredictionStore.load(storage: storage);
    expect(restored.findById('first')!.pointsClaimed, isTrue);
    expect(restored.findById('first')!.resultSeen, isFalse);
  });

  test('確認済み保存と報酬受取が重なっても双方の項目を保持する', () async {
    final storage = RecordingPredictionStorage([
      resultFixture(status: PredictionStatus.completed),
    ])..writeGate = Completer<void>();
    final store = await PredictionStore.load(
      storage: storage,
      now: () => resultTestNow,
    );
    final viewed = store.markResultsSeen(store.resultPredictions);
    final claimed = store.markPointsClaimed('due', claimed: true);
    storage.writeGate!.complete();
    await Future.wait([viewed, claimed]);
    final restored = await PredictionStore.load(
      storage: storage,
      now: () => resultTestNow,
    );
    expect(restored.predictions.single.resultSeen, isTrue);
    expect(restored.predictions.single.pointsClaimed, isTrue);
    expect(restored.predictions.single.awardedPoints, 50);
  });

  test('resolvingの古い表示を確認しても、その後完成した結果は既読にしない', () async {
    final store = PredictionStore.memory(
      predictions: [resultFixture()],
      now: () => resultTestNow,
    );
    final oldView = store.resultPredictions;
    final service = PredictionResolutionService(
      predictionStore: store,
      stockPriceService: StockPriceService(ControlledClosingProvider()),
      notificationStore: NotificationStore.memory(),
      now: () => resultTestNow,
    );
    await service.resolveEligiblePredictions();
    await store.markResultsSeen(oldView);
    expect(store.unseenResultCount, 1);
    expect(store.predictions.single.status, PredictionStatus.completed);
  });

  test('保存失敗で既読やcompletedにせず、次の保存・自動確認を継続できる', () async {
    final storage = RecordingPredictionStorage([resultFixture()])
      ..failNextWrite = true;
    final store = await PredictionStore.load(
      storage: storage,
      now: () => resultTestNow,
    );
    await expectLater(
      store.markResultsSeen(store.resultPredictions),
      throwsStateError,
    );
    expect(store.unseenResultCount, 1);
    storage.failNextWrite = true;
    final notifications = NotificationStore.memory();
    final service = PredictionResolutionService(
      predictionStore: store,
      stockPriceService: StockPriceService(ControlledClosingProvider()),
      notificationStore: notifications,
      now: () => resultTestNow,
    );
    expect(
      (await service.resolveEligiblePredictions()).single.status,
      PredictionResolutionStatus.failed,
    );
    expect(store.predictions.single.status, PredictionStatus.waiting);
    expect(notifications.notifications, isEmpty);
    await service.resolveEligiblePredictions();
    expect(store.predictions.single.status, PredictionStatus.completed);
    expect(notifications.notifications, hasLength(1));
  });
}
