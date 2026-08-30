import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../services/owned_company_service.dart';
import '../../services/stock_price_service.dart';
import '../../services/trading_calendar_service.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';
import '../../theme/company_theme.dart';
import 'prediction_screen.dart';

class CompanyPredictionSelectScreen extends StatelessWidget {
  const CompanyPredictionSelectScreen({
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
  Widget build(BuildContext context) {
    final companies = OwnedCompanyService.from(gameState);
    return Scaffold(
      appBar: AppBar(
        title: const Text('予想する企業'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: companies.isEmpty
          ? Center(
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
            )
          : ListView.separated(
              key: const Key('prediction-company-list'),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              itemCount: companies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final company = companies[index];
                final card = company.representative;
                final theme = CompanyTheme.forCompany(company.companyId);
                return Card(
                  child: ListTile(
                    key: Key('prediction-company-${company.companyId}'),
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: theme.baseColor,
                      foregroundColor: theme.accentColor,
                      child: Icon(theme.abstractSymbol),
                    ),
                    title: Text(card.companyName),
                    subtitle: Text(
                      '${card.ticker} ・ ${card.industry}\n'
                      '最高レアリティ：${company.highestRarity.label}  '
                      '${company.ownedRarityCount} / 4種類取得',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => PredictionScreen(
                          company: company,
                          predictionStore: predictionStore,
                          stockPriceService: stockPriceService,
                          tradingCalendarService: tradingCalendarService,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
