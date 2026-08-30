import 'package:flutter/material.dart';

import '../../data/card_catalog.dart';
import '../../models/company_card.dart';
import '../card/card_detail_screen.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';
import '../../widgets/card_rarity_style.dart';
import '../../widgets/company_card_artwork.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.gameState,
    required this.predictionStore,
  });
  final GameState gameState;
  final PredictionStore predictionStore;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  CardRarity? _filter;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.gameState,
    builder: (context, _) {
      final cards = CardCatalog.cards
          .where((card) => _filter == null || card.rarity == _filter)
          .toList();
      final registered = widget.gameState.registeredCardCount;
      final completion = registered * 100 ~/ CardCatalog.cards.length;
      return CustomScrollView(
        key: const Key('collection-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('図鑑', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    '$registered / ${CardCatalog.cards.length}  ・  コンプリート率 $completion%',
                    key: const Key('collection-progress'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'すべて',
                          selected: _filter == null,
                          onTap: () => setState(() => _filter = null),
                        ),
                        for (final rarity in CardRarity.values)
                          _FilterChip(
                            label: rarity.label,
                            selected: _filter == rarity,
                            onTap: () => setState(() => _filter = rarity),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverGrid.builder(
              key: const Key('collection-grid'),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5 / 3.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final ownedCount = widget.gameState.ownedCount(card.id);
                return _CatalogCard(
                  card: card,
                  ownedCount: ownedCount,
                  onTap: ownedCount == 0
                      ? null
                      : () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => CardDetailScreen(
                              card: card,
                              gameState: widget.gameState,
                              predictionStore: widget.predictionStore,
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      key: Key('filter-$label'),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.card,
    required this.ownedCount,
    required this.onTap,
  });
  final CompanyCard card;
  final int ownedCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final owned = ownedCount > 0;
    final rarity = CardRarityStyle.of(card.rarity);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        key: Key('catalog-card-${card.id}'),
        fit: StackFit.expand,
        children: [
          if (owned)
            FittedBox(
              fit: BoxFit.fill,
              child: CompanyCardArtwork(
                card: card,
                width: 175,
                height: 245,
                compact: true,
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF242927), Color(0xFF0B0E0D)],
                ),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: rarity.border.withValues(alpha: .42)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: rarity.border.withValues(alpha: .48),
                    size: 34,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '？？？',
                    style: TextStyle(
                      color: rarity.border.withValues(alpha: .54),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    card.rarity.label,
                    style: TextStyle(
                      color: rarity.border.withValues(alpha: .64),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          if (owned)
            Positioned(
              right: 7,
              bottom: 7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xDD07100D),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: rarity.border.withValues(alpha: .7),
                  ),
                ),
                child: Text(
                  '×$ownedCount',
                  style: TextStyle(
                    color: rarity.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
