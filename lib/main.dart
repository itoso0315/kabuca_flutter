import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'screens/splash/title_screen.dart';
import 'services/backend_warmup_service.dart';
import 'state/game_state.dart';
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
        ),
      ),
    ),
  );
}

Future<_AppDependencies> _loadDependencies() async {
  final values = await Future.wait<Object>([
    GameState.load(),
    PredictionStore.load(),
  ]);
  return _AppDependencies(
    gameState: values[0] as GameState,
    predictionStore: values[1] as PredictionStore,
  );
}

class _AppDependencies {
  const _AppDependencies({required this.gameState, required this.predictionStore});

  final GameState gameState;
  final PredictionStore predictionStore;
}
