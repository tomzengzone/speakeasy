import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/application/session/device_session_coordinator.dart';
import 'package:speakeasy/application/session/device_session_models.dart';

class _FakeDeviceSessionsRemoteApi implements DeviceSessionsRemoteApi {
  Map<String, dynamic> response = <String, dynamic>{
    'schema_version': 1,
    'sessions': <Map<String, dynamic>>[],
  };
  Object? logoutCurrentError;
  Object? logoutAllError;
  final List<String> events = <String>[];
  int revokeCount = 0;

  @override
  Future<Map<String, dynamic>> listSessions() async => response;

  @override
  Future<void> logoutAll() async {
    events.add('remote-all');
    if (logoutAllError case final Object error) {
      throw error;
    }
  }

  @override
  Future<void> logoutCurrent() async {
    events.add('remote-current');
    if (logoutCurrentError case final Object error) {
      throw error;
    }
  }

  @override
  Future<void> logoutOthers() async {
    events.add('remote-others');
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    revokeCount += 1;
    events.add('revoke:$sessionId');
  }
}

void main() {
  test(
    'loads current device first and orders other devices by activity',
    () async {
      final _FakeDeviceSessionsRemoteApi remote = _FakeDeviceSessionsRemoteApi()
        ..response = <String, dynamic>{
          'schema_version': 1,
          'sessions': <Map<String, dynamic>>[
            _sessionJson(id: 'older', lastActiveAt: '2026-08-20T08:00:00Z'),
            _sessionJson(id: 'newer', lastActiveAt: '2026-08-28T08:00:00Z'),
            _sessionJson(
              id: 'current',
              current: true,
              lastActiveAt: '2026-08-18T08:00:00Z',
            ),
          ],
        };
      final DeviceSessionCoordinator coordinator = DeviceSessionCoordinator(
        remoteApi: remote,
      );

      final List<DeviceSessionSummary> sessions = await coordinator
          .loadSessions();

      expect(
        sessions.map((DeviceSessionSummary item) => item.sessionId),
        <String>['current', 'newer', 'older'],
      );
    },
  );

  test('current device cannot use remote revoke action', () async {
    final _FakeDeviceSessionsRemoteApi remote = _FakeDeviceSessionsRemoteApi();
    final DeviceSessionCoordinator coordinator = DeviceSessionCoordinator(
      remoteApi: remote,
    );
    final DeviceSessionSummary current = DeviceSessionSummary.fromJson(
      _sessionJson(id: 'current', current: true),
    );

    expect(() => coordinator.revokeSession(current), throwsArgumentError);
    expect(remote.revokeCount, 0);
  });

  test('normal logout calls server before local session cleanup', () async {
    final _FakeDeviceSessionsRemoteApi remote = _FakeDeviceSessionsRemoteApi();
    final DeviceSessionCoordinator coordinator = DeviceSessionCoordinator(
      remoteApi: remote,
    );

    final DeviceLogoutResult result = await coordinator.logoutCurrent(
      clearLocalSession: () async => remote.events.add('local-clear'),
    );

    expect(remote.events, <String>['remote-current', 'local-clear']);
    expect(result.remoteCompleted, isTrue);
    expect(result.userMessage, isNull);
  });

  test(
    'normal logout still clears local state when server is offline',
    () async {
      final _FakeDeviceSessionsRemoteApi remote = _FakeDeviceSessionsRemoteApi()
        ..logoutCurrentError = Exception('offline');
      final DeviceSessionCoordinator coordinator = DeviceSessionCoordinator(
        remoteApi: remote,
      );

      final DeviceLogoutResult result = await coordinator.logoutCurrent(
        clearLocalSession: () async => remote.events.add('local-clear'),
      );

      expect(remote.events, <String>['remote-current', 'local-clear']);
      expect(result.remoteCompleted, isFalse);
      expect(result.userMessage, contains('服务器端会话可能尚未撤销'));
    },
  );

  test(
    'logout all clears local state and reports honest network warning',
    () async {
      final _FakeDeviceSessionsRemoteApi remote = _FakeDeviceSessionsRemoteApi()
        ..logoutAllError = Exception('offline');
      final DeviceSessionCoordinator coordinator = DeviceSessionCoordinator(
        remoteApi: remote,
      );

      final DeviceLogoutResult result = await coordinator.logoutAll(
        clearLocalSession: () async => remote.events.add('local-clear'),
      );

      expect(remote.events, <String>['remote-all', 'local-clear']);
      expect(result.remoteCompleted, isFalse);
      expect(result.userMessage, contains('其他设备可能尚未退出'));
    },
  );
}

Map<String, dynamic> _sessionJson({
  required String id,
  bool current = false,
  String lastActiveAt = '2026-08-27T08:00:00Z',
}) {
  return <String, dynamic>{
    'session_id': id,
    'current': current,
    'device_name': current ? 'This phone' : 'Other phone',
    'platform': 'android',
    'app_version': '2.4.0',
    'created_at': '2026-08-20T08:00:00Z',
    'last_active_at': lastActiveAt,
    'device_id': 'must-not-be-exposed',
    'ip_address': '192.0.2.1',
    'refresh_token': 'must-not-be-exposed',
  };
}
