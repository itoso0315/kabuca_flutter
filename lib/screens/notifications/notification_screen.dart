import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../models/app_notification.dart';
import '../../models/stock_prediction.dart';
import '../../state/notification_store.dart';
import '../../state/prediction_store.dart';
import '../prediction/prediction_result_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({
    super.key,
    required this.store,
    this.predictionStore,
  });

  final NotificationStore store;
  final PredictionStore? predictionStore;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.cream,
    appBar: AppBar(
      title: const Text('お知らせ'),
      actions: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) => TextButton(
            key: const Key('mark-all-notifications-read'),
            onPressed: store.unreadCount == 0 ? null : store.markAllAsRead,
            child: const Text('すべて既読'),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.notifications.isEmpty) {
          return const Center(
            key: Key('notification-empty-state'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.mutedGold,
                  size: 48,
                ),
                SizedBox(height: 14),
                Text('まだお知らせはありません'),
              ],
            ),
          );
        }
        return ListView.separated(
          key: const Key('notification-list'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          itemCount: store.notifications.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final notification = store.notifications[index];
            return _NotificationTile(
              notification: notification,
              onTap: () => _openNotification(context, notification),
            );
          },
        );
      },
    ),
  );

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    await store.markAsRead(notification.id);
    if (!context.mounted ||
        notification.type != NotificationType.predictionResult ||
        notification.relatedPredictionId == null) {
      return;
    }
    final prediction = predictionStore?.findById(
      notification.relatedPredictionId!,
    );
    if (prediction == null || prediction.status != PredictionStatus.completed) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PredictionResultScreen(prediction: prediction),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Material(
      key: Key('notification-${notification.id}'),
      color: unread ? const Color(0xFFF2E9CE) : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.softGreen,
                foregroundColor: AppColors.deepGreen,
                child: Icon(_iconFor(notification.type), size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (unread)
                          const DecoratedBox(
                            key: Key('notification-unread-dot'),
                            decoration: BoxDecoration(
                              color: AppColors.mutedGold,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 8, height: 8),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatJapanTime(notification.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(NotificationType type) => switch (type) {
  NotificationType.predictionResult => Icons.show_chart_rounded,
  NotificationType.featureUpdate => Icons.auto_awesome_rounded,
  NotificationType.reward => Icons.card_giftcard_rounded,
  NotificationType.collection => Icons.auto_awesome_mosaic_rounded,
  NotificationType.general => Icons.notifications_none_rounded,
};

String _formatJapanTime(DateTime timestamp) {
  final japan = timestamp.toUtc().add(const Duration(hours: 9));
  return '${japan.month}/${japan.day} '
      '${japan.hour.toString().padLeft(2, '0')}:'
      '${japan.minute.toString().padLeft(2, '0')}';
}
