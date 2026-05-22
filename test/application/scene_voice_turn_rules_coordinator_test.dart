import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/application/scene/scene_voice_turn_rules_coordinator.dart';

void main() {
  const SceneVoiceTurnRulesCoordinator coordinator =
      SceneVoiceTurnRulesCoordinator();

  test('normalizeTranscript 会折叠空白并规范化独立 i', () {
    expect(
      coordinator.normalizeTranscript('  i   want   coffee  '),
      'I want coffee',
    );
  });

  test('mergeTranscriptSegments 会合并重叠片段', () {
    expect(
      coordinator.mergeTranscriptSegments('I want', 'want coffee'),
      'I want coffee',
    );
  });

  test('stripSceneMetadataSuffix 会去掉尾部 metadata JSON', () {
    expect(
      coordinator.stripSceneMetadataSuffix(
        'Hello there {"mood":"happy","coach":"tip"}',
      ),
      'Hello there',
    );
  });

  test('packPcmChunks 会按目标大小合并 chunk', () {
    final List<Uint8List> packed = coordinator.packPcmChunks(<Uint8List>[
      Uint8List(3200),
      Uint8List(3200),
      Uint8List(1000),
    ]);

    expect(packed, hasLength(2));
    expect(packed.first.length, 6400);
    expect(packed.last.length, 1000);
  });

  test('estimateVoiceDurationSeconds 会按 16k pcm 估算秒数', () {
    expect(
      coordinator.estimateVoiceDurationSeconds(<Uint8List>[
        Uint8List(16000 * 2),
      ]),
      1,
    );
    expect(
      coordinator.estimateVoiceDurationSeconds(<Uint8List>[
        Uint8List((16000 * 2) + 1),
      ]),
      2,
    );
  });

  test('shouldIgnoreAssistantSpeakingEvent 会正确判断忽略条件', () {
    expect(
      coordinator.shouldIgnoreAssistantSpeakingEvent(
        realtimeAudioStreaming: true,
        isAiSpeaking: true,
        speaking: true,
        hasBufferedAssistantTurn: false,
      ),
      isTrue,
    );
    expect(
      coordinator.shouldIgnoreAssistantSpeakingEvent(
        realtimeAudioStreaming: true,
        isAiSpeaking: true,
        speaking: false,
        hasBufferedAssistantTurn: true,
      ),
      isFalse,
    );
  });
}
