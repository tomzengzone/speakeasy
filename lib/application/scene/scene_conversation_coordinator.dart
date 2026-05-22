import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/app_session.dart';

typedef SendSceneMessageAction =
    Future<SceneReply> Function({
      required String sessionId,
      required String userText,
      required SceneDraft draft,
      required List<SceneHistoryTurn> history,
    });

class SceneTurnMetaResult {
  const SceneTurnMetaResult({
    required this.summary,
    required this.coach,
    required this.event,
    required this.turnContract,
    required this.sceneState,
  });

  final String summary;
  final String coach;
  final String event;
  final SceneTurnContract? turnContract;
  final SceneStateSnapshot? sceneState;
}

abstract class SceneConversationRemoteApi {
  Future<Map<String, dynamic>> generateSceneTurnMeta({
    required SceneDraft draft,
    required List<Map<String, dynamic>> history,
    required String assistantText,
    Map<String, dynamic>? sceneState,
  });
}

class ApiClientSceneConversationRemoteApi
    implements SceneConversationRemoteApi {
  const ApiClientSceneConversationRemoteApi();

  @override
  Future<Map<String, dynamic>> generateSceneTurnMeta({
    required SceneDraft draft,
    required List<Map<String, dynamic>> history,
    required String assistantText,
    Map<String, dynamic>? sceneState,
  }) {
    return ApiClient.generateSceneTurnMeta(
      draft: draft,
      history: history,
      assistantText: assistantText,
      sceneState: sceneState,
    );
  }
}

class SceneConversationCoordinator {
  const SceneConversationCoordinator({
    SceneConversationRemoteApi remoteApi =
        const ApiClientSceneConversationRemoteApi(),
  }) : _remoteApi = remoteApi;

  final SceneConversationRemoteApi _remoteApi;

  Future<SceneReply> sendMessageWithRecovery({
    required String sessionId,
    required Future<String> Function() recreateSessionId,
    required bool Function(Object error) isSessionMissingError,
    required SendSceneMessageAction sendSceneMessage,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) async {
    String activeSessionId = sessionId.trim();
    if (activeSessionId.isEmpty) {
      activeSessionId = await recreateSessionId();
    }
    try {
      return await sendSceneMessage(
        sessionId: activeSessionId,
        userText: userText,
        draft: draft,
        history: history,
      );
    } catch (error) {
      if (!isSessionMissingError(error)) {
        rethrow;
      }
      final String recoveredSessionId = await recreateSessionId();
      return sendSceneMessage(
        sessionId: recoveredSessionId,
        userText: userText,
        draft: draft,
        history: history,
      );
    }
  }

  Future<SceneTurnMetaResult> generateTurnMeta({
    required SceneDraft draft,
    required List<Map<String, dynamic>> history,
    required String assistantText,
    Map<String, dynamic>? sceneState,
  }) async {
    final Map<String, dynamic> meta = await _remoteApi.generateSceneTurnMeta(
      draft: draft,
      history: history,
      assistantText: assistantText,
      sceneState: sceneState,
    );
    return SceneTurnMetaResult(
      summary: (meta['summary'] as String? ?? meta['mood'] as String? ?? '')
          .trim(),
      coach: (meta['coach'] as String? ?? '').trim(),
      event: (meta['event'] as String? ?? '').trim(),
      turnContract: parseSceneTurnContract(meta['turnContract']),
      sceneState: parseSceneStateSnapshot(meta['sceneState']),
    );
  }

  SceneTurnContract? parseSceneTurnContract(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SceneTurnContract.fromJson(value);
    }
    if (value is Map) {
      return SceneTurnContract.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  SceneStateSnapshot? parseSceneStateSnapshot(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SceneStateSnapshot.fromJson(value);
    }
    if (value is Map) {
      return SceneStateSnapshot.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }
}
