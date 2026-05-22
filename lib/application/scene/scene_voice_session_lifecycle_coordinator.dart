import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:speakeasy/services/voice_chat_service.dart';

class SceneVoiceSessionLifecycleCoordinator {
  const SceneVoiceSessionLifecycleCoordinator();

  Future<void> disposeSession({
    required VoiceChatService? service,
    required StreamSubscription<String>? connectionSubscription,
    required StreamSubscription<VoiceChatTurnEvent>? turnEventSubscription,
    Future<void> Function()? stopPlayback,
    Future<void> Function()? stopStreamRecording,
    bool disconnectService = false,
  }) async {
    if (stopPlayback != null) {
      try {
        await stopPlayback();
      } catch (error) {
        debugPrint('[Voice] Stop playback error: $error');
      }
    }
    if (stopStreamRecording != null) {
      try {
        await stopStreamRecording();
      } catch (error) {
        debugPrint('[Voice] Stop stream recording error: $error');
      }
    }

    await connectionSubscription?.cancel();
    await turnEventSubscription?.cancel();

    if (disconnectService) {
      try {
        await service?.disconnect();
      } catch (error) {
        debugPrint('[Voice] Disconnect service error: $error');
      }
    }

    service?.dispose();
  }
}
