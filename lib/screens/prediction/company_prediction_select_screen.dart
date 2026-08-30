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
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'まずはパックを開けて\n企業カードを集めよう',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, height: 1.6),
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
