import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../services/owned_company_service.dart';
import '../../services/stock_price_service.dart';
import '../../services/trading_calendar_service.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';
import '../../theme/company_theme.dart';
import 'prediction_screen.dart';

class CompanyPredictionSelectScreen extends StatefulWidget {
  const CompanyPredictionSelectScreen({
    super.key,
    required this.industry,
    required this.gameState,
    required this.predictionStore,
    this.stockPriceService,
    this.tradingCalendarService,
  });

  final String industry;
  final GameState gameState;
  final PredictionStore predictionStore;
  final StockPriceService? stockPriceService;
  final TradingCalendarService? tradingCalendarService;

  @override
  State<CompanyPredictionSelectScreen> createState() =>
      _CompanyPredictionSelectScreenState();
}

class _CompanyPredictionSelectScreenState
    extends State<CompanyPredictionSelectScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: Text(widget.industry),
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.deepGreen,
      surfaceTintColor: Colors.transparent,
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: TextField(
              key: const Key('prediction-company-search'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                hintText: '企業名・銘柄コードで検索',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('prediction-company-search-clear'),
                        tooltip: '検索をクリア',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.gameState,
              builder: (context, _) {
                // Filtering preserves OwnedCompanyService's company-name order.
                final companies = OwnedCompanyService.from(widget.gameState)
                    .where((company) {
                      final card = company.representative;
                      return card.industry == widget.industry &&
                          (card.companyName.toLowerCase().contains(_query) ||
                              card.ticker.toLowerCase().contains(_query));
                    })
                    .toList();
                if (companies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _query.isEmpty
                            ? 'このカテゴリで予想できる企業がありません'
                            : '一致する企業がありません',
                        key: const Key('prediction-company-search-empty'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  key: const Key('prediction-company-list'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
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
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => PredictionScreen(
                                company: company,
                                predictionStore: widget.predictionStore,
                                stockPriceService: widget.stockPriceService,
                                tradingCalendarService:
                                    widget.tradingCalendarService,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
