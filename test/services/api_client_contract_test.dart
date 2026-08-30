import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

void main() {
  test('generated OpenAPI Dart boundary pins the canonical hash', () {
    final Map<String, dynamic> manifest =
        jsonDecode(
              File(
                'docs/architecture/openapi/dart-client-drift-manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final String marker = File(
      'lib/generated/api/.openapi-sha256',
    ).readAsStringSync().trim();

    expect(manifest['mode'], 'generated_client_drift');
    expect(
      manifest['generator'],
      'python scripts/check_openapi_dart_drift.py --write',
    );
    expect(manifest['generated_files'], <String>[
      'lib/generated/api/speakeasy_api.dart',
      'lib/generated/api/.openapi-sha256',
    ]);
    expect(SpeakeasyApiContract.openApiSha256, marker);
    expect(manifest['openapi_sha256'], marker);
  });

  test('generated path registry covers MVP backend active endpoints', () {
    expect(
      SpeakeasyApiContract.pathTemplates,
      containsAll(<String>[
        '/auth/login/phone',
        '/auth/login/apple',
        '/auth/login/wechat',
        '/auth/refresh',
        '/auth/logout',
        '/auth/logout-others',
        '/auth/logout-all',
        '/auth/sessions',
        '/auth/sessions/{auth_session_id}',
        '/user/me',
        '/user/deletion-status',
        '/onboarding/assessment',
        '/scenarios',
        '/scenarios/{scenario_id}/courses',
        '/courses/{course_id}/versions/{course_version_id}',
        '/practice/sessions',
        '/expressions/queue',
        '/learning/evidence',
        '/learning/report/summary',
        '/membership/boundary',
        '/membership/android/purchase',
        '/membership/android/restore',
        '/entitlements',
        '/entitlements/refresh',
        '/subscription/plans',
        '/subscriptions/apple/verify',
        '/subscriptions/google/verify',
        '/subscriptions/restore',
        '/usage/reserve',
        '/usage/commit',
        '/usage/release',
        '/usage/summary',
        '/offline-content/status',
        '/achievements/status',
        '/ai/transcribe',
        '/ai/tts',
        '/ai/coach-turn',
        '/ai/feedback',
        '/ai/pronunciation',
      ]),
    );
  });

  test('generated Course paths encode identifiers safely', () {
    expect(
      SpeakeasyApiPaths.scenarioCourses('scenario/with space'),
      '/scenarios/scenario%2Fwith%20space/courses',
    );
    expect(
      SpeakeasyApiPaths.courseVersion('course/1', 'version 2'),
      '/courses/course%2F1/versions/version%202',
    );
  });

  test('generated auth session path encodes identifiers safely', () {
    expect(
      SpeakeasyApiPaths.authSession('session/with space'),
      '/auth/sessions/session%2Fwith%20space',
    );
  });

  test('generated type registry covers the Course read contract', () {
    expect(
      SpeakeasyApiContract.courseSchemaNames,
      containsAll(<String>[
        'CourseId',
        'CourseVersionId',
        'CourseContentBindingId',
        'ScenarioVersionId',
        'ScenarioLevelId',
        'CourseContentBindingRef',
        'CourseSummary',
        'TypicalDuration',
        'CourseDetail',
        'CourseListResponse',
        'CourseDetailResponse',
      ]),
    );
    expect(
      SpeakeasyApiContract.schemaPropertyTypes['ErrorDetails.retryable'],
      'bool?',
    );
    expect(
      ErrorCode.tryParse('CONTENT_READ_UNAVAILABLE'),
      ErrorCode.contentReadUnavailable,
    );
    expect(ErrorCode.values.map((ErrorCode code) => code.wireValue), <String>[
      'UNAUTHENTICATED',
      'ACCESS_TOKEN_EXPIRED',
      'ACCESS_TOKEN_INVALID',
      'REFRESH_TOKEN_EXPIRED',
      'REFRESH_TOKEN_INVALID',
      'SESSION_REVOKED',
      'SESSION_NOT_FOUND',
      'TOKEN_REUSE_DETECTED',
      'ACCOUNT_DISABLED',
      'AUTH_RATE_LIMITED',
      'AUTH_SERVICE_UNAVAILABLE',
      'FORBIDDEN',
      'INSUFFICIENT_SCOPE',
      'ENTITLEMENT_REQUIRED',
      'USAGE_LIMIT_EXCEEDED',
      'INVALID_RECEIPT',
      'PRODUCT_MISMATCH',
      'SUBSCRIPTION_EXPIRED',
      'IDEMPOTENCY_CONFLICT',
      'SCHEMA_VALIDATION_FAILED',
      'PROVIDER_UNAVAILABLE',
      'CONTENT_READ_UNAVAILABLE',
      'DELETE_IN_PROGRESS',
      'RESOURCE_NOT_FOUND',
      'CONFLICT',
    ]);
    expect(ErrorCode.tryParse('content_read_unavailable'), isNull);
    expect(ErrorCode.tryParse(false), isNull);
    expect(LevelCode.values.map((LevelCode level) => level.wireValue), <String>[
      'A1',
      'A2',
      'B1',
      'B2',
      'C1',
      'C2',
    ]);
  });

  test('generated ScenarioId accepts future canonical values', () {
    final ScenarioId futureScenario = ScenarioId.parse('travel_planning');

    expect(futureScenario.wireValue, 'travel_planning');
    expect(futureScenario, ScenarioId.parse('travel_planning'));
    expect(ScenarioId.parse('a').wireValue, 'a');
    expect(
      ScenarioId.parse(List<String>.filled(80, 'a').join()).wireValue.length,
      80,
    );
    expect(ScenarioId.jobInterview.wireValue, 'job_interview');
    expect(
      ScenarioId.onboardingIntroduction.wireValue,
      'onboarding_introduction',
    );

    for (final Object? invalid in <Object?>[
      null,
      false,
      '',
      'Travel_Planning',
      'travel-planning',
      'travel__planning',
      List<String>.filled(81, 'a').join(),
    ]) {
      expect(
        () => ScenarioId.parse(invalid),
        throwsFormatException,
        reason: 'ScenarioId must reject $invalid',
      );
    }
  });

  test('generated catalog DTOs decode exact typed identities and CEFR', () {
    final ScenarioListResponse themes = ScenarioListResponse.fromJson(
      <String, Object?>{
        'schema_version': 1,
        'request_id': 'request-themes',
        'scenarios': <Object?>[
          <String, Object?>{
            'scenario_id': 'job_interview',
            'title': '求职面试',
            'summary': '准备常见面试沟通',
            'levels': <Object?>['A1', 'C2'],
            'status': 'available',
            'access': <String, Object?>{'allowed': true},
          },
        ],
      },
    );
    final CourseListResponse courses = CourseListResponse.fromJson(
      <String, Object?>{
        'schema_version': 1,
        'request_id': 'request-courses',
        'scenario_id': 'job_interview',
        'courses': <Object?>[
          <String, Object?>{
            'course_id': '11111111-1111-4111-8111-111111111111',
            'course_version_id': '22222222-2222-4222-8222-222222222222',
            'title_en': 'Interview Foundations',
            'summary_zh': '建立面试表达基础',
            'level_code': 'C1',
            'content_binding_ref': <String, Object?>{
              'course_content_binding_id':
                  '33333333-3333-4333-8333-333333333333',
              'scenario_version_id': '44444444-4444-4444-8444-444444444444',
              'scenario_level_id': '55555555-5555-4555-8555-555555555555',
            },
          },
        ],
      },
    );

    expect(themes.scenarios.single.scenarioId, ScenarioId.jobInterview);
    expect(themes.scenarios.single.levels, <LevelCode>[
      LevelCode.a1,
      LevelCode.c2,
    ]);
    expect(courses.courses.single.levelCode, LevelCode.c1);
    expect(
      courses.courses.single.courseVersionId,
      '22222222-2222-4222-8222-222222222222',
    );
    expect(
      CourseListResponse.fromJson(<String, Object?>{
        'schema_version': 1,
        'request_id': 'uuid-v7',
        'scenario_id': 'job_interview',
        'courses': <Object?>[
          <String, Object?>{
            'course_id': '018f3f4e-7b5d-7cc0-98c4-d4b4ce52f700',
            'course_version_id': '018f3f4e-7b5d-8cc0-98c4-d4b4ce52f701',
            'title_en': 'Modern UUID course',
            'summary_zh': '接受契约允许的 UUID 版本',
            'level_code': 'B2',
            'content_binding_ref': <String, Object?>{
              'course_content_binding_id':
                  '018f3f4e-7b5d-6cc0-98c4-d4b4ce52f702',
              'scenario_version_id': '018f3f4e-7b5d-7cc0-98c4-d4b4ce52f703',
              'scenario_level_id': '018f3f4e-7b5d-8cc0-98c4-d4b4ce52f704',
            },
          },
        ],
      }).courses.single.courseId,
      '018f3f4e-7b5d-7cc0-98c4-d4b4ce52f700',
    );
    expect(
      () => CourseListResponse.fromJson(<String, Object?>{
        'schema_version': 1,
        'request_id': 'legacy-level',
        'scenario_id': 'job_interview',
        'courses': <Object?>[
          <String, Object?>{
            'course_id': '11111111-1111-4111-8111-111111111111',
            'course_version_id': '22222222-2222-4222-8222-222222222222',
            'title_en': 'Legacy',
            'summary_zh': '旧等级不可接受',
            'level_code': 'L3',
            'content_binding_ref': <String, Object?>{
              'course_content_binding_id':
                  '33333333-3333-4333-8333-333333333333',
              'scenario_version_id': '44444444-4444-4444-8444-444444444444',
              'scenario_level_id': '55555555-5555-4555-8555-555555555555',
            },
          },
        ],
      }),
      throwsFormatException,
    );

    final CourseDetailResponse detail = CourseDetailResponse.fromJson(
      <String, Object?>{
        'schema_version': 1,
        'request_id': 'request-detail',
        'course': <String, Object?>{
          'course_id': '11111111-1111-4111-8111-111111111111',
          'course_version_id': '22222222-2222-4222-8222-222222222222',
          'title_en': 'Interview Foundations',
          'summary_zh': '建立面试表达基础',
          'level_code': 'A2',
          'content_binding_ref': <String, Object?>{
            'course_content_binding_id': '33333333-3333-4333-8333-333333333333',
            'scenario_version_id': '44444444-4444-4444-8444-444444444444',
            'scenario_level_id': '55555555-5555-4555-8555-555555555555',
          },
          'typical_duration': <String, Object?>{'value': 45, 'unit': 'minutes'},
          'background_asset_ref': null,
        },
      },
    );
    expect(detail.course.courseId, '11111111-1111-4111-8111-111111111111');
    expect(
      detail.course.courseVersionId,
      '22222222-2222-4222-8222-222222222222',
    );
    expect(detail.course.typicalDuration.value, 45);
    expect(detail.course.typicalDuration.unit, 'minutes');
    expect(detail.course.backgroundAssetRef, isNull);
    expect(
      () => CourseDetailResponse.fromJson(<String, Object?>{
        'schema_version': 1,
        'request_id': 'invalid-duration',
        'course': <String, Object?>{
          'course_id': '11111111-1111-4111-8111-111111111111',
          'course_version_id': '22222222-2222-4222-8222-222222222222',
          'title_en': 'Interview Foundations',
          'summary_zh': '建立面试表达基础',
          'level_code': 'A2',
          'content_binding_ref': <String, Object?>{
            'course_content_binding_id': '33333333-3333-4333-8333-333333333333',
            'scenario_version_id': '44444444-4444-4444-8444-444444444444',
            'scenario_level_id': '55555555-5555-4555-8555-555555555555',
          },
          'typical_duration': <String, Object?>{'value': 0, 'unit': 'minutes'},
        },
      }),
      throwsFormatException,
    );
    expect(
      () => CourseDetailResponse.fromJson(<String, Object?>{
        'schema_version': 1,
        'request_id': 'invalid-duration-unit',
        'course': <String, Object?>{
          'course_id': '11111111-1111-4111-8111-111111111111',
          'course_version_id': '22222222-2222-4222-8222-222222222222',
          'title_en': 'Interview Foundations',
          'summary_zh': '建立面试表达基础',
          'level_code': 'A2',
          'content_binding_ref': <String, Object?>{
            'course_content_binding_id': '33333333-3333-4333-8333-333333333333',
            'scenario_version_id': '44444444-4444-4444-8444-444444444444',
            'scenario_level_id': '55555555-5555-4555-8555-555555555555',
          },
          'typical_duration': <String, Object?>{'value': 45, 'unit': '   '},
        },
      }),
      throwsFormatException,
    );
  });

  test('typed Course catalog adapter owns paths and error semantics', () async {
    final List<String> requestedPaths = <String>[];
    final ApiClientCourseCatalogApi api =
        ApiClientCourseCatalogApi.withTransport((String path) async {
          requestedPaths.add(path);
          if (path == SpeakeasyApiPaths.scenarios) {
            return <String, dynamic>{
              '_httpStatus': 200,
              'schema_version': 1,
              'request_id': 'themes',
              'scenarios': <Object?>[],
            };
          }
          if (path ==
              SpeakeasyApiPaths.courseVersion(
                '11111111-1111-4111-8111-111111111111',
                '22222222-2222-4222-8222-222222222222',
              )) {
            return <String, dynamic>{
              '_httpStatus': 200,
              'schema_version': 1,
              'request_id': 'detail',
              'course': <String, Object?>{
                'course_id': '11111111-1111-4111-8111-111111111111',
                'course_version_id': '22222222-2222-4222-8222-222222222222',
                'title_en': 'Interview Foundations',
                'summary_zh': '建立面试表达基础',
                'level_code': 'A2',
                'content_binding_ref': <String, Object?>{
                  'course_content_binding_id':
                      '33333333-3333-4333-8333-333333333333',
                  'scenario_version_id': '44444444-4444-4444-8444-444444444444',
                  'scenario_level_id': '55555555-5555-4555-8555-555555555555',
                },
                'typical_duration': <String, Object?>{
                  'value': 45,
                  'unit': 'minutes',
                },
                'background_asset_ref': null,
              },
            };
          }
          return <String, dynamic>{
            '_httpStatus': 503,
            'error': <String, Object?>{
              'code': 'CONTENT_READ_UNAVAILABLE',
              'message': 'temporarily unavailable',
              'request_id': 'courses',
              'details': <String, Object?>{'retryable': true},
            },
          };
        });

    expect((await api.listContentThemes()).scenarios, isEmpty);
    final CourseDetailResponse detail = await api.getCourseVersionDetail(
      '11111111-1111-4111-8111-111111111111',
      '22222222-2222-4222-8222-222222222222',
    );
    expect(detail.course.titleEn, 'Interview Foundations');
    await expectLater(
      api.listScenarioCourses(ScenarioId.jobInterview),
      throwsA(
        isA<ContentApiFailure>()
            .having(
              (ContentApiFailure failure) => failure.kind,
              'kind',
              ContentApiFailureKind.retryable,
            )
            .having(
              (ContentApiFailure failure) => failure.requestId,
              'requestId',
              'courses',
            ),
      ),
    );
    expect(requestedPaths, <String>[
      '/scenarios',
      '/courses/11111111-1111-4111-8111-111111111111/versions/22222222-2222-4222-8222-222222222222',
      '/scenarios/job_interview/courses',
    ]);
  });

  test('exact Course detail maps typed 401, 404, and 503 failures', () async {
    const String detailPath =
        '/courses/11111111-1111-4111-8111-111111111111/versions/'
        '22222222-2222-4222-8222-222222222222';
    const List<
      ({
        int status,
        String code,
        bool retryable,
        ContentApiFailureKind expectedKind,
      })
    >
    cases =
        <
          ({
            int status,
            String code,
            bool retryable,
            ContentApiFailureKind expectedKind,
          })
        >[
          (
            status: 401,
            code: 'UNAUTHENTICATED',
            retryable: false,
            expectedKind: ContentApiFailureKind.unauthenticated,
          ),
          (
            status: 404,
            code: 'RESOURCE_NOT_FOUND',
            retryable: false,
            expectedKind: ContentApiFailureKind.notFound,
          ),
          (
            status: 503,
            code: 'CONTENT_READ_UNAVAILABLE',
            retryable: true,
            expectedKind: ContentApiFailureKind.retryable,
          ),
        ];

    for (final testCase in cases) {
      final String requestId = 'detail-${testCase.status}';
      final ApiClientCourseCatalogApi api =
          ApiClientCourseCatalogApi.withTransport((String path) async {
            expect(path, detailPath);
            return <String, dynamic>{
              '_httpStatus': testCase.status,
              'error': <String, Object?>{
                'code': testCase.code,
                'message': 'typed detail failure',
                'request_id': requestId,
                'details': <String, Object?>{'retryable': testCase.retryable},
              },
            };
          });

      await expectLater(
        api.getCourseVersionDetail(
          '11111111-1111-4111-8111-111111111111',
          '22222222-2222-4222-8222-222222222222',
        ),
        throwsA(
          isA<ContentApiFailure>()
              .having(
                (ContentApiFailure failure) => failure.kind,
                'kind',
                testCase.expectedKind,
              )
              .having(
                (ContentApiFailure failure) => failure.requestId,
                'requestId',
                requestId,
              ),
        ),
      );
    }
  });

  test('ApiClient no longer references pre-OpenAPI active MVP paths', () {
    final String source = File(
      'lib/services/api_client.dart',
    ).readAsStringSync();

    for (final String oldPath in <String>[
      '/auth/sms/send',
      '/auth/sms/verify',
      '/auth/test-login',
      '/auth/apple',
      '/auth/wechat',
      '/ai/tts/cache',
      '/ai/score',
      '/ai/interview/coach-turn',
      '/payments/apple/verify-receipt',
      '/user/me/avatar',
    ]) {
      expect(source, isNot(contains(oldPath)), reason: oldPath);
    }
    expect(source, isNot(contains('uploadAvatar(')));
    expect(source, isNot(contains('MultipartRequest')));

    expect(source, contains('SpeakeasyApiPaths.authLoginPhone'));
    expect(source, contains('SpeakeasyApiPaths.aiPronunciation'));
    expect(source, contains('SpeakeasyApiPaths.userMe'));
    expect(source, contains("copy('avatarUrl', 'avatar_ref')"));
    expect(source, contains("copy('avatarRef', 'avatar_ref')"));
    expect(source, contains("copy('avatar_ref', 'avatar_ref')"));
    expect(source, contains('SpeakeasyApiPaths.subscriptionsAppleVerify'));
    expect(source, contains('SpeakeasyApiPaths.subscriptionsGoogleVerify'));
    expect(source, contains('SpeakeasyApiPaths.subscriptionsRestore'));
    expect(source, contains('SpeakeasyApiPaths.entitlementsRefresh'));
  });

  test('legacy handwritten paths are documented as drift exceptions', () {
    final String source = File(
      'lib/services/api_client.dart',
    ).readAsStringSync();
    final Map<String, dynamic> manifest =
        jsonDecode(
              File(
                'docs/architecture/openapi/dart-client-drift-manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final Map<String, dynamic> exceptions =
        manifest['handwritten_client_exceptions'] as Map<String, dynamic>;

    for (final MapEntry<String, dynamic> entry in exceptions.entries) {
      expect(source, contains(entry.key), reason: entry.key);
      expect((entry.value as String).trim(), isNotEmpty, reason: entry.key);
    }
  });
}
