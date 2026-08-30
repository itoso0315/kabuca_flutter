import 'dart:math';

import '../data/card_catalog.dart';
import '../models/company_card.dart';

class CardPackService {
  CardPackService({List<CompanyCard>? catalog, Random? random})
    : _catalog = catalog ?? CardCatalog.cards,
      _random = random ?? Random();

  final List<CompanyCard> _catalog;
  final Random _random;

  List<CompanyCard> openPack({int cardCount = 3}) {
    if (_catalog.length < cardCount) {
      throw StateError('カードプールが排出枚数より少ないです');
    }

    final selected = <CompanyCard>[];
    while (selected.length < cardCount) {
      final rarity = rarityForRoll(_random.nextDouble());
      final candidates = _catalog
          .where(
            (card) =>
                card.rarity == rarity &&
                !selected.any((selectedCard) => selectedCard.id == card.id),
          )
          .toList();
      if (candidates.isEmpty) continue;
      selected.add(candidates[_random.nextInt(candidates.length)]);
    }
    return List.unmodifiable(selected);
  }

  static CardRarity rarityForRoll(double roll) {
    if (roll < 0 || roll >= 1) {
      throw RangeError.range(roll, 0, 1, 'roll', '0以上1未満');
    }
    if (roll < 0.70) return CardRarity.n;
    if (roll < 0.92) return CardRarity.r;
    if (roll < 0.99) return CardRarity.sr;
    return CardRarity.ur;
  }
}
