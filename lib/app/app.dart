import 'package:flutter/material.dart';

import '../screens/collection/collection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../state/game_state.dart';
import 'app_theme.dart';

class KabucaApp extends StatelessWidget {
  const KabucaApp({super.key, required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KABUCA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MainScreen(gameState: gameState),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.gameState});

  final GameState gameState;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(gameState: widget.gameState),
      CollectionScreen(gameState: widget.gameState),
      const ProfileScreen(),
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
