import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/theme/company_artwork_registry.dart';
import 'package:kabuca_flutter/widgets/company_card_artwork.dart';

void main() {
  const expectedAssets = <String, String>{
    'toyota': 'assets/toyota_card.png',
    'ntt': 'assets/ntt_card.png',
    'mufg': 'assets/mufg_card.png',
    'sony': 'assets/sony_card.png',
    'inpex': 'assets/inpex_card.png',
    'keyence': 'assets/keyence_card.png',
    'softbank': 'assets/softbank_card.png',
    'recruit': 'assets/recruit_card.png',
  };

  test('companyIdから実在する企業アートを引ける', () {
    for (final entry in expectedAssets.entries) {
      expect(
        CompanyArtworkRegistry.forCompany(entry.key)?.assetPath,
        entry.value,
      );
    }
  });

  test('N/R/SR/URは同じ企業アートを共用する', () {
    final toyotaCards = CardCatalog.cards.where(
      (card) => card.companyId == 'toyota',
    );
    expect(toyotaCards.map((card) => card.rarity).toSet(), CardRarity.values);
    expect(
      toyotaCards
          .map(
            (card) =>
                CompanyArtworkRegistry.forCompany(card.companyId)?.assetPath,
          )
          .toSet(),
      {'assets/toyota_card.png'},
    );
  });

  testWidgets('登録企業はImage.asset、未登録企業は抽象アートを表示する', (tester) async {
    final toyota = CardCatalog.cards.firstWhere(
      (card) => card.companyId == 'toyota',
    );
    final nintendo = CardCatalog.cards.firstWhere(
      (card) => card.companyId == 'nintendo',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            CompanyCardArtwork(
              card: toyota,
              width: 125,
              height: 175,
              compact: true,
            ),
            CompanyCardArtwork(
              card: nintendo,
              width: 125,
              height: 175,
              compact: true,
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('company-artwork-image-toyota')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('company-artwork-fallback-symbol')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
