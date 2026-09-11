import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_theme.dart';
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
  String _appVersion = '-';
  String _buildNumber = '-';

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _loadAppInfo();
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
          const SizedBox(height: 20),
          _ProfileSection(
            title: 'ヘルプ',
            children: [
              ListTile(
                key: const Key('show-onboarding-guide-tile'),
                leading: const Icon(Icons.auto_awesome_rounded),
                title: const Text('初回ガイドをもう一度見る'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _showOnboardingGuide,
              ),
              const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFEAE5DA),
              ),
              ListTile(
                key: const Key('support-tile'),
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('サポート・お問い合わせ'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                onTap: () =>
                    _openExternalUrl('https://kabuca-api.onrender.com/support'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileSection(
            title: '法務',
            children: [
              ListTile(
                key: const Key('privacy-policy-tile'),
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('プライバシーポリシー'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                onTap: () =>
                    _openExternalUrl('https://kabuca-api.onrender.com/privacy'),
              ),
              const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFEAE5DA),
              ),
              ListTile(
                key: const Key('terms-tile'),
                leading: const Icon(Icons.description_outlined),
                title: const Text('利用規約'),
                trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                onTap: () =>
                    _openExternalUrl('https://kabuca-api.onrender.com/terms'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ProfileSection(
            title: 'アプリ情報',
            children: [
              ListTile(
                key: const Key('app-info-tile'),
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('KABUCA'),
                subtitle: Text('バージョン $_appVersion  •  Build $_buildNumber'),
              ),
            ],
          ),
          if (kDebugMode) ...[
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
                    key: const Key('add-1000-kabu-button'),

                    onPressed: widget.pointWallet == null
                        ? null
                        : () async {
                            await widget.pointWallet!.refund(1000);
                          },

                    icon: const Icon(Icons.auto_awesome_rounded),

                    label: const Text('+1000 KABU'),
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;

    setState(() {
      _appVersion = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  Future<void> _openExternalUrl(String value) async {
    final uri = Uri.parse(value);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ページを開けませんでした')));
  }

  Future<void> _showOnboardingGuide() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('profile-onboarding-guide-dialog'),
        icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB39450)),
        title: const Text('KABUCAの遊び方'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideItem(
              icon: Icons.inventory_2_rounded,
              title: 'まずは無料パック3個！',
              description: '最初から3パック持っています。さっそく企業カードを集めよう。',
            ),
            SizedBox(height: 16),
            _GuideItem(
              icon: Icons.insights_rounded,
              title: '株価予想でKABUを貯めよう',
              description: '企業の株価が上がるか下がるか予想。結果に応じてKABUを獲得できます。',
            ),
            SizedBox(height: 16),
            _GuideItem(
              icon: Icons.menu_book_rounded,
              title: '図鑑を埋めよう',
              description: 'ゲットした企業カードは図鑑に登録されます。日本の企業をどんどん集めよう。',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('予想結果の通知をONにしました')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('通知が許可されていません')));
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('1分後のテスト通知を予約しました')));
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Card(
        margin: EdgeInsets.zero,
        child: Column(children: children),
      ),
    ],
  );
}

class _GuideItem extends StatelessWidget {
  const _GuideItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF4E9C8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFFA67D2D), size: 21),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF123D33),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF66736C),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
