import 'dart:async';

import 'package:speakeasy/services/voice_chat_service.dart';

class SceneVoiceSessionBinding {
  const SceneVoiceSessionBinding({
    required this.connectionSubscription,
    required this.turnEventSubscription,
  });

  final StreamSubscription<String> connectionSubscription;
  final StreamSubscription<VoiceChatTurnEvent> turnEventSubscription;
}

class SceneVoiceSessionBindingCoordinator {
  const SceneVoiceSessionBindingCoordinator();

  SceneVoiceSessionBinding bind({
    required VoiceChatService service,
    required bool plannerModeAware,
    required bool Function() isActive,
    required bool Function() shouldHandleDisconnected,
    required Future<void> Function() onConnected,
    required Future<void> Function(String message) onError,
    required Future<void> Function() onDisconnected,
    required Future<void> Function(String text) onUserFinal,
    required Future<void> Function(VoiceChatTurnEvent event) onAssistantEvent,
  }) {
    final StreamSubscription<String> connectionSubscription = service
        .connectionStream
        .listen((String state) async {
          if (!isActive()) {
            return;
          }
          if (state == 'connected') {
            await onConnected();
            return;
          }
          if (state == 'error') {
            await onError(plannerModeAware ? '实时通话连接失败' : '语音对话连接失败');
            return;
          }
          if (state == 'disconnected' && shouldHandleDisconnected()) {
            await onDisconnected();
          }
        });

    final StreamSubscription<VoiceChatTurnEvent> turnEventSubscription = service
        .turnEventStream
        .listen((VoiceChatTurnEvent event) async {
          if (!isActive()) {
            return;
          }
          if (event.type == VoiceChatTurnEventType.userFinal) {
            await onUserFinal(event.text);
            return;
          }
          await onAssistantEvent(event);
        });

    return SceneVoiceSessionBinding(
      connectionSubscription: connectionSubscription,
      turnEventSubscription: turnEventSubscription,
    );
  }
}
