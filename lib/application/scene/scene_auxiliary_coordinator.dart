import 'dart:io';

import 'package:speakeasy/services/api_client.dart';

abstract class SceneAuxiliaryRemoteApi {
  Future<String> translateTextToChinese(String text);

  Future<String> transcribeAudio(
    File audioFile, {
    String? hintText,
    Map<String, dynamic>? sceneDraft,
  });

  Future<String> generateConversationSummary({
    required String npcName,
    required List<Map<String, dynamic>> history,
    String? existingSummary,
  });
}

class ApiClientSceneAuxiliaryRemoteApi implements SceneAuxiliaryRemoteApi {
  const ApiClientSceneAuxiliaryRemoteApi();

  @override
  Future<String> generateConversationSummary({
    required String npcName,
    required List<Map<String, dynamic>> history,
    String? existingSummary,
  }) {
    return ApiClient.generateConversationSummary(
      npcName: npcName,
      history: history,
      existingSummary: existingSummary,
    );
  }

  @override
  Future<String> transcribeAudio(
    File audioFile, {
    String? hintText,
    Map<String, dynamic>? sceneDraft,
  }) {
    return ApiClient.transcribeAudio(
      audioFile,
      hintText: hintText,
      sceneDraft: sceneDraft,
    );
  }

  @override
  Future<String> translateTextToChinese(String text) {
    return ApiClient.translateTextToChinese(text);
  }
}

class SceneAuxiliaryCoordinator {
  const SceneAuxiliaryCoordinator({
    SceneAuxiliaryRemoteApi remoteApi =
        const ApiClientSceneAuxiliaryRemoteApi(),
  }) : _remoteApi = remoteApi;

  final SceneAuxiliaryRemoteApi _remoteApi;

  Future<String> translateText(String text) {
    return _remoteApi.translateTextToChinese(text);
  }

  Future<String> transcribeAudio(
    File audioFile, {
    String? hintText,
    Map<String, dynamic>? sceneDraft,
  }) {
    return _remoteApi.transcribeAudio(
      audioFile,
      hintText: hintText,
      sceneDraft: sceneDraft,
    );
  }

  Future<String> generateConversationSummary({
    required String npcName,
    required List<Map<String, dynamic>> history,
    String? existingSummary,
  }) {
    return _remoteApi.generateConversationSummary(
      npcName: npcName,
      history: history,
      existingSummary: existingSummary,
    );
  }
}
