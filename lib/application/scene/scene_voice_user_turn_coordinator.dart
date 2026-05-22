import 'dart:typed_data';

import 'package:speakeasy/application/scene/scene_voice_turn_rules_coordinator.dart';

enum SceneVoiceUserTurnAction { appendLocalMessage, sendViaPlanner }

class PreparedSceneVoiceUserTurn {
  const PreparedSceneVoiceUserTurn({
    required this.normalizedText,
    required this.userVoiceChunks,
    required this.resolvedVoiceDuration,
    required this.shouldSendViaPlanner,
  });

  final String normalizedText;
  final List<Uint8List> userVoiceChunks;
  final int resolvedVoiceDuration;
  final bool shouldSendViaPlanner;
}

class ResolvedSceneVoiceUserTurn {
  const ResolvedSceneVoiceUserTurn({
    required this.normalizedText,
    required this.resolvedVoiceDuration,
    required this.action,
    this.audioPath,
  });

  final String normalizedText;
  final int resolvedVoiceDuration;
  final SceneVoiceUserTurnAction action;
  final String? audioPath;
}

abstract class SceneVoiceUserTurnAudioGateway {
  Future<String?> persistChunksAsWav(
    List<Uint8List> chunks, {
    required int sampleRate,
    required String prefix,
  });
}

class SceneVoiceUserTurnCoordinator {
  const SceneVoiceUserTurnCoordinator({
    SceneVoiceTurnRulesCoordinator rulesCoordinator =
        const SceneVoiceTurnRulesCoordinator(),
  }) : _rulesCoordinator = rulesCoordinator;

  final SceneVoiceTurnRulesCoordinator _rulesCoordinator;

  PreparedSceneVoiceUserTurn? prepareUserFinalTurn({
    required String text,
    required bool plannerModeAware,
    required bool plannerModeActive,
    required List<Uint8List> pendingVoiceChunks,
    required int pendingVoiceMessageDuration,
  }) {
    final String normalizedText = plannerModeAware
        ? _rulesCoordinator.normalizeTranscript(text)
        : text.trim();
    if (normalizedText.isEmpty) {
      return null;
    }

    final List<Uint8List> userVoiceChunks = List<Uint8List>.from(
      pendingVoiceChunks,
    );
    final int resolvedVoiceDuration = userVoiceChunks.isEmpty
        ? pendingVoiceMessageDuration
        : _rulesCoordinator.estimateVoiceDurationSeconds(userVoiceChunks);

    return PreparedSceneVoiceUserTurn(
      normalizedText: normalizedText,
      userVoiceChunks: userVoiceChunks,
      resolvedVoiceDuration: resolvedVoiceDuration,
      shouldSendViaPlanner: plannerModeAware && plannerModeActive,
    );
  }

  Future<ResolvedSceneVoiceUserTurn> resolvePreparedTurn({
    required PreparedSceneVoiceUserTurn preparedTurn,
    required SceneVoiceUserTurnAudioGateway audioGateway,
  }) async {
    String? audioPath;
    if (preparedTurn.userVoiceChunks.isNotEmpty) {
      try {
        audioPath = await audioGateway.persistChunksAsWav(
          preparedTurn.userVoiceChunks,
          sampleRate: 16000,
          prefix: 'user_rt',
        );
      } catch (_) {
        audioPath = null;
      }
    }

    return ResolvedSceneVoiceUserTurn(
      normalizedText: preparedTurn.normalizedText,
      resolvedVoiceDuration: preparedTurn.resolvedVoiceDuration,
      audioPath: audioPath,
      action: preparedTurn.shouldSendViaPlanner
          ? SceneVoiceUserTurnAction.sendViaPlanner
          : SceneVoiceUserTurnAction.appendLocalMessage,
    );
  }
}
