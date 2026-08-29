import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/core/bootstrap/app_root.dart';
import 'package:speakeasy/features/content/content_catalog_page.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';

void main() {
  testWidgets('renders all typed themes, exact Course order, and true empty', (
    WidgetTester tester,
  ) async {
    final _FakeCourseCatalogApi api = _FakeCourseCatalogApi();
    await tester.pumpWidget(_catalogApp(api));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('content_theme_catalog')),
      findsOneWidget,
    );
    expect(find.text('共 3 个主题'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('theme_card')), findsNWidgets(3));
    expect(
      find.byKey(const ValueKey<String>('theme_card:travel_planning')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('theme_card:job_interview')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('course_summary_list')),
      findsOneWidget,
    );
    expect(find.text('共 2 门课程'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('course_summary_card')),
      findsNWidgets(2),
    );
    expect(
      tester
          .widgetList<Text>(
            find.byKey(const ValueKey<String>('course_summary_title_en')),
          )
          .map((Text widget) => widget.data),
      <String?>['Interview Foundations', 'Confident Follow-ups'],
    );
    expect(find.text('建立面试表达基础'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('C2'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('theme_card:travel_planning')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('course_list_empty')),
      findsOneWidget,
    );
    expect(find.text('该主题暂时没有可浏览的课程'), findsOneWidget);
  });

  testWidgets('retryable refresh preserves known Course context', (
    WidgetTester tester,
  ) async {
    final _FakeCourseCatalogApi api = _FakeCourseCatalogApi();
    await tester.pumpWidget(_catalogApp(api));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('theme_card:job_interview')),
    );
    await tester.pumpAndSettle();

    api.nextCourseFailure = const ContentApiFailure(
      kind: ContentApiFailureKind.retryable,
      message: 'temporarily unavailable',
    );
    await tester.tap(find.byKey(const ValueKey<String>('course_list_refresh')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('course_list_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('course_summary_card')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey<String>('course_list_retry')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('course_list_retry')));
    await tester.pumpAndSettle();
    final Focus courseFocus = tester.widget<Focus>(
      find.byKey(const ValueKey<String>('course_list_focus')),
    );
    expect(courseFocus.focusNode?.hasFocus, isTrue);
    expect(find.text('共 2 门课程'), findsOneWidget);
  });

  testWidgets('privacy-safe 404 clears body and exposes no retry or refresh', (
    WidgetTester tester,
  ) async {
    final _FakeCourseCatalogApi api = _FakeCourseCatalogApi();
    await tester.pumpWidget(_catalogApp(api));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('theme_card:job_interview')),
    );
    await tester.pumpAndSettle();

    api.nextCourseFailure = const ContentApiFailure(
      kind: ContentApiFailureKind.notFound,
      message: 'not found',
    );
    await tester.tap(find.byKey(const ValueKey<String>('course_list_refresh')));
    await tester.pumpAndSettle();

    expect(find.text('内容暂不可用'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('course_summary_card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('course_list_retry')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('course_list_refresh')),
      findsNothing,
    );
  });

  testWidgets('401 clears learner body and invokes reauthentication', (
    WidgetTester tester,
  ) async {
    final _FakeCourseCatalogApi api = _FakeCourseCatalogApi()
      ..nextThemeFailure = const ContentApiFailure(
        kind: ContentApiFailureKind.unauthenticated,
        message: 'expired',
      );
    int reauthenticateCalls = 0;
    await tester.pumpWidget(
      _catalogApp(api, onReauthenticate: () async => reauthenticateCalls += 1),
    );
    await tester.pumpAndSettle();

    expect(find.text('登录状态已失效，请重新登录'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('content_theme_catalog')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('content_catalog_refresh')),
      findsNothing,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('content_reauthenticate')),
    );
    await tester.pump();
    expect(reauthenticateCalls, 1);
  });

  testWidgets('visible access-denied theme is explained and not opened', (
    WidgetTester tester,
  ) async {
    final _LockedCatalogApi api = _LockedCatalogApi();
    await tester.pumpWidget(_catalogApp(api));
    await tester.pumpAndSettle();

    expect(find.text('当前账号暂不可访问'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('theme_card:job_interview')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(api.courseCalls, 0);
    expect(
      find.byKey(const ValueKey<String>('content_theme_catalog')),
      findsOneWidget,
    );
  });

  testWidgets(
    'production AppRoot traverses Home, catalog, and exact Course detail',
    (WidgetTester tester) async {
      final AppSession session = (await tester.runAsync(_onboardedSession))!;
      final AudioService audioService = AudioService();
      addTearDown(session.dispose);

      await tester.pumpWidget(
        SpeakEasyAppRoot(
          session: session,
          audioService: audioService,
          courseCatalogApi: _FakeCourseCatalogApi(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      final Finder entry = find.byKey(
        const ValueKey<String>('content_asset_entry'),
      );
      expect(entry, findsOneWidget);
      await tester.tap(entry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey<String>('content_theme_catalog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('theme_card:travel_planning')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('theme_card:job_interview')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey<String>('course_summary_title_en')),
        findsNWidgets(2),
      );
      expect(find.text('A1'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'course_summary_card:11111111-1111-4111-8111-111111111111:'
            '21111111-1111-4111-8111-111111111111',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const ValueKey<String>('course_detail_header')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('course_detail_title_en')),
        findsOneWidget,
      );
      expect(find.text('45 minutes'), findsOneWidget);
    },
  );
}

Widget _catalogApp(
  CourseCatalogApi api, {
  Future<void> Function()? onReauthenticate,
}) {
  return MaterialApp(
    home: ContentCatalogPage(
      api: api,
      onReauthenticate: onReauthenticate ?? () async {},
    ),
  );
}

class _FakeCourseCatalogApi implements CourseCatalogApi {
  ContentApiFailure? nextThemeFailure;
  ContentApiFailure? nextCourseFailure;

  @override
  Future<ScenarioListResponse> listContentThemes() async {
    final ContentApiFailure? failure = nextThemeFailure;
    nextThemeFailure = null;
    if (failure != null) {
      throw failure;
    }
    return ScenarioListResponse(
      schemaVersion: 1,
      requestId: 'themes',
      scenarios: <ScenarioSummary>[
        ScenarioSummary(
          scenarioId: ScenarioId.jobInterview,
          title: '求职面试',
          summary: '准备常见面试沟通',
          levels: const <LevelCode>[LevelCode.a1, LevelCode.c2],
          status: ScenarioStatus.available,
          access: const AccessState(allowed: true),
        ),
        ScenarioSummary(
          scenarioId: ScenarioId.onboardingIntroduction,
          title: '入职介绍',
          summary: '认识新团队',
          levels: const <LevelCode>[LevelCode.a2],
          status: ScenarioStatus.available,
          access: const AccessState(allowed: true),
        ),
        ScenarioSummary(
          scenarioId: ScenarioId.parse('travel_planning'),
          title: '旅行规划',
          summary: '练习旅行安排沟通',
          levels: const <LevelCode>[LevelCode.b1],
          status: ScenarioStatus.available,
          access: const AccessState(allowed: true),
        ),
      ],
    );
  }

  @override
  Future<CourseListResponse> listScenarioCourses(ScenarioId scenarioId) async {
    final ContentApiFailure? failure = nextCourseFailure;
    nextCourseFailure = null;
    if (failure != null) {
      throw failure;
    }
    return CourseListResponse(
      schemaVersion: 1,
      requestId: 'courses',
      scenarioId: scenarioId,
      courses: scenarioId == ScenarioId.jobInterview
          ? <CourseSummary>[
              _course(
                courseId: '11111111-1111-4111-8111-111111111111',
                versionId: '21111111-1111-4111-8111-111111111111',
                title: 'Interview Foundations',
                summary: '建立面试表达基础',
                level: LevelCode.a1,
              ),
              _course(
                courseId: '12222222-2222-4222-8222-222222222222',
                versionId: '22222222-2222-4222-8222-222222222222',
                title: 'Confident Follow-ups',
                summary: '自信应对追问',
                level: LevelCode.c2,
              ),
            ]
          : const <CourseSummary>[],
    );
  }

  @override
  Future<CourseDetailResponse> getCourseVersionDetail(
    String courseId,
    String courseVersionId,
  ) async {
    if (courseId != '11111111-1111-4111-8111-111111111111' ||
        courseVersionId != '21111111-1111-4111-8111-111111111111') {
      throw const ContentApiFailure(
        kind: ContentApiFailureKind.notFound,
        message: 'not found',
        requestId: 'detail-not-found',
      );
    }
    return const CourseDetailResponse(
      schemaVersion: 1,
      requestId: 'detail',
      course: CourseDetail(
        courseId: '11111111-1111-4111-8111-111111111111',
        courseVersionId: '21111111-1111-4111-8111-111111111111',
        titleEn: 'Interview Foundations',
        summaryZh: '建立面试表达基础',
        levelCode: LevelCode.a1,
        contentBindingRef: CourseContentBindingRef(
          courseContentBindingId: '33333333-3333-4333-8333-333333333333',
          scenarioVersionId: '44444444-4444-4444-8444-444444444444',
          scenarioLevelId: '55555555-5555-4555-8555-555555555555',
        ),
        typicalDuration: TypicalDuration(value: 45, unit: 'minutes'),
      ),
    );
  }
}

class _LockedCatalogApi implements CourseCatalogApi {
  int courseCalls = 0;

  @override
  Future<ScenarioListResponse> listContentThemes() async {
    return const ScenarioListResponse(
      schemaVersion: 1,
      requestId: 'locked-theme',
      scenarios: <ScenarioSummary>[
        ScenarioSummary(
          scenarioId: ScenarioId.jobInterview,
          title: '求职面试',
          status: ScenarioStatus.available,
          access: AccessState(
            allowed: false,
            reasonCode: AccessReasonCode.entitlementRequired,
          ),
        ),
      ],
    );
  }

  @override
  Future<CourseListResponse> listScenarioCourses(ScenarioId scenarioId) async {
    courseCalls += 1;
    return CourseListResponse(
      schemaVersion: 1,
      requestId: 'must-not-be-called',
      scenarioId: scenarioId,
      courses: const <CourseSummary>[],
    );
  }

  @override
  Future<CourseDetailResponse> getCourseVersionDetail(
    String courseId,
    String courseVersionId,
  ) {
    throw UnimplementedError('Locked themes cannot open Course detail');
  }
}

CourseSummary _course({
  required String courseId,
  required String versionId,
  required String title,
  required String summary,
  required LevelCode level,
}) {
  return CourseSummary(
    courseId: courseId,
    courseVersionId: versionId,
    titleEn: title,
    summaryZh: summary,
    levelCode: level,
    contentBindingRef: const CourseContentBindingRef(
      courseContentBindingId: '33333333-3333-4333-8333-333333333333',
      scenarioVersionId: '44444444-4444-4444-8444-444444444444',
      scenarioLevelId: '55555555-5555-4555-8555-555555555555',
    ),
  );
}

class _MockSessionLifecycleCoordinator extends Mock
    implements SessionLifecycleCoordinator {}

class _MockSessionProfileCoordinator extends Mock
    implements SessionProfileCoordinator {}

class _MockSessionStatsCoordinator extends Mock
    implements SessionStatsCoordinator {}

Future<AppSession> _onboardedSession() async {
  const LoginSubmission submission = LoginSubmission(
    provider: LoginProvider.phone,
    phone: '13800138000',
    code: '123456',
  );
  final _MockSessionLifecycleCoordinator lifecycle =
      _MockSessionLifecycleCoordinator();
  final _MockSessionProfileCoordinator profile =
      _MockSessionProfileCoordinator();
  final _MockSessionStatsCoordinator stats = _MockSessionStatsCoordinator();
  when(() => lifecycle.loadStoredSession()).thenAnswer(
    (_) async => const StoredSessionSnapshot(
      user: null,
      onboardingDone: false,
      themeMode: ThemeMode.light,
    ),
  );
  when(() => lifecycle.hydrateExistingSession()).thenAnswer((_) async => null);
  when(() => lifecycle.signIn(submission)).thenAnswer(
    (_) async => const SessionSignInResult.local(
      user: AppUser(
        nickname: 'Catalog learner',
        avatarUrl: '',
        memberPlan: 'free',
      ),
    ),
  );
  when(() => profile.persistUser(any())).thenAnswer((_) async {});
  when(
    () => profile.persistOnboarding(
      user: any(named: 'user'),
      goals: any(named: 'goals'),
      level: any(named: 'level'),
      dailyMinutes: any(named: 'dailyMinutes'),
    ),
  ).thenAnswer((_) async {});
  when(
    () => profile.syncOnboardingAssessment(
      goalDirection: any(named: 'goalDirection'),
      painPoints: any(named: 'painPoints'),
      outputLevel: any(named: 'outputLevel'),
      dailyMinutes: any(named: 'dailyMinutes'),
    ),
  ).thenAnswer((_) async {});
  when(() => stats.loadCachedStats()).thenAnswer((_) async => null);

  final AppSession session = AppSession(
    sessionCoordinator: lifecycle,
    profileCoordinator: profile,
    statsCoordinator: stats,
  );
  await Future<void>.delayed(Duration.zero);
  await session.signIn(submission);
  await session.completeOnboarding(
    goals: const <String>['job_interview'],
    level: 1,
    dailyMinutes: 15,
  );
  return session;
}
