import 'package:flutter/material.dart';

import '../../widgets/daily_pack_card.dart';
import '../../widgets/home_stat_card.dart';
import '../../models/company_card.dart';
import '../../services/card_pack_service.dart';
import '../../services/stock_price_service.dart';
import '../../services/trading_calendar_service.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';
import '../prediction/company_prediction_select_screen.dart';
import '../prediction/prediction_list_screen.dart';
import '../pack/pack_opening_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.gameState,
    required this.predictionStore,
    this.cardPackService,
    this.stockPriceService,
    this.tradingCalendarService,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final CardPackService? cardPackService;
  final StockPriceService? stockPriceService;
  final TradingCalendarService? tradingCalendarService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([gameState, predictionStore]),
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'KABUCA',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '集めよう、日本の企業。',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                DailyPackCard(
                  packCount: gameState.packCount,
                  onOpen: gameState.packCount > 0
                      ? () => _openPack(context)
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: HomeStatCard(
                        label: '所持カード',
                        value: '${gameState.totalOwnedCardCount}枚',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HomeStatCard(
                        label: '図鑑コンプリート率',
                        value: '${gameState.registeredCardCount * 100 ~/ 80}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '株価予想',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          '持っている企業から未来を予想しよう',
                          style: TextStyle(color: Color(0xFF66736C)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          key: const Key('start-prediction-button'),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => CompanyPredictionSelectScreen(
                                gameState: gameState,
                                predictionStore: predictionStore,
                                stockPriceService: stockPriceService,
                                tradingCalendarService: tradingCalendarService,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.insights_rounded),
                          label: const Text('予想する'),
                        ),
                        TextButton(
                          key: const Key('waiting-predictions-button'),
                          onPressed: () => Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PredictionListScreen(store: predictionStore),
                            ),
                          ),
                          child: Text(
                            '予想中を見る（${predictionStore.waitingPredictions.length}）',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPack(BuildContext context) async {
    final cards = await Navigator.of(context).push<List<CompanyCard>>(
      PackOpeningRoute(
        cards: (cardPackService ?? CardPackService()).openPack(),
        onPackOpened: _consumePack,
        gameState: gameState,
      ),
    );
    if (cards == null) return;
    await gameState.addCards(cards);
  }

  void _consumePack() {
    gameState.consumePack();
  }
}
