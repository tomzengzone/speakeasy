import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:speakeasy/application/session/device_session_coordinator.dart';
import 'package:speakeasy/application/session/device_session_models.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_client.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/payment_service.dart';

class _MockProfileCoordinator extends Mock
    implements SessionProfileCoordinator {}

class _MockStatsCoordinator extends Mock implements SessionStatsCoordinator {}

class _StoredSessionCoordinator extends SessionLifecycleCoordinator {
  _StoredSessionCoordinator()
    : super(authService: AuthService(signInWithEmail: (_) async => _user));

  static const AppUser _user = AppUser(
    nickname: 'Tester',
    avatarUrl: '',
    memberPlan: 'free',
    onboardingDone: true,
  );

  @override
  Future<StoredSessionSnapshot> loadStoredSession() async {
    return const StoredSessionSnapshot(
      user: _user,
      onboardingDone: true,
      themeMode: ThemeMode.light,
    );
  }

  @override
  Future<ResolvedAuthenticatedSession?> hydrateExistingSession() async => null;
}

class _RecordingDeviceApi implements DeviceSessionsRemoteApi {
  _RecordingDeviceApi(this.events);

  final List<String> events;
  Object? logoutCurrentError;
  Object? logoutAllError;

  @override
  Future<Map<String, dynamic>> listSessions() async {
    return <String, dynamic>{
      'schema_version': 1,
      'sessions': <Map<String, dynamic>>[],
    };
  }

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
  Future<void> logoutOthers() async {}

  @override
  Future<void> revokeSession(String sessionId) async {}
}

void main() {
  late _MockProfileCoordinator profileCoordinator;
  late _MockStatsCoordinator statsCoordinator;
  late List<String> events;

  setUp(() {
    profileCoordinator = _MockProfileCoordinator();
    statsCoordinator = _MockStatsCoordinator();
    events = <String>[];
    when(
      () => profileCoordinator.clearSessionData(),
    ).thenAnswer((_) async => events.add('profile-clear'));
    when(
      () => statsCoordinator.clearCache(),
    ).thenAnswer((_) async => events.add('stats-clear'));
    when(
      () => statsCoordinator.loadCachedStats(),
    ).thenAnswer((_) async => null);
  });

  AppSession createSession({
    required _RecordingDeviceApi remote,
    Stream<SessionSecurityFailure>? failures,
  }) {
    return AppSession(
      paymentService: const UnsupportedPaymentService(),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => <String, dynamic>{
          'plan': 'free',
          'status': 'inactive',
          'features': <String, dynamic>{},
        },
      ),
      sessionCoordinator: _StoredSessionCoordinator(),
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
      deviceSessionCoordinator: DeviceSessionCoordinator(remoteApi: remote),
      sessionSecurityFailures:
          failures ?? const Stream<SessionSecurityFailure>.empty(),
    );
  }

  test(
    'normal logout attempts server first then clears all local state',
    () async {
      final _RecordingDeviceApi remote = _RecordingDeviceApi(events);
      final AppSession session = createSession(remote: remote);
      await pumpEventQueue(times: 8);
      expect(session.isLoggedIn, isTrue);

      final DeviceLogoutResult result = await session.logout();

      expect(result.remoteCompleted, isTrue);
      expect(events, <String>[
        'remote-current',
        'profile-clear',
        'stats-clear',
      ]);
      expect(session.isLoggedIn, isFalse);
      session.dispose();
    },
  );

  test(
    'logout all network failure still clears local state and warns',
    () async {
      final _RecordingDeviceApi remote = _RecordingDeviceApi(events)
        ..logoutAllError = Exception('offline');
      final AppSession session = createSession(remote: remote);
      await pumpEventQueue(times: 8);

      final DeviceLogoutResult result = await session.logoutAll();

      expect(result.remoteCompleted, isFalse);
      expect(events, <String>['remote-all', 'profile-clear', 'stats-clear']);
      expect(session.isLoggedIn, isFalse);
      expect(session.authErrorMessage, contains('其他设备可能尚未退出'));
      session.dispose();
    },
  );

  for (final ({SessionSecurityReason reason, String code, String message})
      scenario
      in <({SessionSecurityReason reason, String code, String message})>[
        (
          reason: SessionSecurityReason.sessionRevoked,
          code: 'SESSION_REVOKED',
          message: '此设备的登录已被退出，请重新登录。',
        ),
        (
          reason: SessionSecurityReason.refreshTokenExpired,
          code: 'REFRESH_TOKEN_EXPIRED',
          message: '登录已过期，请重新登录。',
        ),
        (
          reason: SessionSecurityReason.refreshTokenInvalid,
          code: 'REFRESH_TOKEN_INVALID',
          message: '登录已失效，请重新登录。',
        ),
        (
          reason: SessionSecurityReason.tokenReuseDetected,
          code: 'TOKEN_REUSE_DETECTED',
          message: '检测到登录凭证异常，为保护账号已退出登录，请重新登录。',
        ),
        (
          reason: SessionSecurityReason.accountDisabled,
          code: 'ACCOUNT_DISABLED',
          message: '账号已被禁用，如有疑问请联系支持。',
        ),
      ]) {
    test(
      '${scenario.code} clears session and preserves distinct copy',
      () async {
        final StreamController<SessionSecurityFailure> failures =
            StreamController<SessionSecurityFailure>.broadcast(sync: true);
        final AppSession session = createSession(
          remote: _RecordingDeviceApi(events),
          failures: failures.stream,
        );
        await pumpEventQueue(times: 8);

        failures.add(
          SessionSecurityFailure(
            reason: scenario.reason,
            backendCode: scenario.code,
            userMessage: scenario.message,
          ),
        );
        await untilCalled(() => profileCoordinator.clearSessionData());
        await pumpEventQueue(times: 4);

        expect(session.isLoggedIn, isFalse);
        expect(session.authErrorMessage, scenario.message);
        verify(() => profileCoordinator.clearSessionData()).called(1);
        verify(() => statsCoordinator.clearCache()).called(1);
        session.dispose();
        await failures.close();
      },
    );
  }
}
