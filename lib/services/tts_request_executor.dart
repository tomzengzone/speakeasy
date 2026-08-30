import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/authenticated_request_executor.dart';

typedef BackendTtsAudioRequest =
    Future<Uint8List> Function(
      String text, {
      String? voice,
      Duration timeout,
      RequestCancellationToken? cancellation,
    });

class TtsRequestExecutor {
  TtsRequestExecutor({BackendTtsAudioRequest? request})
    : _request = request ?? ApiClient.tts;

  final BackendTtsAudioRequest _request;

  Future<Uint8List> request(
    String text, {
    required String voice,
    int maxAttempts = 2,
    required Duration requestTimeout,
    RequestCancellationToken? cancellation,
  }) async {
    final int safeMaxAttempts = math.max(1, maxAttempts);
    Object? lastError;
    for (int attempt = 1; attempt <= safeMaxAttempts; attempt += 1) {
      cancellation?.throwIfCancelled();
      try {
        final Uint8List audioBytes = await _request(
          text,
          voice: voice,
          timeout: requestTimeout,
          cancellation: cancellation,
        );
        if (audioBytes.isNotEmpty) {
          return audioBytes;
        }
      } on SessionSecurityFailure {
        rethrow;
      } on RequestCancelledException {
        rethrow;
      } catch (error) {
        lastError = error;
      }
      if (attempt < safeMaxAttempts) {
        await _delayUnlessCancelled(
          const Duration(milliseconds: 350),
          cancellation,
        );
      }
    }
    if (lastError != null) {
      throw lastError;
    }
    return Uint8List(0);
  }

  Future<void> _delayUnlessCancelled(
    Duration duration,
    RequestCancellationToken? cancellation,
  ) {
    if (cancellation == null) {
      return Future<void>.delayed(duration);
    }
    cancellation.throwIfCancelled();
    return Future.any<void>(<Future<void>>[
      Future<void>.delayed(duration),
      cancellation.whenCancelled.then<void>((_) {
        throw const RequestCancelledException();
      }),
    ]);
  }
}
