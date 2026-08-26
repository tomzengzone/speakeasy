import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/refresh_coordinator.dart';
import 'package:speakeasy/core/auth/token_provider.dart';
import 'package:speakeasy/services/api_client.dart';

class _MemoryTokenProvider implements TokenProvider {
  _MemoryTokenProvider(this.credentials);

  AuthCredentials? credentials;
  int replaceCount = 0;

  @override
  Future<AuthCredentials?> getCredentials() async => credentials;

  Future<void> replace(AuthCredentials next) async {
    replaceCount += 1;
    credentials = next;
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

  test('healthy credentials do not refresh', () async {
    final AuthCredentials current = credentials(
      accessToken: 'access-token-1',
      refreshToken: 'refresh-token-1',
      expiresAt: now.add(const Duration(minutes: 20)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
    int refreshCount = 0;
    final RefreshCoordinator coordinator = RefreshCoordinator(
      tokenProvider: provider,
      refreshCredentials: (String refreshToken) async {
        refreshCount += 1;
        throw StateError('unexpected refresh');
      },
      replaceCredentials: provider.replace,
      now: () => now,
    );

    final AuthCredentials result = await coordinator.refreshIfNeeded();

    expect(result, same(current));
    expect(refreshCount, 0);
    expect(provider.replaceCount, 0);
  });

  test(
    'near-expiry credentials refresh and rotate the complete set once',
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
      int refreshCount = 0;
      final RefreshCoordinator coordinator = RefreshCoordinator(
        tokenProvider: provider,
        refreshCredentials: (String refreshToken) async {
          refreshCount += 1;
          expect(refreshToken, 'refresh-token-1');
          return rotated;
        },
        replaceCredentials: provider.replace,
        now: () => now,
      );

      final AuthCredentials result = await coordinator.refreshIfNeeded();

      expect(result, same(rotated));
      expect(provider.credentials, same(rotated));
      expect(provider.credentials!.accessToken, 'access-token-2');
      expect(provider.credentials!.refreshToken, 'refresh-token-2');
      expect(
        provider.credentials!.expiresAt,
        now.add(const Duration(hours: 1)),
      );
      expect(refreshCount, 1);
      expect(provider.replaceCount, 1);
    },
  );

  test(
    'three concurrent proactive refreshes share one in-flight refresh',
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
      final RefreshCoordinator coordinator = RefreshCoordinator(
        tokenProvider: provider,
        refreshCredentials: (String refreshToken) {
          refreshCount += 1;
          return refreshCompleter.future;
        },
        replaceCredentials: provider.replace,
        now: () => now,
      );

      final List<Future<AuthCredentials>> futures =
          List<Future<AuthCredentials>>.generate(
            3,
            (_) => coordinator.refreshIfNeeded(),
          );
      await Future<void>.delayed(Duration.zero);

      expect(refreshCount, 1);
      refreshCompleter.complete(rotated);
      final List<AuthCredentials> results = await Future.wait(futures);

      expect(results, everyElement(same(rotated)));
      expect(provider.replaceCount, 1);
    },
  );

  test(
    'stale 401 returns rotated credentials without another refresh',
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
      int refreshCount = 0;
      final RefreshCoordinator coordinator = RefreshCoordinator(
        tokenProvider: provider,
        refreshCredentials: (String refreshToken) async {
          refreshCount += 1;
          return rotated;
        },
        replaceCredentials: provider.replace,
        now: () => now,
      );

      await coordinator.refreshIfNeeded(failedAccessToken: 'access-token-1');
      final AuthCredentials result = await coordinator.refreshIfNeeded(
        failedAccessToken: 'access-token-1',
      );

      expect(result, same(rotated));
      expect(refreshCount, 1);
      expect(provider.replaceCount, 1);
    },
  );

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
      '${failure.kind.name} refresh failure preserves credentials',
      () async {
        final AuthCredentials current = credentials(
          accessToken: 'access-token-1',
          refreshToken: 'refresh-token-1',
          expiresAt: now.add(const Duration(minutes: 20)),
        );
        final _MemoryTokenProvider provider = _MemoryTokenProvider(current);
        final RefreshCoordinator coordinator = RefreshCoordinator(
          tokenProvider: provider,
          refreshCredentials: (String refreshToken) async => throw failure,
          replaceCredentials: provider.replace,
          now: () => now,
        );

        await expectLater(
          coordinator.refreshIfNeeded(failedAccessToken: 'access-token-1'),
          throwsA(same(failure)),
        );

        expect(provider.credentials, same(current));
        expect(provider.replaceCount, 0);
      },
    );
  }
}
