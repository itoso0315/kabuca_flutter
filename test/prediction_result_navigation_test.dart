import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/app_notification.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/screens/notifications/notification_screen.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_list_screen.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  testWidgets('判定済み一覧から結果画面を開ける', (tester) async {
    final prediction = _completedPrediction();
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionListScreen(
          store: PredictionStore.memory(predictions: [prediction]),
        ),
      ),
    );

    expect(find.textContaining('結果を見る'), findsOneWidget);
    await tester.tap(find.byKey(Key('prediction-${prediction.id}')));
    await tester.pumpAndSettle();

    expect(find.text('予想的中！'), findsOneWidget);
    expect(find.text('判定価格'), findsOneWidget);
    expect(find.text('獲得 100pt'), findsOneWidget);
  });

  testWidgets('結果通知を既読化して対応する結果へ遷移する', (tester) async {
    final prediction = _completedPrediction();
    final notifications = NotificationStore.memory(
      notifications: [
        AppNotification(
          id: 'prediction-result-${prediction.id}',
          type: NotificationType.predictionResult,
          title: '予想結果',
          message: '予想的中！',
          createdAt: DateTime.utc(2026, 9, 2),
          isRead: false,
          relatedPredictionId: prediction.id,
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(
          store: notifications,
          predictionStore: PredictionStore.memory(predictions: [prediction]),
        ),
      ),
    );

    await tester.tap(
      find.byKey(Key('notification-prediction-result-${prediction.id}')),
    );
    await tester.pumpAndSettle();

    expect(notifications.unreadCount, 0);
    expect(find.text('予想的中！'), findsOneWidget);
  });

  testWidgets('対応予想がない結果通知は既読化だけ行う', (tester) async {
    final notifications = NotificationStore.memory(
      notifications: [
        AppNotification(
          id: 'missing-result',
          type: NotificationType.predictionResult,
          title: '予想結果',
          message: '結果を確認できます',
          createdAt: DateTime.utc(2026, 9, 2),
          isRead: false,
          relatedPredictionId: 'missing',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(
          store: notifications,
          predictionStore: PredictionStore.memory(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('notification-missing-result')));
    await tester.pumpAndSettle();

    expect(notifications.unreadCount, 0);
    expect(find.text('予想結果'), findsOneWidget);
    expect(find.text('判定価格'), findsNothing);
  });
}

StockPrediction _completedPrediction() => StockPrediction(
  id: 'prediction-1',
  companyId: 'toyota',
  companyName: 'トヨタ自動車',
  ticker: '7203',
  direction: PredictionDirection.up,
  horizon: PredictionHorizon.nextTradingDay,
  createdAt: DateTime.utc(2026, 9, 1),
  status: PredictionStatus.completed,
  basePrice: 1000,
  basePriceAt: DateTime.utc(2026, 9, 1, 6),
  targetDate: DateTime.utc(2026, 9, 2),
  resultPrice: 1100,
  resultPriceAt: DateTime.utc(2026, 9, 2),
  changePercent: 10,
  isCorrect: true,
  awardedPoints: 100,
);
