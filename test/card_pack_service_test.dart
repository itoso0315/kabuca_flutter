import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/data/card_catalog.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/services/card_pack_service.dart';
import 'package:kabuca_flutter/models/pack_type.dart';

void main() {
  test('CardCatalogは日経225社×4レアリティの900枚を持つ', () {
    expect(CardCatalog.cards, hasLength(225 * CardRarity.values.length));
  });

  test('CardCatalogには225社すべてのcompanyIdが含まれる', () {
    final companyIds = CardCatalog.cards.map((card) => card.companyId).toSet();
    expect(companyIds, hasLength(225));
  });

  test('1パック3枚で同一企業は重複しない', () {
    for (var seed = 0; seed < 100; seed++) {
      final cards = CardPackService(random: Random(seed)).openPack();
      expect(cards, hasLength(3));
      expect(cards.map((card) => card.id).toSet(), hasLength(3));
      expect(cards.map((card) => card.companyId).toSet(), hasLength(3));
    }
  });

  test('Random注入により抽選結果を再現できる', () {
    final first = CardPackService(random: Random(42)).openPack();
    final second = CardPackService(random: Random(42)).openPack();
    expect(
      first.map((card) => card.id),
      orderedEquals(second.map((card) => card.id)),
    );
  });

  test('通常枠はNまたはRのみで境界値が正しい', () {
    expect(CardPackService.normalSlotRarityForRoll(0), CardRarity.n);
    expect(CardPackService.normalSlotRarityForRoll(0.759999), CardRarity.n);
    expect(CardPackService.normalSlotRarityForRoll(0.76), CardRarity.r);
    expect(CardPackService.normalSlotRarityForRoll(0.999999), CardRarity.r);
  });

  test('START PACK3枚目のレアリティ確率の境界値が正しい', () {
    expect(
      CardPackService.finalSlotRarityForRoll(0, type: PackType.starter),
      CardRarity.n,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.589999, type: PackType.starter),
      CardRarity.n,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.59, type: PackType.starter),
      CardRarity.r,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.779999, type: PackType.starter),
      CardRarity.r,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.78, type: PackType.starter),
      CardRarity.sr,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.969999, type: PackType.starter),
      CardRarity.sr,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.97, type: PackType.starter),
      CardRarity.ur,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.999999, type: PackType.starter),
      CardRarity.ur,
    );
  });

  test('PREMIUM PACK3枚目のレアリティ確率の境界値が正しい', () {
    expect(
      CardPackService.finalSlotRarityForRoll(0, type: PackType.premium),
      CardRarity.n,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.379999, type: PackType.premium),
      CardRarity.n,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.38, type: PackType.premium),
      CardRarity.r,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.499999, type: PackType.premium),
      CardRarity.r,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.50, type: PackType.premium),
      CardRarity.sr,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.919999, type: PackType.premium),
      CardRarity.sr,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.92, type: PackType.premium),
      CardRarity.ur,
    );
    expect(
      CardPackService.finalSlotRarityForRoll(0.999999, type: PackType.premium),
      CardRarity.ur,
    );
  });

  test('SUPER PREMIUM PACKは全枠R以上でPREMIUMより上位確率が高い', () {
    expect(CardPackService.superPremiumSlotRarityForRoll(0), CardRarity.r);
    expect(CardPackService.superPremiumSlotRarityForRoll(0.20), CardRarity.sr);
    expect(CardPackService.superPremiumSlotRarityForRoll(0.75), CardRarity.ur);

    for (var seed = 0; seed < 100; seed++) {
      final cards = CardPackService(
        random: Random(seed),
      ).openPack(type: PackType.superPremium);
      expect(
        cards,
        everyElement(
          predicate<CompanyCard>((card) => card.rarity != CardRarity.n),
        ),
      );
    }
  });

  test('SRまたはURが出る場合は必ず3枚目に入る', () {
    for (var seed = 0; seed < 500; seed++) {
      final cards = CardPackService(random: Random(seed)).openPack();
      expect(cards[0].rarity, isNot(anyOf(CardRarity.sr, CardRarity.ur)));
      expect(cards[1].rarity, isNot(anyOf(CardRarity.sr, CardRarity.ur)));
    }
  });
}
