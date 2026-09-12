import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/screens/pack/pack_opening_screen.dart';
import 'package:kabuca_flutter/state/game_state.dart';
import 'package:kabuca_flutter/theme/company_theme.dart';
import 'package:kabuca_flutter/widgets/company_card_artwork.dart';
import 'package:kabuca_flutter/widgets/daily_pack_card.dart';
import 'package:kabuca_flutter/widgets/kabuca_card_back.dart';
import 'package:kabuca_flutter/widgets/tearable_pack.dart';

void main() {
  CompanyCard cardOf(CardRarity rarity) => CardCatalog.cards.firstWhere(
    (card) => card.companyId == 'toyota' && card.rarity == rarity,
  );

  testWidgets('PREMIUM PACKにSTART PACK・OPEN・3 CARDSを表示する', (tester) async {
    await tester.pumpWidget(MaterialApp(home: TearablePack(onOpened: () {})));

    expect(find.textContaining('OPEN'), findsOneWidget);
    expect(find.text('START PACK'), findsOneWidget);
    expect(find.text('3 CARDS'), findsOneWidget);
    expect(find.byKey(const Key('pack-open-guidance')), findsOneWidget);
  });

  testWidgets('PREMIUM PACKにSR・UR排出率の違いを表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyPackCard(
          onOpen: () {},
          packCount: 1,
          packName: 'PREMIUM PACK',
          isPremium: true,
        ),
      ),
    );

    expect(
      find.byKey(const Key('premium-pack-rarity-guidance')),
      findsOneWidget,
    );
    expect(
      find.text('SR 42% / UR 8%  (START PACK: SR 19% / UR 3%)'),
      findsOneWidget,
    );
  });

  testWidgets('SUPER PREMIUM PACKにR以上の排出率を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailyPackCard(
          onOpen: () {},
          packCount: 1,
          packName: 'SUPER PREMIUM PACK',
          isPremium: true,
          isSuperPremium: true,
        ),
      ),
    );

    expect(
      find.byKey(const Key('super-premium-pack-rarity-guidance')),
      findsOneWidget,
    );
    expect(find.text('R 20% / SR 55% / UR 25%'), findsOneWidget);
  });

  testWidgets('パック開封後にカード表面を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PackOpeningScreen(
          cards: [cardOf(CardRarity.n)],
          onPackOpened: () {},
          gameState: GameState.memory(),
        ),
      ),
    );
    expect(find.byKey(const Key('card-company-name')), findsNothing);
    final topLeft = tester.getTopLeft(find.byKey(const Key('tearable-pack')));
    await tester.dragFrom(topLeft + const Offset(20, 40), const Offset(400, 0));

    for (var index = 0; index < 40; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

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
