import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/features/commercial/commercial_entitlement_projection.dart';
import 'package:speakeasy/features/commercial/commercial_scenario_gate.dart';
import 'package:speakeasy/features/interview/interview_llm_scheduler.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_practice_page.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/storage_service.dart';

class _StaticSessionLifecycleCoordinator extends SessionLifecycleCoordinator {
  _StaticSessionLifecycleCoordinator(this.memberPlan)
    : super(
        authService: AuthService(
          signInWithEmail: (_) async => AppUser(
            nickname: 'Commercial tester',
            avatarUrl: '',
            memberPlan: memberPlan,
            onboardingDone: true,
          ),
        ),
        remoteApi: const _NoopSessionRemoteApi(),
        localStore: const _EmptySessionLocalStore(),
      );

  final String memberPlan;

  @override
  Future<StoredSessionSnapshot> loadStoredSession() async {
    return StoredSessionSnapshot(
      user: AppUser(
        nickname: 'Commercial tester',
        avatarUrl: '',
        memberPlan: memberPlan,
        onboardingDone: true,
      ),
      onboardingDone: true,
      themeMode: ThemeMode.light,
    );
  }

  @override
  Future<ResolvedAuthenticatedSession?> hydrateExistingSession() async => null;
}

class _NoopSessionRemoteApi implements SessionRemoteApi {
  const _NoopSessionRemoteApi();

  @override
  Future<void> clearToken() async {}

  @override
  Future<Map<String, dynamic>> getMe() async => <String, dynamic>{'code': 401};

  @override
  Future<String?> getToken() async => null;

  @override
  Future<Map<String, dynamic>> refreshToken() async => <String, dynamic>{
    'code': 401,
  };

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<Map<String, dynamic>> testPhoneLogin(String phone) async =>
      <String, dynamic>{'code': 401};
}

class _EmptySessionLocalStore implements SessionLocalStore {
  const _EmptySessionLocalStore();

  @override
  AuthSessionStorageModel? getAuthSession() => null;

  @override
  StoredUserProfileModel? getUserProfile() => null;

  @override
  UserPreferencesStorageModel getUserPreferences() {
    return const UserPreferencesStorageModel();
  }
}

class _FakeInterviewLlmScheduler extends InterviewLlmScheduler {
  @override
  Future<String?> generateOpeningQuestion({
    required InterviewPracticeSession session,
    required InterviewQuestionPlan plan,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    return null;
  }

  @override
  Future<String?> adaptNextQuestion({
    required InterviewPracticeSession session,
    required InterviewQuestionPlan plan,
    required String userText,
    required List<InterviewChatMessage> messages,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'speakeasy_commercial_scenario_gate_',
    );
    await StorageService.instance.init(hivePath: hiveDir.path);
    await StorageService.instance.remove('interview_personal_wiki_expressions');
    await StorageService.instance.remove('interview_compiled_wiki');
    await StorageService.instance.remove('interview_user_growth_wiki');
    await StorageService.instance.remove('interview_dismissed_wiki_items');
    await StorageService.instance.remove('interview_useful_wiki_items');
  });

  tearDown(() async {
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  Future<AppSession> sessionForPlan(String memberPlan) async {
    return AppSession(
      sessionCoordinator: _StaticSessionLifecycleCoordinator(memberPlan),
    );
  }

  Future<void> pumpPractice(
    WidgetTester tester, {
    required String memberPlan,
    String targetLevel = 'beginner',
    CommercialEntitlementProjection? entitlementProjection,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      MaterialApp(
        home: AudioServiceScope(
          service: AudioService(),
          child: AppSessionScope(
            session: await sessionForPlan(memberPlan),
            child: InterviewPracticePage(
              targetLevel: targetLevel,
              entitlementProjection:
                  entitlementProjection ?? _freeEntitlement(),
              llmScheduler: _FakeInterviewLlmScheduler(),
            ),
          ),
        ),
      ),
    );
    for (int i = 0; i < 60; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('点击说话').evaluate().isNotEmpty ||
          find
              .text(CommercialScenarioGate.lockedMessage)
              .evaluate()
              .isNotEmpty) {
        break;
      }
    }
  }

  Future<void> openSceneMap(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('interview_scene_map_menu_button')),
    );
    for (int i = 0; i < 12; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 320));
  }

  testWidgets('TC-COM-010 免费用户训练入口阻断 L3 高级场景', (WidgetTester tester) async {
    await pumpPractice(
      tester,
      memberPlan: 'free',
      targetLevel: CommercialScenarioGate.proTargetLevel,
    );

    expect(find.text(CommercialScenarioGate.lockedMessage), findsOneWidget);
    expect(find.text('点击说话'), findsNothing);
  });

  testWidgets('TC-COM-010 免费用户场景导航展示同一 L3 锁定状态', (WidgetTester tester) async {
    await pumpPractice(tester, memberPlan: 'free');

    expect(find.text('点击说话'), findsOneWidget);
    await openSceneMap(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('scene_map_level_dropdown')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('scene_map_level_advanced')),
      findsOneWidget,
    );
    expect(find.text(CommercialScenarioGate.lockedBadge), findsOneWidget);
    expect(
      find.textContaining('I really appreciate you making the time'),
      findsNothing,
    );
  });

  testWidgets('TC-COM-010 本地付费方案不能绕过后端权益投影', (WidgetTester tester) async {
    await pumpPractice(
      tester,
      memberPlan: 'yearly',
      targetLevel: CommercialScenarioGate.proTargetLevel,
      entitlementProjection: _freeEntitlement(),
    );

    expect(find.text(CommercialScenarioGate.lockedMessage), findsOneWidget);
    expect(find.text('点击说话'), findsNothing);
  });

  testWidgets('TC-COM-010 后端 Pro 权益可覆盖本地免费展示态', (WidgetTester tester) async {
    await pumpPractice(
      tester,
      memberPlan: 'free',
      targetLevel: CommercialScenarioGate.proTargetLevel,
      entitlementProjection: _proEntitlement(),
    );

    expect(find.text('点击说话'), findsOneWidget);
    expect(find.text(CommercialScenarioGate.lockedMessage), findsNothing);
  });

  testWidgets('TC-COM-010 Pro 用户列表、详情和训练入口一致解锁 L3', (
    WidgetTester tester,
  ) async {
    await pumpPractice(
      tester,
      memberPlan: 'yearly',
      entitlementProjection: _proEntitlement(),
    );

    await openSceneMap(tester);
    await tester.tap(
      find.byKey(const ValueKey<String>('scene_map_level_dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('scene_map_level_advanced')),
    );
    for (int i = 0; i < 30; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('interview_scene_map_page'))
          .evaluate()
          .isEmpty) {
        break;
      }
    }

    expect(find.text('点击说话'), findsOneWidget);
    await openSceneMap(tester);
    expect(find.text('英语面试 · 13 个表达'), findsOneWidget);
    expect(
      find.textContaining('I really appreciate you making the time'),
      findsWidgets,
    );
    expect(find.textContaining('Thank you for making the time.'), findsNothing);
  });
}

CommercialEntitlementProjection _freeEntitlement() {
  return CommercialEntitlementProjection.fromJson(<String, dynamic>{
    'plan': 'free',
    'status': 'active',
    'features': <String, dynamic>{'advanced_scenarios': false},
    'validUntil': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    'generatedAt': DateTime.now().toIso8601String(),
  });
}

CommercialEntitlementProjection _proEntitlement() {
  return CommercialEntitlementProjection.fromJson(<String, dynamic>{
    'plan': 'pro',
    'status': 'active',
    'features': <String, dynamic>{'advanced_scenarios': true},
    'validUntil': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
    'generatedAt': DateTime.now().toIso8601String(),
  });
}
