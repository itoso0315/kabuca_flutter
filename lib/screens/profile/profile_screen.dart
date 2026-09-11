import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../data/card_catalog.dart';
import '../../models/app_notification.dart';
import '../../models/stock_prediction.dart';
import '../../services/prediction_local_notification_service.dart';
import '../../state/game_state.dart';
import '../../state/notification_store.dart';
import '../../state/point_wallet.dart';
import '../../state/prediction_store.dart';
import '../debug/company_art_preview_screen.dart';
import '../prediction/prediction_result_screen.dart';

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
  bool _predictionNotificationsEnabled = false;
  bool _loadingNotificationSetting = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

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
                  Text(
                    '図鑑登録  ${widget.gameState.registeredCardCount} / ${CardCatalog.cards.length}',
                  ),
                  Text('保存済み予想  ${widget.predictionStore.predictions.length}件'),
                  Text('KABU  ${widget.pointWallet?.currentPoints ?? 0} KABU'),
                  Text(
                    'お知らせ  ${widget.notificationStore.notifications.length}件',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Card(
            child: SwitchListTile(
              key: const Key('prediction-notification-switch'),
              value: _predictionNotificationsEnabled,
              onChanged: _loadingNotificationSetting
                  ? null
                  : _changePredictionNotifications,
              secondary: const Icon(Icons.notifications_active_rounded),
              title: const Text(
                '予想結果の通知',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('答え合わせ予定日の17:00にお知らせします'),
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
                  '実機テスト用に、パック・カード・図鑑・予想・KABU・お知らせを初期状態へ戻します。',
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
                    key: const Key('company-art-preview-button'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const CompanyArtPreviewScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.image_search_rounded),
                    label: const Text('企業アート確認'),
                  ),
                  TextButton.icon(
                    key: const Key('prediction-result-preview-button'),
                    onPressed: _openPredictionResultPreview,
                    icon: const Icon(Icons.emoji_events_rounded),
                    label: const Text('予想結果を確認'),
                  ),
                  TextButton.icon(
                    key: const Key('add-100-kabu-button'),
                    onPressed: widget.pointWallet == null
                        ? null
                        : () async {
                            await widget.pointWallet!.refund(100);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('開発用に100 KABU追加しました'),
                              ),
                            );
                          },
                    icon: const Icon(Icons.stars_rounded),
                    label: const Text('+100 KABU'),
                  ),
                  TextButton.icon(
                    key: const Key('add-sample-notification-button'),
                    onPressed: _addSampleNotification,
                    icon: const Icon(Icons.add_alert_rounded),
                    label: const Text('サンプル通知を追加'),
                  ),
                  TextButton.icon(
                    key: const Key('test-local-notification-button'),
                    onPressed: _scheduleTestLocalNotification,
                    icon: const Icon(Icons.notifications_active_rounded),
                    label: const Text('1分後にテスト通知'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotificationSetting() async {
    final enabled = await PredictionLocalNotificationService.instance
        .isEnabled();

    if (!mounted) return;

    setState(() {
      _predictionNotificationsEnabled = enabled;
      _loadingNotificationSetting = false;
    });
  }

  Future<void> _changePredictionNotifications(bool enabled) async {
    if (enabled) {
      final granted = await PredictionLocalNotificationService.instance
          .enable();

      if (!mounted) return;

      setState(() {
        _predictionNotificationsEnabled = granted;
      });

      if (granted) {
        await PredictionLocalNotificationService.instance.scheduleAll(
          widget.predictionStore.pendingPredictions,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('予想結果の通知をONにしました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('通知が許可されていません')),
        );
      }
    } else {
      await PredictionLocalNotificationService.instance.disable();

      if (!mounted) return;

      setState(() {
        _predictionNotificationsEnabled = false;
      });
    }
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

  void _openPredictionResultPreview() {
    final now = DateTime.now();

    final prediction = StockPrediction(
      id: 'debug_prediction_result',
      companyId: 'toyota',
      companyName: 'トヨタ自動車',
      ticker: '7203',
      direction: PredictionDirection.up,
      horizon: PredictionHorizon.nextTradingDay,
      createdAt: now.subtract(const Duration(days: 1)),
      status: PredictionStatus.completed,
      basePrice: 3000,
      basePriceAt: now.subtract(const Duration(days: 1)),
      targetDate: now,
      resultPrice: 3105,
      resultPriceAt: now,
      changePercent: 3.5,
      isCorrect: true,
      awardedPoints: 45,
      baseReward: 20,
      movementBonus: 10,
      streakBonus: 15,
      correctStreak: 4,
      pointsClaimed: false,
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PredictionResultScreen(prediction: prediction),
      ),
    );
  }

  Future<void> _scheduleTestLocalNotification() async {
    await PredictionLocalNotificationService.instance
        .scheduleTestNotification();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('1分後のテスト通知を予約しました')),
    );
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
