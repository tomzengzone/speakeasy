import 'package:flutter/material.dart';

import 'package:speakeasy/core/constants/avatar_defaults.dart';
import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/apple_auth_service.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/storage_service.dart';
import 'package:speakeasy/services/wechat_auth_service.dart';

typedef AppleSignIn = Future<AppleAuthResult> Function();
typedef WeChatSignIn = Future<WeChatAuthResult> Function();

DateTime _utcNow() => DateTime.now().toUtc();

class AuthenticatedSessionPayload {
  const AuthenticatedSessionPayload({
    required this.credentials,
    this.userJson = const <String, dynamic>{},
  });

  final AuthCredentials credentials;
  final Map<String, dynamic> userJson;

  String get token => credentials.accessToken;
}

class SessionSignInResult {
  const SessionSignInResult.local({required this.user})
    : authenticatedSession = null;

  const SessionSignInResult.authenticated({required this.authenticatedSession})
    : user = null;

  final AppUser? user;
  final AuthenticatedSessionPayload? authenticatedSession;

  bool get hasAuthenticatedSession => authenticatedSession != null;
}

class ResolvedAuthenticatedSession {
  const ResolvedAuthenticatedSession({
    this.credentials,
    this.legacyAccessToken,
    required this.userJson,
  });

  final AuthCredentials? credentials;
  final String? legacyAccessToken;
  final Map<String, dynamic> userJson;

  String get token => credentials?.accessToken ?? legacyAccessToken ?? '';
}

class StoredSessionSnapshot {
  const StoredSessionSnapshot({
    required this.user,
    required this.onboardingDone,
    required this.themeMode,
  });

  final AppUser? user;
  final bool onboardingDone;
  final ThemeMode themeMode;
}

abstract class SessionRemoteApi {
  Future<String?> getToken();

  Future<Map<String, dynamic>> refreshToken(String refreshToken);

  Future<Map<String, dynamic>> getMe();

  Future<Map<String, dynamic>> testPhoneLogin(String phone);
}

class ApiClientSessionRemoteApi implements SessionRemoteApi {
  const ApiClientSessionRemoteApi();

  @override
  Future<Map<String, dynamic>> getMe() => ApiClient.getMe();

  @override
  Future<String?> getToken() => ApiClient.getToken();

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) {
    return ApiClient.refreshToken(refreshToken: refreshToken);
  }

  @override
  Future<Map<String, dynamic>> testPhoneLogin(String phone) {
    return ApiClient.testPhoneLogin(phone);
  }
}

abstract class SessionCredentialStore {
  Future<AuthCredentials?> read();

  Future<void> replace(AuthCredentials credentials);
}

class ApiClientSessionCredentialStore implements SessionCredentialStore {
  const ApiClientSessionCredentialStore();

  @override
  Future<AuthCredentials?> read() => ApiClient.getCredentials();

  @override
  Future<void> replace(AuthCredentials credentials) {
    return ApiClient.saveCredentials(credentials);
  }
}

abstract class SessionLocalStore {
  AuthSessionStorageModel? getAuthSession();

  StoredUserProfileModel? getUserProfile();

  UserPreferencesStorageModel getUserPreferences();
}

class StorageServiceSessionLocalStore implements SessionLocalStore {
  const StorageServiceSessionLocalStore();

  @override
  AuthSessionStorageModel? getAuthSession() {
    return StorageService.instance.getAuthSession();
  }

  @override
  UserPreferencesStorageModel getUserPreferences() {
    return StorageService.instance.getUserPreferences();
  }

  @override
  StoredUserProfileModel? getUserProfile() {
    return StorageService.instance.getUserProfile();
  }
}

class SessionLifecycleCoordinator {
  SessionLifecycleCoordinator({
    required AuthService authService,
    SessionRemoteApi remoteApi = const ApiClientSessionRemoteApi(),
    SessionCredentialStore credentialStore =
        const ApiClientSessionCredentialStore(),
    SessionLocalStore localStore = const StorageServiceSessionLocalStore(),
    DateTime Function()? now,
  }) : _authService = authService,
       _remoteApi = remoteApi,
       _credentialStore = credentialStore,
       _localStore = localStore,
       _now = now ?? _utcNow;

  final AuthService _authService;
  final SessionRemoteApi _remoteApi;
  final SessionCredentialStore _credentialStore;
  final SessionLocalStore _localStore;
  final DateTime Function() _now;

  Future<SessionSignInResult> signIn(LoginSubmission submission) async {
    final AuthSession session = await _authService.signIn(submission);
    if (session.hasToken) {
      return SessionSignInResult.authenticated(
        authenticatedSession: AuthenticatedSessionPayload(
          credentials: session.credentials!,
          userJson: session.userJson,
        ),
      );
    }
    return SessionSignInResult.local(user: session.user);
  }

  Future<AuthenticatedSessionPayload> signInWithApple({
    AppleSignIn? signIn,
  }) async {
    final AppleSignIn runner =
        signIn ?? const AppleAuthService().signInWithApple;
    final AppleAuthResult result = await runner();
    return AuthenticatedSessionPayload(
      credentials: result.credentials,
      userJson: result.userJson,
    );
  }

  Future<AuthenticatedSessionPayload> signInWithWeChat({
    WeChatSignIn? signIn,
  }) async {
    final WeChatSignIn runner =
        signIn ?? WeChatAuthService.instance.sendWeChatAuth;
    final WeChatAuthResult result = await runner();
    return AuthenticatedSessionPayload(
      credentials: result.credentials,
      userJson: result.userJson,
    );
  }

  Future<AuthenticatedSessionPayload> signInWithTestPhone({
    required String phone,
  }) async {
    final Map<String, dynamic> res = await _remoteApi.testPhoneLogin(
      phone.trim(),
    );
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '测试登录失败');
    }

    final Map<String, dynamic> data = _asMap(res['data']);
    final AuthCredentials credentials;
    try {
      credentials = AuthCredentials.fromJson(data);
    } on FormatException {
      throw Exception('测试登录凭证无效');
    }

    return AuthenticatedSessionPayload(
      credentials: credentials,
      userJson: _asMap(data['user']),
    );
  }

  Future<StoredSessionSnapshot> loadStoredSession() async {
    final AuthCredentials? credentials = await _credentialStore.read();
    final AuthSessionStorageModel? authSession = _localStore.getAuthSession();
    final StoredUserProfileModel? userProfile = _localStore.getUserProfile();
    final UserPreferencesStorageModel preferences = _localStore
        .getUserPreferences();

    AppUser? user;
    final String? token = credentials?.accessToken ?? authSession?.token;
    if (token != null && token.isNotEmpty && userProfile != null) {
      final String nickname = userProfile.nickname.trim();
      if (nickname.isNotEmpty) {
        user = userProfile.toAppUser().copyWith(
          avatarUrl: userProfile.avatarUrl.isEmpty
              ? defaultAvatarUrls.first
              : userProfile.avatarUrl,
        );
      }
    }

    return StoredSessionSnapshot(
      user: user,
      onboardingDone: preferences.onboardingDone,
      themeMode: preferences.themeMode,
    );
  }

  Future<ResolvedAuthenticatedSession?> hydrateExistingSession() async {
    final AuthCredentials? credentials = await _credentialStore.read();
    final String? token =
        credentials?.accessToken ?? await _remoteApi.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    if (credentials == null) {
      return _hydrateWithCurrentAccessToken(
        credentials: null,
        legacyAccessToken: token,
      );
    }

    if (!credentials.needsRefreshAt(_now())) {
      return _hydrateWithCurrentAccessToken(credentials: credentials);
    }

    try {
      final Map<String, dynamic> refreshRes = await _remoteApi.refreshToken(
        credentials.refreshToken,
      );
      if (refreshRes['code'] != 0) {
        throw StateError('Refresh API returned an unsuccessful envelope');
      }
      final Map<String, dynamic> data = _asMap(refreshRes['data']);
      final AuthCredentials refreshedCredentials = AuthCredentials.fromJson(
        data,
      );
      await _credentialStore.replace(refreshedCredentials);
      return ResolvedAuthenticatedSession(
        credentials: refreshedCredentials,
        userJson: _asMap(data['user']),
      );
    } on RefreshFailure catch (failure) {
      if (failure.kind == RefreshFailureKind.authentication ||
          credentials.isExpiredAt(_now())) {
        rethrow;
      }
      return _hydrateWithCurrentAccessToken(credentials: credentials);
    }
  }

  Future<ResolvedAuthenticatedSession> _hydrateWithCurrentAccessToken({
    required AuthCredentials? credentials,
    String? legacyAccessToken,
  }) async {
    final Map<String, dynamic> meRes = await _remoteApi.getMe();
    if (meRes['code'] != 0) {
      throw Exception(meRes['message'] ?? '恢复登录状态失败');
    }
    return ResolvedAuthenticatedSession(
      credentials: credentials,
      legacyAccessToken: legacyAccessToken,
      userJson: _asMap(meRes['data']),
    );
  }

  Future<ResolvedAuthenticatedSession> resolveAuthenticatedSession(
    AuthenticatedSessionPayload payload,
  ) async {
    await _credentialStore.replace(payload.credentials);
    if (payload.userJson.isNotEmpty) {
      return ResolvedAuthenticatedSession(
        credentials: payload.credentials,
        userJson: payload.userJson,
      );
    }

    final Map<String, dynamic> meRes = await _remoteApi.getMe();
    if (meRes['code'] != 0) {
      throw Exception(meRes['message'] ?? '获取用户信息失败');
    }

    return ResolvedAuthenticatedSession(
      credentials: payload.credentials,
      userJson: _asMap(meRes['data']),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
