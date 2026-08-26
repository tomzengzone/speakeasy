import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/credential_repository.dart';
import 'package:speakeasy/core/auth/refresh_coordinator.dart';
import 'package:speakeasy/core/auth/token_provider.dart';
import 'package:speakeasy/services/api_client.dart';

class _MemoryTokenProvider implements TokenProvider, CredentialRepository {
  _MemoryTokenProvider(this.credentials);

  AuthCredentials? credentials;
  int replaceCount = 0;

  @override
  Future<AuthCredentials?> getCredentials() async => credentials;

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
      credentialRepository: provider,
      refreshCredentials: (String refreshToken) async {
        refreshCount += 1;
        throw StateError('unexpected refresh');
      },
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
        credentialRepository: provider,
        refreshCredentials: (String refreshToken) async {
          refreshCount += 1;
          expect(refreshToken, 'refresh-token-1');
          return rotated;
        },
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
        credentialRepository: provider,
        refreshCredentials: (String refreshToken) {
          refreshCount += 1;
          return refreshCompleter.future;
        },
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

  test('logout during refresh discards the stale result', () async {
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
      credentialRepository: provider,
      refreshCredentials: (String refreshToken) {
        refreshCount += 1;
        return refreshCompleter.future;
      },
      now: () => now,
    );

    final Future<AuthCredentials> refresh = coordinator.refreshIfNeeded();
    await Future<void>.delayed(Duration.zero);
    provider.credentials = null;
    refreshCompleter.complete(rotated);

    await expectLater(refresh, throwsA(isA<CredentialContextChanged>()));
    expect(provider.credentials, isNull);
    expect(provider.replaceCount, 0);
    expect(refreshCount, 1);
  });

  test('account switch during refresh preserves the new account', () async {
    final AuthCredentials accountA = credentials(
      accessToken: 'account-a-access-1',
      refreshToken: 'account-a-refresh-1',
      expiresAt: now.add(const Duration(seconds: 30)),
    );
    final AuthCredentials accountARefreshed = credentials(
      accessToken: 'account-a-access-2',
      refreshToken: 'account-a-refresh-2',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final AuthCredentials accountB = credentials(
      accessToken: 'account-b-access-1',
      refreshToken: 'account-b-refresh-1',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    final _MemoryTokenProvider provider = _MemoryTokenProvider(accountA);
    final Completer<AuthCredentials> refreshCompleter =
        Completer<AuthCredentials>();
    final RefreshCoordinator coordinator = RefreshCoordinator(
      tokenProvider: provider,
      credentialRepository: provider,
      refreshCredentials: (String refreshToken) => refreshCompleter.future,
      now: () => now,
    );

    final Future<AuthCredentials> refresh = coordinator.refreshIfNeeded();
    await Future<void>.delayed(Duration.zero);
    provider.credentials = accountB;
    refreshCompleter.complete(accountARefreshed);

    await expectLater(refresh, throwsA(isA<CredentialContextChanged>()));
    expect(provider.credentials, same(accountB));
    expect(provider.replaceCount, 0);
  });

  test(
    'concurrent callers share one context-changed failure after logout',
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
        credentialRepository: provider,
        refreshCredentials: (String refreshToken) {
          refreshCount += 1;
          return refreshCompleter.future;
        },
        now: () => now,
      );

      final List<Future<AuthCredentials>> refreshes =
          List<Future<AuthCredentials>>.generate(
            3,
            (_) => coordinator.refreshIfNeeded(),
          );
      await Future<void>.delayed(Duration.zero);
      provider.credentials = null;
      refreshCompleter.complete(rotated);

      final List<Object> failures = await Future.wait<Object>(
        refreshes.map(
          (Future<AuthCredentials> refresh) => refresh.then<Object>(
            (_) => fail('stale refresh unexpectedly succeeded'),
            onError: (Object error) => error,
          ),
        ),
      );

      expect(refreshCount, 1);
      expect(provider.credentials, isNull);
      expect(provider.replaceCount, 0);
      expect(failures, everyElement(isA<CredentialContextChanged>()));
      expect(failures.skip(1), everyElement(same(failures.first)));

      provider.credentials = current;
      final AuthCredentials retried = await coordinator.refreshIfNeeded(
        force: true,
      );
      expect(retried, same(rotated));
      expect(refreshCount, 2);
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
        credentialRepository: provider,
        refreshCredentials: (String refreshToken) async {
          refreshCount += 1;
          return rotated;
        },
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
          credentialRepository: provider,
          refreshCredentials: (String refreshToken) async => throw failure,
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
