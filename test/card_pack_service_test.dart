import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/company_card.dart';
import 'package:kabuca_flutter/services/card_pack_service.dart';
import 'package:kabuca_flutter/models/pack_type.dart';

void main() {
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

  test('スタートパックのレアリティ確率の境界値が正しい', () {
    expect(
      CardPackService.rarityForRoll(0, type: PackType.starter),
      CardRarity.n,
    );
    expect(
      CardPackService.rarityForRoll(0.699999, type: PackType.starter),
      CardRarity.n,
    );
    expect(
      CardPackService.rarityForRoll(0.70, type: PackType.starter),
      CardRarity.r,
    );
    expect(
      CardPackService.rarityForRoll(0.919999, type: PackType.starter),
      CardRarity.r,
    );
    expect(
      CardPackService.rarityForRoll(0.92, type: PackType.starter),
      CardRarity.sr,
    );
    expect(
      CardPackService.rarityForRoll(0.989999, type: PackType.starter),
      CardRarity.sr,
    );
    expect(
      CardPackService.rarityForRoll(0.99, type: PackType.starter),
      CardRarity.ur,
    );
    expect(
      CardPackService.rarityForRoll(0.999999, type: PackType.starter),
      CardRarity.ur,
    );
  });

  test('プレミアムパックはSR・URウェイトを3倍にして正規化する', () {
    const nEnd = 70 / 116;
    const rEnd = 92 / 116;
    const srEnd = 113 / 116;

    expect(
      CardPackService.rarityForRoll(0, type: PackType.premium),
      CardRarity.n,
    );
    expect(
      CardPackService.rarityForRoll(nEnd - 0.000001, type: PackType.premium),
      CardRarity.n,
    );
    expect(
      CardPackService.rarityForRoll(nEnd, type: PackType.premium),
      CardRarity.r,
    );
    expect(
      CardPackService.rarityForRoll(rEnd - 0.000001, type: PackType.premium),
      CardRarity.r,
    );
    expect(
      CardPackService.rarityForRoll(rEnd, type: PackType.premium),
      CardRarity.sr,
    );
    expect(
      CardPackService.rarityForRoll(srEnd - 0.000001, type: PackType.premium),
      CardRarity.sr,
    );
    expect(
      CardPackService.rarityForRoll(srEnd, type: PackType.premium),
      CardRarity.ur,
    );
    expect(
      CardPackService.rarityForRoll(0.999999, type: PackType.premium),
      CardRarity.ur,
    );
  });
}
