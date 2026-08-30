import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/bootstrap/app_root.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_client.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/payment_service.dart';

class _MockRepository extends Mock implements AppRepository {}

class _MockProfileCoordinator extends Mock
    implements SessionProfileCoordinator {}

class _MockStatsCoordinator extends Mock implements SessionStatsCoordinator {}

class _ControlledSessionCoordinator extends SessionLifecycleCoordinator {
  _ControlledSessionCoordinator()
    : super(
        authService: AuthService(
          signInWithEmail: (_) async => const AppUser(
            nickname: 'cached learner',
            avatarUrl: '',
            memberPlan: 'free',
          ),
        ),
      );

  final Completer<StoredSessionSnapshot> stored =
      Completer<StoredSessionSnapshot>();
  final Completer<ResolvedAuthenticatedSession?> hydrated =
      Completer<ResolvedAuthenticatedSession?>();
  Completer<AuthCredentials?> foreground = Completer<AuthCredentials?>();
  int foregroundCalls = 0;

  @override
  Future<StoredSessionSnapshot> loadStoredSession() => stored.future;

  @override
  Future<ResolvedAuthenticatedSession?> hydrateExistingSession() {
    return hydrated.future;
  }

  @override
  Future<AuthCredentials?> refreshForForeground() {
    foregroundCalls += 1;
    return foreground.future;
  }
}

void main() {
  late _MockProfileCoordinator profile;
  late _MockStatsCoordinator stats;

  setUpAll(() {
    registerFallbackValue(
      const AppUser(nickname: 'fallback', avatarUrl: '', memberPlan: 'free'),
    );
    registerFallbackValue(const LearningStatsModel());
  });

  setUp(() {
    profile = _MockProfileCoordinator();
    stats = _MockStatsCoordinator();
    when(() => profile.persistUser(any())).thenAnswer((_) async {});
    when(() => stats.loadCachedStats()).thenAnswer((_) async => null);
    when(
      () => stats.refreshStats(currentStats: any(named: 'currentStats')),
    ).thenAnswer((_) async => const LearningStatsModel());
  });

  AppSession createSession(
    _ControlledSessionCoordinator coordinator, {
    void Function()? onEntitlementRefresh,
  }) {
    return AppSession(
      repository: _MockRepository(),
      paymentService: const UnsupportedPaymentService(),
      sessionCoordinator: coordinator,
      profileCoordinator: profile,
      statsCoordinator: stats,
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async {
          onEntitlementRefresh?.call();
          return <String, dynamic>{
            'plan': 'free',
            'status': 'inactive',
            'features': <String, dynamic>{},
          };
        },
      ),
      sessionSecurityFailures: const Stream<SessionSecurityFailure>.empty(),
    );
  }

  test(
    'startup gates authenticated work until one hydration chain resolves',
    () async {
      final _ControlledSessionCoordinator coordinator =
          _ControlledSessionCoordinator();
      int entitlementRefreshes = 0;
      final AppSession session = createSession(
        coordinator,
        onEntitlementRefresh: () => entitlementRefreshes += 1,
      );

      expect(session.authState, SessionAuthState.initializing);
      expect(session.isLoggedIn, isFalse);

      coordinator.stored.complete(
        const StoredSessionSnapshot(
          user: AppUser(
            nickname: 'cached learner',
            avatarUrl: '',
            memberPlan: 'free',
          ),
          onboardingDone: false,
          themeMode: ThemeMode.light,
          hasCredentials: true,
        ),
      );
      await pumpEventQueue(times: 2);

      expect(session.authState, SessionAuthState.initializing);
      expect(session.isLoggedIn, isFalse);
      expect(entitlementRefreshes, 0);

      coordinator.hydrated.complete(
        ResolvedAuthenticatedSession(
          credentials: AuthCredentials(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.utc(2099),
          ),
          userJson: const <String, dynamic>{
            'nickname': 'verified learner',
            'memberPlan': 'free',
            'onboardingDone': false,
          },
        ),
      );
      await pumpEventQueue(times: 8);

      expect(session.authState, SessionAuthState.authenticated);
      expect(session.isLoggedIn, isTrue);
      expect(entitlementRefreshes, 1);
      session.dispose();
    },
  );

  test(
    'startup network failure keeps credentials in a recoverable offline gate',
    () async {
      final _ControlledSessionCoordinator coordinator =
          _ControlledSessionCoordinator();
      final AppSession session = createSession(coordinator);
      coordinator.stored.complete(
        const StoredSessionSnapshot(
          user: AppUser(
            nickname: 'cached learner',
            avatarUrl: '',
            memberPlan: 'free',
          ),
          onboardingDone: true,
          themeMode: ThemeMode.light,
          hasCredentials: true,
        ),
      );
      coordinator.hydrated.completeError(
        const RefreshFailure(
          kind: RefreshFailureKind.infrastructure,
          message: 'offline',
        ),
      );

      await pumpEventQueue(times: 6);

      expect(session.authState, SessionAuthState.offlineDegraded);
      expect(session.isLoggedIn, isFalse);
      session.dispose();
    },
  );

  test(
    'foreground resume is single-flight for all lifecycle notifications',
    () async {
      final _ControlledSessionCoordinator coordinator =
          _ControlledSessionCoordinator();
      final AppSession session = createSession(coordinator);
      coordinator.stored.complete(
        const StoredSessionSnapshot(
          user: null,
          onboardingDone: false,
          themeMode: ThemeMode.light,
          hasCredentials: true,
        ),
      );
      final AuthCredentials credentials = AuthCredentials(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.utc(2099),
      );
      coordinator.hydrated.complete(
        ResolvedAuthenticatedSession(
          credentials: credentials,
          userJson: const <String, dynamic>{
            'nickname': 'verified learner',
            'memberPlan': 'free',
            'onboardingDone': false,
          },
        ),
      );
      await pumpEventQueue(times: 8);

      final Future<void> first = session.handleForegroundResume();
      final Future<void> second = session.handleForegroundResume();
      expect(coordinator.foregroundCalls, 1);

      coordinator.foreground.complete(credentials);
      await Future.wait(<Future<void>>[first, second]);
      expect(coordinator.foregroundCalls, 1);
      session.dispose();
    },
  );

  testWidgets('app lifecycle resume delegates to the session coordinator', (
    WidgetTester tester,
  ) async {
    final _ControlledSessionCoordinator coordinator =
        _ControlledSessionCoordinator();
    final AppSession session = createSession(coordinator);
    coordinator.stored.complete(
      const StoredSessionSnapshot(
        user: null,
        onboardingDone: false,
        themeMode: ThemeMode.light,
        hasCredentials: true,
      ),
    );
    final AuthCredentials credentials = AuthCredentials(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.utc(2099),
    );
    coordinator.hydrated.complete(
      ResolvedAuthenticatedSession(
        credentials: credentials,
        userJson: const <String, dynamic>{
          'nickname': 'verified learner',
          'memberPlan': 'free',
          'onboardingDone': false,
        },
      ),
    );
    for (int index = 0; index < 8; index += 1) {
      await tester.pump();
    }
    await tester.pumpWidget(
      AppSessionLifecycleObserver(
        session: session,
        child: const SizedBox.shrink(),
      ),
    );

    final dynamic observerState = tester.state(
      find.byType(AppSessionLifecycleObserver),
    );
    observerState.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();

    expect(coordinator.foregroundCalls, 1);
    coordinator.foreground.complete(credentials);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}
