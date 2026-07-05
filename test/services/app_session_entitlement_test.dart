import 'dart:async';

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
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/payment_service.dart';

class _MockAppRepository extends Mock implements AppRepository {}

class _MockProfileCoordinator extends Mock
    implements SessionProfileCoordinator {}

class _MockStatsCoordinator extends Mock implements SessionStatsCoordinator {}

class _StaticSessionLifecycleCoordinator extends SessionLifecycleCoordinator {
  _StaticSessionLifecycleCoordinator({required this.user})
    : super(
        authService: AuthService(
          signInWithEmail: (_) async =>
              user ??
              const AppUser(
                nickname: 'tester',
                avatarUrl: '',
                memberPlan: 'free',
              ),
        ),
      );

  final AppUser? user;

  @override
  Future<StoredSessionSnapshot> loadStoredSession() async {
    return StoredSessionSnapshot(
      user: user,
      onboardingDone: user?.onboardingDone ?? false,
      themeMode: ThemeMode.light,
    );
  }

  @override
  Future<ResolvedAuthenticatedSession?> hydrateExistingSession() async => null;
}

class _FakePaymentService implements PaymentService {
  const _FakePaymentService({
    this.purchaseResult,
    this.purchaseHandler,
    this.statusHandler,
    this.restoreHandler,
  });

  final PaymentResult? purchaseResult;
  final Future<PaymentResult> Function(String planId)? purchaseHandler;
  final Future<PaymentResult> Function()? statusHandler;
  final Future<PaymentResult> Function()? restoreHandler;

  @override
  Future<PaymentResult> purchasePlan(String planId) async {
    final Future<PaymentResult> Function(String planId)? handler =
        purchaseHandler;
    if (handler != null) {
      return handler(planId);
    }
    return purchaseResult ??
        PaymentResult(
          success: false,
          status: PaymentStatus.error,
          planId: planId,
          errorMessage: 'not configured',
        );
  }

  @override
  Future<PaymentResult> restorePurchases() async {
    final Future<PaymentResult> Function()? handler = restoreHandler;
    if (handler != null) {
      return handler();
    }
    return const PaymentResult(
      success: false,
      status: PaymentStatus.inactive,
      message: 'not configured',
    );
  }

  @override
  Future<PaymentResult> checkSubscriptionStatus() async {
    final Future<PaymentResult> Function()? handler = statusHandler;
    if (handler != null) {
      return handler();
    }
    return const PaymentResult(
      success: false,
      status: PaymentStatus.inactive,
      message: 'not configured',
    );
  }
}

void main() {
  const AppUser freeUser = AppUser(
    nickname: 'tester',
    avatarUrl: '',
    memberPlan: 'free',
    onboardingDone: true,
  );

  setUpAll(() {
    registerFallbackValue(freeUser);
    registerFallbackValue(const LearningStatsModel());
  });

  late _MockAppRepository repository;
  late _MockProfileCoordinator profileCoordinator;
  late _MockStatsCoordinator statsCoordinator;

  setUp(() {
    repository = _MockAppRepository();
    profileCoordinator = _MockProfileCoordinator();
    statsCoordinator = _MockStatsCoordinator();

    when(() => profileCoordinator.persistUser(any())).thenAnswer((_) async {});
    when(() => profileCoordinator.clearSessionData()).thenAnswer((_) async {});
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

  test('loads backend entitlement projection after stored session', () async {
    final AppSession session = AppSession(
      repository: repository,
      paymentService: const _FakePaymentService(),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => _proEntitlementJson(),
      ),
      sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
    );

    await pumpEventQueue(times: 8);

    expect(session.displayMemberPlan, 'free');
    expect(session.entitlementProjection.plan, 'pro');
    expect(
      session.entitlementProjection
          .requireFeature('advanced_scenarios')
          .allowed,
      isTrue,
    );
  });

  test(
    'old entitlement refresh cannot overwrite purchase entitlement',
    () async {
      final Completer<Map<String, dynamic>> refreshCompleter =
          Completer<Map<String, dynamic>>();
      final CommercialEntitlementProjection proProjection =
          CommercialEntitlementProjection.fromJson(_proEntitlementJson());
      final AppSession session = AppSession(
        repository: repository,
        paymentService: _FakePaymentService(
          purchaseResult: PaymentResult(
            success: true,
            status: PaymentStatus.success,
            planId: 'yearly',
            entitlement: proProjection,
          ),
        ),
        entitlementClient: CommercialEntitlementClient(
          refreshTransport: () => refreshCompleter.future,
        ),
        sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
        profileCoordinator: profileCoordinator,
        statsCoordinator: statsCoordinator,
      );

      await pumpEventQueue(times: 4);
      await session.changeMembership('yearly');
      expect(session.entitlementProjection.plan, 'pro');

      refreshCompleter.complete(_freeEntitlementJson());
      await pumpEventQueue(times: 4);

      expect(session.entitlementProjection.plan, 'pro');
    },
  );

  test('payment result after logout is ignored', () async {
    final Completer<PaymentResult> purchaseCompleter =
        Completer<PaymentResult>();
    final AppSession session = AppSession(
      repository: repository,
      paymentService: _FakePaymentService(
        purchaseHandler: (_) => purchaseCompleter.future,
      ),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => _freeEntitlementJson(),
      ),
      sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
    );

    await pumpEventQueue(times: 8);
    final Future<void> purchase = session.changeMembership('yearly');
    await pumpEventQueue(times: 2);
    await session.logout();

    purchaseCompleter.complete(
      PaymentResult(
        success: true,
        status: PaymentStatus.success,
        planId: 'yearly',
        entitlement: CommercialEntitlementProjection.fromJson(
          _proEntitlementJson(),
        ),
      ),
    );
    await purchase;

    expect(session.isLoggedIn, isFalse);
    expect(session.isUpdatingMembership, isFalse);
    expect(
      session.entitlementProjection.refreshState,
      CommercialEntitlementRefreshState.unknown,
    );
    expect(session.membershipErrorMessage, isNull);
  });

  test(
    'older subscription status refresh cannot beat purchase result',
    () async {
      final Completer<PaymentResult> statusCompleter =
          Completer<PaymentResult>();
      final Completer<PaymentResult> purchaseCompleter =
          Completer<PaymentResult>();
      final AppSession session = AppSession(
        repository: repository,
        paymentService: _FakePaymentService(
          statusHandler: () => statusCompleter.future,
          purchaseHandler: (_) => purchaseCompleter.future,
        ),
        entitlementClient: CommercialEntitlementClient(
          refreshTransport: () async => _freeEntitlementJson(),
        ),
        sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
        profileCoordinator: profileCoordinator,
        statsCoordinator: statsCoordinator,
      );

      await pumpEventQueue(times: 8);
      final Future<void> statusRefresh = session.refreshMembershipStatus();
      await pumpEventQueue(times: 2);
      final Future<void> purchase = session.changeMembership('yearly');
      await pumpEventQueue(times: 2);

      statusCompleter.complete(
        PaymentResult(
          success: false,
          status: PaymentStatus.inactive,
          entitlement: CommercialEntitlementProjection.fromJson(
            _freeEntitlementJson(),
          ),
        ),
      );
      await statusRefresh;
      expect(session.entitlementProjection.plan, 'free');

      purchaseCompleter.complete(
        PaymentResult(
          success: true,
          status: PaymentStatus.success,
          planId: 'yearly',
          entitlement: CommercialEntitlementProjection.fromJson(
            _proEntitlementJson(),
          ),
        ),
      );
      await purchase;

      expect(session.entitlementProjection.plan, 'pro');
      expect(session.isUpdatingMembership, isFalse);
    },
  );

  test(
    'entitlement refresh during pending purchase does not keep loading',
    () async {
      final Completer<PaymentResult> purchaseCompleter =
          Completer<PaymentResult>();
      int refreshCount = 0;
      final AppSession session = AppSession(
        repository: repository,
        paymentService: _FakePaymentService(
          purchaseHandler: (_) => purchaseCompleter.future,
        ),
        entitlementClient: CommercialEntitlementClient(
          refreshTransport: () async {
            refreshCount += 1;
            return _freeEntitlementJson();
          },
        ),
        sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
        profileCoordinator: profileCoordinator,
        statsCoordinator: statsCoordinator,
      );

      await pumpEventQueue(times: 8);
      final Future<void> purchase = session.changeMembership('yearly');
      await pumpEventQueue(times: 2);
      expect(session.isUpdatingMembership, isTrue);

      await session.refreshEntitlementProjection();
      expect(refreshCount, 1);
      expect(session.isUpdatingMembership, isTrue);

      purchaseCompleter.complete(
        PaymentResult(
          success: true,
          status: PaymentStatus.success,
          planId: 'yearly',
          entitlement: CommercialEntitlementProjection.fromJson(
            _proEntitlementJson(),
          ),
        ),
      );
      await purchase;

      expect(session.isUpdatingMembership, isFalse);
      expect(session.entitlementProjection.plan, 'pro');
    },
  );

  test(
    'restore applies entitlement without changing local memberPlan',
    () async {
      final AppSession session = AppSession(
        repository: repository,
        paymentService: _FakePaymentService(
          restoreHandler: () async => PaymentResult(
            success: true,
            status: PaymentStatus.restored,
            planId: 'yearly',
            entitlement: CommercialEntitlementProjection.fromJson(
              _proEntitlementJson(),
            ),
          ),
        ),
        entitlementClient: CommercialEntitlementClient(
          refreshTransport: () async => _freeEntitlementJson(),
        ),
        sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
        profileCoordinator: profileCoordinator,
        statsCoordinator: statsCoordinator,
      );

      await pumpEventQueue(times: 8);
      await session.restoreMembershipPurchases();

      expect(session.displayMemberPlan, 'yearly');
      expect(session.isUpdatingMembership, isFalse);
      expect(session.entitlementProjection.plan, 'pro');
      verifyNever(
        () => repository.changeMembership(
          user: any(named: 'user'),
          planId: any(named: 'planId'),
        ),
      );
    },
  );

  test(
    'restore without product plan keeps entitlement and avoids guessing plan',
    () async {
      final AppSession session = AppSession(
        repository: repository,
        paymentService: _FakePaymentService(
          restoreHandler: () async => PaymentResult(
            success: true,
            status: PaymentStatus.restored,
            entitlement: CommercialEntitlementProjection.fromJson(
              _proEntitlementJson(),
            ),
          ),
        ),
        entitlementClient: CommercialEntitlementClient(
          refreshTransport: () async => _freeEntitlementJson(),
        ),
        sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
        profileCoordinator: profileCoordinator,
        statsCoordinator: statsCoordinator,
      );

      await pumpEventQueue(times: 8);
      await session.restoreMembershipPurchases();

      expect(session.displayMemberPlan, 'free');
      expect(session.entitlementProjection.plan, 'pro');
      expect(session.entitlementProjection.isFreshActivePaid(), isTrue);
    },
  );

  test(
    'cancelled purchase does not poison existing entitlement projection',
    () async {
      final AppSession session = AppSession(
        repository: repository,
        paymentService: _FakePaymentService(
          purchaseResult: const PaymentResult(
            success: false,
            status: PaymentStatus.cancelled,
            message: 'cancelled',
          ),
        ),
        entitlementClient: CommercialEntitlementClient(
          refreshTransport: () async => _proEntitlementJson(),
        ),
        sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
        profileCoordinator: profileCoordinator,
        statsCoordinator: statsCoordinator,
      );

      await pumpEventQueue(times: 8);
      expect(session.entitlementProjection.plan, 'pro');

      await session.changeMembership('yearly');

      expect(session.membershipErrorMessage, 'cancelled');
      expect(session.entitlementProjection.plan, 'pro');
      expect(session.entitlementProjection.isFreshActivePaid(), isTrue);
    },
  );

  test('subscription status exception fails closed', () async {
    final AppSession session = AppSession(
      repository: repository,
      paymentService: _FakePaymentService(
        statusHandler: () async => throw Exception('status unavailable'),
      ),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => _proEntitlementJson(),
      ),
      sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
    );

    await pumpEventQueue(times: 8);
    expect(session.entitlementProjection.plan, 'pro');

    await session.refreshMembershipStatus(silent: false);

    expect(session.isUpdatingMembership, isFalse);
    expect(
      session.entitlementProjection.refreshState,
      CommercialEntitlementRefreshState.failed,
    );
    expect(
      session.entitlementProjection.requireFeature('advanced_scenarios').code,
      CommercialEntitlementDecisionCode.refreshFailed,
    );
  });

  test('subscription status without entitlement fails closed', () async {
    final AppSession session = AppSession(
      repository: repository,
      paymentService: _FakePaymentService(
        statusHandler: () async => const PaymentResult(
          success: false,
          status: PaymentStatus.inactive,
          message: 'missing entitlement',
        ),
      ),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => _proEntitlementJson(),
      ),
      sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
    );

    await pumpEventQueue(times: 8);
    await session.refreshMembershipStatus(silent: false);

    expect(session.isUpdatingMembership, isFalse);
    expect(
      session.entitlementProjection.refreshState,
      CommercialEntitlementRefreshState.failed,
    );
    expect(session.membershipErrorMessage, 'missing entitlement');
  });

  test(
    'purchase applies payment entitlement without changing local memberPlan',
    () async {
      final CommercialEntitlementProjection proProjection =
          CommercialEntitlementProjection.fromJson(_proEntitlementJson());
      final AppSession session = AppSession(
        repository: repository,
        paymentService: _FakePaymentService(
          purchaseResult: PaymentResult(
            success: true,
            status: PaymentStatus.success,
            planId: 'yearly',
            entitlement: proProjection,
          ),
        ),
        entitlementClient: CommercialEntitlementClient(
          refreshTransport: () async => _freeEntitlementJson(),
        ),
        sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
        profileCoordinator: profileCoordinator,
        statsCoordinator: statsCoordinator,
      );

      await pumpEventQueue(times: 8);
      await session.changeMembership('yearly');

      expect(session.displayMemberPlan, 'yearly');
      expect(session.isUpdatingMembership, isFalse);
      expect(session.entitlementProjection.plan, 'pro');
      expect(session.entitlementProjection.isFreshActivePaid(), isTrue);
      verifyNever(
        () => repository.changeMembership(
          user: any(named: 'user'),
          planId: any(named: 'planId'),
        ),
      );
    },
  );

  test('refresh failure fails closed and keeps typed error state', () async {
    final AppSession session = AppSession(
      repository: repository,
      paymentService: const _FakePaymentService(),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => throw Exception('network down'),
      ),
      sessionCoordinator: _StaticSessionLifecycleCoordinator(user: freeUser),
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
    );

    await pumpEventQueue(times: 8);

    expect(
      session.entitlementProjection.refreshState,
      CommercialEntitlementRefreshState.failed,
    );
    expect(
      session.entitlementProjection.requireFeature('advanced_scenarios').code,
      CommercialEntitlementDecisionCode.refreshFailed,
    );
  });
}

Map<String, dynamic> _proEntitlementJson() {
  return <String, dynamic>{
    'plan': 'pro',
    'status': 'active',
    'features': <String, dynamic>{'advanced_scenarios': true},
    'validUntil': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    'generatedAt': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic> _freeEntitlementJson() {
  return <String, dynamic>{
    'plan': 'free',
    'status': 'active',
    'features': <String, dynamic>{},
    'validUntil': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    'generatedAt': DateTime.now().toIso8601String(),
  };
}
