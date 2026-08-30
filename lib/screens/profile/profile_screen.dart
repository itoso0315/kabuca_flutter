import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../app/app_theme.dart';
import '../../models/app_notification.dart';
import '../../state/game_state.dart';
import '../../state/notification_store.dart';
import '../../state/prediction_store.dart';
import '../../state/point_wallet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.gameState,
    required this.predictionStore,
    required this.notificationStore,
    this.pointWallet,
  });

  final GameState gameState;
  final PredictionStore predictionStore;
  final NotificationStore notificationStore;
  final PointWallet? pointWallet;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _resetting = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.gameState,
        widget.predictionStore,
        widget.notificationStore,
        if (widget.pointWallet != null) widget.pointWallet!,
      ]),
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
                  Text('ポイント  ${widget.pointWallet?.currentPoints ?? 0}pt'),
                  Text(
                    'お知らせ  ${widget.notificationStore.notifications.length}件',
                  ),
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
                  '実機テスト用に、パック・カード・図鑑・予想・ポイント・お知らせを初期状態へ戻します。',
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
                if (kDebugMode) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    key: const Key('add-sample-notification-button'),
                    onPressed: _addSampleNotification,
                    icon: const Icon(Icons.add_alert_rounded),
                    label: const Text('サンプル通知を追加'),
                  ),
                ],
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
      widget.notificationStore.deleteAll(),
      if (widget.pointWallet != null)
        widget.pointWallet!.resetDevelopmentData(),
    ]);
    if (!mounted) return;
    setState(() => _resetting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('開発用データを初期化しました')));
  }

  Future<void> _addSampleNotification() async {
    final index = widget.notificationStore.notifications.length % 3;
    final now = DateTime.now().toUtc();
    final sample = switch (index) {
      0 => AppNotification(
        id: 'sample_${now.microsecondsSinceEpoch}',
        type: NotificationType.predictionResult,
        title: '予想結果が出ました',
        message: '任天堂・1週間後 UP の答え合わせができます',
        createdAt: now,
        isRead: false,
        relatedCompanyId: 'nintendo',
      ),
      1 => AppNotification(
        id: 'sample_${now.microsecondsSinceEpoch}',
        type: NotificationType.featureUpdate,
        title: 'KABUCAに新機能！',
        message: '株価予想が遊べるようになりました',
        createdAt: now,
        isRead: false,
      ),
      _ => AppNotification(
        id: 'sample_${now.microsecondsSinceEpoch}',
        type: NotificationType.reward,
        title: 'パックを獲得しました',
        message: '新しいパックを1個獲得しました',
        createdAt: now,
        isRead: false,
      ),
    };
    await widget.notificationStore.add(sample);
  }
}
