import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/credential_repository.dart';
import 'package:speakeasy/core/auth/refresh_coordinator.dart';
import 'package:speakeasy/core/auth/token_provider.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/authenticated_request_executor.dart';

class _MemoryTokenProvider implements TokenProvider, CredentialRepository {
  _MemoryTokenProvider(this.credentials);

  AuthCredentials? credentials;
  int readCount = 0;
  int replaceCount = 0;

  @override
  Future<AuthCredentials?> getCredentials() async {
    readCount += 1;
    return credentials;
  }

  @override
  Future<AuthCredentials?> read() => getCredentials();

  @override
  Future<void> replace(AuthCredentials next) async {
    replaceCount += 1;
    credentials = next;
  }

  @override
  Future<void> clear() async {
    credentials = null;
  }
}

void main() {
  final DateTime now = DateTime.utc(2026, 8, 26, 12);

  AuthCredentials credentials({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) {
    return AuthCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  AuthenticatedRequestExecutor executor({
    required _MemoryTokenProvider provider,
    required Future<AuthCredentials> Function(String refreshToken) refresh,
    Future<String?> Function()? legacyAccessToken,
  }) {
    final RefreshCoordinator coordinator = RefreshCoordinator(
      tokenProvider: provider,
      credentialRepository: provider,
      refreshCredentials: refresh,
      now: () => now,
    );
    return AuthenticatedRequestExecutor(
      tokenProvider: provider,
      refreshCoordinator: coordinator,
      legacyAccessToken: legacyAccessToken,
    );
  }

  test('healthy AT sends one request with the current bearer token', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(minutes: 20)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    int refreshCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      refresh: (String refreshToken) async {
        refreshCount += 1;
        throw StateError('unexpected refresh');
      },
    );
    final List<Map<String, String>> requests = <Map<String, String>>[];

    final http.Response response = await requestExecutor.execute(
      authPolicy: AuthPolicy.required,
      headers: const <String, String>{'Content-Type': 'application/json'},
      send: (Map<String, String> headers) async {
        requests.add(headers);
        return http.Response('{}', 200);
      },
    );

    expect(response.statusCode, 200);
    expect(requests, hasLength(1));
    expect(requests.single['Authorization'], 'Bearer access-token-1');
    expect(refreshCount, 0);
  });

  test('near-expiry AT refreshes before sending and uses the new AT', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(seconds: 30)),
    );
    final AuthCredentials rotated = credentials(
      accessToken: 'access-token-2',
      refreshToken: 'refresh-token-2',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    int refreshCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      refresh: (String refreshToken) async {
        refreshCount += 1;
        return rotated;
      },
    );
    final List<Map<String, String>> requests = <Map<String, String>>[];

    await requestExecutor.execute(
      authPolicy: AuthPolicy.required,
      send: (Map<String, String> headers) async {
        requests.add(headers);
        return http.Response('{}', 200);
      },
    );

    expect(refreshCount, 1);
    expect(provider.replaceCount, 1);
    expect(requests, hasLength(1));
    expect(requests.single['Authorization'], 'Bearer access-token-2');
  });

  test(
    'three concurrent near-expiry requests refresh once and all send AT2',
    () async {
      final AuthCredentials current = credentials(
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        expiresAt: now.add(const Duration(seconds: 30)),
      );
      final AuthCredentials rotated = credentials(
        accessToken: 'access-token-2',
        refreshToken: 'refresh-token-2',
        expiresAt: now.add(const Duration(hours: 1)),
      );
      final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
      final Completer<AuthCredentials> refreshCompleter =
          Completer<AuthCredentials>();
      int refreshCount = 0;
      final AuthenticatedRequestExecutor requestExecutor = executor(
        provider: provider,
        refresh: (String refreshToken) {
          refreshCount += 1;
          return refreshCompleter.future;
        },
      );
      final List<Map<String, String>> requests = <Map<String, String>>[];

      final List<Future<http.Response>> futures =
          List<Future<http.Response>>.generate(3, (_) {
            return requestExecutor.execute(
              authPolicy: AuthPolicy.required,
              send: (Map<String, String> headers) async {
                requests.add(headers);
                return http.Response('{}', 200);
              },
            );
          });
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 1);
      refreshCompleter.complete(rotated);
      await Future.wait(futures);

      expect(requests, hasLength(3));
      expect(
        requests.map((Map<String, String> headers) => headers['Authorization']),
        everyElement('Bearer access-token-2'),
      );
      expect(provider.replaceCount, 1);
    },
  );

  test('one 401 refreshes and retries the original request once', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(minutes: 20)),
    );
    final AuthCredentials rotated = credentials(
      accessToken: 'access-token-2',
      refreshToken: 'refresh-token-2',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    int refreshCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      refresh: (String refreshToken) async {
        refreshCount += 1;
        return rotated;
      },
    );
    final List<Map<String, String>> requests = <Map<String, String>>[];

    final http.Response response = await requestExecutor.execute(
      authPolicy: AuthPolicy.required,
      send: (Map<String, String> headers) async {
        requests.add(headers);
        return http.Response('{}', requests.length == 1 ? 401 : 200);
      },
    );

    expect(response.statusCode, 200);
    expect(refreshCount, 1);
    expect(requests, hasLength(2));
    expect(requests.first['Authorization'], 'Bearer access-token-1');
    expect(requests.last['Authorization'], 'Bearer access-token-2');
  });

  test(
    'three concurrent 401 requests refresh once and all retry with AT2',
    () async {
      final AuthCredentials current = credentials(
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        expiresAt: now.add(const Duration(minutes: 20)),
      );
      final AuthCredentials rotated = credentials(
        accessToken: 'access-token-2',
        refreshToken: 'refresh-token-2',
        expiresAt: now.add(const Duration(hours: 1)),
      );
      final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
      final Completer<AuthCredentials> refreshCompleter =
          Completer<AuthCredentials>();
      int refreshCount = 0;
      final AuthenticatedRequestExecutor requestExecutor = executor(
        provider: provider,
        refresh: (String refreshToken) {
          refreshCount += 1;
          return refreshCompleter.future;
        },
      );
      final List<List<Map<String, String>>> requestHeaders =
          List<List<Map<String, String>>>.generate(
            3,
            (_) => <Map<String, String>>[],
          );

      final List<Future<http.Response>> requests =
          List<Future<http.Response>>.generate(3, (int index) {
            return requestExecutor.execute(
              authPolicy: AuthPolicy.required,
              send: (Map<String, String> headers) async {
                requestHeaders[index].add(headers);
                return http.Response(
                  '{}',
                  requestHeaders[index].length == 1 ? 401 : 200,
                );
              },
            );
          });
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 1);
      refreshCompleter.complete(rotated);
      final List<http.Response> responses = await Future.wait(requests);

      expect(
        responses.map((http.Response response) => response.statusCode),
        <int>[200, 200, 200],
      );
      for (final List<Map<String, String>> headers in requestHeaders) {
        expect(headers, hasLength(2));
        expect(headers.first['Authorization'], 'Bearer access-token-1');
        expect(headers.last['Authorization'], 'Bearer access-token-2');
      }
      expect(provider.replaceCount, 1);
    },
  );

  test('a delayed stale 401 reuses AT2 without refreshing again', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(minutes: 20)),
    );
    final AuthCredentials rotated = credentials(
      accessToken: 'access-token-2',
      refreshToken: 'refresh-token-2',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    final Completer<void> delayed401 = Completer<void>();
    int refreshCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      refresh: (String refreshToken) async {
        refreshCount += 1;
        return rotated;
      },
    );
    final List<Map<String, String>> requestA = <Map<String, String>>[];
    final List<Map<String, String>> requestB = <Map<String, String>>[];

    final Future<http.Response> pendingB = requestExecutor.execute(
      authPolicy: AuthPolicy.required,
      send: (Map<String, String> headers) async {
        requestB.add(headers);
        if (requestB.length == 1) {
          await delayed401.future;
          return http.Response('{}', 401);
        }
        return http.Response('{}', 200);
      },
    );
    await Future<void>.delayed(Duration.zero);

    final http.Response responseA = await requestExecutor.execute(
      authPolicy: AuthPolicy.required,
      send: (Map<String, String> headers) async {
        requestA.add(headers);
        return http.Response('{}', requestA.length == 1 ? 401 : 200);
      },
    );
    expect(responseA.statusCode, 200);
    expect(refreshCount, 1);

    delayed401.complete();
    final http.Response responseB = await pendingB;

    expect(responseB.statusCode, 200);
    expect(refreshCount, 1);
    expect(requestA.first['Authorization'], 'Bearer access-token-1');
    expect(requestA.last['Authorization'], 'Bearer access-token-2');
    expect(requestB.first['Authorization'], 'Bearer access-token-1');
    expect(requestB.last['Authorization'], 'Bearer access-token-2');
  });

  test('a retry that also returns 401 stops without another refresh', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(minutes: 20)),
    );
    final AuthCredentials rotated = credentials(
      accessToken: 'access-token-2',
      refreshToken: 'refresh-token-2',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    int refreshCount = 0;
    int requestCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      refresh: (String refreshToken) async {
        refreshCount += 1;
        return rotated;
      },
    );

    final http.Response response = await requestExecutor.execute(
      authPolicy: AuthPolicy.required,
      send: (Map<String, String> headers) async {
        requestCount += 1;
        return http.Response('{}', 401);
      },
    );

    expect(response.statusCode, 401);
    expect(requestCount, 2);
    expect(refreshCount, 1);
  });

  for (final int statusCode in <int>[403, 404, 500]) {
    test('$statusCode does not trigger refresh', () async {
      final AuthCredentials current = credentials(
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        expiresAt: now.add(const Duration(minutes: 20)),
      );
      final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
      int refreshCount = 0;
      final AuthenticatedRequestExecutor requestExecutor = executor(
        provider: provider,
        refresh: (String refreshToken) async {
          refreshCount += 1;
          throw StateError('unexpected refresh');
        },
      );

      final http.Response response = await requestExecutor.execute(
        authPolicy: AuthPolicy.required,
        send: (Map<String, String> headers) async {
          return http.Response('{}', statusCode);
        },
      );

      expect(response.statusCode, statusCode);
      expect(refreshCount, 0);
    });
  }

  test('business transport failure does not trigger refresh', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(minutes: 20)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    int refreshCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      refresh: (String refreshToken) async {
        refreshCount += 1;
        throw StateError('unexpected refresh');
      },
    );

    await expectLater(
      requestExecutor.execute(
        authPolicy: AuthPolicy.required,
        send: (Map<String, String> headers) async {
          throw const SocketException('network unavailable');
        },
      ),
      throwsA(isA<SocketException>()),
    );

    expect(refreshCount, 0);
  });

  for (final RefreshFailure failure in <RefreshFailure>[
    const RefreshFailure(
      kind: RefreshFailureKind.authentication,
      message: 'Refresh token is invalid.',
      httpStatus: 401,
      backendCode: 'UNAUTHENTICATED',
    ),
    const RefreshFailure(
      kind: RefreshFailureKind.infrastructure,
      message: 'Authentication service unavailable.',
      httpStatus: 503,
    ),
  ]) {
    test(
      '${failure.kind.name} refresh failure does not retry business request',
      () async {
        final AuthCredentials current = credentials(
          accessToken: 'access-token-1',
          refreshToken: 'refresh-token-1',
          expiresAt: now.add(const Duration(minutes: 20)),
        );
        final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
        int requestCount = 0;
        final AuthenticatedRequestExecutor requestExecutor = executor(
          provider: provider,
          refresh: (String refreshToken) async => throw failure,
        );

        await expectLater(
          requestExecutor.execute(
            authPolicy: AuthPolicy.required,
            send: (Map<String, String> headers) async {
              requestCount += 1;
              return http.Response('{}', 401);
            },
          ),
          throwsA(same(failure)),
        );

        expect(requestCount, 1);
        expect(provider.replaceCount, 0);
        expect(provider.credentials, same(current));
      },
    );
  }

  test(
    'explicit auth-none login skips credentials, bearer, and refresh',
    () async {
      final AuthCredentials current = credentials(
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        expiresAt: now.add(const Duration(seconds: 30)),
      );
      final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
      int refreshCount = 0;
      final AuthenticatedRequestExecutor requestExecutor = executor(
        provider: provider,
        refresh: (String refreshToken) async {
          refreshCount += 1;
          throw StateError('unexpected refresh');
        },
      );

      for (final String loginKind in <String>['phone', 'apple', 'wechat']) {
        await requestExecutor.execute(
          authPolicy: AuthPolicy.none,
          headers: const <String, String>{
            'authorization': 'Bearer must-not-leak',
          },
          send: (Map<String, String> headers) async {
            expect(
              headers.keys.map((String name) => name.toLowerCase()),
              isNot(contains('authorization')),
              reason: '$loginKind login must be unauthenticated',
            );
            return http.Response('{}', 200);
          },
        );
      }

      expect(provider.readCount, 0);
      expect(refreshCount, 0);
    },
  );

  test('explicit auth-none refresh 401 cannot recursively refresh', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(minutes: 20)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    int refreshCount = 0;
    int requestCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      refresh: (String refreshToken) async {
        refreshCount += 1;
        throw StateError('recursive refresh');
      },
    );

    final http.Response response = await requestExecutor.execute(
      authPolicy: AuthPolicy.none,
      headers: const <String, String>{'authorization': 'Bearer must-not-leak'},
      send: (Map<String, String> headers) async {
        requestCount += 1;
        expect(
          headers.keys.map((String name) => name.toLowerCase()),
          isNot(contains('authorization')),
        );
        return http.Response('{}', 401);
      },
    );

    expect(response.statusCode, 401);
    expect(requestCount, 1);
    expect(provider.readCount, 0);
    expect(refreshCount, 0);
  });

  test(
    'default policy remains required for a renamed public-like call',
    () async {
      final AuthCredentials current = credentials(
        accessToken: 'access-token-1',
        refreshToken: 'refresh-token-1',
        expiresAt: now.add(const Duration(minutes: 20)),
      );
      final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
      int refreshCount = 0;
      final AuthenticatedRequestExecutor requestExecutor = executor(
        provider: provider,
        refresh: (String refreshToken) async {
          refreshCount += 1;
          throw StateError('unexpected refresh');
        },
      );

      final http.Response response = await requestExecutor.execute(
        send: (Map<String, String> headers) async {
          expect(headers['Authorization'], 'Bearer access-token-1');
          return http.Response('{}', 200);
        },
      );

      expect(response.statusCode, 200);
      expect(provider.readCount, greaterThan(0));
      expect(refreshCount, 0);
    },
  );

  test('legacy-only AT sends once but a 401 cannot trigger refresh', () async {
    final _MemoryTokenProvider provider = _MemoryTokenProvider(null);
    int refreshCount = 0;
    int requestCount = 0;
    final AuthenticatedRequestExecutor requestExecutor = executor(
      provider: provider,
      legacyAccessToken: () async => 'legacy-access-token',
      refresh: (String refreshToken) async {
        refreshCount += 1;
        throw StateError('legacy credentials cannot refresh');
      },
    );

    final http.Response response = await requestExecutor.execute(
      authPolicy: AuthPolicy.required,
      send: (Map<String, String> headers) async {
        requestCount += 1;
        expect(headers['Authorization'], 'Bearer legacy-access-token');
        return http.Response('{}', 401);
      },
    );

    expect(response.statusCode, 401);
    expect(requestCount, 1);
    expect(refreshCount, 0);
  });
}
