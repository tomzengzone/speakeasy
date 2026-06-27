import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_client.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/payment_service.dart';

class MockSessionLifecycleCoordinator extends Mock
    implements SessionLifecycleCoordinator {}

class MockSessionProfileCoordinator extends Mock
    implements SessionProfileCoordinator {}

class MockSessionStatsCoordinator extends Mock
    implements SessionStatsCoordinator {}

void main() {
  late MockSessionLifecycleCoordinator sessionCoordinator;
  late MockSessionProfileCoordinator profileCoordinator;
  late MockSessionStatsCoordinator statsCoordinator;

  setUpAll(() {
    registerFallbackValue(
      const AppUser(nickname: 'fallback', avatarUrl: '', memberPlan: 'free'),
    );
    registerFallbackValue(const LearningStatsModel());
  });

  setUp(() {
    sessionCoordinator = MockSessionLifecycleCoordinator();
    profileCoordinator = MockSessionProfileCoordinator();
    statsCoordinator = MockSessionStatsCoordinator();

    when(() => sessionCoordinator.loadStoredSession()).thenAnswer(
      (_) async => const StoredSessionSnapshot(
        user: null,
        onboardingDone: false,
        themeMode: ThemeMode.light,
      ),
    );
    when(() => sessionCoordinator.hydrateExistingSession()).thenAnswer(
      (_) async => const ResolvedAuthenticatedSession(
        token: 'jwt-token',
        userJson: <String, dynamic>{
          'nickname': '付费用户',
          'avatarUrl': '',
          'memberPlan': 'yearly',
        },
      ),
    );
    when(() => profileCoordinator.persistUser(any())).thenAnswer((_) async {});
    when(() => profileCoordinator.deleteAccount()).thenAnswer((_) async {});
    when(
      () => statsCoordinator.loadCachedStats(),
    ).thenAnswer((_) async => null);
    when(() => statsCoordinator.clearCache()).thenAnswer((_) async {});
    when(
      () => statsCoordinator.refreshStats(
        currentStats: any(named: 'currentStats'),
      ),
    ).thenAnswer((_) async => const LearningStatsModel());
  });

  test('TC-COM-014 账号删除后清理本地会员态与缓存', () async {
    final AppSession session = AppSession(
      paymentService: const UnsupportedPaymentService(),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => <String, dynamic>{
          'plan': 'pro',
          'status': 'active',
          'features': <String, dynamic>{'advanced_scenarios': true},
        },
      ),
      sessionCoordinator: sessionCoordinator,
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
    );

    await pumpEventQueue(times: 8);
    expect(session.isLoggedIn, isTrue);
    expect(session.memberPlan, 'yearly');
    expect(session.entitlementProjection.plan, 'pro');

    await session.deleteAccount();

    expect(session.isLoggedIn, isFalse);
    expect(session.memberPlan, 'free');
    expect(
      session.entitlementProjection.refreshState,
      CommercialEntitlementRefreshState.unknown,
    );
    expect(session.membershipErrorMessage, isNull);
    verify(() => profileCoordinator.deleteAccount()).called(1);
    verify(() => statsCoordinator.clearCache()).called(1);
  });
}
