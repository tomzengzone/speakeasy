import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/core/auth/installation_id_store.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'creates one opaque installation id and reuses it across sessions',
    () async {
      const String generated = '123e4567-e89b-42d3-a456-426614174000';
      final InstallationIdStore first = InstallationIdStore(
        generateId: () => generated,
      );

      expect(await first.readOrCreate(), generated);
      expect(await first.readOrCreate(), generated);
      expect(await InstallationIdStore().readOrCreate(), generated);
    },
  );

  test('replaces malformed stored values instead of sending them', () async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      InstallationIdStore.storageKey: 'raw user supplied value',
    });
    const String replacement = '123e4567-e89b-42d3-a456-426614174001';

    expect(
      await InstallationIdStore(generateId: () => replacement).readOrCreate(),
      replacement,
    );
  });
}
