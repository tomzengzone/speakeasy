import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/core/auth/credential_repository.dart';
import 'package:speakeasy/core/auth/installation_id_store.dart';
import 'package:speakeasy/core/auth/refresh_coordinator.dart';
import 'package:speakeasy/core/auth/secure_token_store.dart';
import 'package:speakeasy/core/auth/token_provider.dart';
import 'package:speakeasy/generated/api/speakeasy_api.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/services/authenticated_request_executor.dart';
import 'package:speakeasy/services/storage_service.dart';

typedef ContentGet = Future<Map<String, dynamic>> Function(String path);
typedef AuthPost =
    Future<Map<String, dynamic>> Function(
      String path,
      Map<String, dynamic> body,
    );

enum _HttpMethod { get, post, put, patch, delete }

enum RefreshFailureKind { authentication, rateLimited, infrastructure }

enum SessionSecurityReason {
  accessTokenInvalid,
  sessionRevoked,
  refreshTokenExpired,
  refreshTokenInvalid,
  tokenReuseDetected,
  accountDisabled,
}

class SessionSecurityFailure implements Exception {
  const SessionSecurityFailure({
    required this.reason,
    required this.backendCode,
    required this.userMessage,
  });

  final SessionSecurityReason reason;
  final String backendCode;
  final String userMessage;

  @override
  String toString() => 'SessionSecurityFailure($backendCode)';
}

class RefreshFailure implements Exception {
  const RefreshFailure({
    required this.kind,
    required this.message,
    this.httpStatus,
    this.backendCode,
    this.cause,
  });

  final RefreshFailureKind kind;
  final String message;
  final int? httpStatus;
  final String? backendCode;
  final Object? cause;

  @override
  String toString() => 'RefreshFailure($kind, $message)';
}

class RateLimitedRefreshFailure extends RefreshFailure
    implements RefreshRateLimitSignal {
  const RateLimitedRefreshFailure({
    required super.message,
    required this.retryAfter,
    super.httpStatus,
    super.backendCode,
  }) : super(kind: RefreshFailureKind.rateLimited);

  @override
  final Duration retryAfter;
}

enum ContentApiFailureKind {
  unauthenticated,
  notFound,
  retryable,
  nonRetryable,
  invalidResponse,
}

class ContentApiFailure implements Exception {
  const ContentApiFailure({
    required this.kind,
    required this.message,
    this.requestId,
  });

  final ContentApiFailureKind kind;
  final String message;
  final String? requestId;

  @override
  String toString() => 'ContentApiFailure($kind, $message)';
}

abstract interface class CourseCatalogApi {
  Future<ScenarioListResponse> listContentThemes();

  Future<CourseListResponse> listScenarioCourses(ScenarioId scenarioId);

  Future<CourseDetailResponse> getCourseVersionDetail(
    String courseId,
    String courseVersionId,
  );
}

class ApiClientCourseCatalogApi implements CourseCatalogApi {
  const ApiClientCourseCatalogApi() : _get = null;

  const ApiClientCourseCatalogApi.withTransport(ContentGet get) : _get = get;

  final ContentGet? _get;

  @override
  Future<ScenarioListResponse> listContentThemes() {
    return ApiClient._readContent(
      SpeakeasyApiPaths.scenarios,
      ScenarioListResponse.fromJson,
      transport: _get,
    );
  }

  @override
  Future<CourseListResponse> listScenarioCourses(ScenarioId scenarioId) {
    return ApiClient._readContent(
      SpeakeasyApiPaths.scenarioCourses(scenarioId.wireValue),
      CourseListResponse.fromJson,
      transport: _get,
    );
  }

  @override
  Future<CourseDetailResponse> getCourseVersionDetail(
    String courseId,
    String courseVersionId,
  ) {
    return ApiClient._readContent(
      SpeakeasyApiPaths.courseVersion(courseId, courseVersionId),
      CourseDetailResponse.fromJson,
      transport: _get,
    );
  }
}

class ApiClient {
  static String? _pendingAccountDeletionKey;
  static final StreamController<SessionSecurityFailure>
  _sessionSecurityFailures = StreamController<SessionSecurityFailure>.broadcast(
    sync: true,
  );
  static final SecureTokenStore _secureTokenStore = SecureTokenStore();
  static final InstallationIdStore _installationIds = InstallationIdStore();
  static final CredentialRepository _credentialRepository =
      SecureCredentialRepository(
        tokenStore: _secureTokenStore,
        clearLegacyAuthSession: StorageService.instance.clearAuthSession,
      );
  static final TokenProvider _tokenProvider = SecureTokenProvider(
    _credentialRepository,
  );
  static final RefreshCoordinator _refreshCoordinator = RefreshCoordinator(
    tokenProvider: _tokenProvider,
    credentialRepository: _credentialRepository,
    refreshCredentials: _refreshRuntimeCredentials,
  );
  static final AuthenticatedRequestExecutor _requestExecutor =
      AuthenticatedRequestExecutor(
        tokenProvider: _tokenProvider,
        refreshCoordinator: _refreshCoordinator,
      );

  static Stream<SessionSecurityFailure> get sessionSecurityFailures =>
      _sessionSecurityFailures.stream;

  static Future<AuthCredentials?> getCredentials() {
    return _tokenProvider.getCredentials();
  }

  static Future<void> saveCredentials(AuthCredentials credentials) async {
    await _credentialRepository.replace(credentials);
  }

  static Future<String?> getToken() async {
    final AuthCredentials? credentials = await getCredentials();
    return credentials?.accessToken;
  }

  @Deprecated('Persist complete AuthCredentials through CredentialRepository.')
  static Future<void> saveToken(String token) async {
    final AuthCredentials? credentials = await getCredentials();
    if (credentials == null) {
      throw StateError('Complete authentication credentials are required');
    }
    await saveCredentials(credentials.copyWith(accessToken: token));
  }

  static Future<void> clearToken() async {
    await _credentialRepository.clear();
  }

  static SessionSecurityFailure? _sessionSecurityFailure(
    Map<String, dynamic> response,
  ) {
    final Map<String, dynamic> error = _asMap(response['error']);
    final ErrorCode? code = ErrorCode.tryParse(error['code']);
    return switch (code) {
      ErrorCode.accessTokenInvalid => const SessionSecurityFailure(
        reason: SessionSecurityReason.accessTokenInvalid,
        backendCode: 'ACCESS_TOKEN_INVALID',
        userMessage: '登录凭证无效，请重新登录。',
      ),
      ErrorCode.sessionRevoked => const SessionSecurityFailure(
        reason: SessionSecurityReason.sessionRevoked,
        backendCode: 'SESSION_REVOKED',
        userMessage: '此设备的登录已被退出，请重新登录。',
      ),
      ErrorCode.refreshTokenExpired => const SessionSecurityFailure(
        reason: SessionSecurityReason.refreshTokenExpired,
        backendCode: 'REFRESH_TOKEN_EXPIRED',
        userMessage: '登录已过期，请重新登录。',
      ),
      ErrorCode.refreshTokenInvalid => const SessionSecurityFailure(
        reason: SessionSecurityReason.refreshTokenInvalid,
        backendCode: 'REFRESH_TOKEN_INVALID',
        userMessage: '登录已失效，请重新登录。',
      ),
      ErrorCode.tokenReuseDetected => const SessionSecurityFailure(
        reason: SessionSecurityReason.tokenReuseDetected,
        backendCode: 'TOKEN_REUSE_DETECTED',
        userMessage: '检测到登录凭证异常，为保护账号已退出登录，请重新登录。',
      ),
      ErrorCode.accountDisabled => const SessionSecurityFailure(
        reason: SessionSecurityReason.accountDisabled,
        backendCode: 'ACCOUNT_DISABLED',
        userMessage: '账号已被禁用，如有疑问请联系支持。',
      ),
      _ => null,
    };
  }

  static Future<Never> _terminateSession(SessionSecurityFailure failure) async {
    try {
      await clearToken();
    } catch (_) {
      // The AppSession listener also clears local session data.
    }
    _sessionSecurityFailures.add(failure);
    throw failure;
  }

  static Future<void> _throwIfTerminalSessionResponse(
    http.Response response,
  ) async {
    final String raw = response.body.trim();
    if (raw.isEmpty) {
      return;
    }
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final SessionSecurityFailure? failure = _sessionSecurityFailure(
        decoded.cast<String, dynamic>(),
      );
      if (failure != null) {
        await _terminateSession(failure);
      }
    } on SessionSecurityFailure {
      rethrow;
    } on FormatException {
      return;
    }
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
        return <String, dynamic>{
          'code': 0,
          '_httpStatus': response.statusCode,
          '_responseHeaders': _responseHeaders(response),
        };
      }
      throw Exception('服务器返回空响应');
    }

    final dynamic decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return <String, dynamic>{
        ...decoded,
        '_httpStatus': response.statusCode,
        '_responseHeaders': _responseHeaders(response),
      };
    }
    if (decoded is Map) {
      return <String, dynamic>{
        ...decoded.cast<String, dynamic>(),
        '_httpStatus': response.statusCode,
        '_responseHeaders': _responseHeaders(response),
      };
    }
    return <String, dynamic>{
      'code': response.statusCode >= 200 && response.statusCode < 300
          ? 0
          : response.statusCode,
      'data': decoded,
      '_httpStatus': response.statusCode,
      '_responseHeaders': _responseHeaders(response),
    };
  }

  static Map<String, String> _responseHeaders(http.Response response) {
    return <String, String>{
      for (final MapEntry<String, String> header in response.headers.entries)
        header.key.toLowerCase(): header.value,
    };
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    return _executeRequest(method: _HttpMethod.get, path: path);
  }

  static Future<T> _readContent<T>(
    String path,
    T Function(Object? value) decode, {
    ContentGet? transport,
  }) async {
    late final Map<String, dynamic> response;
    try {
      response = await (transport ?? _get)(path);
    } on ContentApiFailure {
      rethrow;
    } catch (_) {
      throw const ContentApiFailure(
        kind: ContentApiFailureKind.retryable,
        message: '内容获取失败，请稍后重试',
      );
    }

    final int? statusCode = (response['_httpStatus'] as num?)?.toInt();
    if (statusCode != null && (statusCode < 200 || statusCode >= 300)) {
      throw _contentFailure(response, statusCode);
    }
    try {
      return decode(response);
    } on FormatException catch (error) {
      throw ContentApiFailure(
        kind: ContentApiFailureKind.invalidResponse,
        message: error.message.toString(),
      );
    } catch (_) {
      throw const ContentApiFailure(
        kind: ContentApiFailureKind.invalidResponse,
        message: '内容响应格式无效',
      );
    }
  }

  static ContentApiFailure _contentFailure(
    Map<String, dynamic> response,
    int statusCode,
  ) {
    ApiError? apiError;
    try {
      apiError = ErrorResponse.fromJson(response).error;
    } on FormatException {
      apiError = null;
    }

    final ContentApiFailureKind kind;
    if (statusCode == 401 || apiError?.code == ErrorCode.unauthenticated) {
      kind = ContentApiFailureKind.unauthenticated;
    } else if (statusCode == 404 ||
        apiError?.code == ErrorCode.resourceNotFound) {
      kind = ContentApiFailureKind.notFound;
    } else if (apiError?.details?.retryable == true || statusCode >= 500) {
      kind = ContentApiFailureKind.retryable;
    } else {
      kind = ContentApiFailureKind.nonRetryable;
    }
    return ContentApiFailure(
      kind: kind,
      message: apiError?.message.trim().isNotEmpty == true
          ? apiError!.message
          : '内容获取失败（$statusCode）',
      requestId: apiError?.requestId,
    );
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool allowEmpty = false,
    AuthPolicy authPolicy = AuthPolicy.required,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String> headers = const <String, String>{},
  }) async {
    return _executeRequest(
      method: _HttpMethod.post,
      path: path,
      body: body,
      allowEmpty: allowEmpty,
      authPolicy: authPolicy,
      timeout: timeout,
      headers: headers,
    );
  }

  static Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    return _executeRequest(method: _HttpMethod.put, path: path, body: body);
  }

  static Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    return _executeRequest(
      method: _HttpMethod.patch,
      path: path,
      body: body,
      headers: headers,
    );
  }

  static Future<Map<String, dynamic>> _delete(
    String path, {
    bool allowEmpty = false,
    Map<String, String> headers = const <String, String>{},
  }) async {
    return _executeRequest(
      method: _HttpMethod.delete,
      path: path,
      allowEmpty: allowEmpty,
      headers: headers,
    );
  }

  static Future<Map<String, dynamic>> _executeRequest({
    required _HttpMethod method,
    required String path,
    Map<String, dynamic>? body,
    bool allowEmpty = false,
    AuthPolicy authPolicy = AuthPolicy.required,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String> headers = const <String, String>{},
  }) async {
    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final String? encodedBody = body == null ? null : jsonEncode(body);
    final Map<String, String> requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...headers,
    };
    final http.Response response = await _requestExecutor.execute(
      authPolicy: authPolicy,
      headers: requestHeaders,
      send: (Map<String, String> resolvedHeaders) async {
        final Future<http.Response> request = switch (method) {
          _HttpMethod.get => http.get(uri, headers: resolvedHeaders),
          _HttpMethod.post => http.post(
            uri,
            headers: resolvedHeaders,
            body: encodedBody,
          ),
          _HttpMethod.put => http.put(
            uri,
            headers: resolvedHeaders,
            body: encodedBody,
          ),
          _HttpMethod.patch => http.patch(
            uri,
            headers: resolvedHeaders,
            body: encodedBody,
          ),
          _HttpMethod.delete => http.delete(uri, headers: resolvedHeaders),
        };
        final http.Response response = await request.timeout(timeout);
        await _throwIfTerminalSessionResponse(response);
        return response;
      },
    );
    return _decodeResponse(response, allowEmpty: allowEmpty);
  }

  static Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    final String? installationId = await _installationId();
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.authPhoneVerificationCode,
      <String, dynamic>{
        'schema_version': 1,
        'phone_number': phone.trim(),
        'device_id': ?installationId,
      },
      authPolicy: AuthPolicy.none,
    );
    _ensureSuccess(response, fallback: '验证码发送失败');
    return _okEnvelope(<String, dynamic>{
      'status': response['status'],
      'phoneNumber': phone.trim(),
    });
  }

  static Future<Map<String, dynamic>> verifySmsCode(
    String phone,
    String code,
  ) async {
    final Map<String, dynamic> deviceMetadata = await _loginDeviceMetadata();
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.authLoginPhone, <String, dynamic>{
          'schema_version': 1,
          'phone_number': phone.trim(),
          'verification_code': code.trim(),
          'terms_accepted': true,
          ...deviceMetadata,
        }, authPolicy: AuthPolicy.none);
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
    String? nonce,
  }) async {
    final Map<String, dynamic> deviceMetadata = await _loginDeviceMetadata();
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.authLoginApple, <String, dynamic>{
          'schema_version': 1,
          'provider_token': identityToken.trim().isNotEmpty
              ? identityToken.trim()
              : authorizationCode.trim(),
          if (nonce != null && nonce.trim().isNotEmpty) 'nonce': nonce.trim(),
          'terms_accepted': true,
          ...deviceMetadata,
        }, authPolicy: AuthPolicy.none);
    return _authSessionEnvelope(response);
  }

  static Future<Map<String, dynamic>> signInWithWeChat({
    required String code,
    String? state,
  }) async {
    final Map<String, dynamic> deviceMetadata = await _loginDeviceMetadata();
    final Map<String, dynamic> response =
        await _post(SpeakeasyApiPaths.authLoginWechat, <String, dynamic>{
          'schema_version': 1,
          'provider_token': code.trim(),
          if (state != null && state.trim().isNotEmpty) 'nonce': state.trim(),
          'terms_accepted': true,
          ...deviceMetadata,
        }, authPolicy: AuthPolicy.none);
    return _authSessionEnvelope(response);
  }

  static Future<Map<String, dynamic>> _loginDeviceMetadata() async {
    final ({String name, String platform}) device =
        switch (defaultTargetPlatform) {
          TargetPlatform.iOS => (name: 'iOS device', platform: 'ios'),
          TargetPlatform.android => (
            name: 'Android device',
            platform: 'android',
          ),
          _ => (name: 'Unknown device', platform: 'unknown'),
        };
    String? appVersion;
    try {
      final String resolvedVersion = (await PackageInfo.fromPlatform()).version
          .trim();
      if (resolvedVersion.isNotEmpty) {
        appVersion = resolvedVersion;
      }
    } catch (_) {
      // Optional device metadata must never block authentication.
    }
    final String? installationId = await _installationId();
    return <String, dynamic>{
      'device_id': ?installationId,
      'device_name': device.name,
      'platform': device.platform,
      'app_version': ?appVersion,
    };
  }

  static Future<String?> _installationId() async {
    try {
      return await _installationIds.readOrCreate();
    } catch (_) {
      // Installation metadata is supplemental and must not block authentication.
      return null;
    }
  }

  static Future<Map<String, dynamic>> refreshToken({
    String? refreshToken,
    AuthPost? transport,
  }) async {
    final String resolvedRefreshToken =
        (refreshToken ?? (await getCredentials())?.refreshToken ?? '').trim();
    if (resolvedRefreshToken.isEmpty) {
      return <String, dynamic>{
        'code': 401,
        'message': '本地没有可用的 refresh token。',
      };
    }

    late final Map<String, dynamic> response;
    try {
      final String? installationId = await _installationId();
      response =
          await (transport ??
              (String path, Map<String, dynamic> body) => _post(
                path,
                body,
                authPolicy: AuthPolicy.none,
              ))(SpeakeasyApiPaths.authRefresh, <String, dynamic>{
            'schema_version': 1,
            'refresh_token': resolvedRefreshToken,
            'device_id': ?installationId,
          });
    } on SessionSecurityFailure {
      rethrow;
    } on RefreshFailure {
      rethrow;
    } catch (error) {
      throw RefreshFailure(
        kind: RefreshFailureKind.infrastructure,
        message: '刷新登录状态失败，请检查网络连接。',
        cause: error,
      );
    }

    final int? statusCode = (response['_httpStatus'] as num?)?.toInt();
    if (statusCode != null && (statusCode < 200 || statusCode >= 300)) {
      final Map<String, dynamic> error = _asMap(response['error']);
      final String backendCode = (error['code'] as String? ?? '').trim();
      final String backendMessage = (error['message'] as String? ?? '').trim();
      final SessionSecurityFailure? securityFailure = _sessionSecurityFailure(
        response,
      );
      if (securityFailure != null) {
        await _terminateSession(securityFailure);
      }
      if (statusCode == 429 && backendCode == 'AUTH_RATE_LIMITED') {
        throw RateLimitedRefreshFailure(
          message: backendMessage.isEmpty ? '刷新请求过于频繁，请稍后再试。' : backendMessage,
          retryAfter: _retryAfter(response),
          httpStatus: statusCode,
          backendCode: backendCode,
        );
      }
      if ((statusCode == 400 || statusCode == 401 || statusCode == 403) &&
          backendCode == 'UNAUTHENTICATED') {
        throw RefreshFailure(
          kind: RefreshFailureKind.authentication,
          message: backendMessage.isEmpty ? '登录凭证已失效。' : backendMessage,
          httpStatus: statusCode,
          backendCode: backendCode,
        );
      }
      if (statusCode >= 500 && statusCode < 600) {
        throw RefreshFailure(
          kind: RefreshFailureKind.infrastructure,
          message: backendMessage.isEmpty ? '认证服务暂时不可用。' : backendMessage,
          httpStatus: statusCode,
          backendCode: backendCode.isEmpty ? null : backendCode,
        );
      }
    }
    return _authSessionEnvelope(response);
  }

  static Duration _retryAfter(Map<String, dynamic> response) {
    final Map<String, dynamic> rawHeaders = _asMap(
      response['_responseHeaders'],
    );
    String raw = '';
    for (final MapEntry<String, dynamic> header in rawHeaders.entries) {
      if (header.key.toLowerCase() == 'retry-after') {
        raw = header.value?.toString().trim() ?? '';
        break;
      }
    }
    final int parsed = int.tryParse(raw) ?? 5;
    return Duration(seconds: parsed.clamp(5, 300));
  }

  static Future<AuthCredentials> _refreshRuntimeCredentials(
    String refreshToken,
  ) async {
    final Map<String, dynamic> response = await ApiClient.refreshToken(
      refreshToken: refreshToken,
    );
    return AuthCredentials.fromJson(_asMap(response['data']));
  }

  static Future<Map<String, dynamic>> getMe() async {
    final Map<String, dynamic> response = await _get(SpeakeasyApiPaths.userMe);
    _ensureSuccess(response, fallback: '获取用户信息失败');
    return _okEnvelope(_appUserJson(_asMap(response['user'])));
  }

  static Future<Map<String, dynamic>> listAuthSessions() async {
    final Map<String, dynamic> response = await _get(
      SpeakeasyApiPaths.authSessions,
    );
    _ensureSuccess(response, fallback: '获取设备会话失败');
    return response;
  }

  static Future<void> revokeAuthSession(String sessionId) async {
    final String resolvedSessionId = sessionId.trim();
    if (resolvedSessionId.isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must not be empty');
    }
    final Map<String, dynamic> response = await _delete(
      SpeakeasyApiPaths.authSession(resolvedSessionId),
      allowEmpty: true,
    );
    _ensureSuccess(response, fallback: '退出该设备失败');
  }

  static Future<void> logoutOtherSessions() async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.authLogoutOthers,
      const <String, dynamic>{},
      allowEmpty: true,
    );
    _ensureSuccess(response, fallback: '退出其他设备失败');
  }

  static Future<void> logoutAllSessions() async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.authLogoutAll,
      const <String, dynamic>{},
      allowEmpty: true,
    );
    _ensureSuccess(response, fallback: '退出全部设备失败');
  }

  static Future<void> logoutCurrentSession() async {
    final Map<String, dynamic> response = await _post(
      SpeakeasyApiPaths.authLogout,
      const <String, dynamic>{},
      allowEmpty: true,
    );
    _ensureSuccess(response, fallback: '退出登录失败');
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
    final AuthCredentials credentials =
        AuthCredentials.fromJson(<String, dynamic>{
          'accessToken': response['access_token'],
          'refreshToken': response['refresh_token'],
          'expiresAt': response['expires_at'],
        });
    return _okEnvelope(<String, dynamic>{
      ...credentials.toJson(),
      'token': credentials.accessToken,
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
      return 'A2';
    }
    if (sceneSpec.pressureLevel >= 4 || sceneSpec.followupDepth >= 4) {
      return 'B2';
    }
    if (sceneSpec.pressureLevel >= 3 || sceneSpec.followupDepth >= 3) {
      return 'B1';
    }
    return 'A2';
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
