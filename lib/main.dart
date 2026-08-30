import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'state/game_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final gameState = await GameState.load();
  runApp(KabucaApp(gameState: gameState));
}
