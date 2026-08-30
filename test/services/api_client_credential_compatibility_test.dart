import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/storage_service.dart';

import '../support/hive_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'speakeasy_api_credentials_',
    );
    await StorageService.instance.init(
      hivePath: hiveDirectory.path,
      migrateFromSharedPreferences: false,
    );
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await StorageService.instance.clearAuthSession();
  });

  tearDownAll(() async {
    await deleteHiveTestDirectory(hiveDirectory);
  });

  AuthCredentials credentials() {
    return AuthCredentials(
      accessToken: 'secure-access-token',
      refreshToken: 'secure-refresh-token',
      expiresAt: DateTime.utc(2026, 8, 27),
    );
  }

  test('ApiClient.clearToken clears secure and legacy credentials', () async {
    await ApiClient.saveCredentials(credentials());
    await StorageService.instance.saveAuthSession(
      const AuthSessionStorageModel(token: 'legacy-access-token'),
    );

    await ApiClient.clearToken();

    expect(await ApiClient.getCredentials(), isNull);
    expect(StorageService.instance.getAuthSession(), isNull);
  });

  test('ApiClient.getToken prefers the complete secure credentials', () async {
    await ApiClient.saveCredentials(credentials());
    await StorageService.instance.saveAuthSession(
      const AuthSessionStorageModel(token: 'legacy-access-token'),
    );

    expect(await ApiClient.getToken(), 'secure-access-token');
  });

  test('ApiClient.getToken rejects a legacy-only access token', () async {
    await StorageService.instance.saveAuthSession(
      const AuthSessionStorageModel(token: 'legacy-access-token'),
    );

    expect(await ApiClient.getToken(), isNull);
  });
}
