import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/screens/home/home_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/state/point_wallet.dart';
import 'package:kabuca_flutter/services/pack_exchange_service.dart';
import 'package:kabuca_flutter/services/quiz_daily_progress_store.dart';
import 'package:kabuca_flutter/widgets/tearable_pack.dart';

void main() {
  Future<void> viewNewCompanyCard(WidgetTester tester) async {
    final button = find.byKey(const Key('new-company-view-card'));
    if (button.evaluate().isEmpty) return;
    await tester.ensureVisible(button);
    await tester.tap(button);
    // SR/UR retain their existing staged reveal after the new-company screen.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> finishOpening(WidgetTester tester) async {
    final packTopLeft = tester.getTopLeft(
      find.byKey(const Key('tearable-pack')),
    );
    await tester.dragFrom(
      packTopLeft + const Offset(24, 42),
      const Offset(280, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(
      tester.state<TearablePackState>(find.byType(TearablePack)).progress,
      greaterThanOrEqualTo(0.96),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  }

  testWidgets('3パックから1つ消費し、3枚を順番に獲得できる', (tester) async {
    final gameState = GameState.memory();
    final totalCards = CardCatalog.cards.length;
    final companyCount = CardCatalog.companyCount;
    final completionRate = 3 * 100 ~/ totalCards;
    await tester.pumpWidget(
      KabucaApp(
        gameState: gameState,
        predictionStore: PredictionStore.memory(),
        notificationStore: NotificationStore.memory(),
      ),
    );

    expect(find.byKey(const Key('home-brand-logo')), findsOneWidget);
    expect(find.text('企業を集めて、未来を予想しよう。'), findsOneWidget);
    expect(find.text('KABUCA PACK'), findsNothing);
    expect(find.text('START PACK'), findsOneWidget);
    expect(find.byKey(const Key('home-brand-logo')), findsOneWidget);
    final homeLogo = tester.widget<Text>(
      find.byKey(const Key('home-brand-logo')),
    );
    expect(homeLogo.style?.letterSpacing, greaterThanOrEqualTo(6));
    expect(homeLogo.style?.fontWeight, FontWeight.w600);
    expect(find.byKey(const Key('notification-bell-button')), findsOneWidget);
    expect(find.byKey(const Key('home-point-balance')), findsOneWidget);
    expect(find.text('0 KABU'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'パックを開ける'), findsOneWidget);
    expect(find.text('0枚'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'パックを開ける'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'パックを開ける'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pack-back-button')), findsOneWidget);
    expect(find.text('左から右へ、封を破ろう'), findsNothing);
    expect(find.text('パック上部を指でなぞってください'), findsNothing);
    expect(find.byKey(const Key('pack-open-guidance')), findsOneWidget);
    expect(
      ModalRoute.of(
        tester.element(find.byType(TearablePack)),
      )!.popGestureEnabled,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('pack-back-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'パックを開ける'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'パックを開ける'));
    await tester.pumpAndSettle();
    await finishOpening(tester);
    await viewNewCompanyCard(tester);

    expect(find.text('CARD 1 / 3'), findsOneWidget);
    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
    expect(find.byKey(const Key('card-metadata')), findsOneWidget);
    expect(find.byKey(const Key('card-rarity')), findsOneWidget);
    expect(find.byKey(const Key('card-title')), findsOneWidget);
    expect(find.byKey(const Key('card-description')), findsOneWidget);
    expect(find.byKey(const Key('card-operation-hint')), findsOneWidget);
    expect(find.text('次へ'), findsNothing);

    await tester.longPress(find.byKey(const Key('card-confirmation-gesture')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-detail-screen')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('detail-owned-count')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('所持 ×1'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('CARD 1 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-confirmation-gesture')));
    await tester.tap(find.byKey(const Key('card-confirmation-gesture')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    await viewNewCompanyCard(tester);
    expect(find.text('CARD 2 / 3'), findsOneWidget);
    expect(find.text('CARD 3 / 3'), findsNothing);
    expect(find.byKey(const Key('card-title')), findsOneWidget);
    expect(find.byKey(const Key('card-description')), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-confirmation-gesture')));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    await viewNewCompanyCard(tester);
    expect(find.text('CARD 3 / 3'), findsOneWidget);
    expect(find.byKey(const Key('card-title')), findsOneWidget);
    expect(find.byKey(const Key('card-description')), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-confirmation-gesture')));
    await tester.pumpAndSettle();
    expect(find.text('3枚獲得！'), findsOneWidget);
    await tester.tap(find.byKey(const Key('collect-cards-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-scroll')), findsOneWidget);
    expect(
      find.text('3 / $totalCards  ・  コンプリート率 $completionRate%'),
      findsOneWidget,
    );

    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('3枚'), findsOneWidget);

    await tester.tap(find.text('図鑑'));
    await tester.pumpAndSettle();
    expect(find.text('図鑑'), findsNWidgets(2));
    expect(
      find.text('3 / $totalCards  ・  コンプリート率 $completionRate%'),
      findsOneWidget,
    );
    var grid = tester.widget<SliverGrid>(
      find.byKey(const Key('collection-grid')),
    );
    expect(grid.delegate.estimatedChildCount, totalCards);
    await tester.tap(find.byKey(const Key('filter-SR')));
    await tester.pumpAndSettle();
    grid = tester.widget<SliverGrid>(find.byKey(const Key('collection-grid')));
    expect(grid.delegate.estimatedChildCount, companyCount);
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
    await tester.tap(find.byKey(const Key('collection-layout-toggle')));
    await tester.tap(find.text('4列'));
    await tester.pumpAndSettle();
    grid = tester.widget<SliverGrid>(find.byKey(const Key('collection-grid')));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      4,
    );
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    final ownedCardsStat = find.text('所持カード');
    await tester.ensureVisible(ownedCardsStat);
    await tester.tap(ownedCardsStat);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-scroll')), findsOneWidget);
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    final completionStat = find.text('図鑑コンプリート率');
    await tester.ensureVisible(completionStat);
    await tester.tap(completionStat);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('collection-scroll')), findsOneWidget);
    await tester.tap(find.text('マイページ'));
    await tester.pumpAndSettle();
    expect(find.text('マイページ'), findsNWidgets(2));
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
  });

  testWidgets('所持パック0かつKABU不足ではKABU開封できない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            gameState: GameState.memory(packCount: 0),
            predictionStore: PredictionStore.memory(),
            notificationStore: NotificationStore.memory(),
          ),
        ),
      ),
    );

    expect(find.text('100 KABUで開ける'), findsOneWidget);
    expect(find.text('あと100 KABUで開けられます'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '100 KABUで開ける'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('所持カード100枚でSUPER PREMIUM PACKが解放される', (tester) async {
    final cards = CardCatalog.cards.take(101).toList();

    Future<void> pumpWithCardCount(int count) async {
      final gameState = GameState.memory(
        cardCounts: {for (final card in cards.take(count)) card.id: 1},
      );
      final pointWallet = PointWallet.memory(currentPoints: 500);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              gameState: gameState,
              predictionStore: PredictionStore.memory(),
              notificationStore: NotificationStore.memory(),
              pointWallet: pointWallet,
              exchangeService: PackExchangeService(
                pointWallet: pointWallet,
                gameState: gameState,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('home-pack-carousel')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('home-pack-carousel')),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
    }

    await pumpWithCardCount(99);
    expect(find.text('SUPER PREMIUM PACK'), findsOneWidget);
    expect(
      find.byKey(const Key('super-premium-pack-lock-guidance')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('super-premium-locked-button')),
          )
          .onPressed,
      isNull,
    );

    await pumpWithCardCount(100);
    expect(find.text('SUPER PREMIUM PACK'), findsOneWidget);
    expect(
      find.byKey(const Key('super-premium-pack-lock-guidance')),
      findsNothing,
    );
    expect(find.text('500 KABUで開ける'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('open-super-premium-pack-button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('画面下部のタブを左右スワイプで移動できる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MainScreen(
          gameState: GameState.memory(),
          predictionStore: PredictionStore.memory(),
          notificationStore: NotificationStore.memory(),
          dailyProgressStore: MemoryQuizDailyProgressStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('クイズ'));
    await tester.pumpAndSettle();
    final pageView = find.byKey(const Key('main-page-view'));
    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('collection-scroll')), findsOneWidget);
    expect(find.text('図鑑'), findsNWidgets(2));
  });
}
