import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/application/scene/scene_voice_user_turn_coordinator.dart';

void main() {
  const SceneVoiceUserTurnCoordinator coordinator =
      SceneVoiceUserTurnCoordinator();

  test('prepareUserFinalTurn 会规范化 transcript 并计算 planner 分流', () {
    final PreparedSceneVoiceUserTurn? prepared = coordinator
        .prepareUserFinalTurn(
          text: '  i   need help ',
          plannerModeAware: true,
          plannerModeActive: true,
          pendingVoiceChunks: <Uint8List>[Uint8List(32000)],
          pendingVoiceMessageDuration: 3,
        );

    expect(prepared, isNotNull);
    expect(prepared!.normalizedText, 'I need help');
    expect(prepared.resolvedVoiceDuration, 1);
    expect(prepared.shouldSendViaPlanner, isTrue);
  });

  test('prepareUserFinalTurn 在非 planner 路径保留 trim 后文本', () {
    final PreparedSceneVoiceUserTurn? prepared = coordinator
        .prepareUserFinalTurn(
          text: ' hello there ',
          plannerModeAware: false,
          plannerModeActive: true,
          pendingVoiceChunks: const <Uint8List>[],
          pendingVoiceMessageDuration: 5,
        );

    expect(prepared, isNotNull);
    expect(prepared!.normalizedText, 'hello there');
    expect(prepared.resolvedVoiceDuration, 5);
    expect(prepared.shouldSendViaPlanner, isFalse);
  });

  test('prepareUserFinalTurn 在空文本时返回 null', () {
    expect(
      coordinator.prepareUserFinalTurn(
        text: '   ',
        plannerModeAware: true,
        plannerModeActive: true,
        pendingVoiceChunks: const <Uint8List>[],
        pendingVoiceMessageDuration: 3,
      ),
      isNull,
    );
  });

  test('resolvePreparedTurn 会持久化音频并返回 planner 动作', () async {
    final _FakeSceneVoiceUserTurnAudioGateway gateway =
        _FakeSceneVoiceUserTurnAudioGateway()..audioPath = '/tmp/user.wav';
    final PreparedSceneVoiceUserTurn prepared = coordinator
        .prepareUserFinalTurn(
          text: 'i need help',
          plannerModeAware: true,
          plannerModeActive: true,
          pendingVoiceChunks: <Uint8List>[Uint8List(3200)],
          pendingVoiceMessageDuration: 3,
        )!;

    final ResolvedSceneVoiceUserTurn resolved = await coordinator
        .resolvePreparedTurn(preparedTurn: prepared, audioGateway: gateway);

    expect(resolved.normalizedText, 'I need help');
    expect(resolved.audioPath, '/tmp/user.wav');
    expect(resolved.action, SceneVoiceUserTurnAction.sendViaPlanner);
    expect(gateway.persistCallCount, 1);
  });

  test('resolvePreparedTurn 在持久化失败时回退为 null audioPath', () async {
    final _FakeSceneVoiceUserTurnAudioGateway gateway =
        _FakeSceneVoiceUserTurnAudioGateway()
          ..error = StateError('persist failed');
    final PreparedSceneVoiceUserTurn prepared = coordinator
        .prepareUserFinalTurn(
          text: 'hello',
          plannerModeAware: false,
          plannerModeActive: false,
          pendingVoiceChunks: <Uint8List>[Uint8List(3200)],
          pendingVoiceMessageDuration: 3,
        )!;

    final ResolvedSceneVoiceUserTurn resolved = await coordinator
        .resolvePreparedTurn(preparedTurn: prepared, audioGateway: gateway);

    expect(resolved.audioPath, isNull);
    expect(resolved.action, SceneVoiceUserTurnAction.appendLocalMessage);
  });
}

class _FakeSceneVoiceUserTurnAudioGateway
    implements SceneVoiceUserTurnAudioGateway {
  String? audioPath;
  Object? error;
  int persistCallCount = 0;

  @override
  Future<String?> persistChunksAsWav(
    List<Uint8List> chunks, {
    required int sampleRate,
    required String prefix,
  }) async {
    persistCallCount++;
    if (error != null) {
      throw error!;
    }
    return audioPath;
  }
}
