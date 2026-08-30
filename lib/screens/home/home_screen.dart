import 'package:flutter/material.dart';

import '../../widgets/daily_pack_card.dart';
import '../../widgets/home_stat_card.dart';
import '../../models/company_card.dart';
import '../../services/card_pack_service.dart';
import '../../services/stock_price_service.dart';
import '../../services/trading_calendar_service.dart';
import '../../services/prediction_resolution_service.dart';
import '../../services/prediction_reward_service.dart';
import '../../services/pack_exchange_service.dart';
import '../../state/game_state.dart';
import '../../state/notification_store.dart';
import '../../state/prediction_store.dart';
import '../../state/point_wallet.dart';
import '../notifications/notification_screen.dart';
import '../prediction/company_prediction_select_screen.dart';
import '../prediction/prediction_list_screen.dart';
import '../pack/pack_opening_screen.dart';
import '../rewards/pack_exchange_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.gameState,
    required this.predictionStore,
    required this.notificationStore,
    this.cardPackService,
    this.stockPriceService,
    this.tradingCalendarService,
    this.predictionResolutionService,
    this.pointWallet,
    this.rewardService,
    this.exchangeService,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final CardPackService? cardPackService;
  final StockPriceService? stockPriceService;
  final TradingCalendarService? tradingCalendarService;
  final PredictionResolutionService? predictionResolutionService;
  final PointWallet? pointWallet;
  final PredictionRewardService? rewardService;
  final PackExchangeService? exchangeService;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        gameState,
        predictionStore,
        notificationStore,
        ?pointWallet,
      ]),
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: const Text(
                          'KABUCA',
                          key: Key('home-brand-logo'),
                          style: TextStyle(
                            color: Color(0xFF123D33),
                            fontSize: 31,
                            height: 1,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 6.2,
                          ),
                        ),
                      ),
                    ),
                    _PointBalanceButton(
                      points: pointWallet?.currentPoints ?? 0,
                      onPressed: pointWallet == null || exchangeService == null
                          ? null
                          : () => _openExchange(context),
                    ),
                    _NotificationBell(
                      unreadCount: notificationStore.unreadCount,
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => NotificationScreen(
                            store: notificationStore,
                            predictionStore: predictionStore,
                            pointWallet: pointWallet,
                            rewardService: rewardService,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                              builder: (_) => PredictionListScreen(
                                store: predictionStore,
                                resolutionService: predictionResolutionService,
                                pointWallet: pointWallet,
                                rewardService: rewardService,
                              ),
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

  Future<void> _openExchange(BuildContext context) async {
    final exchanged = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PackExchangeScreen(
          pointWallet: pointWallet!,
          gameState: gameState,
          exchangeService: exchangeService!,
        ),
      ),
    );
    if (exchanged == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('スタートパックを1個獲得しました')));
    }
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

class _PointBalanceButton extends StatelessWidget {
  const _PointBalanceButton({required this.points, required this.onPressed});
  final int points;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('home-point-balance'),
    onTap: onPressed,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E9C8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6B870)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 15, color: Color(0xFFA67D2D)),
          const SizedBox(width: 4),
          Text(
            '$points pt',
            style: const TextStyle(
              color: Color(0xFF5A481E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unreadCount, required this.onPressed});

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        key: const Key('notification-bell-button'),
        tooltip: 'お知らせ',
        onPressed: onPressed,
        icon: const Icon(Icons.notifications_none_rounded),
      ),
      if (unreadCount > 0)
        Positioned(
          key: const Key('notification-unread-badge'),
          right: 2,
          top: 2,
          child: Container(
            constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFB7654F),
              borderRadius: BorderRadius.all(Radius.circular(9)),
            ),
            alignment: Alignment.center,
            child: Text(
              unreadCount > 9 ? '9+' : '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
    ],
  );
}
