import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_client.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/payment_service.dart';

class _MockProfileCoordinator extends Mock
    implements SessionProfileCoordinator {}

class _MockStatsCoordinator extends Mock implements SessionStatsCoordinator {}

class _StaticSessionLifecycleCoordinator extends SessionLifecycleCoordinator {
  _StaticSessionLifecycleCoordinator({required this.user})
    : super(authService: AuthService(signInWithEmail: (_) async => user));

  final AppUser user;

  @override
  Future<StoredSessionSnapshot> loadStoredSession() async {
    return StoredSessionSnapshot(
      user: user,
      onboardingDone: user.onboardingDone,
      themeMode: ThemeMode.light,
    );
  }

  @override
  Future<ResolvedAuthenticatedSession?> hydrateExistingSession() async => null;
}

class _FakePaymentService implements PaymentService {
  const _FakePaymentService();

  @override
  Future<PaymentResult> checkSubscriptionStatus() async {
    return const PaymentResult(success: false, status: PaymentStatus.inactive);
  }

  @override
  Future<PaymentResult> purchasePlan(String planId) async {
    return PaymentResult(
      success: false,
      status: PaymentStatus.error,
      planId: planId,
    );
  }

  @override
  Future<PaymentResult> restorePurchases() async {
    return const PaymentResult(success: false, status: PaymentStatus.inactive);
  }
}

void main() {
  const String initialAvatar = 'assets/images/avatars/default_avatar_1.png';
  const String updatedAvatar = 'assets/images/avatars/default_avatar_3.png';
  const AppUser storedUser = AppUser(
    nickname: 'Old Name',
    avatarUrl: initialAvatar,
    memberPlan: 'free',
    onboardingDone: true,
  );

  late _MockProfileCoordinator profileCoordinator;
  late _MockStatsCoordinator statsCoordinator;

  setUpAll(() {
    registerFallbackValue(storedUser);
    registerFallbackValue(const LearningStatsModel());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    profileCoordinator = _MockProfileCoordinator();
    statsCoordinator = _MockStatsCoordinator();
    when(() => profileCoordinator.persistUser(any())).thenAnswer((_) async {});
    when(
      () => profileCoordinator.syncUserPatch(any()),
    ).thenAnswer((_) async => null);
    when(
      () => statsCoordinator.loadCachedStats(),
    ).thenAnswer((_) async => null);
    when(
      () => statsCoordinator.refreshStats(
        currentStats: any(named: 'currentStats'),
      ),
    ).thenAnswer((_) async => const LearningStatsModel());
  });

  AppSession createSession({AppUser user = storedUser}) {
    return AppSession(
      paymentService: const _FakePaymentService(),
      entitlementClient: CommercialEntitlementClient(
        refreshTransport: () async => <String, dynamic>{
          'plan': 'free',
          'status': 'inactive',
          'features': <String, dynamic>{},
        },
      ),
      sessionCoordinator: _StaticSessionLifecycleCoordinator(user: user),
      profileCoordinator: profileCoordinator,
      statsCoordinator: statsCoordinator,
    );
  }

  test(
    'updateProfile syncs display_name and avatar_ref through profile patch',
    () async {
      final AppSession session = createSession();

      await pumpEventQueue(times: 8);

      await session.updateProfile(
        nickname: '  New Name  ',
        avatarUrl: updatedAvatar,
      );

      await untilCalled(() => profileCoordinator.syncUserPatch(any()));
      final List<Object?> captured = verify(
        () => profileCoordinator.syncUserPatch(captureAny()),
      ).captured;
      expect(captured, isNotEmpty);
      expect(captured.last, <String, dynamic>{
        'display_name': 'New Name',
        'avatar_ref': updatedAvatar,
      });
      expect(session.nickname, 'New Name');
      expect(session.avatarUrl, updatedAvatar);
    },
  );

  test('updateAvatar delegates to the profile patch avatar_ref sync', () async {
    final AppSession session = createSession();

    await pumpEventQueue(times: 8);

    // ignore: deprecated_member_use_from_same_package
    await session.updateAvatar(updatedAvatar);

    await untilCalled(() => profileCoordinator.syncUserPatch(any()));
    final List<Object?> captured = verify(
      () => profileCoordinator.syncUserPatch(captureAny()),
    ).captured;
    expect(captured, isNotEmpty);
    expect(captured.last, <String, dynamic>{
      'display_name': 'Old Name',
      'avatar_ref': updatedAvatar,
    });
    expect(session.nickname, 'Old Name');
    expect(session.avatarUrl, updatedAvatar);
  });

  test('updateProfile normalizes unsupported legacy avatar refs', () async {
    const AppUser legacyUser = AppUser(
      nickname: 'Legacy Name',
      avatarUrl: 'https://example.com/avatar.png',
      memberPlan: 'free',
      onboardingDone: true,
    );
    final AppSession session = createSession(user: legacyUser);

    await pumpEventQueue(times: 8);

    expect(session.avatarUrl, defaultAvatarUrls.first);

    await session.updateProfile(
      nickname: 'Legacy Name',
      avatarUrl: legacyUser.avatarUrl,
    );

    await untilCalled(() => profileCoordinator.syncUserPatch(any()));
    final List<Object?> captured = verify(
      () => profileCoordinator.syncUserPatch(captureAny()),
    ).captured;
    expect(captured, isNotEmpty);
    expect(captured.last, <String, dynamic>{
      'display_name': 'Legacy Name',
      'avatar_ref': defaultAvatarUrls.first,
    });
    expect(session.avatarUrl, defaultAvatarUrls.first);
  });
}
