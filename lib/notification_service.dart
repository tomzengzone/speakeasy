import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 1001;
  static const String _prefEnabled = 'notif_enabled';
  static const String _prefHour = 'notif_hour';
  static const String _prefMinute = 'notif_minute';

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

    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefEnabled) ?? false;
    _hour = prefs.getInt(_prefHour) ?? 20;
    _minute = prefs.getInt(_prefMinute) ?? 0;

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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, value);
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHour, hour);
    await prefs.setInt(_prefMinute, minute);
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
    const NotificationDetails details =
        NotificationDetails(android: android, iOS: ios);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '该练口语了 💬',
      '今天还没练习，点击开始今日任务',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
