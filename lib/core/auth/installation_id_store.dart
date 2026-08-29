import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef InstallationIdGenerator = String Function();

class InstallationIdStore {
  InstallationIdStore({
    FlutterSecureStorage? storage,
    InstallationIdGenerator? generateId,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _generateId = generateId ?? _generateUuidV4;

  static const String storageKey = 'speakeasy.authentication.installation.v1';
  static final RegExp _validId = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final FlutterSecureStorage _storage;
  final InstallationIdGenerator _generateId;
  Future<String>? _inFlight;

  Future<String> readOrCreate() {
    final Future<String>? inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final Future<String> operation = _readOrCreate();
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
  }

  Future<String> _readOrCreate() async {
    final String existing = (await _storage.read(key: storageKey) ?? '')
        .trim()
        .toLowerCase();
    if (_validId.hasMatch(existing)) return existing;

    final String generated = _generateId().trim().toLowerCase();
    if (!_validId.hasMatch(generated)) {
      throw StateError('Installation id generator returned an invalid UUID v4');
    }
    await _storage.write(key: storageKey, value: generated);
    return generated;
  }

  static String _generateUuidV4() {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final String hex = bytes
        .map((int value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
