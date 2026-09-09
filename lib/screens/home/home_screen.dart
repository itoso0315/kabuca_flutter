import 'package:flutter/material.dart';

import '../../data/card_catalog.dart';
import '../../models/pack_type.dart';
import '../../widgets/daily_pack_card.dart';
import '../../widgets/home_stat_card.dart';
import '../../widgets/prediction_result_bell.dart';
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
import '../prediction/prediction_category_select_screen.dart';
import '../prediction/prediction_list_screen.dart';
import '../prediction/prediction_result_list_screen.dart';
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
    this.onShowCollection,
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
  final VoidCallback? onShowCollection;

  @override
  Widget build(BuildContext context) {
    return _LifecycleRefresh(
      builder: (context) => ListenableBuilder(
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
                        onPressed:
                            pointWallet == null || exchangeService == null
                            ? null
                            : () => _openExchange(context),
                      ),
                      PredictionResultBell(
                        store: predictionStore,
                        onPressed: () => _openPredictionResults(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gameState.totalOwnedCardCount == 0
                        ? '企業を集めて、未来を予想しよう。'
                        : '集めよう、日本の企業。',
                    key: const Key('home-guidance-copy'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  if (gameState.hasFreeStarterPackToday) ...[
                    _DailyFreePackBanner(
                      onOpen: () => _openDailyFreeStarterPack(context),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _PackCarousel(
                    starterPackCount: gameState.starterPackCount,
                    premiumPackCount: gameState.premiumPackCount,
                    kabuBalance: pointWallet?.currentPoints ?? 0,
                    canExchange: pointWallet != null && exchangeService != null,
                    onOpenStarter: () => _openPack(context, PackType.starter),
                    onOpenPremium: () => _openPack(context, PackType.premium),
                    onBuyStarter: () =>
                        _openPackWithKabu(context, PackType.starter),
                    onBuyPremium: () =>
                        _openPackWithKabu(context, PackType.premium),
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
                            onPressed: () => _openPrediction(context),
                            icon: const Icon(Icons.insights_rounded),
                            label: const Text('予想する'),
                          ),
                          TextButton(
                            key: const Key('waiting-predictions-button'),
                            onPressed: () => _openPredictionList(context),
                            child: Text(
                              '予想中を見る（${predictionStore.pendingPredictions.length}）',
                            ),
                          ),
                        ],
                      ),
                    ),
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
                          value:
                              '${gameState.registeredCardCount * 100 ~/ CardCatalog.cards.length}%',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDailyFreeStarterPack(BuildContext context) async {
    await _openPack(
      context,
      PackType.starter,
      onPackOpened: () {
        gameState.consumeDailyFreeStarterPack();
      },
    );
  }

  Future<void> _openPackWithKabu(BuildContext context, PackType type) async {
    final wallet = pointWallet;
    final service = exchangeService;
    if (wallet == null || service == null) return;

    final isPremium = type == PackType.premium;
    final cost = isPremium
        ? PackExchangeRules.premiumPackCost
        : PackExchangeRules.starterPackCost;
    if (wallet.currentPoints < cost) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: Key(
          isPremium
              ? 'open-premium-pack-with-kabu-confirm-dialog'
              : 'open-pack-with-kabu-confirm-dialog',
        ),
        icon: const Icon(Icons.stars_rounded, color: Color(0xFFB39450)),
        title: Text(isPremium ? 'プレミアムパックを開けますか？' : 'パックを開けますか？'),
        content: Text(
          '$cost KABUを使います\n\n'
          '所持KABU ${wallet.currentPoints} → ${wallet.currentPoints - cost} KABU',
        ),
        actions: [
          TextButton(
            key: const Key('cancel-open-pack-with-kabu-button'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('confirm-open-pack-with-kabu-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('開ける'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = isPremium
        ? await service.exchangePremiumPack()
        : await service.exchangeStarterPack();
    if (!context.mounted || result != PackExchangeResult.exchanged) return;

    await _openPack(context, type);
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
      final openNow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('pack-exchange-success-dialog'),
          icon: const Icon(Icons.inventory_2_rounded, color: Color(0xFFB39450)),
          title: const Text('スタートパックを1個獲得しました'),
          actions: [
            TextButton(
              key: const Key('pack-exchange-later-button'),
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('あとで'),
            ),
            FilledButton(
              key: const Key('pack-exchange-open-button'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('開封する'),
            ),
          ],
        ),
      );
      if (openNow == true && context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        await _openPack(context, PackType.starter);
      }
    }
  }

  Future<void> _openPrediction(BuildContext context) {
    predictionStore.refreshTime();
    predictionResolutionService?.resolveEligiblePredictions(automatic: true);
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PredictionCategorySelectScreen(
          gameState: gameState,
          predictionStore: predictionStore,
          stockPriceService: stockPriceService,
          tradingCalendarService: tradingCalendarService,
        ),
      ),
    );
  }

  Future<void> _openPredictionResults(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PredictionResultListScreen(
            store: predictionStore,
            resolutionService: predictionResolutionService,
            pointWallet: pointWallet,
            rewardService: rewardService,
            onPredictAgain: () => _openPrediction(context),
            onOpenExchange: pointWallet == null || exchangeService == null
                ? null
                : () => _openExchange(context),
            onShowNotifications: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => NotificationScreen(
                  store: notificationStore,
                  predictionStore: predictionStore,
                  pointWallet: pointWallet,
                  rewardService: rewardService,
                  onPredictAgain: () => _openPrediction(context),
                  onOpenExchange: pointWallet == null || exchangeService == null
                      ? null
                      : () => _openExchange(context),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _openPredictionList(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PredictionListScreen(
            store: predictionStore,
            resolutionService: predictionResolutionService,
            pointWallet: pointWallet,
            rewardService: rewardService,
            gameState: gameState,
            onPredict: () => _openPrediction(context),
            onShowResults: () => _openPredictionResults(context),
            onOpenPack: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            onOpenExchange: pointWallet == null || exchangeService == null
                ? null
                : () => _openExchange(context),
          ),
        ),
      );

  Future<void> _openPack(
    BuildContext context,
    PackType type, {
    VoidCallback? onPackOpened,
  }) async {
    final result = await Navigator.of(context).push<PackOpeningResult>(
      PackOpeningRoute(
        cards: (cardPackService ?? CardPackService()).openPack(type: type),
        onPackOpened: onPackOpened ?? () => _consumePack(type),
        gameState: gameState,
        packType: type,
      ),
    );
    if (result == null) return;
    await gameState.addCards(result.cards);
    if (result.destination == PackOpeningDestination.collection) {
      onShowCollection?.call();
    }
  }

  void _consumePack(PackType type) {
    gameState.consumePack(type);
  }
}

class _LifecycleRefresh extends StatefulWidget {
  const _LifecycleRefresh({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_LifecycleRefresh> createState() => _LifecycleRefreshState();
}

class _LifecycleRefreshState extends State<_LifecycleRefresh>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class _DailyFreePackBanner extends StatelessWidget {
  const _DailyFreePackBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('daily-free-starter-pack-banner'),
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
    decoration: BoxDecoration(
      color: const Color(0xFFF4E9C8),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFD6B870)),
    ),
    child: Row(
      children: [
        const Icon(Icons.redeem_rounded, color: Color(0xFFA67D2D), size: 24),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '本日の無料パック',
                style: TextStyle(
                  color: Color(0xFF3F351C),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'スタートパックを1回無料で開封できます',
                style: TextStyle(
                  color: Color(0xFF786A43),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: Key('open-daily-free-starter-pack-button'),
          onPressed: onOpen,
          child: Text('無料で開く'),
        ),
      ],
    ),
  );
}

class _PackCarousel extends StatefulWidget {
  const _PackCarousel({
    required this.starterPackCount,
    required this.premiumPackCount,
    required this.kabuBalance,
    required this.canExchange,
    required this.onOpenStarter,
    required this.onOpenPremium,
    required this.onBuyStarter,
    required this.onBuyPremium,
  });

  final int starterPackCount;
  final int premiumPackCount;
  final int kabuBalance;
  final bool canExchange;
  final VoidCallback onOpenStarter;
  final VoidCallback onOpenPremium;
  final VoidCallback onBuyStarter;
  final VoidCallback onBuyPremium;

  @override
  State<_PackCarousel> createState() => _PackCarouselState();
}

class _PackCarouselState extends State<_PackCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 455,
          child: PageView(
            key: const Key('home-pack-carousel'),
            controller: _controller,
            onPageChanged: (page) => setState(() => _page = page),
            children: [
              DailyPackCard(
                packName: 'スタートパック',
                packCount: widget.starterPackCount,
                kabuBalance: widget.kabuBalance,
                kabuCost: PackExchangeRules.starterPackCost,
                onOpen: widget.starterPackCount > 0
                    ? widget.onOpenStarter
                    : null,
                onOpenWithKabu:
                    widget.starterPackCount == 0 && widget.canExchange
                    ? widget.onBuyStarter
                    : null,
              ),
              DailyPackCard(
                packName: 'プレミアムパック',
                isPremium: true,
                packCount: widget.premiumPackCount,
                kabuBalance: widget.kabuBalance,
                kabuCost: PackExchangeRules.premiumPackCost,
                onOpen: widget.premiumPackCount > 0
                    ? widget.onOpenPremium
                    : null,
                onOpenWithKabu:
                    widget.premiumPackCount == 0 && widget.canExchange
                    ? widget.onBuyPremium
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final selected = index == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 18 : 7,
              height: 7,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF123D33)
                    : const Color(0xFFC9CEC9),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
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
            '$points KABU',
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
