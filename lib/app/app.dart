import 'package:flutter/material.dart';

import '../screens/collection/collection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../state/game_state.dart';
import '../state/notification_store.dart';
import '../state/prediction_store.dart';
import '../services/prediction_resolution_service.dart';
import '../services/prediction_reward_service.dart';
import '../services/pack_exchange_service.dart';
import '../services/quiz_daily_progress_store.dart';
import '../state/point_wallet.dart';
import '../widgets/prediction_auto_check.dart';
import 'app_theme.dart';

class KabucaApp extends StatelessWidget {
  const KabucaApp({
    super.key,
    required this.gameState,
    required this.predictionStore,
    required this.notificationStore,
    this.predictionResolutionService,
    this.pointWallet,
    this.dailyProgressStore,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PredictionResolutionService? predictionResolutionService;
  final PointWallet? pointWallet;
  final QuizDailyProgressStore? dailyProgressStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KABUCA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MainScreen(
        gameState: gameState,
        predictionStore: predictionStore,
        notificationStore: notificationStore,
        predictionResolutionService: predictionResolutionService,
        pointWallet: pointWallet,
        dailyProgressStore: dailyProgressStore,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
    required this.gameState,
    required this.predictionStore,
    required this.notificationStore,
    this.predictionResolutionService,
    this.pointWallet,
    this.dailyProgressStore,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PredictionResolutionService? predictionResolutionService;
  final PointWallet? pointWallet;
  final QuizDailyProgressStore? dailyProgressStore;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late final PointWallet _pointWallet;
  late final PredictionRewardService _rewardService;
  late final PackExchangeService _exchangeService;
  late final QuizDailyProgressStore _dailyProgressStore;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _handlePageChanged(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      widget.predictionStore.refreshTime();
      widget.predictionResolutionService?.resolveEligiblePredictions(
        automatic: true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pointWallet = widget.pointWallet ?? PointWallet.memory();
    _rewardService = PredictionRewardService(
      predictionStore: widget.predictionStore,
      pointWallet: _pointWallet,
    );
    _exchangeService = PackExchangeService(
      pointWallet: _pointWallet,
      gameState: widget.gameState,
    );
    _dailyProgressStore =
        widget.dailyProgressStore ?? SharedPreferencesQuizDailyProgressStore();
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        gameState: widget.gameState,
        predictionStore: widget.predictionStore,
        notificationStore: widget.notificationStore,
        predictionResolutionService: widget.predictionResolutionService,
        pointWallet: _pointWallet,
        rewardService: _rewardService,
        exchangeService: _exchangeService,
        onShowCollection: () => _goToPage(2),
      ),
      QuizScreen(
        gameState: widget.gameState,
        pointWallet: _pointWallet,
        dailyProgressStore: _dailyProgressStore,
      ),
      CollectionScreen(
        gameState: widget.gameState,
        predictionStore: widget.predictionStore,
        onOpenPack: () => _goToPage(0),
      ),
      ProfileScreen(
        gameState: widget.gameState,
        predictionStore: widget.predictionStore,
        notificationStore: widget.notificationStore,
        pointWallet: _pointWallet,
        dailyProgressStore: _dailyProgressStore,
      ),
    ];
    return PredictionAutoCheck(
      store: widget.predictionStore,
      resolutionService: widget.predictionResolutionService,
      child: Scaffold(
        body: SafeArea(
          child: PageView(
            key: const Key('main-page-view'),
            controller: _pageController,
            onPageChanged: _handlePageChanged,
            children: screens,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _goToPage,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'ホーム',
            ),
            NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz_rounded),
              label: 'クイズ',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_mosaic_outlined),
              selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded),
              label: '図鑑',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'マイページ',
            ),
          ],
        ),
      ),
    );
  }
}
