import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';

abstract interface class NotificationStorage {
  Future<List<AppNotification>> readNotifications();
  Future<void> writeNotifications(List<AppNotification> notifications);
}

class SharedPreferencesNotificationStorage implements NotificationStorage {
  static const key = 'notifications.items';

  @override
  Future<List<AppNotification>> readNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(key) ?? const [])
        .map(
          (value) => AppNotification.fromJson(
            jsonDecode(value) as Map<String, Object?>,
          ),
        )
        .toList();
  }

  @override
  Future<void> writeNotifications(List<AppNotification> notifications) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      key,
      notifications.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }
}

class NotificationStore extends ChangeNotifier {
  NotificationStore._(this._storage, Iterable<AppNotification> notifications)
    : _notifications = List.of(notifications)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final NotificationStorage _storage;
  final List<AppNotification> _notifications;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((item) => !item.isRead).length;

  static Future<NotificationStore> load({NotificationStorage? storage}) async {
    final target = storage ?? SharedPreferencesNotificationStorage();
    return NotificationStore._(target, await target.readNotifications());
  }

  static NotificationStore memory({
    Iterable<AppNotification> notifications = const [],
  }) => NotificationStore._(_MemoryNotificationStorage(), notifications);

  Future<void> add(AppNotification notification) async {
    _notifications.removeWhere((item) => item.id == notification.id);
    _notifications.insert(0, notification);
    notifyListeners();
    await _persist();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    await _persist();
  }

  Future<void> markAllAsRead() async {
    if (unreadCount == 0) return;
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    final removed = _notifications.length;
    _notifications.removeWhere((item) => item.id == id);
    if (removed == _notifications.length) return;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteAll() async {
    if (_notifications.isEmpty) return;
    _notifications.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() => _storage.writeNotifications(_notifications);
}

class _MemoryNotificationStorage implements NotificationStorage {
  List<AppNotification> values = [];

  @override
  Future<List<AppNotification>> readNotifications() async => List.of(values);

  @override
  Future<void> writeNotifications(List<AppNotification> notifications) async {
    values = List.of(notifications);
  }
}
