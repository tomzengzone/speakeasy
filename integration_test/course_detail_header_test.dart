import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/features/content/content_catalog_page.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

void main() {
  testWidgets('course summary opens the same version detail and returns', (
    WidgetTester tester,
  ) async {
    final _CourseDetailIntegrationApi api = _CourseDetailIntegrationApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ContentCatalogPage(api: api, onReauthenticate: () async {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('theme_card:job_interview')),
    );
    await tester.pumpAndSettle();
    const ValueKey<String> selectedCourseKey = ValueKey<String>(
      'course_summary_card:11111111-1111-4111-8111-111111111111:'
      '22222222-2222-4222-8222-222222222222',
    );
    final ScrollableState listScrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('course_summary_list')),
        matching: find.byType(Scrollable),
      ),
    );
    final double initialScrollOffset = listScrollable.position.pixels;
    await tester.tap(find.byKey(selectedCourseKey));
    await tester.pumpAndSettle();

    expect(api.requestedIdentity, (
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222',
    ));
    expect(
      find.byKey(const ValueKey<String>('course_detail_header')),
      findsOneWidget,
    );
    expect(find.text('Interview Foundations'), findsOneWidget);
    expect(find.text('建立面试表达基础'), findsOneWidget);
    expect(find.text('A2'), findsOneWidget);
    expect(find.text('45 minutes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('course_detail_back')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('course_summary_list')),
      findsOneWidget,
    );
    expect(find.text('Interview Foundations'), findsOneWidget);
    expect(
      tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(const ValueKey<String>('course_summary_list')),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels,
      initialScrollOffset,
    );
    final InkWell selectedCourse = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(selectedCourseKey),
        matching: find.byKey(const ValueKey<String>('course_card')),
      ),
    );
    expect(selectedCourse.focusNode?.hasFocus, isTrue);
  });
}

class _CourseDetailIntegrationApi implements CourseCatalogApi {
  (String, String)? requestedIdentity;

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
          courseId: '11111111-1111-4111-8111-111111111111',
          courseVersionId: '22222222-2222-4222-8222-222222222222',
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
    String courseId,
    String courseVersionId,
  ) async {
    requestedIdentity = (courseId, courseVersionId);
    return const CourseDetailResponse(
      schemaVersion: 1,
      requestId: 'detail',
      course: CourseDetail(
        courseId: '11111111-1111-4111-8111-111111111111',
        courseVersionId: '22222222-2222-4222-8222-222222222222',
        titleEn: 'Interview Foundations',
        summaryZh: '建立面试表达基础',
        levelCode: LevelCode.a2,
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
