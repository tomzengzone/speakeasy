import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/credential_repository.dart';
import 'package:speakeasy/core/auth/secure_token_store.dart';
import 'package:speakeasy/core/auth/token_provider.dart';

class MockSecureTokenStore extends Mock implements SecureTokenStore {}

class MockCredentialRepository extends Mock implements CredentialRepository {}

class _BlockingSecureTokenStore extends SecureTokenStore {
  _BlockingSecureTokenStore(this.credentials, {this.blockNextReplace = false});

  AuthCredentials? credentials;
  bool blockNextReplace;
  final Completer<void> replaceStarted = Completer<void>();
  final Completer<void> releaseReplace = Completer<void>();

  @override
  Future<AuthCredentials?> read() async => credentials;

  @override
  Future<void> replace(AuthCredentials next) async {
    if (blockNextReplace) {
      blockNextReplace = false;
      replaceStarted.complete();
      await releaseReplace.future;
    }
    credentials = next;
  }

  @override
  Future<void> clear() async {
    credentials = null;
  }
}

void main() {
  final AuthCredentials credentials = AuthCredentials(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    expiresAt: DateTime.utc(2026, 8, 27),
  );

  test(
    'replace writes complete credentials and clears legacy session once',
    () async {
      final MockSecureTokenStore tokenStore = MockSecureTokenStore();
      int legacyCleanupCount = 0;
      when(() => tokenStore.replace(credentials)).thenAnswer((_) async {});
      final SecureCredentialRepository repository = SecureCredentialRepository(
        tokenStore: tokenStore,
        clearLegacyAuthSession: () async {
          legacyCleanupCount += 1;
        },
      );

      await repository.replace(credentials);

      verify(() => tokenStore.replace(credentials)).called(1);
      expect(legacyCleanupCount, 1);
    },
  );

  test('clear removes secure credentials and legacy session once', () async {
    final MockSecureTokenStore tokenStore = MockSecureTokenStore();
    int legacyCleanupCount = 0;
    when(tokenStore.clear).thenAnswer((_) async {});
    final SecureCredentialRepository repository = SecureCredentialRepository(
      tokenStore: tokenStore,
      clearLegacyAuthSession: () async {
        legacyCleanupCount += 1;
      },
    );

    await repository.clear();

    verify(tokenStore.clear).called(1);
    expect(legacyCleanupCount, 1);
  });

  test('SecureTokenProvider reads through CredentialRepository', () async {
    final MockCredentialRepository repository = MockCredentialRepository();
    when(repository.read).thenAnswer((_) async => credentials);
    final SecureTokenProvider provider = SecureTokenProvider(repository);

    final AuthCredentials? result = await provider.getCredentials();

    expect(result, same(credentials));
    verify(repository.read).called(1);
  });

  test(
    'clear queued after conditional comparison cannot be overwritten',
    () async {
      final AuthCredentials refreshed = credentials.copyWith(
        accessToken: 'access-token-2',
        refreshToken: 'refresh-token-2',
      );
      final _BlockingSecureTokenStore tokenStore = _BlockingSecureTokenStore(
        credentials,
        blockNextReplace: true,
      );
      final SecureCredentialRepository repository = SecureCredentialRepository(
        tokenStore: tokenStore,
      );

      final Future<bool> conditionalReplace = repository.replaceIfCurrent(
        expected: credentials,
        replacement: refreshed,
      );
      await tokenStore.replaceStarted.future;

      final Future<void> clear = repository.clear();
      await Future<void>.delayed(Duration.zero);

      expect(tokenStore.credentials, same(credentials));
      tokenStore.releaseReplace.complete();
      expect(await conditionalReplace, isTrue);
      await clear;
      expect(tokenStore.credentials, isNull);
    },
  );

  test(
    'account switch queued after conditional comparison wins final write',
    () async {
      final AuthCredentials refreshed = credentials.copyWith(
        accessToken: 'account-a-access-2',
        refreshToken: 'account-a-refresh-2',
      );
      final AuthCredentials accountB = credentials.copyWith(
        accessToken: 'account-b-access-1',
        refreshToken: 'account-b-refresh-1',
      );
      final _BlockingSecureTokenStore tokenStore = _BlockingSecureTokenStore(
        credentials,
        blockNextReplace: true,
      );
      final SecureCredentialRepository repository = SecureCredentialRepository(
        tokenStore: tokenStore,
      );

      final Future<bool> conditionalReplace = repository.replaceIfCurrent(
        expected: credentials,
        replacement: refreshed,
      );
      await tokenStore.replaceStarted.future;

      final Future<void> accountSwitch = repository.replace(accountB);
      await Future<void>.delayed(Duration.zero);

      expect(tokenStore.credentials, same(credentials));
      tokenStore.releaseReplace.complete();
      expect(await conditionalReplace, isTrue);
      await accountSwitch;
      expect(tokenStore.credentials, same(accountB));
    },
  );

  test('conditional replace rejects a changed credential generation', () async {
    final AuthCredentials accountB = credentials.copyWith(
      accessToken: 'account-b-access-1',
      refreshToken: 'account-b-refresh-1',
    );
    final AuthCredentials refreshed = credentials.copyWith(
      accessToken: 'account-a-access-2',
      refreshToken: 'account-a-refresh-2',
    );
    final _BlockingSecureTokenStore tokenStore = _BlockingSecureTokenStore(
      accountB,
    );
    int legacyCleanupCount = 0;
    final SecureCredentialRepository repository = SecureCredentialRepository(
      tokenStore: tokenStore,
      clearLegacyAuthSession: () async {
        legacyCleanupCount += 1;
      },
    );

    final bool replaced = await repository.replaceIfCurrent(
      expected: credentials,
      replacement: refreshed,
    );

    expect(replaced, isFalse);
    expect(tokenStore.credentials, same(accountB));
    expect(legacyCleanupCount, 0);
  });

  test('a failed operation does not block the serialized queue', () async {
    final MockSecureTokenStore tokenStore = MockSecureTokenStore();
    when(
      () => tokenStore.replace(credentials),
    ).thenThrow(StateError('secure write failed'));
    when(tokenStore.clear).thenAnswer((_) async {});
    final SecureCredentialRepository repository = SecureCredentialRepository(
      tokenStore: tokenStore,
    );

    await expectLater(repository.replace(credentials), throwsStateError);
    await repository.clear();

    verify(tokenStore.clear).called(1);
  });
}
