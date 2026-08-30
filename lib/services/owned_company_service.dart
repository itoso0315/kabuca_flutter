import '../data/card_catalog.dart';
import '../models/company_card.dart';
import '../state/game_state.dart';

class OwnedCompanySummary {
  const OwnedCompanySummary({required this.companyId, required this.cards});

  final String companyId;
  final List<CompanyCard> cards;

  CompanyCard get representative => cards.first;
  CardRarity get highestRarity => cards
      .map((card) => card.rarity)
      .reduce((a, b) => a.index > b.index ? a : b);
  int get ownedRarityCount => cards.length;
}

abstract final class OwnedCompanyService {
  static List<OwnedCompanySummary> from(GameState gameState) {
    final groups = <String, List<CompanyCard>>{};
    for (final card in CardCatalog.cards) {
      if (!gameState.owns(card.id)) continue;
      groups.putIfAbsent(card.companyId, () => []).add(card);
    }
    final summaries = groups.entries
        .map(
          (entry) => OwnedCompanySummary(
            companyId: entry.key,
            cards: List.unmodifiable(
              entry.value
                ..sort((a, b) => a.rarity.index.compareTo(b.rarity.index)),
            ),
          ),
        )
        .toList();
    summaries.sort(
      (a, b) =>
          a.representative.companyName.compareTo(b.representative.companyName),
    );
    return summaries;
  }
}
