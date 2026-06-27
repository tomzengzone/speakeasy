import 'package:flutter/material.dart';

import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/storage_service.dart';

abstract class SessionProfileRemoteApi {
  Future<String?> getToken();

  Future<void> clearToken();

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> patch);

  Future<Map<String, dynamic>> submitOnboardingAssessment(
    Map<String, dynamic> assessment,
  );

  Future<Map<String, dynamic>> deleteAccount();
}

class ApiClientSessionProfileRemoteApi implements SessionProfileRemoteApi {
  const ApiClientSessionProfileRemoteApi();

  @override
  Future<void> clearToken() => ApiClient.clearToken();

  @override
  Future<String?> getToken() => ApiClient.getToken();

  @override
  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> patch) {
    return ApiClient.updateMe(patch);
  }

  @override
  Future<Map<String, dynamic>> submitOnboardingAssessment(
    Map<String, dynamic> assessment,
  ) {
    return ApiClient.submitOnboardingAssessment(
      goalDirection: assessment['goal_direction'] as String,
      painPoints: (assessment['pain_points'] as List<dynamic>)
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      outputLevel: assessment['output_level'] as String,
      dailyMinutes: assessment['daily_minutes'] as int,
    );
  }

  @override
  Future<Map<String, dynamic>> deleteAccount() {
    return ApiClient.deleteAccount();
  }
}

abstract class SessionProfileLocalStore {
  Future<void> clearUserPreferences();

  Future<void> clearUserProfile();

  UserPreferencesStorageModel getUserPreferences();

  Future<void> saveUserPreferences(UserPreferencesStorageModel preferences);

  Future<void> saveUserProfile(StoredUserProfileModel profile);
}

class StorageServiceSessionProfileLocalStore
    implements SessionProfileLocalStore {
  const StorageServiceSessionProfileLocalStore();

  @override
  Future<void> clearUserPreferences() {
    return StorageService.instance.clearUserPreferences();
  }

  @override
  Future<void> clearUserProfile() {
    return StorageService.instance.clearUserProfile();
  }

  @override
  UserPreferencesStorageModel getUserPreferences() {
    return StorageService.instance.getUserPreferences();
  }

  @override
  Future<void> saveUserPreferences(UserPreferencesStorageModel preferences) {
    return StorageService.instance.saveUserPreferences(preferences);
  }

  @override
  Future<void> saveUserProfile(StoredUserProfileModel profile) {
    return StorageService.instance.saveUserProfile(profile);
  }
}

class SessionProfileCoordinator {
  SessionProfileCoordinator({
    SessionProfileRemoteApi remoteApi =
        const ApiClientSessionProfileRemoteApi(),
    SessionProfileLocalStore localStore =
        const StorageServiceSessionProfileLocalStore(),
  }) : _remoteApi = remoteApi,
       _localStore = localStore;

  final SessionProfileRemoteApi _remoteApi;
  final SessionProfileLocalStore _localStore;

  Future<void> persistUser(AppUser? user) async {
    if (user == null) {
      return;
    }
    await _localStore.saveUserProfile(StoredUserProfileModel.fromAppUser(user));
    await _localStore.saveUserPreferences(
      _localStore.getUserPreferences().copyWith(
        onboardingDone: user.onboardingDone,
      ),
    );
  }

  Future<void> persistOnboarding({
    required AppUser? user,
    required List<String> goals,
    required int level,
    required int dailyMinutes,
  }) async {
    await _localStore.saveUserPreferences(
      _localStore.getUserPreferences().copyWith(
        onboardingDone: true,
        goals: goals,
        level: level,
        dailyGoalMinutes: dailyMinutes,
      ),
    );
    await persistUser(user);
  }

  Future<void> persistThemeMode(ThemeMode mode) async {
    await _localStore.saveUserPreferences(
      _localStore.getUserPreferences().copyWith(themeMode: mode),
    );
  }

  Future<Map<String, dynamic>?> syncUserPatch(
    Map<String, dynamic> patch,
  ) async {
    if (patch.isEmpty) {
      return null;
    }

    final String? token = await _remoteApi.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final Map<String, dynamic> res = await _remoteApi.updateMe(patch);
    if (res['code'] != 0 || res['data'] == null) {
      return null;
    }

    final Map<String, dynamic> data = _asMap(res['data']);
    return data.isEmpty ? null : data;
  }

  Future<void> syncOnboardingAssessment({
    required String goalDirection,
    required List<String> painPoints,
    required String outputLevel,
    required int dailyMinutes,
  }) async {
    final String? token = await _remoteApi.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final Map<String, dynamic> res = await _remoteApi
        .submitOnboardingAssessment(<String, dynamic>{
          'goal_direction': goalDirection,
          'pain_points': painPoints,
          'output_level': outputLevel,
          'daily_minutes': dailyMinutes,
        });
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '首评结果同步失败');
    }
  }

  Future<void> deleteAccount() async {
    final String? token = await _remoteApi.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('请先登录后再注销账号');
    }

    await _remoteApi.deleteAccount();
    await clearSessionData();
  }

  Future<void> clearSessionData() async {
    await _localStore.clearUserProfile();
    await _localStore.clearUserPreferences();
    await _remoteApi.clearToken();
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
