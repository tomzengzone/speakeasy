import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/storage_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _enabled = false;
  int _hour = 20;
  int _minute = 0;

  bool get enabled => _enabled;
  int get hour => _hour;
  int get minute => _minute;

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final NotificationSettingsStorageModel settings = StorageService.instance
        .getNotificationSettings();
    _enabled = settings.enabled;
    _hour = settings.hour;
    _minute = settings.minute;

    if (_enabled) {
      await _schedule();
    }
  }

  Future<bool> requestPermission() async {
    final bool? granted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? true;
  }

  Future<void> setEnabled({required bool value}) async {
    _enabled = value;
    await StorageService.instance.saveNotificationSettings(
      NotificationSettingsStorageModel(
        enabled: value,
        hour: _hour,
        minute: _minute,
      ),
    );
    if (value) {
      await requestPermission();
      await _schedule();
    } else {
      await _plugin.cancel(_dailyReminderId);
    }
  }

  Future<void> setTime({required int hour, required int minute}) async {
    _hour = hour;
    _minute = minute;
    await StorageService.instance.saveNotificationSettings(
      NotificationSettingsStorageModel(
        enabled: _enabled,
        hour: hour,
        minute: minute,
      ),
    );
    if (_enabled) {
      await _schedule();
    }
  }

  Future<void> _schedule() async {
    await _plugin.cancel(_dailyReminderId);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _hour,
      _minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'speakeasy_daily',
      '每日练习提醒',
      channelDescription: '提醒你完成今日英语口语练习',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails ios = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: android,
      iOS: ios,
    );

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '该练口语了 💬',
      '今天还没练习，点击开始今日任务',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
