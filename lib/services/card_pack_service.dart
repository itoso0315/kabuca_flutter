import 'dart:math';

import '../data/card_catalog.dart';
import '../models/company_card.dart';
import '../models/pack_type.dart';

class CardPackService {
  CardPackService({List<CompanyCard>? catalog, Random? random})
    : _catalog = catalog ?? CardCatalog.cards,
      _random = random ?? Random();

  final List<CompanyCard> _catalog;
  final Random _random;

  List<CompanyCard> openPack({
    int cardCount = 3,
    PackType type = PackType.starter,
  }) {
    if (_catalog.length < cardCount) {
      throw StateError('カードプールが排出枚数より少ないです');
    }

    final selected = <CompanyCard>[];
    while (selected.length < cardCount) {
      final slotIndex = selected.length;
      final rarity = type == PackType.superPremium
          ? superPremiumSlotRarityForRoll(_random.nextDouble())
          : slotIndex == cardCount - 1
          ? finalSlotRarityForRoll(_random.nextDouble(), type: type)
          : normalSlotRarityForRoll(_random.nextDouble());
      final candidates = _catalog
          .where(
            (card) =>
                card.rarity == rarity &&
                !selected.any(
                  (selectedCard) => selectedCard.companyId == card.companyId,
                ),
          )
          .toList();
      if (candidates.isEmpty) continue;
      selected.add(candidates[_random.nextInt(candidates.length)]);
    }
    return List.unmodifiable(selected);
  }

  static CardRarity normalSlotRarityForRoll(double roll) {
    if (roll < 0 || roll >= 1) {
      throw RangeError.range(roll, 0, 1, 'roll', '0以上1未満');
    }

    if (roll < 0.76) return CardRarity.n;
    return CardRarity.r;
  }

  static CardRarity finalSlotRarityForRoll(
    double roll, {
    PackType type = PackType.starter,
  }) {
    if (roll < 0 || roll >= 1) {
      throw RangeError.range(roll, 0, 1, 'roll', '0以上1未満');
    }

    switch (type) {
      case PackType.starter:
        if (roll < 0.59) return CardRarity.n;
        if (roll < 0.78) return CardRarity.r;
        if (roll < 0.97) return CardRarity.sr;
        return CardRarity.ur;

      case PackType.premium:
        if (roll < 0.38) return CardRarity.n;
        if (roll < 0.50) return CardRarity.r;
        if (roll < 0.92) return CardRarity.sr;
        return CardRarity.ur;

      case PackType.superPremium:
        if (roll < 0.20) return CardRarity.r;
        if (roll < 0.75) return CardRarity.sr;
        return CardRarity.ur;
    }
  }

  static CardRarity superPremiumSlotRarityForRoll(double roll) {
    if (roll < 0 || roll >= 1) {
      throw RangeError.range(roll, 0, 1, 'roll', '0以上1未満');
    }
    if (roll < 0.20) return CardRarity.r;
    if (roll < 0.75) return CardRarity.sr;
    return CardRarity.ur;
  }

  @Deprecated('Use finalSlotRarityForRoll for the third card slot.')
  static CardRarity rarityForRoll(
    double roll, {
    PackType type = PackType.starter,
  }) => finalSlotRarityForRoll(roll, type: type);
}
