import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/stock_prediction.dart';
import 'package:kabuca_flutter/screens/prediction/company_prediction_select_screen.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_list_screen.dart';
import 'package:kabuca_flutter/screens/prediction/prediction_result_screen.dart';
import 'package:kabuca_flutter/screens/rewards/pack_exchange_screen.dart';
import 'package:kabuca_flutter/services/pack_exchange_service.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/point_wallet.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';

void main() {
  testWidgets('新規ホームから図鑑空状態を経由してパック導線へ戻れる', (tester) async {
    await tester.pumpWidget(
      KabucaApp(
        gameState: GameState.memory(),
        predictionStore: PredictionStore.memory(),
        notificationStore: NotificationStore.memory(),
        pointWallet: PointWallet.memory(),
      ),
    );

    expect(find.text('企業を集めて、未来を予想しよう。'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'パックを開ける'), findsOneWidget);

    await tester.tap(find.text('図鑑'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-empty-state')), findsOneWidget);
    expect(find.text('まだカードを持っていません'), findsOneWidget);
    await tester.tap(find.byKey(const Key('collection-open-pack-button')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'パックを開ける'), findsOneWidget);
  });

  testWidgets('カード0枚の予想選択はパック収集を案内する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CompanyPredictionSelectScreen(
          gameState: GameState.memory(),
          predictionStore: PredictionStore.memory(),
        ),
      ),
    );
    expect(
      find.byKey(const Key('prediction-company-empty-state')),
      findsOneWidget,
    );
    expect(find.text('予想できる企業がありません'), findsOneWidget);
    expect(
      find.byKey(const Key('prediction-empty-open-pack-button')),
      findsOneWidget,
    );
  });

  testWidgets('予想一覧のCTAは所持カード有無で切り替わる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionListScreen(
          store: PredictionStore.memory(),
          gameState: GameState.memory(),
          onOpenPack: () {},
        ),
      ),
    );
    expect(
      find.byKey(const Key('prediction-list-empty-state')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('prediction-list-open-pack-button')),
      findsOneWidget,
    );

    final card = CardCatalog.cards.first;
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionListScreen(
          store: PredictionStore.memory(),
          gameState: GameState.memory(cardCounts: {card.id: 1}),
          onPredict: () {},
        ),
      ),
    );
    expect(
      find.byKey(const Key('prediction-list-predict-button')),
      findsOneWidget,
    );
    expect(find.text('持っている企業の未来を予想してみよう'), findsOneWidget);
  });

  testWidgets('ポイント0でも貯め方と100pt交換ルールを表示する', (tester) async {
    final wallet = PointWallet.memory();
    final gameState = GameState.memory();
    await tester.pumpWidget(
      MaterialApp(
        home: PackExchangeScreen(
          pointWallet: wallet,
          gameState: gameState,
          exchangeService: PackExchangeService(
            pointWallet: wallet,
            gameState: gameState,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('pack-exchange-earning-hint')), findsOneWidget);
    expect(find.text('株価予想を当てるとポイントが貯まります'), findsOneWidget);
    expect(find.text('100ptで1パック'), findsOneWidget);
  });

  testWidgets('結果画面から次の予想とポイント交換へ進める', (tester) async {
    var predicted = false;
    var exchanged = false;
    final prediction = StockPrediction(
      id: 'result-next-action',
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.oneWeek,
      createdAt: DateTime.utc(2026, 8, 1),
      status: PredictionStatus.completed,
      isCorrect: true,
      awardedPoints: 80,
      pointsClaimed: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PredictionResultScreen(
          prediction: prediction,
          onPredictAgain: () => predicted = true,
          onOpenExchange: () => exchanged = true,
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('prediction-result-next-prediction')),
      300,
    );
    await tester.tap(
      find.byKey(const Key('prediction-result-next-prediction')),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('prediction-result-open-exchange')),
      120,
    );
    await tester.tap(find.byKey(const Key('prediction-result-open-exchange')));
    expect(predicted, isTrue);
    expect(exchanged, isTrue);
  });
}
