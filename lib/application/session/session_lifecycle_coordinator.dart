import 'package:flutter/material.dart';

import 'package:speakeasy/core/constants/avatar_defaults.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/apple_auth_service.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/storage_service.dart';
import 'package:speakeasy/services/wechat_auth_service.dart';

typedef AppleSignIn = Future<AppleAuthResult> Function();
typedef WeChatSignIn = Future<WeChatAuthResult> Function();

class AuthenticatedSessionPayload {
  const AuthenticatedSessionPayload({
    required this.token,
    this.userJson = const <String, dynamic>{},
  });

  final String token;
  final Map<String, dynamic> userJson;
}

class SessionSignInResult {
  const SessionSignInResult.local({required this.user})
    : authenticatedSession = null;

  const SessionSignInResult.authenticated({
    required this.authenticatedSession,
  }) : user = null;

  final AppUser? user;
  final AuthenticatedSessionPayload? authenticatedSession;

  bool get hasAuthenticatedSession => authenticatedSession != null;
}

class ResolvedAuthenticatedSession {
  const ResolvedAuthenticatedSession({
    required this.token,
    required this.userJson,
  });

  final String token;
  final Map<String, dynamic> userJson;
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

  Future<void> saveToken(String token);

  Future<void> clearToken();

  Future<Map<String, dynamic>> refreshToken();

  Future<Map<String, dynamic>> getMe();

  Future<Map<String, dynamic>> testPhoneLogin(String phone);
}

class ApiClientSessionRemoteApi implements SessionRemoteApi {
  const ApiClientSessionRemoteApi();

  @override
  Future<void> clearToken() => ApiClient.clearToken();

  @override
  Future<Map<String, dynamic>> getMe() => ApiClient.getMe();

  @override
  Future<String?> getToken() => ApiClient.getToken();

  @override
  Future<Map<String, dynamic>> refreshToken() => ApiClient.refreshToken();

  @override
  Future<void> saveToken(String token) => ApiClient.saveToken(token);

  @override
  Future<Map<String, dynamic>> testPhoneLogin(String phone) {
    return ApiClient.testPhoneLogin(phone);
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
    SessionLocalStore localStore = const StorageServiceSessionLocalStore(),
  }) : _authService = authService,
       _remoteApi = remoteApi,
       _localStore = localStore;

  final AuthService _authService;
  final SessionRemoteApi _remoteApi;
  final SessionLocalStore _localStore;

  Future<SessionSignInResult> signIn(LoginSubmission submission) async {
    final AuthSession session = await _authService.signIn(submission);
    if (session.hasToken) {
      return SessionSignInResult.authenticated(
        authenticatedSession: AuthenticatedSessionPayload(
          token: session.token!,
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
      token: result.token,
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
      token: result.token,
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
    final String token = (data['token'] as String?) ?? '';
    if (token.isEmpty) {
      throw Exception('测试登录凭证无效');
    }

    return AuthenticatedSessionPayload(
      token: token,
      userJson: _asMap(data['user']),
    );
  }

  Future<StoredSessionSnapshot> loadStoredSession() async {
    final AuthSessionStorageModel? authSession = _localStore.getAuthSession();
    final StoredUserProfileModel? userProfile = _localStore.getUserProfile();
    final UserPreferencesStorageModel preferences = _localStore
        .getUserPreferences();

    AppUser? user;
    final String? token = authSession?.token;
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
    final String? token = await _remoteApi.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final Map<String, dynamic> refreshRes = await _remoteApi.refreshToken();
    if (refreshRes['code'] == 0) {
      final Map<String, dynamic> data = _asMap(refreshRes['data']);
      final String refreshedToken = (data['token'] as String?) ?? '';
      final String resolvedToken = refreshedToken.isNotEmpty
          ? refreshedToken
          : token;
      if (refreshedToken.isNotEmpty) {
        await _remoteApi.saveToken(refreshedToken);
      }
      return ResolvedAuthenticatedSession(
        token: resolvedToken,
        userJson: _asMap(data['user']),
      );
    }

    final Map<String, dynamic> meRes = await _remoteApi.getMe();
    if (meRes['code'] != 0) {
      throw Exception(meRes['message'] ?? refreshRes['message']);
    }
    return ResolvedAuthenticatedSession(
      token: token,
      userJson: _asMap(meRes['data']),
    );
  }

  Future<ResolvedAuthenticatedSession> resolveAuthenticatedSession(
    AuthenticatedSessionPayload payload,
  ) async {
    await _remoteApi.saveToken(payload.token);
    if (payload.userJson.isNotEmpty) {
      return ResolvedAuthenticatedSession(
        token: payload.token,
        userJson: payload.userJson,
      );
    }

    final Map<String, dynamic> meRes = await _remoteApi.getMe();
    if (meRes['code'] != 0) {
      throw Exception(meRes['message'] ?? '获取用户信息失败');
    }

    return ResolvedAuthenticatedSession(
      token: payload.token,
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
