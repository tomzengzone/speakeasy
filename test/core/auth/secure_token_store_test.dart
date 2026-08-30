import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/secure_token_store.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late SecureTokenStore tokenStore;

  setUp(() {
    storage = MockFlutterSecureStorage();
    tokenStore = SecureTokenStore(storage: storage);
  });

  test(
    'replace persists the rotated credential set in one encrypted write',
    () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => storage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await tokenStore.replace(
        AuthCredentials(
          accessToken: 'access-token-2',
          refreshToken: 'refresh-token-2',
          expiresAt: DateTime.parse('2026-08-27T00:00:00Z'),
        ),
      );

      final List<dynamic> captured = verify(
        () => storage.write(
          key: any(named: 'key'),
          value: captureAny(named: 'value'),
        ),
      ).captured;
      final Map<String, dynamic> stored =
          jsonDecode(captured.single as String) as Map<String, dynamic>;
      expect(stored['accessToken'], 'access-token-2');
      expect(stored['refreshToken'], 'refresh-token-2');
      expect(stored['expiresAt'], '2026-08-27T00:00:00.000Z');
    },
  );

  test('read restores the complete credential set', () async {
    when(() => storage.read(key: any(named: 'key'))).thenAnswer(
      (_) async => jsonEncode(<String, dynamic>{
        'accessToken': 'access-token',
        'refreshToken': 'refresh-token',
        'expiresAt': '2026-08-27T00:00:00Z',
      }),
    );

    final AuthCredentials? credentials = await tokenStore.read();

    expect(credentials, isNotNull);
    expect(credentials!.accessToken, 'access-token');
    expect(credentials.refreshToken, 'refresh-token');
  });

  test('read migrates v1 credentials before deleting the old item', () async {
    final MockFlutterSecureStorage currentStorage = MockFlutterSecureStorage();
    final MockFlutterSecureStorage legacyStorage = MockFlutterSecureStorage();
    final SecureTokenStore migratingStore = SecureTokenStore(
      storage: currentStorage,
      legacyStorage: legacyStorage,
    );
    when(
      () => currentStorage.read(key: any(named: 'key')),
    ).thenAnswer((_) async => null);
    when(() => legacyStorage.read(key: any(named: 'key'))).thenAnswer(
      (_) async => jsonEncode(<String, dynamic>{
        'accessToken': 'legacy-access-token',
        'refreshToken': 'legacy-refresh-token',
        'expiresAt': '2026-08-27T00:00:00Z',
      }),
    );
    when(
      () => currentStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => legacyStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async {});

    final AuthCredentials? credentials = await migratingStore.read();

    expect(credentials!.accessToken, 'legacy-access-token');
    verifyInOrder(<dynamic Function()>[
      () => currentStorage.read(key: 'speakeasy.authentication.credentials.v2'),
      () => legacyStorage.read(key: 'speakeasy.authentication.credentials.v1'),
      () => currentStorage.write(
        key: 'speakeasy.authentication.credentials.v2',
        value: any(named: 'value'),
      ),
      () =>
          legacyStorage.delete(key: 'speakeasy.authentication.credentials.v1'),
    ]);
  });
}
