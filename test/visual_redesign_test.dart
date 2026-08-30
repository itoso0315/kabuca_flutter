import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/screens/pack/pack_opening_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/theme/company_theme.dart';
import 'package:kabuca_flutter/widgets/company_card_artwork.dart';
import 'package:kabuca_flutter/widgets/kabuca_card_back.dart';
import 'package:kabuca_flutter/widgets/tearable_pack.dart';

void main() {
  CompanyCard cardOf(CardRarity rarity) => CardCatalog.cards.firstWhere(
    (card) => card.companyId == 'toyota' && card.rarity == rarity,
  );

  testWidgets('プレミアムパックにSTART PACK・OPEN・3 CARDSを表示する', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TearablePack(onOpened: () {})));

    expect(find.textContaining('OPEN'), findsOneWidget);
    expect(find.text('START PACK'), findsOneWidget);
    expect(find.text('3 CARDS'), findsOneWidget);
    expect(find.byKey(const Key('pack-open-guidance')), findsOneWidget);
  });

  testWidgets('専用カード裏面からY軸反転して表面を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PackOpeningScreen(
          cards: [cardOf(CardRarity.n)],
          onPackOpened: () {},
          gameState: GameState.memory(),
        ),
      ),
    );
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));
    await tester.dragFrom(topLeft + const Offset(20, 40), const Offset(230, 0));
    for (var index = 0; index < 80; index++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find
          .byKey(const Key('card-confirmation-gesture'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const Key('card-confirmation-gesture')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('card-confirmation-gesture')),
        matching: find.byKey(const Key('kabuca-card-back')),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('card-company-name')), findsNothing);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('card-company-name')), findsOneWidget);
  });

  testWidgets('N/R/SR/URすべてに異なるレアリティ面を適用する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Wrap(
            children: [
              for (final rarity in CardRarity.values)
                CompanyCardArtwork(
                  card: cardOf(rarity),
                  width: 125,
                  height: 175,
                  compact: true,
                ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('card-artwork-surface')), findsNWidgets(4));
    expect(find.text('N'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
    expect(find.text('SR'), findsOneWidget);
    expect(find.text('UR'), findsOneWidget);
    expect(
      CompanyTheme.forCompany('toyota').artworkKind,
      CompanyArtworkKind.motion,
    );
    expect(
      CompanyTheme.forCompany('ntt').artworkKind,
      CompanyArtworkKind.network,
    );
  });

  testWidgets('KABUCA専用カード裏面を単体表示できる', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: KabucaCardBack()));
    expect(find.byKey(const Key('kabuca-card-back')), findsOneWidget);
    expect(find.text('KABUCA'), findsOneWidget);
  });
}
