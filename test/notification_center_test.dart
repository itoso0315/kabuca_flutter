import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/app_notification.dart';
import 'package:kabuca_flutter/screens/home/home_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  Widget home(NotificationStore store) => MaterialApp(
    home: Scaffold(
      body: HomeScreen(
        gameState: GameState.memory(),
        predictionStore: PredictionStore.memory(),
        notificationStore: store,
      ),
    ),
  );

  testWidgets('未読0件はバッジなしで、ベルから空の通知一覧へ進む', (tester) async {
    await tester.pumpWidget(home(NotificationStore.memory()));
    expect(find.byKey(const Key('notification-bell-button')), findsOneWidget);
    expect(find.byKey(const Key('notification-unread-badge')), findsNothing);
    await tester.tap(find.byKey(const Key('notification-bell-button')));
    await tester.pumpAndSettle();
    expect(find.text('お知らせ'), findsOneWidget);
    expect(find.byKey(const Key('notification-empty-state')), findsOneWidget);
  });

  testWidgets('未読バッジを表示し、通知タップで既読化する', (tester) async {
    final store = NotificationStore.memory(
      notifications: [
        AppNotification(
          id: 'result',
          type: NotificationType.predictionResult,
          title: '予想結果が出ました',
          message: '任天堂の答え合わせができます',
          createdAt: DateTime.utc(2026, 8, 30, 1, 30),
          isRead: false,
          relatedPredictionId: 'prediction-1',
        ),
      ],
    );
    await tester.pumpWidget(home(store));
    expect(find.byKey(const Key('notification-unread-badge')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification-bell-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification-unread-dot')), findsOneWidget);
    await tester.tap(find.byKey(const Key('notification-result')));
    await tester.pumpAndSettle();
    expect(store.unreadCount, 0);
    expect(find.byKey(const Key('notification-unread-dot')), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notification-unread-badge')), findsNothing);
  });

  testWidgets('すべて既読で未読を一括更新する', (tester) async {
    final store = NotificationStore.memory(
      notifications: [
        for (var index = 0; index < 2; index++)
          AppNotification(
            id: 'item-$index',
            type: NotificationType.reward,
            title: '報酬$index',
            message: 'パックを獲得しました',
            createdAt: DateTime.utc(2026, 8, 30, index),
            isRead: false,
          ),
      ],
    );
    await tester.pumpWidget(home(store));
    await tester.tap(find.byKey(const Key('notification-bell-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mark-all-notifications-read')));
    await tester.pumpAndSettle();
    expect(store.unreadCount, 0);
  });
}
