import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/application/scene/scene_voice_session_binding_coordinator.dart';
import 'package:speakeasy/services/voice_chat_service.dart';

void main() {
  test('bind 会把 connected 和 error 状态分发到对应回调', () async {
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    final SceneVoiceSessionBindingCoordinator coordinator =
        const SceneVoiceSessionBindingCoordinator();
    int connectedCount = 0;
    String? errorMessage;

    final SceneVoiceSessionBinding binding = coordinator.bind(
      service: service,
      plannerModeAware: true,
      isActive: () => true,
      shouldHandleDisconnected: () => true,
      onConnected: () async {
        connectedCount++;
      },
      onError: (String message) async {
        errorMessage = message;
      },
      onDisconnected: () async {},
      onUserFinal: (String text) async {},
      onAssistantEvent: (VoiceChatTurnEvent event) async {},
    );

    service.emitConnectionState('connected');
    service.emitConnectionState('error');
    await pumpEventQueue();

    expect(connectedCount, 1);
    expect(errorMessage, '实时通话连接失败');
    await binding.connectionSubscription.cancel();
    await binding.turnEventSubscription.cancel();
  });

  test('bind 会把 userFinal 和 assistant event 分流', () async {
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    final SceneVoiceSessionBindingCoordinator coordinator =
        const SceneVoiceSessionBindingCoordinator();
    String? userFinalText;
    VoiceChatTurnEventType? assistantEventType;

    final SceneVoiceSessionBinding binding = coordinator.bind(
      service: service,
      plannerModeAware: false,
      isActive: () => true,
      shouldHandleDisconnected: () => true,
      onConnected: () async {},
      onError: (String message) async {},
      onDisconnected: () async {},
      onUserFinal: (String text) async {
        userFinalText = text;
      },
      onAssistantEvent: (VoiceChatTurnEvent event) async {
        assistantEventType = event.type;
      },
    );

    service.emitTurnEvent(
      const VoiceChatTurnEvent(
        type: VoiceChatTurnEventType.userFinal,
        text: 'hello',
      ),
    );
    service.emitTurnEvent(
      const VoiceChatTurnEvent(type: VoiceChatTurnEventType.assistantStarted),
    );
    await pumpEventQueue();

    expect(userFinalText, 'hello');
    expect(assistantEventType, VoiceChatTurnEventType.assistantStarted);
    await binding.connectionSubscription.cancel();
    await binding.turnEventSubscription.cancel();
  });

  test('bind 在 inactive 时忽略事件，且仅在允许时处理 disconnected', () async {
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    final SceneVoiceSessionBindingCoordinator coordinator =
        const SceneVoiceSessionBindingCoordinator();
    bool active = false;
    int disconnectedCount = 0;
    int connectedCount = 0;

    final SceneVoiceSessionBinding binding = coordinator.bind(
      service: service,
      plannerModeAware: false,
      isActive: () => active,
      shouldHandleDisconnected: () => active,
      onConnected: () async {
        connectedCount++;
      },
      onError: (String message) async {},
      onDisconnected: () async {
        disconnectedCount++;
      },
      onUserFinal: (String text) async {},
      onAssistantEvent: (VoiceChatTurnEvent event) async {},
    );

    service.emitConnectionState('connected');
    service.emitConnectionState('disconnected');
    await pumpEventQueue();

    active = true;
    service.emitConnectionState('connected');
    service.emitConnectionState('disconnected');
    await pumpEventQueue();

    expect(connectedCount, 1);
    expect(disconnectedCount, 1);
    await binding.connectionSubscription.cancel();
    await binding.turnEventSubscription.cancel();
  });
}

class _FakeVoiceChatService extends VoiceChatService {
  final StreamController<String> _connectionController =
      StreamController<String>.broadcast();
  final StreamController<VoiceChatTurnEvent> _turnEventController =
      StreamController<VoiceChatTurnEvent>.broadcast();

  @override
  Stream<String> get connectionStream => _connectionController.stream;

  @override
  Stream<VoiceChatTurnEvent> get turnEventStream => _turnEventController.stream;

  void emitConnectionState(String state) {
    _connectionController.add(state);
  }

  void emitTurnEvent(VoiceChatTurnEvent event) {
    _turnEventController.add(event);
  }

  @override
  void dispose() {
    _connectionController.close();
    _turnEventController.close();
    super.dispose();
  }
}
