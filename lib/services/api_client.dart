import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/storage_service.dart';

class ApiClient {
  static Future<String?> getToken() async {
    return StorageService.instance.getAuthSession()?.token;
  }

  static Future<void> saveToken(String token) async {
    await StorageService.instance.saveAuthSession(
      AuthSessionStorageModel(token: token, updatedAt: DateTime.now()),
    );
  }

  static Future<void> clearToken() async {
    await StorageService.instance.clearAuthSession();
  }

  static Future<Map<String, String>> _headers({bool includeJson = true}) async {
    final String? token = await getToken();
    return <String, String>{
      if (includeJson) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static String _responseMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final String message = (response['message'] as String? ?? '').trim();
    if (message.isNotEmpty) {
      return message;
    }
    final int? statusCode = (response['_httpStatus'] as num?)?.toInt();
    if (statusCode != null && (statusCode < 200 || statusCode >= 300)) {
      return '请求失败（$statusCode）';
    }
    return fallback;
  }

  static void _ensureSuccess(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final int? code = (response['code'] as num?)?.toInt();
    final int? statusCode = (response['_httpStatus'] as num?)?.toInt();
    final bool statusFailed =
        statusCode != null && (statusCode < 200 || statusCode >= 300);
    if ((code != null && code != 0) || statusFailed) {
      throw Exception(_responseMessage(response, fallback: fallback));
    }
  }

  static Map<String, dynamic> _decodeResponse(
    http.Response response, {
    bool allowEmpty = false,
  }) {
    final String raw = response.body.trim();
    if (raw.isEmpty) {
      if (allowEmpty &&
          response.statusCode >= 200 &&
          response.statusCode < 300) {
        return <String, dynamic>{'code': 0};
      }
      throw Exception('服务器返回空响应');
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return <String, dynamic>{...decoded, '_httpStatus': response.statusCode};
    }
    if (decoded is Map) {
      return <String, dynamic>{
        ...decoded.cast<String, dynamic>(),
        '_httpStatus': response.statusCode,
      };
    }
    return <String, dynamic>{
      'code': response.statusCode >= 200 && response.statusCode < 300
          ? 0
          : response.statusCode,
      'data': decoded,
      '_httpStatus': response.statusCode,
    };
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final http.Response response = await http
        .get(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool allowEmpty = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final http.Response response = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(timeout);
    return _decodeResponse(response, allowEmpty: allowEmpty);
  }

  static Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final http.Response response = await http
        .put(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> _delete(
    String path, {
    bool allowEmpty = false,
    Map<String, String> headers = const <String, String>{},
  }) async {
    final Map<String, String> requestHeaders = await _headers();
    requestHeaders.addAll(headers);
    final http.Response response = await http
        .delete(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: requestHeaders,
        )
        .timeout(const Duration(seconds: 15));
    return _decodeResponse(response, allowEmpty: allowEmpty);
  }

  static Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    return <String, dynamic>{
      'code': 0,
      'data': <String, dynamic>{
        'status': 'not_required',
        'phone_number': phone.trim(),
      },
    };
  }

  static Future<Map<String, dynamic>> verifySmsCode(
    String phone,
    String code,
  ) async {
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.authLoginPhone, <String, dynamic>{
          'schema_version': 1,
          'phone_number': phone.trim(),
          'verification_code': code.trim(),
          'terms_accepted': true,
        });
    return _authSessionEnvelope(response);
  }

  static Future<Map<String, dynamic>> testPhoneLogin(String phone) {
    return verifySmsCode(phone, '000000');
  }

  static Future<Map<String, dynamic>> signInWithApple({
    required String authorizationCode,
    required String identityToken,
    String? userIdentifier,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.authLoginApple, <String, dynamic>{
          'schema_version': 1,
          'provider_token': identityToken.trim().isNotEmpty
              ? identityToken.trim()
              : authorizationCode.trim(),
          if (authorizationCode.trim().isNotEmpty)
            'nonce': authorizationCode.trim(),
          'terms_accepted': true,
        });
    return _authSessionEnvelope(response);
  }

  static Future<Map<String, dynamic>> signInWithWeChat({
    required String code,
    String? state,
  }) async {
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.authLoginWechat, <String, dynamic>{
          'schema_version': 1,
          'provider_token': code.trim(),
          if (state != null && state.trim().isNotEmpty) 'nonce': state.trim(),
          'terms_accepted': true,
        });
    return _authSessionEnvelope(response);
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    return <String, dynamic>{
      'code': 401,
      'message': '本地未保存 OpenAPI refresh_token，回退到当前 access token 校验。',
    };
  }

  static Future<Map<String, dynamic>> getMe() async {
    final Map<String, dynamic> response = await _get(SpeakeasyApiPaths.userMe);
    _ensureSuccess(response, fallback: '获取用户信息失败');
    return _okEnvelope(_appUserJson(_asMap(response['user'])));
  }

  static Future<Map<String, dynamic>> updateMe(
    Map<String, dynamic> data,
  ) async {
    final Map<String, dynamic> response = await _put(
      SpeakeasyApiPaths.userMe,
      _updateProfilePayload(data),
    );
    _ensureSuccess(response, fallback: '更新用户信息失败');
    return _okEnvelope(_appUserJson(_asMap(response['user'])));
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    final Map<String, dynamic> response = await _delete(
      SpeakeasyApiPaths.userMe,
      allowEmpty: true,
      headers: <String, String>{
        'Idempotency-Key':
            'account-delete-${DateTime.now().millisecondsSinceEpoch}',
      },
    );
    _ensureSuccess(response, fallback: '注销账号失败');
    return _okEnvelope(response);
  }

  static Future<Map<String, dynamic>> verifyAppleReceipt({
    required String productId,
    required String serverVerificationData,
    String? transactionId,
    String? localVerificationData,
  }) async {
    final Map<String, dynamic> response =
        await _post('/payments/apple/verify-receipt', <String, dynamic>{
          'productId': productId,
          'serverVerificationData': serverVerificationData,
          if (transactionId != null && transactionId.trim().isNotEmpty)
            'transactionId': transactionId.trim(),
          if (localVerificationData != null &&
              localVerificationData.trim().isNotEmpty)
            'localVerificationData': localVerificationData.trim(),
        }, timeout: const Duration(seconds: 20));
    _ensureSuccess(response, fallback: '订阅凭证校验失败');
    return _asMap(response['data']);
  }

  static Future<LearningStatsModel> getLearningStats() async {
    final Map<String, dynamic> res = await _get('/user/stats');
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '获取学习统计失败');
    }
    return LearningStatsModel.fromJson(_asMap(res['data']));
  }

  static Future<LearningStatsModel?> recordPracticeSession({
    required int durationSeconds,
    required int score,
    String? title,
    String? emoji,
    List<String>? tags,
    Map<String, dynamic>? feedback,
    String? promptText,
    Map<String, dynamic>? sceneDraft,
    String feedbackStatus = 'ready',
    Map<String, dynamic>? feedbackContext,
  }) async {
    final Map<String, dynamic> res =
        await _post('/user/stats/session', <String, dynamic>{
          'durationSeconds': durationSeconds,
          'score': score,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          if (emoji != null && emoji.trim().isNotEmpty) 'emoji': emoji.trim(),
          if (tags != null && tags.isNotEmpty) 'tags': tags,
          if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
          if (promptText != null && promptText.trim().isNotEmpty)
            'prompt': promptText.trim(),
          if (sceneDraft != null && sceneDraft.isNotEmpty)
            'sceneDraft': sceneDraft,
          'feedbackStatus': feedbackStatus,
          if (feedbackContext != null && feedbackContext.isNotEmpty)
            'feedbackContext': feedbackContext,
        }, allowEmpty: true);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '记录练习失败');
    }
    final Map<String, dynamic> data = _asMap(res['data']);
    if (data.isEmpty) {
      return null;
    }
    return LearningStatsModel.fromJson(data);
  }

  static Future<LearningStatsModel?> upsertPracticeFeedback({
    required int durationSeconds,
    required int score,
    required String title,
    String? emoji,
    List<String>? tags,
    required Map<String, dynamic> feedback,
    String? promptText,
    Map<String, dynamic>? sceneDraft,
    Map<String, dynamic>? feedbackContext,
  }) async {
    final Map<String, dynamic> res =
        await _post('/user/stats/session/feedback', <String, dynamic>{
          'durationSeconds': durationSeconds,
          'score': score,
          'title': title.trim(),
          if (emoji != null && emoji.trim().isNotEmpty) 'emoji': emoji.trim(),
          if (tags != null && tags.isNotEmpty) 'tags': tags,
          'feedback': feedback,
          if (promptText != null && promptText.trim().isNotEmpty)
            'prompt': promptText.trim(),
          if (sceneDraft != null && sceneDraft.isNotEmpty)
            'sceneDraft': sceneDraft,
          if (feedbackContext != null && feedbackContext.isNotEmpty)
            'feedbackContext': feedbackContext,
        }, allowEmpty: true);
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '更新复盘失败');
    }
    final Map<String, dynamic> data = _asMap(res['data']);
    if (data.isEmpty) {
      return null;
    }
    return LearningStatsModel.fromJson(data);
  }

  static Future<LearningStatsModel?> deletePracticeSceneGroup(
    String title,
  ) async {
    final Map<String, dynamic> res = await _post(
      '/user/stats/session-group/delete',
      <String, dynamic>{'title': title.trim()},
      allowEmpty: true,
    );
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '删除练习记录失败');
    }
    final Map<String, dynamic> data = _asMap(res['data']);
    if (data.isEmpty) {
      return null;
    }
    return LearningStatsModel.fromJson(data);
  }

  static Future<String> uploadAvatar(File imageFile) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/user/me/avatar'),
    );
    final String? token = await getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('avatar', imageFile.path),
    );
    final http.StreamedResponse response = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final Map<String, dynamic> body = _decodeResponse(
      http.Response(
        await response.stream.bytesToString(),
        response.statusCode,
        headers: response.headers,
      ),
    );
    final Map<String, dynamic> data = _asMap(body['data']);
    return (data['avatarUrl'] as String?) ?? '';
  }

  static Future<Map<String, dynamic>> getCards() => _get('/cards');

  static Future<Map<String, dynamic>> generateSceneDraft({
    required String prompt,
    CharacterProfile? characterProfile,
    String? desiredOutcome,
  }) => _post('/ai/scene-draft', <String, dynamic>{
    'prompt': prompt,
    if (characterProfile != null) 'characterProfile': characterProfile.toJson(),
    if (desiredOutcome?.trim().isNotEmpty ?? false)
      'desiredOutcome': desiredOutcome!.trim(),
  });

  static Future<void> updateCardState(
    String cardId, {
    bool? saved,
    bool? dismissed,
    bool? completed,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (saved != null) body['saved'] = saved;
    if (dismissed != null) body['dismissed'] = dismissed;
    if (completed != null) body['completed'] = completed;
    await _put('/cards/$cardId/state', body);
  }

  static Future<Map<String, dynamic>> createAiSessionData({
    required String sceneTitle,
    required String sceneGoal,
    String? roleId,
    CharacterProfile? characterProfile,
    String? discussionTopic,
    String? desiredOutcome,
    String? userRole,
    String? relationship,
    required String npcName,
    required String npcRole,
    required String environment,
    required String challenge,
    SceneSpec? sceneSpec,
    SceneBlueprint? sceneBlueprint,
  }) async {
    final String? trimmedRoleId = roleId?.trim().isNotEmpty ?? false
        ? roleId!.trim()
        : null;
    final String? trimmedUserRole = userRole?.trim().isNotEmpty ?? false
        ? userRole!.trim()
        : null;
    final String? trimmedDiscussionTopic =
        discussionTopic?.trim().isNotEmpty ?? false
        ? discussionTopic!.trim()
        : null;
    final String? trimmedDesiredOutcome =
        desiredOutcome?.trim().isNotEmpty ?? false
        ? desiredOutcome!.trim()
        : null;
    final String? trimmedRelationship = relationship?.trim().isNotEmpty ?? false
        ? relationship!.trim()
        : null;
    final String? trimmedPlotDesign =
        sceneSpec?.plotDesign.trim().isNotEmpty ?? false
        ? sceneSpec!.plotDesign.trim()
        : null;
    final Map<String, dynamic> response = await _post(
      '/ai/sessions',
      <String, dynamic>{
        'sceneTitle': sceneTitle,
        'sceneGoal': sceneGoal,
        'roleId': ?trimmedRoleId,
        if (characterProfile != null)
          'characterProfile': characterProfile.toJson(),
        'discussionTopic': ?trimmedDiscussionTopic,
        'desiredOutcome': ?trimmedDesiredOutcome,
        'userRole': ?trimmedUserRole,
        'relationship': ?trimmedRelationship,
        'npcName': npcName,
        'npcRole': npcRole,
        'environment': environment,
        'challenge': challenge,
        'plotDesign': ?trimmedPlotDesign,
        'draft': <String, dynamic>{
          'title': sceneTitle,
          'roleId': ?trimmedRoleId,
          if (characterProfile != null)
            'characterProfile': characterProfile.toJson(),
          'discussionTopic': ?trimmedDiscussionTopic,
          'desiredOutcome': ?trimmedDesiredOutcome,
          'userRole': ?trimmedUserRole,
          'relationship': ?trimmedRelationship,
          'goal': sceneGoal,
          'npcName': npcName,
          'npcRole': npcRole,
          'environment': environment,
          'challenge': challenge,
          'plotDesign': ?trimmedPlotDesign,
        },
        if (sceneSpec != null) 'sceneSpec': sceneSpec.toJson(),
        if (sceneBlueprint != null) 'sceneBlueprint': sceneBlueprint.toJson(),
      },
    );
    _ensureSuccess(response, fallback: '场景会话创建失败');
    final Map<String, dynamic> data = _asMap(response['data']);
    if (data.isEmpty) {
      throw Exception(_responseMessage(response, fallback: '场景会话创建失败'));
    }
    return data;
  }

  static Future<String> createAiSession({
    required String sceneTitle,
    required String sceneGoal,
    String? roleId,
    CharacterProfile? characterProfile,
    String? discussionTopic,
    String? desiredOutcome,
    String? userRole,
    String? relationship,
    required String npcName,
    required String npcRole,
    required String environment,
    required String challenge,
    SceneSpec? sceneSpec,
    SceneBlueprint? sceneBlueprint,
  }) async {
    final Map<String, dynamic> data = await createAiSessionData(
      sceneTitle: sceneTitle,
      sceneGoal: sceneGoal,
      roleId: roleId,
      characterProfile: characterProfile,
      discussionTopic: discussionTopic,
      desiredOutcome: desiredOutcome,
      userRole: userRole,
      relationship: relationship,
      npcName: npcName,
      npcRole: npcRole,
      environment: environment,
      challenge: challenge,
      sceneSpec: sceneSpec,
      sceneBlueprint: sceneBlueprint,
    );
    return (data['sessionId'] as String?) ?? '';
  }

  static Future<String> sendMessage(
    String sessionId,
    String text, {
    SceneDraft? draft,
    List<Map<String, dynamic>>? history,
  }) async {
    final Map<String, dynamic> data = await sendSceneMessage(
      sessionId,
      text,
      draft: draft,
      history: history,
    );
    return (data['reply'] as String?) ?? '';
  }

  static Future<Map<String, dynamic>> sendSceneMessage(
    String sessionId,
    String text, {
    SceneDraft? draft,
    List<Map<String, dynamic>>? history,
  }) async {
    final List<Map<String, dynamic>> historyPayload =
        (history ?? const <Map<String, dynamic>>[])
            .map(
              (Map<String, dynamic> turn) => <String, dynamic>{
                'role': (turn['role'] as String? ?? '').trim(),
                'text': (turn['text'] as String? ?? '').trim(),
              },
            )
            .where(
              (Map<String, dynamic> turn) =>
                  (turn['role'] as String).isNotEmpty &&
                  (turn['text'] as String).isNotEmpty,
            )
            .toList(growable: false);
    final Map<String, dynamic> response = await _post(
      '/ai/sessions/$sessionId/message',
      <String, dynamic>{
        'text': text,
        if (draft?.roleId?.trim().isNotEmpty ?? false)
          'roleId': draft!.roleId!.trim(),
        if (draft != null)
          'draft': <String, dynamic>{
            'title': draft.title,
            if (draft.roleId?.trim().isNotEmpty ?? false)
              'roleId': draft.roleId!.trim(),
            if (draft.characterProfile != null)
              'characterProfile': draft.characterProfile!.toJson(),
            if (draft.discussionTopic?.trim().isNotEmpty ?? false)
              'discussionTopic': draft.discussionTopic!.trim(),
            if (draft.desiredOutcome?.trim().isNotEmpty ?? false)
              'desiredOutcome': draft.desiredOutcome!.trim(),
            'userRole': draft.userRole,
            'relationship': draft.relationship,
            'goal': draft.goal,
            'npcName': draft.npcName,
            'npcRole': draft.npcRole,
            'environment': draft.environment,
            'challenge': draft.challenge,
            if (draft.plotDesign.trim().isNotEmpty)
              'plotDesign': draft.plotDesign.trim(),
          },
        if (draft?.sceneSpec != null) 'sceneSpec': draft!.sceneSpec!.toJson(),
        if (draft?.sceneBlueprint != null)
          'sceneBlueprint': draft!.sceneBlueprint!.toJson(),
        if (historyPayload.isNotEmpty) 'history': historyPayload,
      },
    );
    _ensureSuccess(response, fallback: '场景消息发送失败');
    final Map<String, dynamic> data = _asMap(response['data']);
    if (data.isEmpty) {
      throw Exception(_responseMessage(response, fallback: '服务器未返回场景回复'));
    }
    return data;
  }

  static Future<void> syncRoleProfiles(List<Map<String, dynamic>> roles) async {
    final Map<String, dynamic> response = await _put(
      '/user/roles/sync',
      <String, dynamic>{'roles': roles},
    );
    _ensureSuccess(response, fallback: '角色同步失败');
  }

  static Future<Map<String, dynamic>?> getRoleMemory(String roleId) async {
    final String trimmedRoleId = roleId.trim();
    if (trimmedRoleId.isEmpty) {
      return null;
    }
    final Map<String, dynamic> response = await _get(
      '/user/roles/$trimmedRoleId/memory',
    );
    _ensureSuccess(response, fallback: '角色记忆加载失败');
    final Map<String, dynamic> data = _asMap(response['data']);
    return data.isEmpty ? null : data;
  }

  static Future<Map<String, dynamic>?> getLearningProfile() async {
    final Map<String, dynamic> response = await _get('/user/learning-profile');
    _ensureSuccess(response, fallback: '学习总结加载失败');
    final Map<String, dynamic> data = _asMap(response['data']);
    return data.isEmpty ? null : data;
  }

  static Future<Map<String, dynamic>> generateSceneTurnMeta({
    required SceneDraft draft,
    required List<Map<String, dynamic>> history,
    required String assistantText,
    Map<String, dynamic>? sceneState,
  }) async {
    final Map<String, dynamic> response = await _post(
      '/ai/scene-turn-meta',
      <String, dynamic>{
        'draft': <String, dynamic>{
          'title': draft.title,
          if (draft.roleId?.trim().isNotEmpty ?? false)
            'roleId': draft.roleId!.trim(),
          if (draft.characterProfile != null)
            'characterProfile': draft.characterProfile!.toJson(),
          if (draft.discussionTopic?.trim().isNotEmpty ?? false)
            'discussionTopic': draft.discussionTopic!.trim(),
          if (draft.desiredOutcome?.trim().isNotEmpty ?? false)
            'desiredOutcome': draft.desiredOutcome!.trim(),
          'userRole': draft.userRole,
          'relationship': draft.relationship,
          'goal': draft.goal,
          'npcName': draft.npcName,
          'npcRole': draft.npcRole,
          'environment': draft.environment,
          'challenge': draft.challenge,
          if (draft.sceneSpec != null) 'sceneSpec': draft.sceneSpec!.toJson(),
          if (draft.sceneBlueprint != null)
            'sceneBlueprint': draft.sceneBlueprint!.toJson(),
        },
        'history': history,
        'assistantText': assistantText,
        if (sceneState != null && sceneState.isNotEmpty)
          'sceneState': sceneState,
      },
    );
    _ensureSuccess(response, fallback: '场景元信息生成失败');
    return _asMap(response['data']);
  }

  static Future<String> translateTextToChinese(String text) async {
    final Map<String, dynamic> response = await _post(
      '/ai/translate',
      <String, dynamic>{'text': text, 'targetLanguage': 'zh-CN'},
    );
    if (response['code'] != 0) {
      throw Exception(response['message'] ?? '翻译失败');
    }
    final Map<String, dynamic> data = _asMap(response['data']);
    final String translated = (data['translation'] as String? ?? '').trim();
    if (translated.isEmpty) {
      throw Exception('翻译结果为空');
    }
    return translated;
  }

  static Future<Uint8List> tts(
    String text, {
    String? voice,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final String resolvedVoice = (voice?.trim().isNotEmpty ?? false)
        ? voice!.trim()
        : AppConfig.ttsVoice;
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.aiTts,
      <String, dynamic>{
        'schema_version': 1,
        'text': text,
        'voice': resolvedVoice,
      },
      timeout: timeout,
    );
    final String status = (response['status'] as String? ?? '').trim();
    if (status != 'available') {
      return Uint8List(0);
    }
    // OpenAPI now returns a backend audio_ref instead of raw bytes; callers that
    // need bytes fall back to on-device TTS until streaming media is routed.
    return Uint8List(0);
  }

  static Future<String?> ttsCacheUrl(
    String text, {
    String? voice,
    String? sceneId,
    String? targetLevel,
    String? nodeId,
  }) async {
    final String cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      return null;
    }
    final String resolvedVoice = (voice?.trim().isNotEmpty ?? false)
        ? voice!.trim()
        : AppConfig.ttsVoice;
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.aiTts,
      <String, dynamic>{
        'schema_version': 1,
        'text': cleanedText,
        'voice': resolvedVoice,
      },
      timeout: const Duration(seconds: 25),
    );
    _ensureSuccess(response, fallback: 'TTS 缓存获取失败');
    final String audioUrl = (response['audio_ref'] as String? ?? '').trim();
    return audioUrl.isEmpty ? null : audioUrl;
  }

  /// 语音转文字（Paraformer）——上传音频文件，返回识别文本
  static Future<String> transcribeAudio(
    File audioFile, {
    String? hintText,
    Map<String, dynamic>? sceneDraft,
    String repairMode = 'background',
    bool preferRawText = false,
  }) async {
    final Map<String, dynamic> body =
        await _post(SpeakeasyApiPaths.aiTranscribe, <String, dynamic>{
          'schema_version': 1,
          'audio_ref': audioFile.path,
          if (hintText != null && hintText.trim().isNotEmpty)
            'language_hint': hintText.trim(),
        }, timeout: const Duration(seconds: 30));
    _ensureSuccess(body, fallback: '语音识别失败');
    final String text = (body['transcript'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw Exception('语音识别结果为空');
    }
    return text;
  }

  /// 生成对话摘要（通过后端 LLM）
  static Future<String> generateConversationSummary({
    required String npcName,
    required List<Map<String, dynamic>> history,
    String? existingSummary,
  }) async {
    final Map<String, dynamic> response =
        await _post('/ai/conversation-summary', <String, dynamic>{
          'npcName': npcName,
          'history': history,
          if (existingSummary != null && existingSummary.isNotEmpty)
            'existingSummary': existingSummary,
        }, timeout: const Duration(seconds: 15));
    _ensureSuccess(response, fallback: '对话摘要生成失败');
    final Map<String, dynamic> data = _asMap(response['data']);
    return (data['summary'] as String?) ?? '';
  }

  /// 生成场景反馈（通过后端 LLM）
  static Future<Map<String, dynamic>> generateFeedback({
    required String title,
    required String goal,
    required String npcName,
    required List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> voiceTurns = const <Map<String, dynamic>>[],
  }) async {
    return _okEnvelope(<String, dynamic>{
      'summary': '当前版本使用本地复盘占位；服务端 /ai/feedback 需要已创建的 practice session。',
      'turnReviews': const <Map<String, dynamic>>[],
      'suggestions': const <Map<String, dynamic>>[],
      'validationStatus': 'fallback',
      'providerStatus': 'not_routed',
    });
  }

  static Future<Map<String, dynamic>> scoreAudio(
    File audioFile,
    String refText, {
    String? cardId,
  }) async {
    final Map<String, dynamic> body = await _post(
      SpeakeasyApiPaths.aiPronunciation,
      <String, dynamic>{
        'schema_version': 1,
        'audio_ref': audioFile.path,
        'reference_text': refText,
      },
      timeout: const Duration(seconds: 30),
    );
    _ensureSuccess(body, fallback: '发音评测失败');
    final Map<String, dynamic> signal = _asMap(body['score_signal']);
    final int overall = (((signal['value'] as num?)?.toDouble() ?? 0) * 100)
        .round()
        .clamp(0, 100);
    return <String, dynamic>{
      'overall': overall,
      'source': signal['source'] ?? 'server_side_adapter',
      'status': signal['status'],
    };
  }

  static Future<Map<String, dynamic>> fetchOralAssessmentAuth() async {
    final Map<String, dynamic> response = await _post(
      '/ai/oral-assessment/auth',
      const <String, dynamic>{},
      timeout: const Duration(seconds: 10),
    );
    _ensureSuccess(response, fallback: '口语测评授权失败');
    return _asMap(response['data']);
  }

  static Future<Map<String, dynamic>> scoreGrammar({
    required String text,
    String? targetText,
    String? questionText,
  }) async {
    final Map<String, dynamic> response =
        await _post('/ai/grammar-score', <String, dynamic>{
          'text': text,
          if (targetText != null && targetText.trim().isNotEmpty)
            'targetText': targetText.trim(),
          if (questionText != null && questionText.trim().isNotEmpty)
            'questionText': questionText.trim(),
        }, timeout: const Duration(seconds: 20));
    _ensureSuccess(response, fallback: '语法评测失败');
    return _asMap(response['data']);
  }

  static Future<Map<String, dynamic>> interviewCoachTurn(
    Map<String, dynamic> payload,
  ) async {
    final String sessionId =
        (payload['session_id'] as String? ??
                payload['sessionId'] as String? ??
                '')
            .trim();
    final String transcript =
        (payload['transcript'] as String? ??
                payload['text'] as String? ??
                payload['answer'] as String? ??
                '')
            .trim();
    if (sessionId.isEmpty || transcript.isEmpty) {
      return <String, dynamic>{
        'summary': '当前会话尚未接入后端 practice session，使用本地教练兜底。',
        'feedbackType': 'fallback',
        'validationStatus': 'fallback',
        'providerStatus': 'not_routed',
      };
    }
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.aiCoachTurn, <String, dynamic>{
          'schema_version': 1,
          'session_id': sessionId,
          'transcript': transcript,
          if (payload['target_expression_ids'] is List)
            'target_expression_ids': payload['target_expression_ids'],
        }, timeout: const Duration(seconds: 8));
    _ensureSuccess(response, fallback: '口语教练决策失败');
    return _asMap(response['feedback']);
  }

  static Map<String, dynamic> _okEnvelope(Map<String, dynamic> data) {
    return <String, dynamic>{'code': 0, 'data': data};
  }

  static Map<String, dynamic> _authSessionEnvelope(
    Map<String, dynamic> response,
  ) {
    _ensureSuccess(response, fallback: '登录失败');
    final Map<String, dynamic> user = _appUserJson(_asMap(response['user']));
    return _okEnvelope(<String, dynamic>{
      'token': (response['access_token'] as String? ?? '').trim(),
      'refreshToken': (response['refresh_token'] as String? ?? '').trim(),
      'expiresAt': response['expires_at'],
      'user': user,
    });
  }

  static Map<String, dynamic> _appUserJson(Map<String, dynamic> user) {
    final String displayName =
        (user['display_name'] as String? ??
                user['displayName'] as String? ??
                user['nickname'] as String? ??
                '')
            .trim();
    final String avatarRef =
        (user['avatar_ref'] as String? ??
                user['avatarRef'] as String? ??
                user['avatarUrl'] as String? ??
                user['avatar'] as String? ??
                '')
            .trim();
    final String onboardingStatus =
        (user['onboarding_status'] as String? ??
                user['onboardingStatus'] as String? ??
                '')
            .trim();
    return <String, dynamic>{
      ...user,
      'nickname': displayName.isEmpty ? '用户' : displayName,
      'avatarUrl': avatarRef,
      'memberPlan': user['member_plan'] ?? user['memberPlan'] ?? 'free',
      'onboardingDone': onboardingStatus == 'complete',
    };
  }

  static Map<String, dynamic> _updateProfilePayload(Map<String, dynamic> data) {
    final Map<String, dynamic> payload = <String, dynamic>{'schema_version': 1};
    void copy(String source, String target) {
      final Object? value = data[source];
      if (value != null) {
        payload[target] = value;
      }
    }

    copy('displayName', 'display_name');
    copy('display_name', 'display_name');
    copy('targetLevel', 'target_level');
    copy('target_level', 'target_level');
    copy('dailyMinutes', 'daily_minutes');
    copy('daily_minutes', 'daily_minutes');
    copy('reminderEnabled', 'reminder_enabled');
    copy('reminder_enabled', 'reminder_enabled');
    copy('reminderTime', 'reminder_time');
    copy('reminder_time', 'reminder_time');
    return payload;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
