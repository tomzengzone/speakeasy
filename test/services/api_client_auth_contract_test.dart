import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/services/api_client.dart';

void main() {
  test(
    'refresh calls the canonical endpoint and preserves rotated credentials',
    () async {
      late String requestedPath;
      late Map<String, dynamic> requestedBody;

      final Map<String, dynamic> result = await ApiClient.refreshToken(
        refreshToken: 'refresh-token-1',
        transport: (String path, Map<String, dynamic> body) async {
          requestedPath = path;
          requestedBody = body;
          return <String, dynamic>{
            '_httpStatus': 200,
            'schema_version': 1,
            'access_token': 'access-token-2',
            'refresh_token': 'refresh-token-2',
            'expires_at': '2026-08-27T00:00:00Z',
            'user': <String, dynamic>{
              'user_id': 'user-1',
              'display_name': '测试用户',
              'account_status': 'active',
              'onboarding_status': 'completed',
            },
          };
        },
      );

      expect(requestedPath, SpeakeasyApiPaths.authRefresh);
      expect(requestedBody, <String, dynamic>{
        'schema_version': 1,
        'refresh_token': 'refresh-token-1',
      });
      expect(result['code'], 0);
      expect(result['data']['accessToken'], 'access-token-2');
      expect(result['data']['refreshToken'], 'refresh-token-2');
      expect(result['data']['expiresAt'], '2026-08-27T00:00:00.000Z');
    },
  );

  test(
    'refresh maps backend 401 UNAUTHENTICATED to authentication failure',
    () async {
      await expectLater(
        ApiClient.refreshToken(
          refreshToken: 'invalid-refresh-token',
          transport: (String path, Map<String, dynamic> body) async {
            return <String, dynamic>{
              '_httpStatus': 401,
              'error': <String, dynamic>{
                'code': 'UNAUTHENTICATED',
                'message': 'Refresh token is invalid.',
                'request_id': 'request-1',
                'details': <String, dynamic>{},
              },
            };
          },
        ),
        throwsA(
          isA<RefreshFailure>()
              .having(
                (RefreshFailure failure) => failure.kind,
                'kind',
                RefreshFailureKind.authentication,
              )
              .having(
                (RefreshFailure failure) => failure.httpStatus,
                'httpStatus',
                401,
              )
              .having(
                (RefreshFailure failure) => failure.backendCode,
                'backendCode',
                'UNAUTHENTICATED',
              ),
        ),
      );
    },
  );

  test('refresh maps HTTP 5xx to infrastructure failure', () async {
    await expectLater(
      ApiClient.refreshToken(
        refreshToken: 'refresh-token',
        transport: (String path, Map<String, dynamic> body) async {
          return <String, dynamic>{
            '_httpStatus': 503,
            'error': <String, dynamic>{
              'code': 'SERVICE_UNAVAILABLE',
              'message': 'Service temporarily unavailable.',
            },
          };
        },
      ),
      throwsA(
        isA<RefreshFailure>()
            .having(
              (RefreshFailure failure) => failure.kind,
              'kind',
              RefreshFailureKind.infrastructure,
            )
            .having(
              (RefreshFailure failure) => failure.httpStatus,
              'httpStatus',
              503,
            ),
      ),
    );
  });

  test(
    'refresh maps canonical 429 and Retry-After to rate-limited failure',
    () async {
      await expectLater(
        ApiClient.refreshToken(
          refreshToken: 'refresh-token',
          transport: (String path, Map<String, dynamic> body) async {
            return <String, dynamic>{
              '_httpStatus': 429,
              '_responseHeaders': <String, String>{'retry-after': '37'},
              'error': <String, dynamic>{
                'code': 'AUTH_RATE_LIMITED',
                'message': 'Too many authentication requests.',
              },
            };
          },
        ),
        throwsA(
          isA<RateLimitedRefreshFailure>()
              .having(
                (RateLimitedRefreshFailure failure) => failure.kind,
                'kind',
                RefreshFailureKind.rateLimited,
              )
              .having(
                (RateLimitedRefreshFailure failure) => failure.retryAfter,
                'retryAfter',
                const Duration(seconds: 37),
              ),
        ),
      );
    },
  );

  test('refresh maps transport timeout to infrastructure failure', () async {
    await expectLater(
      ApiClient.refreshToken(
        refreshToken: 'refresh-token',
        transport: (String path, Map<String, dynamic> body) async {
          throw TimeoutException('refresh timeout');
        },
      ),
      throwsA(
        isA<RefreshFailure>()
            .having(
              (RefreshFailure failure) => failure.kind,
              'kind',
              RefreshFailureKind.infrastructure,
            )
            .having(
              (RefreshFailure failure) => failure.cause,
              'cause',
              isA<TimeoutException>(),
            ),
      ),
    );
  });
}
