import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class SceneVoiceTurnRulesCoordinator {
  const SceneVoiceTurnRulesCoordinator();

  String normalizeTranscript(String transcript) {
    return transcript
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\b(i)\b'), 'I');
  }

  String mergeTranscriptSegments(String base, String incoming) {
    final String normalizedBase = normalizeTranscript(base);
    final String normalizedIncoming = normalizeTranscript(incoming);
    if (normalizedBase.isEmpty) {
      return normalizedIncoming;
    }
    if (normalizedIncoming.isEmpty) {
      return normalizedBase;
    }
    if (normalizedIncoming == normalizedBase ||
        normalizedIncoming.startsWith(normalizedBase)) {
      return normalizedIncoming;
    }
    if (normalizedBase.startsWith(normalizedIncoming)) {
      return normalizedBase;
    }
    final List<String> baseWords = normalizedBase.split(' ');
    final List<String> incomingWords = normalizedIncoming.split(' ');
    final int maxOverlap = math.min(baseWords.length, incomingWords.length);
    for (int overlap = maxOverlap; overlap >= 1; overlap--) {
      final List<String> baseTail = baseWords.sublist(
        baseWords.length - overlap,
      );
      final List<String> incomingHead = incomingWords.sublist(0, overlap);
      if (listEquals(baseTail, incomingHead)) {
        return <String>[
          ...baseWords,
          ...incomingWords.sublist(overlap),
        ].join(' ');
      }
    }
    return '$normalizedBase $normalizedIncoming';
  }

  String stripSceneMetadataSuffix(String rawText) {
    final String trimmed = rawText.trim();
    final RegExp metadataPattern = RegExp(
      r'\{\s*"(?:mood|coach|event)"[\s\S]*$',
      multiLine: true,
    );
    final RegExpMatch? match = metadataPattern.firstMatch(trimmed);
    if (match == null) {
      return trimmed;
    }
    final String visible = trimmed.substring(0, match.start).trim();
    return visible.isEmpty ? trimmed : visible;
  }

  List<Uint8List> packPcmChunks(List<Uint8List> chunks) {
    const int targetChunkBytes = 6400;
    final List<Uint8List> packedChunks = <Uint8List>[];
    final BytesBuilder builder = BytesBuilder(copy: false);
    int bufferedBytes = 0;

    for (final Uint8List chunk in chunks) {
      if (chunk.isEmpty) {
        continue;
      }
      builder.add(chunk);
      bufferedBytes += chunk.length;
      if (bufferedBytes >= targetChunkBytes) {
        packedChunks.add(builder.takeBytes());
        bufferedBytes = 0;
      }
    }

    if (bufferedBytes > 0) {
      packedChunks.add(builder.takeBytes());
    }
    return packedChunks;
  }

  int estimateVoiceDurationSeconds(List<Uint8List> chunks) {
    const double bytesPerSecond = 16000 * 2;
    final int totalBytes = chunks.fold<int>(
      0,
      (int sum, Uint8List chunk) => sum + chunk.length,
    );
    return totalBytes <= 0 ? 1 : (totalBytes / bytesPerSecond).ceil();
  }

  bool shouldIgnoreAssistantSpeakingEvent({
    required bool realtimeAudioStreaming,
    required bool isAiSpeaking,
    required bool speaking,
    required bool hasBufferedAssistantTurn,
  }) {
    return realtimeAudioStreaming &&
        isAiSpeaking == speaking &&
        !(!speaking && hasBufferedAssistantTurn);
  }
}
