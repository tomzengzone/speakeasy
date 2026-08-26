import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/credential_repository.dart';
import 'package:speakeasy/core/auth/secure_token_store.dart';
import 'package:speakeasy/core/auth/token_provider.dart';

class MockSecureTokenStore extends Mock implements SecureTokenStore {}

class MockCredentialRepository extends Mock implements CredentialRepository {}

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
}
