import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/card_catalog.dart';
import '../../models/company_card.dart';
import '../card/card_detail_screen.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';
import '../../theme/company_theme.dart';
import '../../widgets/card_rarity_style.dart';

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
                childAspectRatio: 0.64,
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
    final company = CompanyTheme.forCompany(card.companyId);
    final rarity = CardRarityStyle.of(card.rarity);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: Key('catalog-card-${card.id}'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: owned ? company.baseColor : const Color(0xFFE3E5E2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: owned ? rarity.border : AppColors.outline,
            width: owned ? 2 : 1,
          ),
          boxShadow: owned
              ? const [
                  BoxShadow(
                    color: Color(0x18174A3A),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              card.rarity.label,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: owned ? rarity.accent : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Icon(
              owned ? company.abstractSymbol : Icons.lock_outline_rounded,
              color: owned ? company.accentColor : Colors.grey,
              size: 38,
            ),
            const Spacer(),
            Text(
              owned ? card.companyName : '？？？',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: owned ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${card.ticker} ・ ${card.industry}',
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: owned ? company.accentColor : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              owned ? '所持 ×$ownedCount' : '未取得',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: owned ? rarity.accent : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
