import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../state/game_state.dart';
import '../../state/prediction_store.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.gameState,
    required this.predictionStore,
  });

  final GameState gameState;
  final PredictionStore predictionStore;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _resetting = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.gameState, widget.predictionStore]),
      builder: (context, _) => ListView(
        key: const Key('profile-screen'),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
        children: [
          Text('マイページ', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('データ状況', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text('所持パック  ${widget.gameState.packCount}個'),
                  Text('所持カード  ${widget.gameState.totalOwnedCardCount}枚'),
                  Text('図鑑登録  ${widget.gameState.registeredCardCount} / 80'),
                  Text('保存済み予想  ${widget.predictionStore.predictions.length}件'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            key: const Key('development-section'),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD7B7AE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.developer_mode_rounded,
                      color: Color(0xFF8C493C),
                    ),
                    SizedBox(width: 9),
                    Text(
                      '開発用',
                      style: TextStyle(
                        color: Color(0xFF8C493C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  '実機テスト用に、パック・カード・図鑑・予想を初期状態へ戻します。',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('development-data-reset-button'),
                  onPressed: _resetting ? null : _confirmReset,
                  icon: _resetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restart_alt_rounded),
                  label: const Text('開発用データリセット'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8C493C),
                    side: const BorderSide(color: Color(0xFFC98F80)),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('開発用データリセット'),
        content: const Text('すべてのテストデータを削除しますか？'),
        actions: [
          TextButton(
            key: const Key('cancel-data-reset-button'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            key: const Key('confirm-data-reset-button'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8C493C),
            ),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _resetting = true);
    await Future.wait<void>([
      widget.gameState.resetDevelopmentData(),
      widget.predictionStore.resetDevelopmentData(),
    ]);
    if (!mounted) return;
    setState(() => _resetting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('開発用データを初期化しました')));
  }
}
