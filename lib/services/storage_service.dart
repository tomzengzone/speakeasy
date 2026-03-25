import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/storage_models.dart';

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);
typedef JsonSerializer<T> = Map<String, dynamic> Function(T value);

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const String _boxName = 'speakeasy_storage';
  static const String _migrationVersionKey = '_storage_migration_version';
  static const int _migrationVersion = 1;

  static const String _userPreferencesKey = 'user_preferences';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _authSessionKey = 'auth_session';
  static const String _userProfileKey = 'user_profile';
  static const String _learningProgressKey = 'learning_progress';
  static const String _courseCacheKey = 'course_cache';
  static const String _learningStatsCacheKey = 'learning_stats_cache';
  static const String _conversationHistoryPrefix = 'conversation_history/';

  late final Box<dynamic> _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    await _migrateFromSharedPreferences();
    _initialized = true;
  }

  Future<void> saveObject<T>(
    String key,
    T value,
    JsonSerializer<T> toJson,
  ) async {
    _ensureInitialized();
    await _box.put(key, _normalizeValue(toJson(value)));
  }

  T? getObject<T>(String key, JsonFactory<T> fromJson) {
    _ensureInitialized();
    final Map<String, dynamic>? json = _asMap(_box.get(key));
    if (json == null) {
      return null;
    }
    return fromJson(json);
  }

  Future<void> saveList<T>(
    String key,
    List<T> values,
    JsonSerializer<T> toJson,
  ) async {
    _ensureInitialized();
    await _box.put(
      key,
      values
          .map((T value) => _normalizeValue(toJson(value)))
          .toList(growable: false),
    );
  }

  List<T> getList<T>(String key, JsonFactory<T> fromJson) {
    _ensureInitialized();
    final dynamic raw = _box.get(key);
    if (raw is! List) {
      return List<T>.empty(growable: false);
    }
    return raw
        .whereType<Map>()
        .map((Map item) => fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<void> remove(String key) async {
    _ensureInitialized();
    await _box.delete(key);
  }

  Future<void> saveAuthSession(AuthSessionStorageModel session) {
    return saveObject<AuthSessionStorageModel>(
      _authSessionKey,
      session,
      (AuthSessionStorageModel value) => value.toJson(),
    );
  }

  AuthSessionStorageModel? getAuthSession() {
    return getObject<AuthSessionStorageModel>(
      _authSessionKey,
      AuthSessionStorageModel.fromJson,
    );
  }

  Future<void> clearAuthSession() => remove(_authSessionKey);

  Future<void> saveUserProfile(StoredUserProfileModel profile) {
    return saveObject<StoredUserProfileModel>(
      _userProfileKey,
      profile,
      (StoredUserProfileModel value) => value.toJson(),
    );
  }

  StoredUserProfileModel? getUserProfile() {
    return getObject<StoredUserProfileModel>(
      _userProfileKey,
      StoredUserProfileModel.fromJson,
    );
  }

  Future<void> clearUserProfile() => remove(_userProfileKey);

  Future<void> saveUserPreferences(UserPreferencesStorageModel preferences) {
    return saveObject<UserPreferencesStorageModel>(
      _userPreferencesKey,
      preferences,
      (UserPreferencesStorageModel value) => value.toJson(),
    );
  }

  UserPreferencesStorageModel getUserPreferences() {
    return getObject<UserPreferencesStorageModel>(
          _userPreferencesKey,
          UserPreferencesStorageModel.fromJson,
        ) ??
        const UserPreferencesStorageModel();
  }

  Future<void> clearUserPreferences() => remove(_userPreferencesKey);

  Future<void> saveNotificationSettings(
    NotificationSettingsStorageModel settings,
  ) {
    return saveObject<NotificationSettingsStorageModel>(
      _notificationSettingsKey,
      settings,
      (NotificationSettingsStorageModel value) => value.toJson(),
    );
  }

  NotificationSettingsStorageModel getNotificationSettings() {
    return getObject<NotificationSettingsStorageModel>(
          _notificationSettingsKey,
          NotificationSettingsStorageModel.fromJson,
        ) ??
        const NotificationSettingsStorageModel();
  }

  Future<void> saveLearningProgress(LearningProgressStorageModel progress) {
    return saveObject<LearningProgressStorageModel>(
      _learningProgressKey,
      progress,
      (LearningProgressStorageModel value) => value.toJson(),
    );
  }

  LearningProgressStorageModel getLearningProgress() {
    return getObject<LearningProgressStorageModel>(
          _learningProgressKey,
          LearningProgressStorageModel.fromJson,
        ) ??
        const LearningProgressStorageModel();
  }

  Future<void> clearLearningProgress() => remove(_learningProgressKey);

  Future<void> saveCachedCourseData(CachedCourseDataStorageModel cache) {
    return saveObject<CachedCourseDataStorageModel>(
      _courseCacheKey,
      cache,
      (CachedCourseDataStorageModel value) => value.toJson(),
    );
  }

  CachedCourseDataStorageModel? getCachedCourseData({Duration? maxAge}) {
    final CachedCourseDataStorageModel? cache =
        getObject<CachedCourseDataStorageModel>(
          _courseCacheKey,
          CachedCourseDataStorageModel.fromJson,
        );
    if (cache == null) {
      return null;
    }
    if (maxAge != null &&
        cache.cachedAt != null &&
        DateTime.now().difference(cache.cachedAt!) > maxAge) {
      return null;
    }
    return cache;
  }

  Future<void> clearCachedCourseData() => remove(_courseCacheKey);

  Future<void> saveLearningStatsCache(LearningStatsCacheStorageModel cache) {
    return saveObject<LearningStatsCacheStorageModel>(
      _learningStatsCacheKey,
      cache,
      (LearningStatsCacheStorageModel value) => value.toJson(),
    );
  }

  LearningStatsCacheStorageModel? getLearningStatsCache({Duration? maxAge}) {
    final LearningStatsCacheStorageModel? cache =
        getObject<LearningStatsCacheStorageModel>(
          _learningStatsCacheKey,
          LearningStatsCacheStorageModel.fromJson,
        );
    if (cache == null) {
      return null;
    }
    if (maxAge != null &&
        cache.cachedAt != null &&
        DateTime.now().difference(cache.cachedAt!) > maxAge) {
      return null;
    }
    return cache;
  }

  Future<void> clearLearningStatsCache() => remove(_learningStatsCacheKey);

  Future<void> saveConversationHistory(
    ConversationHistoryStorageModel history,
  ) {
    return saveObject<ConversationHistoryStorageModel>(
      '$_conversationHistoryPrefix${history.sessionId}',
      history,
      (ConversationHistoryStorageModel value) => value.toJson(),
    );
  }

  ConversationHistoryStorageModel? getConversationHistory(String sessionId) {
    return getObject<ConversationHistoryStorageModel>(
      '$_conversationHistoryPrefix$sessionId',
      ConversationHistoryStorageModel.fromJson,
    );
  }

  List<ConversationHistoryStorageModel> getAllConversationHistories() {
    _ensureInitialized();
    return _box.keys
        .whereType<String>()
        .where((String key) => key.startsWith(_conversationHistoryPrefix))
        .map(
          (String key) => getObject<ConversationHistoryStorageModel>(
            key,
            ConversationHistoryStorageModel.fromJson,
          ),
        )
        .whereType<ConversationHistoryStorageModel>()
        .toList(growable: false);
  }

  Future<void> clearConversationHistory(String sessionId) {
    return remove('$_conversationHistoryPrefix$sessionId');
  }

  Future<void> _migrateFromSharedPreferences() async {
    final int version = (_box.get(_migrationVersionKey) as int?) ?? 0;
    if (version >= _migrationVersion) {
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('auth_token');
    if (!_box.containsKey(_authSessionKey) &&
        token != null &&
        token.trim().isNotEmpty) {
      await _box.put(_authSessionKey, <String, dynamic>{
        'token': token.trim(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }

    if (!_box.containsKey(_userProfileKey) &&
        (prefs.containsKey('user_nickname') ||
            prefs.containsKey('user_avatar_url') ||
            prefs.containsKey('user_member_plan') ||
            prefs.containsKey('onboarding_done'))) {
      await _box.put(_userProfileKey, <String, dynamic>{
        'nickname': (prefs.getString('user_nickname') ?? '').trim(),
        'avatarUrl': (prefs.getString('user_avatar_url') ?? '').trim(),
        'memberPlan': (prefs.getString('user_member_plan') ?? 'free').trim(),
        'onboardingDone': prefs.getBool('onboarding_done') ?? false,
      });
    }

    if (!_box.containsKey(_userPreferencesKey) &&
        (prefs.containsKey('onboarding_done') ||
            prefs.containsKey('theme_mode') ||
            prefs.containsKey('user_goals') ||
            prefs.containsKey('user_level') ||
            prefs.containsKey('daily_goal_minutes'))) {
      await _box.put(_userPreferencesKey, <String, dynamic>{
        'onboardingDone': prefs.getBool('onboarding_done') ?? false,
        'themeMode': prefs.getString('theme_mode') ?? 'light',
        'goals': _splitCsv(prefs.getString('user_goals')),
        'level': prefs.getInt('user_level'),
        'dailyGoalMinutes': prefs.getInt('daily_goal_minutes'),
      });
    }

    if (!_box.containsKey(_notificationSettingsKey) &&
        (prefs.containsKey('notif_enabled') ||
            prefs.containsKey('notif_hour') ||
            prefs.containsKey('notif_minute'))) {
      await _box.put(_notificationSettingsKey, <String, dynamic>{
        'enabled': prefs.getBool('notif_enabled') ?? false,
        'hour': prefs.getInt('notif_hour') ?? 20,
        'minute': prefs.getInt('notif_minute') ?? 0,
      });
    }

    if (!_box.containsKey(_learningProgressKey) &&
        (prefs.containsKey('saved_ids') ||
            prefs.containsKey('dismissed_ids') ||
            prefs.containsKey('completed_ids'))) {
      await _box.put(_learningProgressKey, <String, dynamic>{
        'savedIds': _parseLegacyIds(prefs.getString('saved_ids')),
        'dismissedIds': _parseLegacyIds(prefs.getString('dismissed_ids')),
        'completedIds': _parseLegacyIds(prefs.getString('completed_ids')),
      });
    }

    final String? rawStats = prefs.getString('learning_stats');
    if (!_box.containsKey(_learningStatsCacheKey) &&
        rawStats != null &&
        rawStats.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawStats);
        if (decoded is Map) {
          await _box.put(_learningStatsCacheKey, <String, dynamic>{
            'stats': decoded.cast<String, dynamic>(),
            'cachedAt':
                prefs.getString('learning_stats_cached_at') ??
                DateTime.now().toIso8601String(),
          });
        }
      } catch (_) {
        // Ignore invalid legacy cache payloads.
      }
    }

    await _box.put(_migrationVersionKey, _migrationVersion);
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('StorageService.init() must complete before use.');
    }
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  Object? _normalizeValue(Object? value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (dynamic key, dynamic item) =>
            MapEntry(key.toString(), _normalizeValue(item)),
      );
    }
    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }

  List<String> _splitCsv(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const <String>[];
    }
    return value
        .split(',')
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  List<int> _parseLegacyIds(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const <int>[];
    }
    final List<int> ids =
        value
            .split(',')
            .map((String item) => int.tryParse(item.trim()))
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    return ids;
  }
}
