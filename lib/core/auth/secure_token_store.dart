import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:speakeasy/core/auth/auth_credentials.dart';

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
            aOptions: AndroidOptions(
              migrateWithBackup: false,
              storageNamespace: 'speakeasy.authentication',
            ),
          );

  static const String _credentialsKey =
      'speakeasy.authentication.credentials.v1';

  final FlutterSecureStorage _storage;

  Future<AuthCredentials?> read() async {
    final String? raw = await _storage.read(key: _credentialsKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid stored authentication credentials');
    }
    return AuthCredentials.fromJson(decoded.cast<String, dynamic>());
  }

  Future<void> replace(AuthCredentials credentials) {
    return _storage.write(
      key: _credentialsKey,
      value: jsonEncode(credentials.toJson()),
    );
  }

  Future<void> clear() {
    return _storage.delete(key: _credentialsKey);
  }
}
