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

  test('resolvePreparedTurn does not persist local WAV and returns planner action', () {
    final PreparedSceneVoiceUserTurn prepared = coordinator
        .prepareUserFinalTurn(
          text: 'i need help',
          plannerModeAware: true,
          plannerModeActive: true,
          pendingVoiceChunks: <Uint8List>[Uint8List(3200)],
          pendingVoiceMessageDuration: 3,
        )!;

    final ResolvedSceneVoiceUserTurn resolved = coordinator
        .resolvePreparedTurn(preparedTurn: prepared);

    expect(resolved.normalizedText, 'I need help');
    expect(resolved.action, SceneVoiceUserTurnAction.sendViaPlanner);
  });

  test('resolvePreparedTurn no longer depends on audio persistence failures', () {
    final PreparedSceneVoiceUserTurn prepared = coordinator
        .prepareUserFinalTurn(
          text: 'hello',
          plannerModeAware: false,
          plannerModeActive: false,
          pendingVoiceChunks: <Uint8List>[Uint8List(3200)],
          pendingVoiceMessageDuration: 3,
        )!;

    final ResolvedSceneVoiceUserTurn resolved = coordinator
        .resolvePreparedTurn(preparedTurn: prepared);

    expect(resolved.action, SceneVoiceUserTurnAction.appendLocalMessage);
  });
}
