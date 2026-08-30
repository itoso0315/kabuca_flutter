import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_result_screen.dart';
import 'package:kabuca_flutter/screens/rewards/pack_exchange_screen.dart';
import 'package:kabuca_flutter/services/pack_exchange_service.dart';
import 'package:kabuca_flutter/services/prediction_reward_service.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/point_wallet.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  testWidgets('的中ポイントを受け取ると残高へ反映しボタンが消える', (tester) async {
    final prediction = _prediction(points: 80, correct: true);
    final store = PredictionStore.memory(predictions: [prediction]);
    final wallet = PointWallet.memory();
    final service = PredictionRewardService(
      predictionStore: store,
      pointWallet: wallet,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionResultScreen(
          prediction: prediction,
          predictionStore: store,
          pointWallet: wallet,
          rewardService: service,
        ),
      ),
    );

    expect(find.text('+80pt'), findsOneWidget);
    await tester.tap(find.byKey(const Key('claim-prediction-points-button')));
    await tester.pumpAndSettle();

    expect(wallet.currentPoints, 80);
    expect(find.text('80pt獲得済み'), findsOneWidget);
    expect(
      find.byKey(const Key('claim-prediction-points-button')),
      findsNothing,
    );
  });

  testWidgets('外れ結果には受取操作を表示しない', (tester) async {
    final prediction = _prediction(points: 0, correct: false);
    await tester.pumpWidget(
      MaterialApp(home: PredictionResultScreen(prediction: prediction)),
    );
    expect(find.byKey(const Key('prediction-no-points')), findsOneWidget);
    expect(
      find.byKey(const Key('claim-prediction-points-button')),
      findsNothing,
    );
  });

  testWidgets('ポイント不足では交換不可、100pt以上なら1パック交換する', (tester) async {
    final wallet = PointWallet.memory(currentPoints: 65);
    final gameState = GameState.memory();
    final service = PackExchangeService(
      pointWallet: wallet,
      gameState: gameState,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PackExchangeScreen(
          pointWallet: wallet,
          gameState: gameState,
          exchangeService: service,
        ),
      ),
    );

    expect(find.text('あと35ptで交換できます'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('exchange-standard-pack-button')),
          )
          .onPressed,
      isNull,
    );

    await wallet.refund(35);
    await tester.pump();
    await tester.tap(find.byKey(const Key('exchange-standard-pack-button')));
    await tester.pumpAndSettle();
    expect(wallet.currentPoints, 0);
    expect(gameState.packCount, 4);
  });

  testWidgets('ホームのポイント残高から交換画面へ進み即時反映する', (tester) async {
    final wallet = PointWallet.memory(currentPoints: 150);
    final gameState = GameState.memory();
    await tester.pumpWidget(
      KabucaApp(
        gameState: gameState,
        predictionStore: PredictionStore.memory(),
        notificationStore: NotificationStore.memory(),
        pointWallet: wallet,
      ),
    );

    expect(find.text('150 pt'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-point-balance')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-exchange-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('exchange-standard-pack-button')));
    await tester.pumpAndSettle();
    expect(find.text('50 pt'), findsOneWidget);
    expect(gameState.packCount, 4);
    expect(find.text('スタートパックを1個獲得しました'), findsOneWidget);
    expect(find.byKey(const Key('pack-exchange-open-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pack-exchange-open-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tearable-pack')), findsOneWidget);
  });
}

StockPrediction _prediction({required int points, required bool correct}) =>
    StockPrediction(
      id: 'ui-prediction',
      companyId: 'nintendo',
      companyName: '任天堂',
      ticker: '7974',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.oneWeek,
      createdAt: DateTime.utc(2026, 9, 1),
      status: PredictionStatus.completed,
      basePrice: 1000,
      resultPrice: correct ? 1080 : 920,
      changePercent: correct ? 8 : -8,
      isCorrect: correct,
      awardedPoints: points,
      pointsClaimed: false,
    );
