import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/application/scene/scene_voice_session_lifecycle_coordinator.dart';
import 'package:speakeasy/services/voice_chat_service.dart';

void main() {
  test('disposeSession 会停止播放 取消订阅并释放 service', () async {
    final SceneVoiceSessionLifecycleCoordinator coordinator =
        const SceneVoiceSessionLifecycleCoordinator();
    final _FakeVoiceChatService service = _FakeVoiceChatService();
    int playbackStopCount = 0;
    int streamStopCount = 0;
    int connectionCancelCount = 0;
    int turnEventCancelCount = 0;
    final StreamSubscription<String> connectionSubscription =
        StreamController<String>.broadcast(
          onCancel: () => connectionCancelCount++,
        ).stream.listen((_) {});
    final StreamSubscription<VoiceChatTurnEvent> turnEventSubscription =
        StreamController<VoiceChatTurnEvent>.broadcast(
          onCancel: () => turnEventCancelCount++,
        ).stream.listen((_) {});

    await coordinator.disposeSession(
      service: service,
      connectionSubscription: connectionSubscription,
      turnEventSubscription: turnEventSubscription,
      stopPlayback: () async {
        playbackStopCount++;
      },
      stopStreamRecording: () async {
        streamStopCount++;
      },
    );

    expect(playbackStopCount, 1);
    expect(streamStopCount, 1);
    expect(connectionCancelCount, 1);
    expect(turnEventCancelCount, 1);
    expect(service.disconnectCallCount, 0);
    expect(service.disposeCallCount, 1);
  });

  test('disposeSession 在要求断连时会先 disconnect 再 dispose', () async {
    final SceneVoiceSessionLifecycleCoordinator coordinator =
        const SceneVoiceSessionLifecycleCoordinator();
    final _FakeVoiceChatService service = _FakeVoiceChatService();

    await coordinator.disposeSession(
      service: service,
      connectionSubscription: null,
      turnEventSubscription: null,
      disconnectService: true,
    );

    expect(service.disconnectCallCount, 1);
    expect(service.disposeCallCount, 1);
  });
}

class _FakeVoiceChatService extends VoiceChatService {
  int disconnectCallCount = 0;
  int disposeCallCount = 0;

  @override
  Future<void> disconnect() async {
    disconnectCallCount++;
  }

  @override
  void dispose() {
    disposeCallCount++;
    super.dispose();
  }
}
