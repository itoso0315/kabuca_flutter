import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/models/app_notification.dart';
import 'package:kabuca_flutter/screens/profile/profile_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/point_wallet.dart';

void main() {
  testWidgets('確認ダイアログのキャンセルではデータを残す', (tester) async {
    final states = await _populatedStates();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            gameState: states.gameState,
            predictionStore: states.predictionStore,
            notificationStore: states.notificationStore,
            pointWallet: states.pointWallet,
          ),
        ),
      ),
    );
    await tester.drag(
      find.byKey(const Key('profile-screen')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('development-data-reset-button')));
    await tester.pumpAndSettle();
    expect(find.text('すべてのテストデータを削除しますか？'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cancel-data-reset-button')));
    await tester.pumpAndSettle();

    expect(states.gameState.totalOwnedCardCount, 2);
    expect(states.predictionStore.predictions, hasLength(1));
  });

  testWidgets('リセット確定でパック・カード・図鑑・予想を即時初期化する', (tester) async {
    final states = await _populatedStates();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            gameState: states.gameState,
            predictionStore: states.predictionStore,
            notificationStore: states.notificationStore,
            pointWallet: states.pointWallet,
          ),
        ),
      ),
    );

    expect(find.text('所持パック  2個'), findsOneWidget);
    expect(find.text('所持カード  2枚'), findsOneWidget);
    expect(find.text('図鑑登録  1 / 80'), findsOneWidget);
    expect(find.text('保存済み予想  1件'), findsOneWidget);
    expect(find.text('お知らせ  1件'), findsOneWidget);
    expect(find.text('KABU  120 KABU'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('profile-screen')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('development-data-reset-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-data-reset-button')));
    await tester.pumpAndSettle();

    expect(find.text('所持パック  3個'), findsOneWidget);
    expect(find.text('所持カード  0枚'), findsOneWidget);
    expect(find.text('図鑑登録  0 / 80'), findsOneWidget);
    expect(find.text('保存済み予想  0件'), findsOneWidget);
    expect(find.text('お知らせ  0件'), findsOneWidget);
    expect(find.text('KABU  0 KABU'), findsOneWidget);
    expect(states.pointWallet.currentPoints, 0);
    expect(states.notificationStore.notifications, isEmpty);
    expect(find.text('開発用データを初期化しました'), findsOneWidget);
  });

  testWidgets('開発ビルドでサンプル通知を追加できる', (tester) async {
    final states = await _populatedStates();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            gameState: states.gameState,
            predictionStore: states.predictionStore,
            notificationStore: states.notificationStore,
            pointWallet: states.pointWallet,
          ),
        ),
      ),
    );
    await tester.drag(
      find.byKey(const Key('profile-screen')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-sample-notification-button')));
    await tester.pumpAndSettle();
    expect(states.notificationStore.notifications, hasLength(2));
    expect(states.notificationStore.unreadCount, 2);
  });
}

Future<_States> _populatedStates() async {
  final card = CardCatalog.cards.first;
  final gameState = GameState.memory();
  await gameState.consumePack();
  await gameState.addCards([card, card]);
  final predictionStore = PredictionStore.memory();
  await predictionStore.addWaiting(
    companyId: card.companyId,
    companyName: card.companyName,
    ticker: card.ticker,
    direction: PredictionDirection.up,
    horizon: PredictionHorizon.oneWeek,
    basePrice: 3000,
    basePriceAt: DateTime.utc(2026, 8, 30),
    targetDate: DateTime.utc(2026, 9, 7),
  );
  final notificationStore = NotificationStore.memory();
  final pointWallet = PointWallet.memory(currentPoints: 120);
  await notificationStore.add(
    AppNotification(
      id: 'sample',
      type: NotificationType.general,
      title: 'サンプル',
      message: 'リセット対象',
      createdAt: DateTime.utc(2026, 8, 30),
      isRead: false,
    ),
  );
  return _States(gameState, predictionStore, notificationStore, pointWallet);
}

class _States {
  const _States(
    this.gameState,
    this.predictionStore,
    this.notificationStore,
    this.pointWallet,
  );
  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PointWallet pointWallet;
}
