import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/card_catalog.dart';
import '../../models/company_card.dart';
import '../../services/owned_company_service.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';
import '../../theme/company_theme.dart';
import '../../widgets/card_rarity_style.dart';
import '../../widgets/company_card_artwork.dart';
import '../prediction/prediction_screen.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({
    super.key,
    required this.card,
    required this.gameState,
    this.predictionStore,
    this.pendingCards = const [],
  });

  final CompanyCard card;
  final GameState gameState;
  final PredictionStore? predictionStore;
  final List<CompanyCard> pendingCards;

  int _ownedCount(String cardId) =>
      gameState.ownedCount(cardId) +
      pendingCards.where((pending) => pending.id == cardId).length;

  @override
  Widget build(BuildContext context) {
    final rarity = CardRarityStyle.of(card.rarity);
    final companyTheme = CompanyTheme.forCompany(card.companyId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('カード詳細'),
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.deepGreen,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        key: const Key('card-detail-screen'),
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
        children: [
          Center(child: CompanyCardArtwork(card: card)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: Text(
                  card.companyName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: rarity.border.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: rarity.border),
                ),
                child: Text(
                  card.rarity.label,
                  style: TextStyle(
                    color: rarity.border,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${card.ticker}  ・  ${card.industry}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _InformationPanel(card: card),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(
              '所持 ×${_ownedCount(card.id)}',
              key: const Key('detail-owned-count'),
              style: const TextStyle(
                color: AppColors.deepGreen,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text('この企業のカード', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final related in CardCatalog.cards.where(
                (item) => item.companyId == card.companyId,
              ))
                Expanded(
                  child: _RarityStatus(
                    card: related,
                    owned: _ownedCount(related.id) > 0,
                  ),
                ),
            ],
          ),
          if (predictionStore != null && gameState.owns(card.id)) ...[
            const SizedBox(height: 28),
            OutlinedButton.icon(
              key: const Key('predict-this-company-button'),
              onPressed: () => _openPrediction(context),
              icon: const Icon(Icons.insights_rounded),
              label: const Text('この企業を予想する'),
              style: OutlinedButton.styleFrom(
                foregroundColor: companyTheme.baseColor,
                side: BorderSide(color: companyTheme.baseColor),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openPrediction(BuildContext context) {
    final ownedCards = CardCatalog.cards
        .where(
          (candidate) =>
              candidate.companyId == card.companyId &&
              gameState.owns(candidate.id),
        )
        .toList();
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PredictionScreen(
          company: OwnedCompanySummary(
            companyId: card.companyId,
            cards: ownedCards,
          ),
          predictionStore: predictionStore!,
        ),
      ),
    );
  }
}

class _InformationPanel extends StatelessWidget {
  const _InformationPanel({required this.card});
  final CompanyCard card;

  @override
  Widget build(BuildContext context) {
    final heading = switch (card.rarity) {
      CardRarity.n => 'この会社は何をしている会社？',
      CardRarity.r => 'どこで稼いでいる会社？',
      CardRarity.sr => '何が強い会社？',
      CardRarity.ur => 'この会社ならではの物語',
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            card.title,
            key: const Key('detail-card-title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            card.description,
            key: const Key('detail-card-description'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _RarityStatus extends StatelessWidget {
  const _RarityStatus({required this.card, required this.owned});
  final CompanyCard card;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final style = CardRarityStyle.of(card.rarity);
    return Container(
      key: Key('company-rarity-status-${card.rarity.name}'),
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
      decoration: BoxDecoration(
        color: owned ? style.background : const Color(0xFFE5E6E3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: owned ? style.border : AppColors.outline),
      ),
      child: Column(
        children: [
          Icon(
            owned
                ? Icons.check_circle_outline_rounded
                : Icons.lock_outline_rounded,
            color: owned ? style.accent : Colors.grey,
            size: 18,
          ),
          const SizedBox(height: 5),
          Text(
            card.rarity.label,
            style: TextStyle(
              color: owned ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            owned ? '取得済み' : '？？？',
            style: TextStyle(
              color: owned ? style.accent : Colors.grey,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
