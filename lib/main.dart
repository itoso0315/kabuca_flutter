import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'state/game_state.dart';
import 'state/prediction_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gameState = await GameState.load();
  final predictionStore = await PredictionStore.load();
  runApp(KabucaApp(gameState: gameState, predictionStore: predictionStore));
}
