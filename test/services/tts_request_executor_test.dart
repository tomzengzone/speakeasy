import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/authenticated_request_executor.dart';
import 'package:speakeasy/services/tts_request_executor.dart';

void main() {
  test(
    'terminal authentication failure is propagated without TTS retry',
    () async {
      int calls = 0;
      final TtsRequestExecutor executor = TtsRequestExecutor(
        request:
            (
              String text, {
              String? voice,
              Duration timeout = const Duration(seconds: 20),
              RequestCancellationToken? cancellation,
            }) async {
              calls += 1;
              throw const SessionSecurityFailure(
                reason: SessionSecurityReason.sessionRevoked,
                backendCode: 'SESSION_REVOKED',
                userMessage: '请重新登录',
              );
            },
      );

      await expectLater(
        executor.request(
          'hello',
          voice: 'Cherry',
          maxAttempts: 3,
          requestTimeout: const Duration(seconds: 1),
        ),
        throwsA(
          isA<SessionSecurityFailure>().having(
            (SessionSecurityFailure failure) => failure.backendCode,
            'backendCode',
            'SESSION_REVOKED',
          ),
        ),
      );
      expect(calls, 1);
    },
  );

  test('ordinary TTS transport error keeps the bounded retry policy', () async {
    int calls = 0;
    final TtsRequestExecutor executor = TtsRequestExecutor(
      request:
          (
            String text, {
            String? voice,
            Duration timeout = const Duration(seconds: 20),
            RequestCancellationToken? cancellation,
          }) async {
            calls += 1;
            if (calls == 1) throw Exception('temporary TTS failure');
            return Uint8List.fromList(<int>[1, 2, 3]);
          },
    );

    final Uint8List bytes = await executor.request(
      'hello',
      voice: 'Cherry',
      requestTimeout: const Duration(seconds: 1),
    );

    expect(bytes, <int>[1, 2, 3]);
    expect(calls, 2);
  });
}
