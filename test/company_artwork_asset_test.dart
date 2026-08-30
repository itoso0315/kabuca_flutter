import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/theme/company_artwork_registry.dart';
import 'package:kabuca_flutter/widgets/company_card_artwork.dart';

void main() {
  const expectedAssets = <String, String>{
    'toyota': 'assets/company_art/toyota.png',
    'nintendo': 'assets/company_art/nintendo.png',
    'ntt': 'assets/company_art/ntt.png',
    'mufg': 'assets/company_art/mufg.png',
    'sony': 'assets/company_art/sony.png',
    'inpex': 'assets/company_art/inpex.png',
    'keyence': 'assets/company_art/keyence.png',
    'fast_retailing': 'assets/company_art/fast_retailing.png',
    'itochu': 'assets/company_art/itochu.png',
    'nyk': 'assets/company_art/nyk.png',
    'tel': 'assets/company_art/tel.png',
    'softbank': 'assets/company_art/softbank.png',
    'recruit': 'assets/company_art/recruit.png',
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
      {'assets/company_art/toyota.png'},
    );
  });

  testWidgets('登録企業はImage.asset、未登録企業は抽象アートを表示する', (tester) async {
    final toyota = CardCatalog.cards.firstWhere(
      (card) => card.companyId == 'toyota',
    );
    final advantest = CardCatalog.cards.firstWhere(
      (card) => card.companyId == 'advantest',
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
              card: advantest,
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
