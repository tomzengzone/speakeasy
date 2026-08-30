import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';

class SecureTokenStore {
  SecureTokenStore({
    FlutterSecureStorage? storage,
    FlutterSecureStorage? legacyStorage,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
               synchronizable: false,
             ),
             aOptions: AndroidOptions(migrateWithBackup: false),
           ),
       _legacyStorage =
           legacyStorage ?? storage ?? const FlutterSecureStorage();

  static const String _credentialsKey =
      'speakeasy.authentication.credentials.v2';
  static const String _legacyCredentialsKey =
      'speakeasy.authentication.credentials.v1';

  final FlutterSecureStorage _storage;
  final FlutterSecureStorage _legacyStorage;

  Future<AuthCredentials?> read() async {
    final String? raw = await _storage.read(key: _credentialsKey);
    if (raw != null && raw.trim().isNotEmpty) {
      return _decode(raw);
    }

    final String? legacyRaw = await _legacyStorage.read(
      key: _legacyCredentialsKey,
    );
    if (legacyRaw == null || legacyRaw.trim().isEmpty) {
      return null;
    }

    final AuthCredentials migrated = _decode(legacyRaw);
    await _storage.write(
      key: _credentialsKey,
      value: jsonEncode(migrated.toJson()),
    );
    await _legacyStorage.delete(key: _legacyCredentialsKey);
    return migrated;
  }

  AuthCredentials _decode(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid stored authentication credentials');
    }
    return AuthCredentials.fromJson(decoded.cast<String, dynamic>());
  }

  Future<void> replace(AuthCredentials credentials) async {
    await _storage.write(
      key: _credentialsKey,
      value: jsonEncode(credentials.toJson()),
    );
    await _legacyStorage.delete(key: _legacyCredentialsKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _credentialsKey);
    await _legacyStorage.delete(key: _legacyCredentialsKey);
  }
}
