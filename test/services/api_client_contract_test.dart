import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';

void main() {
  test('generated OpenAPI Dart boundary pins the canonical hash', () {
    final Map<String, dynamic> manifest =
        jsonDecode(
              File(
                'docs/architecture/openapi/dart-client-drift-manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final String marker = File(
      'lib/generated/api/.openapi-sha256',
    ).readAsStringSync().trim();

    expect(manifest['mode'], 'generated_client_drift');
    expect(SpeakeasyApiContract.openApiSha256, marker);
    expect(manifest['openapi_sha256'], marker);
  });

  test('generated path registry covers MVP backend active endpoints', () {
    expect(
      SpeakeasyApiContract.pathTemplates,
      containsAll(<String>[
        '/auth/login/phone',
        '/auth/login/apple',
        '/auth/login/wechat',
        '/auth/refresh',
        '/user/me',
        '/user/deletion-status',
        '/onboarding/assessment',
        '/scenarios',
        '/practice/sessions',
        '/expressions/queue',
        '/learning/evidence',
        '/learning/report/summary',
        '/membership/boundary',
        '/membership/android/purchase',
        '/membership/android/restore',
        '/offline-content/status',
        '/achievements/status',
        '/ai/transcribe',
        '/ai/tts',
        '/ai/coach-turn',
        '/ai/feedback',
        '/ai/pronunciation',
      ]),
    );
  });

  test('ApiClient no longer references pre-OpenAPI active MVP paths', () {
    final String source = File(
      'lib/services/api_client.dart',
    ).readAsStringSync();

    for (final String oldPath in <String>[
      '/auth/sms/send',
      '/auth/sms/verify',
      '/auth/test-login',
      '/auth/apple',
      '/auth/wechat',
      '/ai/tts/cache',
      '/ai/score',
      '/ai/interview/coach-turn',
    ]) {
      expect(source, isNot(contains(oldPath)), reason: oldPath);
    }

    expect(source, contains('SpeakeasyApiPaths.authLoginPhone'));
    expect(source, contains('SpeakeasyApiPaths.aiPronunciation'));
    expect(source, contains('SpeakeasyApiPaths.userMe'));
  });

  test('legacy handwritten paths are documented as drift exceptions', () {
    final String source = File(
      'lib/services/api_client.dart',
    ).readAsStringSync();
    final Map<String, dynamic> manifest =
        jsonDecode(
              File(
                'docs/architecture/openapi/dart-client-drift-manifest.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final Map<String, dynamic> exceptions =
        manifest['handwritten_client_exceptions'] as Map<String, dynamic>;

    for (final MapEntry<String, dynamic> entry in exceptions.entries) {
      expect(source, contains(entry.key), reason: entry.key);
      expect((entry.value as String).trim(), isNotEmpty, reason: entry.key);
    }
  });
}
