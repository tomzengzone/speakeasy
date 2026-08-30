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
    required this.credentials,
    required this.userJson,
  });

  final AuthCredentials credentials;
  final Map<String, dynamic> userJson;

  String get token => credentials.accessToken;
}

class StoredSessionSnapshot {
  const StoredSessionSnapshot({
    required this.user,
    required this.onboardingDone,
    required this.themeMode,
    bool? hasCredentials,
  }) : hasCredentials = hasCredentials ?? user != null;

  final AppUser? user;
  final bool onboardingDone;
  final ThemeMode themeMode;
  final bool hasCredentials;
}

abstract class SessionRemoteApi {
  Future<Map<String, dynamic>> refreshToken(String refreshToken);

  Future<Map<String, dynamic>> getMe();

  Future<Map<String, dynamic>> testPhoneLogin(String phone);
}

class ApiClientSessionRemoteApi implements SessionRemoteApi {
  const ApiClientSessionRemoteApi();

  @override
  Future<Map<String, dynamic>> getMe() => ApiClient.getMe();

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

abstract class SessionCredentialRefresher {
  Future<AuthCredentials> refreshIfNeeded();
}

class ApiClientSessionCredentialRefresher
    implements SessionCredentialRefresher {
  const ApiClientSessionCredentialRefresher();

  @override
  Future<AuthCredentials> refreshIfNeeded() {
    return ApiClient.refreshCredentialsIfNeeded();
  }
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
  StoredUserProfileModel? getUserProfile();

  UserPreferencesStorageModel getUserPreferences();
}

class StorageServiceSessionLocalStore implements SessionLocalStore {
  const StorageServiceSessionLocalStore();

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
    SessionCredentialRefresher credentialRefresher =
        const ApiClientSessionCredentialRefresher(),
    SessionLocalStore localStore = const StorageServiceSessionLocalStore(),
    DateTime Function()? now,
  }) : _authService = authService,
       _remoteApi = remoteApi,
       _credentialStore = credentialStore,
       _credentialRefresher = credentialRefresher,
       _localStore = localStore,
       _now = now ?? _utcNow;

  final AuthService _authService;
  final SessionRemoteApi _remoteApi;
  final SessionCredentialStore _credentialStore;
  final SessionCredentialRefresher _credentialRefresher;
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
    final StoredUserProfileModel? userProfile = _localStore.getUserProfile();
    final UserPreferencesStorageModel preferences = _localStore
        .getUserPreferences();

    AppUser? user;
    final String? token = credentials?.accessToken;
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
      hasCredentials: credentials != null,
    );
  }

  Future<ResolvedAuthenticatedSession?> hydrateExistingSession() async {
    final AuthCredentials? credentials = await _credentialStore.read();
    if (credentials == null || credentials.accessToken.isEmpty) {
      return null;
    }

    if (!credentials.needsRefreshAt(_now())) {
      return _hydrateWithCurrentAccessToken(credentials: credentials);
    }

    try {
      final AuthCredentials refreshedCredentials = await _credentialRefresher
          .refreshIfNeeded();
      return _hydrateWithCurrentAccessToken(credentials: refreshedCredentials);
    } on RefreshFailure catch (failure) {
      if (failure.kind == RefreshFailureKind.authentication ||
          credentials.isExpiredAt(_now())) {
        rethrow;
      }
      return _hydrateWithCurrentAccessToken(credentials: credentials);
    }
  }

  Future<AuthCredentials?> refreshForForeground() async {
    final AuthCredentials? credentials = await _credentialStore.read();
    if (credentials == null || credentials.accessToken.isEmpty) {
      return null;
    }
    try {
      return await _credentialRefresher.refreshIfNeeded();
    } on RefreshFailure catch (failure) {
      if (failure.kind == RefreshFailureKind.authentication ||
          credentials.isExpiredAt(_now())) {
        rethrow;
      }
      return credentials;
    }
  }

  Future<ResolvedAuthenticatedSession> _hydrateWithCurrentAccessToken({
    required AuthCredentials credentials,
  }) async {
    final Map<String, dynamic> meRes = await _remoteApi.getMe();
    if (meRes['code'] != 0) {
      throw Exception(meRes['message'] ?? '恢复登录状态失败');
    }
    return ResolvedAuthenticatedSession(
      credentials: credentials,
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
