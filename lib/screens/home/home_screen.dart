import 'package:flutter/material.dart';

import '../../widgets/daily_pack_card.dart';
import '../../widgets/home_stat_card.dart';
import '../../models/company_card.dart';
import '../../services/card_pack_service.dart';
import '../../state/game_state.dart';
import '../pack/pack_opening_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.gameState, this.cardPackService});

  final GameState gameState;
  final CardPackService? cardPackService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
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
      ),
    );
    if (cards == null) return;
    await gameState.addCards(cards);
  }

  void _consumePack() {
    gameState.consumePack();
  }
}
