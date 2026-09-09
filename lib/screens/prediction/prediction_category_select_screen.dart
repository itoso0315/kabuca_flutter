import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/card_catalog.dart';
import '../../services/owned_company_service.dart';
import '../../services/stock_price_service.dart';
import '../../services/trading_calendar_service.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';
import 'company_prediction_select_screen.dart';

class PredictionCategorySelectScreen extends StatelessWidget {
  const PredictionCategorySelectScreen({
    super.key,
    required this.gameState,
    required this.predictionStore,
    this.stockPriceService,
    this.tradingCalendarService,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final StockPriceService? stockPriceService;
  final TradingCalendarService? tradingCalendarService;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: const Text('予想する企業'),
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.deepGreen,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: gameState,
        builder: (context, _) {
          final counts = <String, int>{};
          for (final company in OwnedCompanyService.from(gameState)) {
            counts.update(
              company.representative.industry,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }
          // Keep the catalog's first-occurrence order, independent of which
          // company or rarity the user acquired first. Use industry verbatim.
          final industries = CardCatalog.cards
              .map((card) => card.industry)
              .toSet()
              .where(counts.containsKey)
              .toList();
          if (industries.isEmpty) return const _NoOwnedCompanies();

          return ListView.separated(
            key: const Key('prediction-category-list'),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            itemCount: industries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final industry = industries[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: Key('prediction-category-$industry'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  title: Text(
                    industry,
                    style: const TextStyle(
                      color: AppColors.deepGreen,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${counts[industry]}社',
                        key: Key('prediction-category-count-$industry'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.deepGreen,
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => CompanyPredictionSelectScreen(
                        industry: industry,
                        gameState: gameState,
                        predictionStore: predictionStore,
                        stockPriceService: stockPriceService,
                        tradingCalendarService: tradingCalendarService,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}

class _NoOwnedCompanies extends StatelessWidget {
  const _NoOwnedCompanies();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        key: const Key('prediction-company-empty-state'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.insights_rounded,
            color: AppColors.mutedGold,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            '予想できる企業がありません',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          const Text('まずは企業カードを集めよう'),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('prediction-empty-open-pack-button'),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('パックを開ける'),
          ),
        ],
      ),
    ),
  );
}
