import 'package:flutter/material.dart';

import 'app/app.dart';
import 'screens/splash/title_screen.dart';
import 'services/backend_warmup_service.dart';
import 'services/prediction_resolution_service.dart';
import 'services/stock_price_service.dart';
import 'state/point_wallet.dart';
import 'state/game_state.dart';
import 'state/notification_store.dart';
import 'state/prediction_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'KABUCA',
      debugShowCheckedModeBanner: false,
      home: TitleScreen<_AppDependencies>(
        initialize: _loadDependencies,
        warmupService: HttpBackendWarmupService(),
        homeBuilder: (dependencies) => KabucaApp(
          gameState: dependencies.gameState,
          predictionStore: dependencies.predictionStore,
          notificationStore: dependencies.notificationStore,
          predictionResolutionService: dependencies.predictionResolutionService,
          pointWallet: dependencies.pointWallet,
        ),
      ),
    ),
  );
}

Future<_AppDependencies> _loadDependencies() async {
  final values = await Future.wait<Object>([
    GameState.load(),
    PredictionStore.load(),
    NotificationStore.load(),
    PointWallet.load(),
  ]);
  return _AppDependencies(
    gameState: values[0] as GameState,
    predictionStore: values[1] as PredictionStore,
    notificationStore: values[2] as NotificationStore,
    pointWallet: values[3] as PointWallet,
    predictionResolutionService: PredictionResolutionService(
      predictionStore: values[1] as PredictionStore,
      stockPriceService: StockPriceService.production(),
      notificationStore: values[2] as NotificationStore,
    ),
  );
}

class _AppDependencies {
  const _AppDependencies({
    required this.gameState,
    required this.predictionStore,
    required this.notificationStore,
    required this.predictionResolutionService,
    required this.pointWallet,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PredictionResolutionService predictionResolutionService;
  final PointWallet pointWallet;
}
