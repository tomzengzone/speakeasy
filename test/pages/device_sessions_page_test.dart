import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/application/session/device_session_coordinator.dart';
import 'package:speakeasy/application/session/device_session_models.dart';
import 'package:speakeasy/pages/device_sessions_page.dart';

class _PageRemoteApi implements DeviceSessionsRemoteApi {
  _PageRemoteApi(this.listHandler);

  Future<Map<String, dynamic>> Function() listHandler;
  int revokeAttempts = 0;
  bool failNextRevoke = false;
  int logoutOthersCount = 0;

  @override
  Future<Map<String, dynamic>> listSessions() => listHandler();

  @override
  Future<void> logoutAll() async {}

  @override
  Future<void> logoutCurrent() async {}

  @override
  Future<void> logoutOthers() async {
    logoutOthersCount += 1;
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    revokeAttempts += 1;
    if (failNextRevoke) {
      failNextRevoke = false;
      throw Exception('offline');
    }
  }
}

void main() {
  testWidgets('shows loading then current-first minimal device information', (
    WidgetTester tester,
  ) async {
    final Completer<Map<String, dynamic>> response =
        Completer<Map<String, dynamic>>();
    final _PageRemoteApi remote = _PageRemoteApi(() => response.future);

    await tester.pumpWidget(_app(remote));

    expect(
      find.byKey(const ValueKey<String>('device_sessions_loading')),
      findsOneWidget,
    );

    response.complete(_sessionList());
    await tester.pumpAndSettle();

    final Finder currentCard = find.byKey(
      const ValueKey<String>('device_session_current-session'),
    );
    final Finder otherCard = find.byKey(
      const ValueKey<String>('device_session_other-session'),
    );
    expect(currentCard, findsOneWidget);
    expect(otherCard, findsOneWidget);
    expect(
      tester.getTopLeft(currentCard).dy,
      lessThan(tester.getTopLeft(otherCard).dy),
    );
    expect(find.text('当前设备'), findsOneWidget);
    expect(find.text('This phone'), findsOneWidget);
    expect(find.text('Other phone'), findsOneWidget);
    expect(find.text('secret-device-id'), findsNothing);
    expect(find.text('192.0.2.1'), findsNothing);
    expect(find.text('secret-refresh-token'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('revoke_session_current-session')),
      findsNothing,
    );
  });

  testWidgets('load error exposes retry and recovers to empty state', (
    WidgetTester tester,
  ) async {
    int attempts = 0;
    final _PageRemoteApi remote = _PageRemoteApi(() async {
      attempts += 1;
      if (attempts == 1) {
        throw Exception('offline');
      }
      return <String, dynamic>{
        'schema_version': 1,
        'sessions': <Map<String, dynamic>>[],
      };
    });

    await tester.pumpWidget(_app(remote));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('device_sessions_error')),
      findsOneWidget,
    );
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(
      find.byKey(const ValueKey<String>('device_sessions_empty')),
      findsOneWidget,
    );
  });

  testWidgets('failed remote revoke offers retry and removes only target', (
    WidgetTester tester,
  ) async {
    final _PageRemoteApi remote = _PageRemoteApi(() async => _sessionList())
      ..failNextRevoke = true;

    await tester.pumpWidget(_app(remote));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('revoke_session_other-session')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出设备'));
    await tester.pumpAndSettle();

    expect(remote.revokeAttempts, 1);
    expect(
      find.byKey(const ValueKey<String>('device_sessions_action_error')),
      findsOneWidget,
    );

    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();

    expect(remote.revokeAttempts, 2);
    expect(
      find.byKey(const ValueKey<String>('device_session_other-session')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('device_session_current-session')),
      findsOneWidget,
    );
  });

  testWidgets('logout others confirms and preserves current device', (
    WidgetTester tester,
  ) async {
    final _PageRemoteApi remote = _PageRemoteApi(() async => _sessionList());

    await tester.pumpWidget(_app(remote));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('logout_other_sessions_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出其他设备').last);
    await tester.pumpAndSettle();

    expect(remote.logoutOthersCount, 1);
    expect(
      find.byKey(const ValueKey<String>('device_session_other-session')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('device_session_current-session')),
      findsOneWidget,
    );
  });

  testWidgets('logout all confirms before delegating local-safe logout', (
    WidgetTester tester,
  ) async {
    final _PageRemoteApi remote = _PageRemoteApi(() async => _sessionList());
    int logoutAllCount = 0;

    await tester.pumpWidget(
      _app(
        remote,
        logoutAll: () async {
          logoutAllCount += 1;
          return const DeviceLogoutResult(remoteCompleted: true);
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('logout_all_sessions_button')),
    );
    await tester.pumpAndSettle();

    expect(logoutAllCount, 0);
    await tester.tap(find.text('全部退出'));
    await tester.pumpAndSettle();

    expect(logoutAllCount, 1);
  });
}

Widget _app(
  _PageRemoteApi remote, {
  Future<DeviceLogoutResult> Function()? logoutAll,
}) {
  return MaterialApp(
    home: DeviceSessionsPage(
      coordinator: DeviceSessionCoordinator(remoteApi: remote),
      logoutAll: logoutAll,
    ),
  );
}

Map<String, dynamic> _sessionList() {
  return <String, dynamic>{
    'schema_version': 1,
    'sessions': <Map<String, dynamic>>[
      _session(id: 'other-session', current: false, name: 'Other phone'),
      _session(id: 'current-session', current: true, name: 'This phone'),
    ],
  };
}

Map<String, dynamic> _session({
  required String id,
  required bool current,
  required String name,
}) {
  return <String, dynamic>{
    'session_id': id,
    'current': current,
    'device_name': name,
    'platform': current ? 'ios' : 'android',
    'app_version': '2.4.0',
    'created_at': '2026-08-20T08:00:00Z',
    'last_active_at': current ? '2026-08-27T08:00:00Z' : '2026-08-28T08:00:00Z',
    'device_id': 'secret-device-id',
    'ip_address': '192.0.2.1',
    'refresh_token': 'secret-refresh-token',
  };
}
