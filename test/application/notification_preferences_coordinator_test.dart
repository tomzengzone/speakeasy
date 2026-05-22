import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/profile/notification_preferences_coordinator.dart';

class MockNotificationPreferencesGateway extends Mock
    implements NotificationPreferencesGateway {}

void main() {
  late MockNotificationPreferencesGateway gateway;
  late NotificationPreferencesCoordinator coordinator;

  setUp(() {
    gateway = MockNotificationPreferencesGateway();
    coordinator = NotificationPreferencesCoordinator(gateway: gateway);
  });

  test('loadSettings 会返回当前提醒设置快照', () {
    when(() => gateway.enabled).thenReturn(true);
    when(() => gateway.hour).thenReturn(8);
    when(() => gateway.minute).thenReturn(30);

    final NotificationPreferencesSnapshot snapshot = coordinator.loadSettings();

    expect(snapshot.enabled, isTrue);
    expect(snapshot.hour, 8);
    expect(snapshot.minute, 30);
  });

  test('setReminderEnabled 会委托 gateway 并返回最新快照', () async {
    when(() => gateway.setEnabled(value: true)).thenAnswer((_) async {});
    when(() => gateway.enabled).thenReturn(true);
    when(() => gateway.hour).thenReturn(20);
    when(() => gateway.minute).thenReturn(0);

    final NotificationPreferencesSnapshot snapshot = await coordinator
        .setReminderEnabled(value: true);

    verify(() => gateway.setEnabled(value: true)).called(1);
    expect(snapshot.enabled, isTrue);
    expect(snapshot.hour, 20);
    expect(snapshot.minute, 0);
  });

  test('setReminderTime 会委托 gateway 并返回最新快照', () async {
    when(() => gateway.setTime(hour: 9, minute: 45)).thenAnswer((_) async {});
    when(() => gateway.enabled).thenReturn(true);
    when(() => gateway.hour).thenReturn(9);
    when(() => gateway.minute).thenReturn(45);

    final NotificationPreferencesSnapshot snapshot = await coordinator
        .setReminderTime(hour: 9, minute: 45);

    verify(() => gateway.setTime(hour: 9, minute: 45)).called(1);
    expect(snapshot.enabled, isTrue);
    expect(snapshot.hour, 9);
    expect(snapshot.minute, 45);
  });
}
