import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/storage_service.dart';

class ApiClient {
  static String? _pendingAccountDeletionKey;

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

  static String _normalizeTrustedAudioRef(String audioRef) {
    final String value = audioRef.trim();
    if (!value.startsWith('media://audio/')) {
      throw Exception('trusted audio_ref required');
    }
    return value;
  }

  static String? _normalizeOptionalTrustedAudioRef(String? audioRef) {
    if (audioRef == null || audioRef.trim().isEmpty) {
      return null;
    }
    return _normalizeTrustedAudioRef(audioRef);
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
    Map<String, String> headers = const <String, String>{},
  }) async {
    final Map<String, String> requestHeaders = await _headers();
    requestHeaders.addAll(headers);
    final http.Response response = await http
        .post(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: requestHeaders,
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

  static Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    final Map<String, String> requestHeaders = await _headers();
    requestHeaders.addAll(headers);
    final http.Response response = await http
        .patch(
          Uri.parse('${AppConfig.apiBaseUrl}$path'),
          headers: requestHeaders,
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
    final Map<String, dynamic> response = await _patch(
      SpeakeasyApiPaths.userMe,
      _updateProfilePayload(data),
    );
    _ensureSuccess(response, fallback: '更新用户信息失败');
    return _okEnvelope(_appUserJson(_asMap(response['user'])));
  }

  static Future<Map<String, dynamic>> submitOnboardingAssessment({
    required String goalDirection,
    required List<String> painPoints,
    required String outputLevel,
    required int dailyMinutes,
  }) async {
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.onboardingAssessment, <String, dynamic>{
          'schema_version': 1,
          'goal_direction': goalDirection,
          'pain_points': painPoints,
          'output_level': outputLevel,
          'daily_minutes': dailyMinutes,
        });
    _ensureSuccess(response, fallback: '首评结果同步失败');
    return _okEnvelope(<String, dynamic>{'route': _asMap(response['route'])});
  }

  static Future<Map<String, dynamic>> deleteAccount() async {
    final String idempotencyKey = _pendingAccountDeletionKey ??=
        'account-delete-${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> response = await _delete(
      SpeakeasyApiPaths.userMe,
      allowEmpty: true,
      headers: <String, String>{'Idempotency-Key': idempotencyKey},
    );
    _ensureSuccess(response, fallback: '注销账号失败');
    _pendingAccountDeletionKey = null;
    return _okEnvelope(response);
  }

  static Future<String> currentUserId() async {
    final Map<String, dynamic> response = await getMe();
    final Map<String, dynamic> data = _asMap(response['data']);
    final String userId =
        (data['user_id'] as String? ?? data['userId'] as String? ?? '').trim();
    if (userId.isEmpty) {
      throw Exception('无法获取当前用户标识');
    }
    return userId;
  }

  static Future<Map<String, dynamic>> refreshEntitlements() async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.entitlementsRefresh,
      <String, dynamic>{'schema_version': 1},
    );
    _ensureSuccess(response, fallback: '订阅权益刷新失败');
    return _asMap(response['entitlement']);
  }

  static Future<Map<String, dynamic>> verifyAppleSubscription({
    required String productId,
    required String transactionId,
    required String originalTransactionId,
    required String appAccountToken,
  }) async {
    final String idempotencyKey = 'apple-${transactionId.trim()}';
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.subscriptionsAppleVerify,
      <String, dynamic>{
        'schema_version': 1,
        'transaction_id': transactionId.trim(),
        'original_transaction_id': originalTransactionId.trim(),
        'product_id': productId.trim(),
        'app_account_token': appAccountToken.trim(),
      },
      timeout: const Duration(seconds: 20),
      headers: <String, String>{'Idempotency-Key': idempotencyKey},
    );
    _ensureSuccess(response, fallback: '订阅凭证校验失败');
    return response;
  }

  static Future<Map<String, dynamic>> verifyGoogleSubscription({
    required String purchaseToken,
    required String productId,
  }) async {
    final String idempotencyKey = 'google-${purchaseToken.trim()}';
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.subscriptionsGoogleVerify,
      <String, dynamic>{
        'schema_version': 1,
        'purchase_token': purchaseToken.trim(),
        'product_id': productId.trim(),
      },
      timeout: const Duration(seconds: 20),
      headers: <String, String>{'Idempotency-Key': idempotencyKey},
    );
    _ensureSuccess(response, fallback: 'Google Play 订阅凭证校验失败');
    return response;
  }

  static Future<Map<String, dynamic>> restoreSubscription({
    required String platform,
    String? providerAccountToken,
  }) async {
    final String idempotencyKey = 'restore-${platform.trim()}';
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.subscriptionsRestore,
      <String, dynamic>{
        'schema_version': 1,
        'platform': platform.trim(),
        if (providerAccountToken != null &&
            providerAccountToken.trim().isNotEmpty)
          'provider_account_token': providerAccountToken.trim(),
      },
      timeout: const Duration(seconds: 20),
      headers: <String, String>{'Idempotency-Key': idempotencyKey},
    );
    _ensureSuccess(response, fallback: '恢复购买失败');
    return response;
  }

  static Future<Map<String, dynamic>> createAudioUpload({
    required String purpose,
    required String contentType,
    required int byteSize,
    required int durationSeconds,
    String? checksumSha256,
    String? clientUploadId,
    String? idempotencyKey,
  }) async {
    final String requestKey =
        idempotencyKey ??
        'audio-upload-${DateTime.now().millisecondsSinceEpoch}';
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.mediaAudioUploads,
      <String, dynamic>{
        'schema_version': 1,
        'purpose': purpose.trim(),
        'content_type': contentType.trim(),
        'byte_size': byteSize,
        'duration_seconds': durationSeconds,
        if (checksumSha256 != null && checksumSha256.trim().isNotEmpty)
          'checksum_sha256': checksumSha256.trim(),
        if (clientUploadId != null && clientUploadId.trim().isNotEmpty)
          'client_upload_id': clientUploadId.trim(),
      },
      headers: <String, String>{'Idempotency-Key': requestKey},
    );
    _ensureSuccess(response, fallback: '创建音频上传失败');
    return response;
  }

  static Future<Map<String, dynamic>> completeAudioUpload({
    required String mediaId,
    String? checksumSha256,
    String? objectRef,
  }) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.mediaAudioUploadComplete(mediaId),
      <String, dynamic>{
        'schema_version': 1,
        if (checksumSha256 != null && checksumSha256.trim().isNotEmpty)
          'checksum_sha256': checksumSha256.trim(),
        if (objectRef != null && objectRef.trim().isNotEmpty)
          'object_ref': objectRef.trim(),
      },
    );
    _ensureSuccess(response, fallback: '确认音频上传失败');
    return response;
  }

  static Future<Map<String, dynamic>> startTrainingSession({
    required String scenarioId,
    required String levelCode,
    bool resumeExisting = true,
  }) async {
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.trainingSessions, <String, dynamic>{
          'schema_version': 1,
          'scenario_id': scenarioId.trim(),
          'level_code': levelCode.trim(),
          'resume_existing': resumeExisting,
        });
    _ensureSuccess(response, fallback: '训练会话创建失败');
    return response;
  }

  static Future<Map<String, dynamic>> getTrainingSession(
    String sessionId,
  ) async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.trainingSession(sessionId),
    );
    _ensureSuccess(response, fallback: '训练会话加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> submitTrainingTurn({
    required String sessionId,
    required String idempotencyKey,
    String? transcript,
    String? audioRef,
    String? selectedOptionId,
    int? clientStateVersion,
  }) async {
    final String? trustedAudioRef = _normalizeOptionalTrustedAudioRef(audioRef);
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.trainingSessionTurns(sessionId),
      <String, dynamic>{
        'schema_version': 1,
        if (transcript != null && transcript.trim().isNotEmpty)
          'transcript': transcript.trim(),
        'audio_ref': ?trustedAudioRef,
        if (selectedOptionId != null && selectedOptionId.trim().isNotEmpty)
          'selected_option_id': selectedOptionId.trim(),
        'client_state_version': ?clientStateVersion,
      },
      timeout: const Duration(seconds: 25),
      headers: <String, String>{'Idempotency-Key': idempotencyKey.trim()},
    );
    _ensureSuccess(response, fallback: '训练回合提交失败');
    return response;
  }

  static Future<Map<String, dynamic>> requestTrainingPlannerNext(
    String sessionId,
  ) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.trainingSessionPlannerNext(sessionId),
      <String, dynamic>{'schema_version': 1},
    );
    _ensureSuccess(response, fallback: '训练 planner 加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> requestTrainingHint(
    String sessionId,
  ) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.trainingSessionHints(sessionId),
      <String, dynamic>{'schema_version': 1},
    );
    _ensureSuccess(response, fallback: '训练提示加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> startTrainingPressureCheck(
    String sessionId,
  ) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.trainingSessionPressureCheck(sessionId),
      <String, dynamic>{'schema_version': 1},
    );
    _ensureSuccess(response, fallback: '训练压力检查启动失败');
    return response;
  }

  static Future<Map<String, dynamic>> completeTrainingSession(
    String sessionId,
  ) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.trainingSessionComplete(sessionId),
      <String, dynamic>{'schema_version': 1},
    );
    _ensureSuccess(response, fallback: '训练复盘生成失败');
    return response;
  }

  static Future<Map<String, dynamic>> createGoalAutopilotGoal(
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.goalAutopilotGoals,
      payload,
      headers: <String, String>{'Idempotency-Key': idempotencyKey.trim()},
    );
    _ensureSuccess(response, fallback: '目标创建失败');
    return response;
  }

  static Future<Map<String, dynamic>> getGoalAutopilotSummary() async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.goalAutopilotSummary,
    );
    _ensureSuccess(response, fallback: '目标进度加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> getGoalAutopilotControl() async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.goalAutopilotControl,
    );
    _ensureSuccess(response, fallback: '自动带练控制加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> updateGoalAutopilotControl(
    Map<String, dynamic> payload, {
    required String idempotencyKey,
  }) async {
    final Map<String, dynamic> response = await _patch(
      SpeakeasyApiPaths.goalAutopilotControl,
      payload,
      headers: <String, String>{'Idempotency-Key': idempotencyKey.trim()},
    );
    _ensureSuccess(response, fallback: '自动带练控制更新失败');
    return response;
  }

  static Future<Map<String, dynamic>> pauseGoalAutopilotControl({
    required String idempotencyKey,
    String? pauseReason,
  }) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.goalAutopilotControlPause,
      <String, dynamic>{
        'schema_version': 1,
        if (pauseReason != null && pauseReason.trim().isNotEmpty)
          'pause_reason': pauseReason.trim(),
      },
      headers: <String, String>{'Idempotency-Key': idempotencyKey.trim()},
    );
    _ensureSuccess(response, fallback: '自动带练暂停失败');
    return response;
  }

  static Future<Map<String, dynamic>> resumeGoalAutopilotControl({
    required String idempotencyKey,
    String sourceEvent = 'manual_resume',
  }) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.goalAutopilotControlResume,
      <String, dynamic>{
        'schema_version': 1,
        'source_event': sourceEvent.trim(),
      },
      headers: <String, String>{'Idempotency-Key': idempotencyKey.trim()},
    );
    _ensureSuccess(response, fallback: '自动带练恢复失败');
    return response;
  }

  static Future<Map<String, dynamic>> generateGoalAutopilotPlan({
    bool forceReplan = false,
    String reasonCode = 'flutter_request',
  }) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.goalAutopilotPlansGenerate,
      <String, dynamic>{
        'schema_version': 1,
        'force_replan': forceReplan,
        'reason_code': reasonCode.trim(),
      },
    );
    _ensureSuccess(response, fallback: '目标计划生成失败');
    return response;
  }

  static Future<Map<String, dynamic>> getGoalAutopilotDailyPlan() async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.goalAutopilotDailyPlan,
    );
    _ensureSuccess(response, fallback: '今日计划加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> getGoalAutopilotNextAction() async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.goalAutopilotActionsNext,
    );
    _ensureSuccess(response, fallback: '下一步训练加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> completeGoalAutopilotAction({
    required String planItemId,
    required String outcome,
    String? evidenceRef,
    String? learnerNote,
  }) async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.goalAutopilotActionComplete(planItemId),
      <String, dynamic>{
        'schema_version': 1,
        'outcome': outcome.trim(),
        if (evidenceRef != null && evidenceRef.trim().isNotEmpty)
          'evidence_ref': evidenceRef.trim(),
        if (learnerNote != null && learnerNote.trim().isNotEmpty)
          'learner_note': learnerNote.trim(),
      },
    );
    _ensureSuccess(response, fallback: '训练项更新失败');
    return response;
  }

  static Future<Map<String, dynamic>> getGoalAutopilotForecast() async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.goalAutopilotForecast,
    );
    _ensureSuccess(response, fallback: '目标预测加载失败');
    return response;
  }

  static Future<Map<String, dynamic>>
  getGoalAutopilotProgressProjection() async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.goalAutopilotProgressProjection,
    );
    _ensureSuccess(response, fallback: '目标进度投影加载失败');
    return response;
  }

  static Future<Map<String, dynamic>> submitGoalAutopilotCheckpoint({
    required String checkpointType,
    String? transcript,
    String? audioRef,
    double? scoreHint,
  }) async {
    final String? trustedAudioRef = _normalizeOptionalTrustedAudioRef(audioRef);
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.goalAutopilotCheckpoints,
      <String, dynamic>{
        'schema_version': 1,
        'checkpoint_type': checkpointType.trim(),
        if (transcript != null && transcript.trim().isNotEmpty)
          'transcript': transcript.trim(),
        'audio_ref': ?trustedAudioRef,
        'score_hint': ?scoreHint,
      },
    );
    _ensureSuccess(response, fallback: '阶段复测提交失败');
    return response;
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

  static Future<Map<String, dynamic>> getCards() => _get('/cards');

  static Future<Map<String, dynamic>> generateSceneDraft({
    required String prompt,
    CharacterProfile? characterProfile,
    String? desiredOutcome,
  }) async {
    final String cleanedPrompt = prompt.trim();
    final String npcName = (characterProfile?.name.trim().isNotEmpty ?? false)
        ? characterProfile!.name.trim()
        : 'Maya';
    final String npcRole =
        (characterProfile?.profession.trim().isNotEmpty ?? false)
        ? characterProfile!.profession.trim()
        : 'Conversation partner';
    final String outcome = (desiredOutcome ?? '').trim();
    final String title = cleanedPrompt.isEmpty
        ? 'English speaking practice'
        : cleanedPrompt;
    return _okEnvelope(<String, dynamic>{
      'title': title,
      'tags': <String>['口语练习', '本地草稿', '后端受控会话'],
      if (characterProfile != null)
        'characterProfile': characterProfile.toJson(),
      'discussionTopic': title,
      'desiredOutcome': outcome.isEmpty
          ? 'Complete one natural English speaking practice turn.'
          : outcome,
      'userRole': 'Speaker',
      'relationship': characterProfile == null
          ? 'A practical English conversation.'
          : 'A roleplay conversation with $npcName.',
      'goal': outcome.isEmpty ? title : outcome,
      'npcName': npcName,
      'npcRole': npcRole,
      'environment': 'English speaking practice',
      'challenge': 'Respond clearly and keep the conversation moving.',
      'plotDesign':
          'Open naturally, answer the main point, add one detail, and close with a next step.',
      'providerStatus': 'local_fallback',
    });
  }

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
    final String scenarioId = _legacyPracticeScenarioId(
      sceneTitle: sceneTitle,
      npcRole: npcRole,
      sceneSpec: sceneSpec,
    );
    final String levelCode = _legacyPracticeLevelCode(sceneSpec);
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.practiceSessions, <String, dynamic>{
          'schema_version': 1,
          'scenario_id': scenarioId,
          'level_code': levelCode,
          'resume_existing': true,
        });
    _ensureSuccess(response, fallback: '场景会话创建失败');
    final Map<String, dynamic> session = _asMap(
      response['session'] ?? response['data'],
    );
    final String sessionId =
        (session['session_id'] as String? ??
                session['sessionId'] as String? ??
                '')
            .trim();
    if (sessionId.isEmpty) {
      throw Exception(_responseMessage(response, fallback: '场景会话创建失败'));
    }
    return <String, dynamic>{
      'sessionId': sessionId,
      'session_id': sessionId,
      'scenarioId': scenarioId,
      'scenario_id': scenarioId,
      'levelCode': levelCode,
      'level_code': levelCode,
      'status': (session['status'] as String? ?? '').trim(),
      'roleId': ?trimmedRoleId,
      'characterProfile': ?characterProfile?.toJson(),
      'discussionTopic': ?trimmedDiscussionTopic,
      'desiredOutcome': ?trimmedDesiredOutcome,
      'userRole': ?trimmedUserRole,
      'relationship': ?trimmedRelationship,
      'npcName': npcName,
      'npcRole': npcRole,
      'environment': environment,
      'challenge': challenge,
      'plotDesign': ?trimmedPlotDesign,
      if (sceneSpec != null) 'sceneSpec': sceneSpec.toJson(),
      if (sceneBlueprint != null) 'sceneBlueprint': sceneBlueprint.toJson(),
      'providerStatus': 'practice_gateway',
    };
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
      SpeakeasyApiPaths.practiceSessionTurns(sessionId),
      <String, dynamic>{
        'schema_version': 1,
        'transcript': text.trim(),
        'client_state_version': historyPayload.length,
      },
      timeout: const Duration(seconds: 25),
      headers: <String, String>{
        'Idempotency-Key': _legacyPracticeTurnKey(sessionId, text),
      },
    );
    _ensureSuccess(response, fallback: '场景消息发送失败');
    final Map<String, dynamic> feedback = _asMap(
      response['coach_feedback'] ?? response['coachFeedback'],
    );
    final Map<String, dynamic> recoverable = _asMap(
      response['recoverable_error'] ?? response['recoverableError'],
    );
    final String summary = (feedback['summary'] as String? ?? '').trim();
    final String nextPrompt =
        (feedback['next_prompt'] as String? ??
                feedback['nextPrompt'] as String? ??
                '')
            .trim();
    final String suggestedExpression =
        (feedback['suggested_expression'] as String? ??
                feedback['suggestedExpression'] as String? ??
                '')
            .trim();
    final String recoverableMessage = (recoverable['message'] as String? ?? '')
        .trim();
    final String reply = nextPrompt.isNotEmpty
        ? nextPrompt
        : summary.isNotEmpty
        ? summary
        : recoverableMessage;
    if (reply.isEmpty) {
      throw Exception(_responseMessage(response, fallback: '服务器未返回场景回复'));
    }
    return <String, dynamic>{
      'reply': reply,
      'summary': summary.isNotEmpty ? summary : reply,
      if (suggestedExpression.isNotEmpty) 'coach': suggestedExpression,
      'event':
          (feedback['feedback_type'] as String? ??
                  feedback['feedbackType'] as String? ??
                  '')
              .trim(),
      'providerStatus':
          (feedback['provider_status'] as String? ??
                  feedback['providerStatus'] as String? ??
                  recoverable['code'] as String? ??
                  'practice_gateway')
              .trim(),
      'validationStatus':
          (feedback['validation_status'] as String? ??
                  feedback['validationStatus'] as String? ??
                  '')
              .trim(),
    };
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
    final String text = assistantText.trim();
    return <String, dynamic>{
      'summary': text.isEmpty ? draft.goal : _truncateWords(text, 18),
      'coach': 'Keep the next reply specific and natural.',
      'event': history.isEmpty ? 'opening_turn' : 'practice_turn',
      if (sceneState != null && sceneState.isNotEmpty) 'sceneState': sceneState,
      'providerStatus': 'local_fallback',
    };
  }

  static Future<String> translateTextToChinese(String text) async {
    final String translated = text.trim();
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

  /// 语音转文字（Paraformer）——消费可信 audio_ref，返回识别文本
  // XCB-001: callers must pass a backend-owned trusted audio_ref.
  static Future<String> transcribeTrustedAudioRef({
    required String audioRef,
    String? languageHint,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final String trustedAudioRef = _normalizeTrustedAudioRef(audioRef);
    final Map<String, dynamic> body =
        await _post(SpeakeasyApiPaths.aiTranscribe, <String, dynamic>{
          'schema_version': 1,
          'audio_ref': trustedAudioRef,
          if (languageHint != null && languageHint.trim().isNotEmpty)
            'language_hint': languageHint.trim(),
        }, timeout: timeout);
    _ensureSuccess(body, fallback: '语音识别失败');
    final String text = (body['transcript'] as String? ?? '').trim();
    if (text.isEmpty) {
      throw Exception('语音识别结果为空');
    }
    return text;
  }

  /// 生成对话摘要（本地 fallback；高成本 AI 摘要需走后端受控 API）
  static Future<String> generateConversationSummary({
    required String npcName,
    required List<Map<String, dynamic>> history,
    String? existingSummary,
  }) async {
    final String previous = (existingSummary ?? '').trim();
    final Iterable<String> recent = history.reversed
        .map(
          (Map<String, dynamic> turn) => (turn['text'] as String? ?? '').trim(),
        )
        .where((String item) => item.isNotEmpty)
        .take(4);
    final String summary = recent.toList(growable: false).reversed.join(' ');
    if (summary.isEmpty) {
      return previous;
    }
    return _truncateWords(
      previous.isEmpty ? '$npcName: $summary' : '$previous $summary',
      48,
    );
  }

  /// 生成场景反馈（本地 fallback；高成本 AI 反馈需走 practice session）
  static Future<Map<String, dynamic>> generateFeedback({
    required String title,
    required String goal,
    required String npcName,
    required List<Map<String, dynamic>> history,
    List<Map<String, dynamic>> voiceTurns = const <Map<String, dynamic>>[],
  }) async {
    return _okEnvelope(<String, dynamic>{
      'summary': '当前版本使用本地复盘占位；服务端反馈需要已创建的 practice session。',
      'turnReviews': const <Map<String, dynamic>>[],
      'suggestions': const <Map<String, dynamic>>[],
      'validationStatus': 'fallback',
      'providerStatus': 'not_routed',
    });
  }

  static Future<Map<String, dynamic>> scoreTrustedAudioRefForPronunciation({
    required String audioRef,
    required String referenceText,
  }) async {
    final String trustedAudioRef = _normalizeTrustedAudioRef(audioRef);
    final Map<String, dynamic> body =
        await _post(SpeakeasyApiPaths.aiPronunciation, <String, dynamic>{
          'schema_version': 1,
          'audio_ref': trustedAudioRef,
          'reference_text': referenceText,
        }, timeout: const Duration(seconds: 30));
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

  static Future<Map<String, dynamic>> scoreGrammar({
    required String text,
    String? targetText,
    String? questionText,
  }) async {
    final String cleanedText = text.trim();
    if (cleanedText.isEmpty) {
      return <String, dynamic>{
        'score': 0,
        'issues': <String>['empty_answer'],
        'correction': '',
        'provider': 'local_heuristic',
      };
    }
    final List<String> issues = <String>[];
    final int wordCount = cleanedText
        .split(RegExp(r'\s+'))
        .where((String item) => item.trim().isNotEmpty)
        .length;
    if (wordCount < 5) {
      issues.add('answer_too_short');
    }
    if (!RegExp(r'[.!?]$').hasMatch(cleanedText)) {
      issues.add('missing_terminal_punctuation');
    }
    final String? target = targetText?.trim();
    if (target != null &&
        target.isNotEmpty &&
        !cleanedText.toLowerCase().contains(target.toLowerCase())) {
      issues.add('target_expression_missing');
    }
    final int penalty = (issues.length * 12).clamp(0, 36);
    return <String, dynamic>{
      'score': (88 - penalty).clamp(45, 95),
      'issues': issues,
      'correction': cleanedText,
      'provider': 'local_heuristic',
    };
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
    copy('nickname', 'display_name');
    copy('avatarUrl', 'avatar_ref');
    copy('avatarRef', 'avatar_ref');
    copy('avatar_ref', 'avatar_ref');
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

  static String _legacyPracticeScenarioId({
    required String sceneTitle,
    required String npcRole,
    SceneSpec? sceneSpec,
  }) {
    final String combined = '${sceneSpec?.category ?? ''} $sceneTitle $npcRole'
        .toLowerCase();
    if (combined.contains('interview') ||
        combined.contains('candidate') ||
        combined.contains('recruit') ||
        combined.contains('hr')) {
      return 'job_interview';
    }
    return 'onboarding_introduction';
  }

  static String _legacyPracticeLevelCode(SceneSpec? sceneSpec) {
    if (sceneSpec == null) {
      return 'L1';
    }
    if (sceneSpec.pressureLevel >= 4 || sceneSpec.followupDepth >= 4) {
      return 'L3';
    }
    if (sceneSpec.pressureLevel >= 3 || sceneSpec.followupDepth >= 3) {
      return 'L2';
    }
    return 'L1';
  }

  static String _legacyPracticeTurnKey(String sessionId, String text) {
    final int now = DateTime.now().microsecondsSinceEpoch;
    final int textHash = Object.hash(sessionId.trim(), text.trim(), now);
    return 'legacy-scene-$now-${textHash.abs()}';
  }

  static String _truncateWords(String text, int maxWords) {
    final List<String> words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
    if (words.length <= maxWords) {
      return words.join(' ');
    }
    return '${words.take(maxWords).join(' ')}...';
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
