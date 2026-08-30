import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/app/app.dart';
import 'package:kabuca_flutter/screens/home/home_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/state/notification_store.dart';
import 'package:kabuca_flutter/state/prediction_store.dart';
import 'package:kabuca_flutter/widgets/tearable_pack.dart';

void main() {
  Future<void> finishOpening(WidgetTester tester) async {
    final packTopLeft = tester.getTopLeft(
      find.byKey(const Key('tearable-pack')),
    );
    await tester.dragFrom(
      packTopLeft + const Offset(24, 42),
      const Offset(230, 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(
      tester.state<TearablePackState>(find.byType(TearablePack)).progress,
      1,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
  }

  testWidgets('3パックから1つ消費し、3枚を順番に獲得できる', (tester) async {
    await tester.pumpWidget(
      KabucaApp(
        gameState: GameState.memory(),
        predictionStore: PredictionStore.memory(),
        notificationStore: NotificationStore.memory(),
      ),
    );

    expect(find.text('KABUCA'), findsNWidgets(2));
    expect(find.text('集めよう、日本の企業。'), findsOneWidget);
    expect(find.text('KABUCA PACK'), findsNothing);
    expect(find.text('スタートパック'), findsOneWidget);
    expect(find.byKey(const Key('home-brand-logo')), findsOneWidget);
    final homeLogo = tester.widget<Text>(
      find.byKey(const Key('home-brand-logo')),
    );
    expect(homeLogo.style?.letterSpacing, greaterThanOrEqualTo(6));
    expect(homeLogo.style?.fontWeight, FontWeight.w600);
    expect(find.byKey(const Key('notification-bell-button')), findsOneWidget);
    expect(find.byKey(const Key('home-point-balance')), findsOneWidget);
    expect(find.text('0 pt'), findsOneWidget);
    expect(find.text('所持パック  3'), findsOneWidget);
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
    expect(find.text('所持パック  3'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'パックを開ける'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'パックを開ける'));
    await tester.pumpAndSettle();
    await finishOpening(tester);

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
    expect(find.text('CARD 3 / 3'), findsOneWidget);
    expect(find.byKey(const Key('card-title')), findsOneWidget);
    expect(find.byKey(const Key('card-description')), findsOneWidget);

    await tester.tap(find.byKey(const Key('card-confirmation-gesture')));
    await tester.pumpAndSettle();
    expect(find.text('3枚獲得！'), findsOneWidget);
    await tester.tap(find.byKey(const Key('collect-cards-button')));
    await tester.pumpAndSettle();
    expect(find.text('所持パック  2'), findsOneWidget);
    expect(find.text('3枚'), findsOneWidget);

    await tester.tap(find.text('図鑑'));
    await tester.pumpAndSettle();
    expect(find.text('図鑑'), findsNWidgets(2));
    expect(find.text('3 / 80  ・  コンプリート率 3%'), findsOneWidget);
    var grid = tester.widget<SliverGrid>(
      find.byKey(const Key('collection-grid')),
    );
    expect(grid.delegate.estimatedChildCount, 80);
    await tester.tap(find.byKey(const Key('filter-SR')));
    await tester.pumpAndSettle();
    grid = tester.widget<SliverGrid>(find.byKey(const Key('collection-grid')));
    expect(grid.delegate.estimatedChildCount, 20);
    await tester.tap(find.text('マイページ'));
    await tester.pumpAndSettle();
    expect(find.text('マイページ'), findsNWidgets(2));
    await tester.tap(find.text('ホーム'));
    await tester.pumpAndSettle();
    expect(find.text('所持パック  2'), findsOneWidget);
  });

  testWidgets('所持パック0では開封できない', (tester) async {
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

    expect(find.text('所持パック  0'), findsOneWidget);
    expect(find.text('パックを獲得しよう'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'パックを開ける'),
    );
    expect(button.onPressed, isNull);
  });
}
