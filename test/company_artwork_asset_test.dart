import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/theme/company_artwork_registry.dart';
import 'package:kabuca_flutter/widgets/company_card_artwork.dart';

void main() {
  setUp(CompanyArtworkRegistry.resetCacheForTesting);

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

  test('companyIdからCompanyMaster標準パスの実在アートを引ける', () async {
    for (final entry in expectedAssets.entries) {
      expect(
        (await CompanyArtworkRegistry.forCompany(entry.key))?.assetPath,
        entry.value,
      );
    }
  });

  test('N/R/SR/URは同じ企業アートを共用する', () async {
    final toyotaCards = CardCatalog.cards.where(
      (card) => card.companyId == 'toyota',
    );
    expect(toyotaCards.map((card) => card.rarity).toSet(), CardRarity.values);
    final paths = <String?>{};
    for (final card in toyotaCards) {
      paths.add(
        (await CompanyArtworkRegistry.forCompany(card.companyId))?.assetPath,
      );
    }
    expect(paths, {'assets/company_art/toyota.png'});
  });

  test('存在しない標準画像はnullになり例外overrideとalignmentが機能する', () {
    expect(
      CompanyArtworkRegistry.resolveFromAssetKeys('advantest', const {}),
      isNull,
    );

    const exceptionalPath = 'assets/company_art/special.png';
    final artwork = CompanyArtworkRegistry.resolveFromAssetKeys(
      'advantest',
      const {exceptionalPath},
      overrides: const {
        'advantest': CompanyArtworkOverride(
          assetPath: exceptionalPath,
          alignment: Alignment.topCenter,
          fit: BoxFit.contain,
        ),
      },
    );
    expect(artwork?.assetPath, exceptionalPath);
    expect(artwork?.alignment, Alignment.topCenter);
    expect(artwork?.fit, BoxFit.contain);
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
    await tester.pumpAndSettle();

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
