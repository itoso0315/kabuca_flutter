import 'package:flutter/material.dart';

import 'app/app.dart';
import 'screens/splash/title_screen.dart';
import 'services/backend_warmup_service.dart';
import 'services/prediction_resolution_service.dart';
import 'services/stock_price_service.dart';
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
  ]);
  return _AppDependencies(
    gameState: values[0] as GameState,
    predictionStore: values[1] as PredictionStore,
    notificationStore: values[2] as NotificationStore,
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
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PredictionResolutionService predictionResolutionService;
}
