import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/stock_prediction.dart';

class PredictionLocalNotificationService {
  PredictionLocalNotificationService._();

  static final PredictionLocalNotificationService instance =
      PredictionLocalNotificationService._();

  static const _enabledKey = 'settings.prediction_notifications_enabled';
  static const _payloadPrefix = 'prediction:';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final tz.Location _tokyo;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    _tokyo = tz.getLocation('Asia/Tokyo');

    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  Future<bool> enable() async {
    await initialize();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final granted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, granted);

    return granted;
  }

  Future<void> disable() async {
    await initialize();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, false);

    final pending = await _plugin.pendingNotificationRequests();

    for (final notification in pending) {
      if (notification.payload?.startsWith(_payloadPrefix) ?? false) {
        await _plugin.cancel(id: notification.id);
      }
    }
  }

  Future<void> scheduleFor(StockPrediction prediction) async {
    await initialize();

    if (!await isEnabled()) return;

    final target = prediction.targetDate;
    if (target == null) return;

    final scheduledAt = tz.TZDateTime(
      _tokyo,
      target.year,
      target.month,
      target.day,
      17,
    );

    if (!scheduledAt.isAfter(tz.TZDateTime.now(_tokyo))) return;

    await _plugin.zonedSchedule(
      id: _notificationId(prediction.id),
      title: '予想結果を確認しよう',
      body: '${prediction.companyName}の予想結果を確認できる時間になりました',
      scheduledDate: scheduledAt,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '$_payloadPrefix${prediction.id}',
    );
  }

  Future<void> scheduleAll(Iterable<StockPrediction> predictions) async {
    for (final prediction in predictions) {
      await scheduleFor(prediction);
    }
  }

  Future<void> scheduleTestNotification() async {
    await initialize();

    final scheduledAt = tz.TZDateTime.now(
      _tokyo,
    ).add(const Duration(minutes: 1));

    await _plugin.zonedSchedule(
      id: 2147483000,
      title: 'KABUCA',
      body: 'テスト通知です。ローカル通知は正常に動いています。',
      scheduledDate: scheduledAt,
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'test:local-notification',
    );
  }

  int _notificationId(String predictionId) {
    var hash = 0;

    for (final codeUnit in predictionId.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }

    return hash;
  }
}
