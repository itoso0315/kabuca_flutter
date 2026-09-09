import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/screens/pack/pack_opening_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';

void main() {
  Future<void> tearAndWaitForReveal(
    WidgetTester tester,
    CompanyCard card,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PackOpeningScreen(
          cards: [card],
          onPackOpened: () {},
          gameState: GameState.memory(),
        ),
      ),
    );
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));
    await tester.dragFrom(topLeft + const Offset(20, 40), const Offset(400, 0));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('NEW COMPANY'), findsOneWidget);
    final viewCard = find.byKey(const Key('new-company-view-card'));
    await tester.ensureVisible(viewCard);
    await tester.tap(viewCard);
    await tester.pump();
    if (card.rarity == CardRarity.sr || card.rarity == CardRarity.ur) {
      expect(
        find.byKey(Key('${card.rarity.name}-reveal-prelude')),
        findsOneWidget,
      );
    }
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('card-confirmation-gesture')), findsOneWidget);
  }

  CompanyCard cardOf(CardRarity rarity) =>
      CardCatalog.cards.firstWhere((card) => card.rarity == rarity);

  testWidgets('SRカードを最後まで表示できる', (tester) async {
    await tearAndWaitForReveal(tester, cardOf(CardRarity.sr));

    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
    expect(find.byKey(const Key('pack-complete-title')), findsNothing);
  });

  testWidgets('URカードを最後まで表示できる', (tester) async {
    await tearAndWaitForReveal(tester, cardOf(CardRarity.ur));

    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
    expect(find.byKey(const Key('pack-complete-title')), findsNothing);
  });

  testWidgets('Nカードを最後まで表示できる', (tester) async {
    await tearAndWaitForReveal(tester, cardOf(CardRarity.n));

    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
    expect(find.byKey(const Key('pack-complete-title')), findsNothing);
  });
}
