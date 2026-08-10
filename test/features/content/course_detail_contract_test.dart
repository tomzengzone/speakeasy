import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/features/content/content_catalog_page.dart';
import 'package:speakeasy/features/content/course_detail_page.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

void main() {
  testWidgets('opens and renders the exact CourseVersion without background', (
    WidgetTester tester,
  ) async {
    final _FakeCourseDetailApi api = _FakeCourseDetailApi();
    final List<CourseDetailObservation> observations =
        <CourseDetailObservation>[];
    await tester.pumpWidget(_catalogApp(api, observer: observations.add));

    await _openCourseDetail(tester);

    expect(api.detailRequests, <(String, String)>[(courseId, courseVersionId)]);
    expect(
      find.byKey(const ValueKey<String>('course_detail_header')),
      findsOneWidget,
    );
    expect(find.text('Interview Foundations'), findsOneWidget);
    expect(find.text('建立面试表达基础'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('45 minutes'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey<String>('course_detail_background_placeholder'),
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);
    expect(observations, hasLength(1));
    expect(observations.single.featureArea, 'course_detail');
    expect(observations.single.resultClass, 'success');
    expect(observations.single.requestId, 'detail');
    expect(observations.single.refHash, hasLength(8));
    expect(observations.single.refHash, isNot(contains(courseId)));
    expect(observations.single.validationResult, 'exact_identity');

    await tester.tap(find.byKey(const ValueKey<String>('course_detail_back')));
    await tester.pumpAndSettle();
    final InkWell selectedCourse = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(
          ValueKey<String>('course_summary_card:$courseId:$courseVersionId'),
        ),
        matching: find.byKey(const ValueKey<String>('course_card')),
      ),
    );
    expect(selectedCourse.focusNode?.hasFocus, isTrue);
  });

  testWidgets('retryable refresh preserves the exact known detail', (
    WidgetTester tester,
  ) async {
    final _FakeCourseDetailApi api = _FakeCourseDetailApi();
    await tester.pumpWidget(_catalogApp(api));
    await _openCourseDetail(tester);

    api.nextDetailFailure = const ContentApiFailure(
      kind: ContentApiFailureKind.retryable,
      message: 'temporarily unavailable',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('course_detail_refresh')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Interview Foundations'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('course_detail_error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('course_detail_retry')),
      findsOneWidget,
    );

    api.nextDetailFailure = const ContentApiFailure(
      kind: ContentApiFailureKind.retryable,
      message: 'still unavailable',
      requestId: 'retry-failed',
    );
    await tester.tap(find.byKey(const ValueKey<String>('course_detail_retry')));
    await tester.pumpAndSettle();

    final Focus errorFocus = tester.widget<Focus>(
      find.byKey(const ValueKey<String>('course_detail_error_focus')),
    );
    expect(errorFocus.focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(const ValueKey<String>('course_detail_error')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey<String>('course_detail_retry')));
    await tester.pumpAndSettle();

    final Focus headerFocus = tester.widget<Focus>(
      find.byKey(const ValueKey<String>('course_detail_header_focus')),
    );
    expect(headerFocus.focusNode?.hasFocus, isTrue);
    expect(
      find.byKey(const ValueKey<String>('course_detail_error')),
      findsNothing,
    );
  });

  testWidgets('privacy-safe 404 clears detail and exposes only return', (
    WidgetTester tester,
  ) async {
    final _FakeCourseDetailApi api = _FakeCourseDetailApi();
    final List<CourseDetailObservation> observations =
        <CourseDetailObservation>[];
    await tester.pumpWidget(_catalogApp(api, observer: observations.add));

    await _openCourseDetail(tester);
    expect(find.text('Interview Foundations'), findsOneWidget);

    api.nextDetailFailure = const ContentApiFailure(
      kind: ContentApiFailureKind.notFound,
      message: 'hidden or stale',
      requestId: 'detail-404',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('course_detail_refresh')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('course_detail_unavailable')),
      findsOneWidget,
    );
    expect(find.text('内容暂不可用'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('course_detail_retry')),
      findsNothing,
    );
    expect(find.text('Interview Foundations'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('course_detail_back')),
      findsOneWidget,
    );
    expect(observations.last.resultClass, 'not_found');
    expect(observations.last.requestId, 'detail-404');
    expect(observations.last.validationResult, 'not_evaluated');
  });

  testWidgets('401 clears detail and invokes reauthentication', (
    WidgetTester tester,
  ) async {
    final _FakeCourseDetailApi api = _FakeCourseDetailApi();
    int reauthenticateCalls = 0;
    await tester.pumpWidget(
      _catalogApp(api, onReauthenticate: () async => reauthenticateCalls += 1),
    );

    await _openCourseDetail(tester);
    expect(find.text('Interview Foundations'), findsOneWidget);

    api.nextDetailFailure = const ContentApiFailure(
      kind: ContentApiFailureKind.unauthenticated,
      message: 'expired',
      requestId: 'detail-401',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('course_detail_refresh')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('course_detail_unauthenticated')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('content_reauthenticate')),
    );
    await tester.pump();
    expect(reauthenticateCalls, 1);
  });

  testWidgets(
    'mismatched response identity never substitutes another version',
    (WidgetTester tester) async {
      final _FakeCourseDetailApi api = _FakeCourseDetailApi()
        ..detailResponse = _detailResponse(
          versionId: '99999999-9999-4999-8999-999999999999',
        );
      final List<CourseDetailObservation> observations =
          <CourseDetailObservation>[];
      await tester.pumpWidget(_catalogApp(api, observer: observations.add));

      await _openCourseDetail(tester);

      expect(
        find.byKey(const ValueKey<String>('course_detail_error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('course_detail_header')),
        findsNothing,
      );
      expect(observations.single.resultClass, 'invalid_response');
      expect(observations.single.requestId, 'detail');
      expect(observations.single.refHash, hasLength(8));
      expect(observations.single.validationResult, 'identity_mismatch');
    },
  );

  final List<({String field, CourseDetailResponse response})> mismatchCases =
      <({String field, CourseDetailResponse response})>[
        (
          field: 'course identity',
          response: _detailResponse(
            responseCourseId: 'dddddddd-dddd-4ddd-8ddd-dddddddddddd',
          ),
        ),
        (field: 'title', response: _detailResponse(title: 'Wrong title')),
        (field: 'summary', response: _detailResponse(summary: '错误摘要')),
        (field: 'CEFR', response: _detailResponse(level: LevelCode.c1)),
        (
          field: 'content binding',
          response: _detailResponse(
            bindingId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
          ),
        ),
        (
          field: 'scenario version binding',
          response: _detailResponse(
            scenarioVersionId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
          ),
        ),
        (
          field: 'scenario level binding',
          response: _detailResponse(
            scenarioLevelId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
          ),
        ),
      ];
  for (final mismatchCase in mismatchCases) {
    testWidgets('rejects a mismatched ${mismatchCase.field}', (
      WidgetTester tester,
    ) async {
      final _FakeCourseDetailApi api = _FakeCourseDetailApi()
        ..detailResponse = mismatchCase.response;
      await tester.pumpWidget(_catalogApp(api));

      await _openCourseDetail(tester);

      expect(
        find.byKey(const ValueKey<String>('course_detail_error')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('course_detail_header')),
        findsNothing,
      );
    });
  }

  testWidgets('rollback switch disables detail entry and detail request', (
    WidgetTester tester,
  ) async {
    final _FakeCourseDetailApi api = _FakeCourseDetailApi();
    await tester.pumpWidget(_catalogApp(api, enableCourseDetail: false));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('theme_card:job_interview')),
    );
    await tester.pumpAndSettle();

    final InkWell courseCard = tester.widget<InkWell>(
      find.byKey(const ValueKey<String>('course_card')),
    );
    expect(courseCard.onTap, isNull);
    await tester.tap(
      find.byKey(
        ValueKey<String>('course_summary_card:$courseId:$courseVersionId'),
      ),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(api.detailRequests, isEmpty);
    expect(
      find.byKey(const ValueKey<String>('course_detail_header')),
      findsNothing,
    );
  });

  testWidgets('telemetry failure never blocks exact detail rendering', (
    WidgetTester tester,
  ) async {
    final _FakeCourseDetailApi api = _FakeCourseDetailApi();
    await tester.pumpWidget(
      _catalogApp(
        api,
        observer: (_) => throw StateError('telemetry unavailable'),
      ),
    );

    await _openCourseDetail(tester);

    expect(
      find.byKey(const ValueKey<String>('course_detail_header')),
      findsOneWidget,
    );
    expect(find.text('45 minutes'), findsOneWidget);
  });
}

const String courseId = '11111111-1111-4111-8111-111111111111';
const String courseVersionId = '22222222-2222-4222-8222-222222222222';

Future<void> _openCourseDetail(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey<String>('theme_card:job_interview')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(
      ValueKey<String>('course_summary_card:$courseId:$courseVersionId'),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _catalogApp(
  CourseCatalogApi api, {
  Future<void> Function()? onReauthenticate,
  bool? enableCourseDetail,
  CourseDetailObserver? observer,
}) {
  return MaterialApp(
    home: ContentCatalogPage(
      api: api,
      onReauthenticate: onReauthenticate ?? () async {},
      enableCourseDetail: enableCourseDetail,
      detailObserver: observer ?? logCourseDetailObservation,
    ),
  );
}

class _FakeCourseDetailApi implements CourseCatalogApi {
  ContentApiFailure? nextDetailFailure;
  CourseDetailResponse detailResponse = _detailResponse();
  final List<(String, String)> detailRequests = <(String, String)>[];

  @override
  Future<ScenarioListResponse> listContentThemes() async {
    return const ScenarioListResponse(
      schemaVersion: 1,
      requestId: 'themes',
      scenarios: <ScenarioSummary>[
        ScenarioSummary(
          scenarioId: ScenarioId.jobInterview,
          title: '求职面试',
          status: ScenarioStatus.available,
          access: AccessState(allowed: true),
        ),
      ],
    );
  }

  @override
  Future<CourseListResponse> listScenarioCourses(ScenarioId scenarioId) async {
    return const CourseListResponse(
      schemaVersion: 1,
      requestId: 'courses',
      scenarioId: ScenarioId.jobInterview,
      courses: <CourseSummary>[
        CourseSummary(
          courseId: courseId,
          courseVersionId: courseVersionId,
          titleEn: 'Interview Foundations',
          summaryZh: '建立面试表达基础',
          levelCode: LevelCode.a2,
          contentBindingRef: CourseContentBindingRef(
            courseContentBindingId: '33333333-3333-4333-8333-333333333333',
            scenarioVersionId: '44444444-4444-4444-8444-444444444444',
            scenarioLevelId: '55555555-5555-4555-8555-555555555555',
          ),
        ),
      ],
    );
  }

  @override
  Future<CourseDetailResponse> getCourseVersionDetail(
    String requestedCourseId,
    String requestedCourseVersionId,
  ) async {
    detailRequests.add((requestedCourseId, requestedCourseVersionId));
    final ContentApiFailure? failure = nextDetailFailure;
    nextDetailFailure = null;
    if (failure != null) {
      throw failure;
    }
    return detailResponse;
  }
}

CourseDetailResponse _detailResponse({
  String responseCourseId = courseId,
  String versionId = courseVersionId,
  String title = 'Interview Foundations',
  String summary = '建立面试表达基础',
  LevelCode level = LevelCode.a2,
  String bindingId = '33333333-3333-4333-8333-333333333333',
  String scenarioVersionId = '44444444-4444-4444-8444-444444444444',
  String scenarioLevelId = '55555555-5555-4555-8555-555555555555',
}) {
  return CourseDetailResponse(
    schemaVersion: 1,
    requestId: 'detail',
    course: CourseDetail(
      courseId: responseCourseId,
      courseVersionId: versionId,
      titleEn: title,
      summaryZh: summary,
      levelCode: level,
      contentBindingRef: CourseContentBindingRef(
        courseContentBindingId: bindingId,
        scenarioVersionId: scenarioVersionId,
        scenarioLevelId: scenarioLevelId,
      ),
      typicalDuration: const TypicalDuration(value: 45, unit: 'minutes'),
    ),
  );
}
