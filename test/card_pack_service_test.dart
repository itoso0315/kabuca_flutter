import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/services/card_pack_service.dart';

void main() {
  test('1パック3枚で同一カードIDは重複しない', () {
    for (var seed = 0; seed < 100; seed++) {
      final cards = CardPackService(random: Random(seed)).openPack();
      expect(cards, hasLength(3));
      expect(cards.map((card) => card.id).toSet(), hasLength(3));
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

  test('レアリティ確率の境界値が正しい', () {
    expect(CardPackService.rarityForRoll(0), CardRarity.n);
    expect(CardPackService.rarityForRoll(0.699999), CardRarity.n);
    expect(CardPackService.rarityForRoll(0.70), CardRarity.r);
    expect(CardPackService.rarityForRoll(0.919999), CardRarity.r);
    expect(CardPackService.rarityForRoll(0.92), CardRarity.sr);
    expect(CardPackService.rarityForRoll(0.989999), CardRarity.sr);
    expect(CardPackService.rarityForRoll(0.99), CardRarity.ur);
    expect(CardPackService.rarityForRoll(0.999999), CardRarity.ur);
  });
}
