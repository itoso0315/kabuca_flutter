import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';

void main() {
  test('20社以上の各企業にN/R/SR/URがありIDが一意', () {
    expect(CardCatalog.companyCount, greaterThanOrEqualTo(20));
    expect(CardCatalog.cards, hasLength(CardCatalog.companyCount * 4));

    final ids = CardCatalog.cards.map((card) => card.id).toSet();
    expect(ids, hasLength(CardCatalog.cards.length));

    final companyIds = CardCatalog.cards.map((card) => card.companyId).toSet();
    for (final companyId in companyIds) {
      final rarities = CardCatalog.cards
          .where((card) => card.companyId == companyId)
          .map((card) => card.rarity)
          .toSet();
      expect(rarities, CardRarity.values.toSet());
    }
  });

  test('同じ企業でもレアリティごとに異なる情報を持つ', () {
    final toyota = CardCatalog.cards
        .where((card) => card.companyId == 'toyota')
        .toList();
    expect(toyota, hasLength(4));
    expect(toyota.map((card) => card.title).toSet(), hasLength(4));
    expect(toyota.map((card) => card.description).toSet(), hasLength(4));
    expect(toyota.map((card) => card.id).toSet(), hasLength(4));
  });
}
