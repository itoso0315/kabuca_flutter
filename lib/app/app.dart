import 'package:flutter/material.dart';

import '../screens/collection/collection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../state/game_state.dart';
import '../state/notification_store.dart';
import '../state/prediction_store.dart';
import '../services/prediction_resolution_service.dart';
import '../services/prediction_reward_service.dart';
import '../services/pack_exchange_service.dart';
import '../state/point_wallet.dart';
import 'app_theme.dart';

class KabucaApp extends StatelessWidget {
  const KabucaApp({
    super.key,
    required this.gameState,
    required this.predictionStore,
    required this.notificationStore,
    this.predictionResolutionService,
    this.pointWallet,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PredictionResolutionService? predictionResolutionService;
  final PointWallet? pointWallet;

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
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PredictionResolutionService? predictionResolutionService;
  final PointWallet? pointWallet;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final PointWallet _pointWallet;
  late final PredictionRewardService _rewardService;
  late final PackExchangeService _exchangeService;

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
    widget.predictionResolutionService?.resolveEligiblePredictions();
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
      ),
      CollectionScreen(
        gameState: widget.gameState,
        predictionStore: widget.predictionStore,
      ),
      ProfileScreen(
        gameState: widget.gameState,
        predictionStore: widget.predictionStore,
        notificationStore: widget.notificationStore,
        pointWallet: _pointWallet,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'ホーム',
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
    );
  }
}
