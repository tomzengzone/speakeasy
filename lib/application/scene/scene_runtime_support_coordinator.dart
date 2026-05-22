import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/storage_service.dart';

abstract class SceneRuntimeSupportGateway {
  Future<String?> getToken();

  Future<void> saveConversationHistory(ConversationHistoryStorageModel history);
}

class DefaultSceneRuntimeSupportGateway implements SceneRuntimeSupportGateway {
  const DefaultSceneRuntimeSupportGateway();

  @override
  Future<String?> getToken() {
    return ApiClient.getToken();
  }

  @override
  Future<void> saveConversationHistory(
    ConversationHistoryStorageModel history,
  ) {
    return StorageService.instance.saveConversationHistory(history);
  }
}

class SceneRuntimeSupportCoordinator {
  const SceneRuntimeSupportCoordinator({
    SceneRuntimeSupportGateway gateway =
        const DefaultSceneRuntimeSupportGateway(),
  }) : _gateway = gateway;

  final SceneRuntimeSupportGateway _gateway;

  Future<String?> loadToken() {
    return _gateway.getToken();
  }

  Future<void> saveConversationHistory(
    ConversationHistoryStorageModel history,
  ) {
    return _gateway.saveConversationHistory(history);
  }
}
