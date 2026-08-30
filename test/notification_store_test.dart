import 'package:flutter_test/flutter_test.dart';
import 'package:kabuca_flutter/models/app_notification.dart';
import 'package:kabuca_flutter/state/notification_store.dart';

void main() {
  test('追加・既読・全件既読を永続化して復元できる', () async {
    final storage = _Storage();
    final store = await NotificationStore.load(storage: storage);
    await store.add(_notification('one'));
    await store.add(_notification('two'));
    expect(store.unreadCount, 2);

    await store.markAsRead('one');
    expect(store.unreadCount, 1);
    var restored = await NotificationStore.load(storage: storage);
    expect(restored.notifications, hasLength(2));
    expect(
      restored.notifications.singleWhere((item) => item.id == 'one').isRead,
      isTrue,
    );

    await restored.markAllAsRead();
    expect(restored.unreadCount, 0);
    restored = await NotificationStore.load(storage: storage);
    expect(restored.unreadCount, 0);
  });

  test('1件削除と全件削除ができる', () async {
    final store = NotificationStore.memory(
      notifications: [_notification('one'), _notification('two')],
    );
    await store.delete('one');
    expect(store.notifications.map((item) => item.id), ['two']);
    await store.deleteAll();
    expect(store.notifications, isEmpty);
    expect(store.unreadCount, 0);
  });
}

AppNotification _notification(String id) => AppNotification(
  id: id,
  type: NotificationType.general,
  title: 'お知らせ$id',
  message: '本文$id',
  createdAt: DateTime.utc(2026, 8, 30),
  isRead: false,
  relatedPredictionId: 'prediction-$id',
  relatedCompanyId: 'company-$id',
);

class _Storage implements NotificationStorage {
  List<Map<String, Object?>> json = [];

  @override
  Future<List<AppNotification>> readNotifications() async =>
      json.map(AppNotification.fromJson).toList();

  @override
  Future<void> writeNotifications(List<AppNotification> notifications) async {
    json = notifications.map((item) => item.toJson()).toList();
  }
}
