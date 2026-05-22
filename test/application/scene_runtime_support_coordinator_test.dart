import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/application/scene/scene_runtime_support_coordinator.dart';
import 'package:speakeasy/models/storage_models.dart';

void main() {
  test('loadToken 会委托 gateway 获取 token', () async {
    final _FakeSceneRuntimeSupportGateway gateway =
        _FakeSceneRuntimeSupportGateway()..token = 'scene-token';
    final SceneRuntimeSupportCoordinator coordinator =
        SceneRuntimeSupportCoordinator(gateway: gateway);

    final String? token = await coordinator.loadToken();

    expect(token, 'scene-token');
    expect(gateway.getTokenCallCount, 1);
  });

  test('saveConversationHistory 会委托 gateway 持久化历史', () async {
    final _FakeSceneRuntimeSupportGateway gateway =
        _FakeSceneRuntimeSupportGateway();
    final SceneRuntimeSupportCoordinator coordinator =
        SceneRuntimeSupportCoordinator(gateway: gateway);
    const ConversationHistoryStorageModel history =
        ConversationHistoryStorageModel(
          sessionId: 'session-1',
          npcName: 'Alex',
          messages: <ConversationHistoryTurnStorageModel>[
            ConversationHistoryTurnStorageModel(role: 'user', text: 'Hi'),
          ],
        );

    await coordinator.saveConversationHistory(history);

    expect(gateway.savedHistory, same(history));
  });
}

class _FakeSceneRuntimeSupportGateway implements SceneRuntimeSupportGateway {
  String? token;
  int getTokenCallCount = 0;
  ConversationHistoryStorageModel? savedHistory;

  @override
  Future<String?> getToken() async {
    getTokenCallCount++;
    return token;
  }

  @override
  Future<void> saveConversationHistory(
    ConversationHistoryStorageModel history,
  ) async {
    savedHistory = history;
  }
}
