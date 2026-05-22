import 'package:speakeasy/services/notification_service.dart';

class NotificationPreferencesSnapshot {
  const NotificationPreferencesSnapshot({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;
}

abstract class NotificationPreferencesGateway {
  bool get enabled;
  int get hour;
  int get minute;

  Future<void> setEnabled({required bool value});

  Future<void> setTime({required int hour, required int minute});
}

class NotificationServicePreferencesGateway
    implements NotificationPreferencesGateway {
  const NotificationServicePreferencesGateway();

  @override
  bool get enabled => NotificationService.instance.enabled;

  @override
  int get hour => NotificationService.instance.hour;

  @override
  int get minute => NotificationService.instance.minute;

  @override
  Future<void> setEnabled({required bool value}) {
    return NotificationService.instance.setEnabled(value: value);
  }

  @override
  Future<void> setTime({required int hour, required int minute}) {
    return NotificationService.instance.setTime(hour: hour, minute: minute);
  }
}

class NotificationPreferencesCoordinator {
  const NotificationPreferencesCoordinator({
    NotificationPreferencesGateway gateway =
        const NotificationServicePreferencesGateway(),
  }) : _gateway = gateway;

  final NotificationPreferencesGateway _gateway;

  NotificationPreferencesSnapshot loadSettings() {
    return NotificationPreferencesSnapshot(
      enabled: _gateway.enabled,
      hour: _gateway.hour,
      minute: _gateway.minute,
    );
  }

  Future<NotificationPreferencesSnapshot> setReminderEnabled({
    required bool value,
  }) async {
    await _gateway.setEnabled(value: value);
    return loadSettings();
  }

  Future<NotificationPreferencesSnapshot> setReminderTime({
    required int hour,
    required int minute,
  }) async {
    await _gateway.setTime(hour: hour, minute: minute);
    return loadSettings();
  }
}
