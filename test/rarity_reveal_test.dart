import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/screens/pack/pack_opening_screen.dart';

void main() {
  Future<void> tearToPrelude(WidgetTester tester, CompanyCard card) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PackOpeningScreen(cards: [card], onPackOpened: () {}),
      ),
    );
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));
    await tester.dragFrom(topLeft + const Offset(20, 40), const Offset(230, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  CompanyCard cardOf(CardRarity rarity) =>
      CardCatalog.cards.firstWhere((card) => card.rarity == rarity);

  testWidgets('SRはカード表示前に専用予兆を表示する', (tester) async {
    await tearToPrelude(tester, cardOf(CardRarity.sr));
    expect(find.byKey(const Key('sr-reveal-prelude')), findsOneWidget);
    expect(find.byKey(const Key('card-company-name')), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
  });

  testWidgets('URはSRとは異なる専用予兆を表示する', (tester) async {
    await tearToPrelude(tester, cardOf(CardRarity.ur));
    expect(find.byKey(const Key('ur-reveal-prelude')), findsOneWidget);
    expect(find.byKey(const Key('sr-reveal-prelude')), findsNothing);
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
  });

  testWidgets('Nは特殊予兆なしでカードを表示する', (tester) async {
    await tearToPrelude(tester, cardOf(CardRarity.n));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sr-reveal-prelude')), findsNothing);
    expect(find.byKey(const Key('ur-reveal-prelude')), findsNothing);
    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
  });
}
