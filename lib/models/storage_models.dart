import 'package:flutter/material.dart';

import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/auth_models.dart';
import 'learning_stats_model.dart';

class UserPreferencesStorageModel {
  const UserPreferencesStorageModel({
    this.onboardingDone = false,
    this.themeMode = ThemeMode.light,
    this.goals = const <String>[],
    this.level,
    this.dailyGoalMinutes,
  });

  final bool onboardingDone;
  final ThemeMode themeMode;
  final List<String> goals;
  final int? level;
  final int? dailyGoalMinutes;

  UserPreferencesStorageModel copyWith({
    bool? onboardingDone,
    ThemeMode? themeMode,
    List<String>? goals,
    int? level,
    bool clearLevel = false,
    int? dailyGoalMinutes,
    bool clearDailyGoalMinutes = false,
  }) {
    return UserPreferencesStorageModel(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      themeMode: themeMode ?? this.themeMode,
      goals: goals ?? this.goals,
      level: clearLevel ? null : level ?? this.level,
      dailyGoalMinutes: clearDailyGoalMinutes
          ? null
          : dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'onboardingDone': onboardingDone,
      'themeMode': themeMode.name,
      'goals': goals,
      'level': level,
      'dailyGoalMinutes': dailyGoalMinutes,
    };
  }

  factory UserPreferencesStorageModel.fromJson(Map<String, dynamic> json) {
    return UserPreferencesStorageModel(
      onboardingDone: json['onboardingDone'] as bool? ?? false,
      themeMode: _parseThemeMode(json['themeMode'] as String?),
      goals: _readStringList(json['goals']),
      level: _readNullableInt(json['level']),
      dailyGoalMinutes: _readNullableInt(json['dailyGoalMinutes']),
    );
  }
}

class NotificationSettingsStorageModel {
  const NotificationSettingsStorageModel({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  final bool enabled;
  final int hour;
  final int minute;

  NotificationSettingsStorageModel copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return NotificationSettingsStorageModel(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
    };
  }

  factory NotificationSettingsStorageModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsStorageModel(
      enabled: json['enabled'] as bool? ?? false,
      hour: _readInt(json['hour'], fallback: 20),
      minute: _readInt(json['minute']),
    );
  }
}

class AuthSessionStorageModel {
  const AuthSessionStorageModel({required this.token, this.updatedAt});

  final String token;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'token': token,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AuthSessionStorageModel.fromJson(Map<String, dynamic> json) {
    return AuthSessionStorageModel(
      token: (json['token'] as String? ?? '').trim(),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

class StoredUserProfileModel {
  const StoredUserProfileModel({
    required this.nickname,
    required this.avatarUrl,
    required this.memberPlan,
    this.onboardingDone = false,
  });

  final String nickname;
  final String avatarUrl;
  final String memberPlan;
  final bool onboardingDone;

  factory StoredUserProfileModel.fromAppUser(AppUser user) {
    return StoredUserProfileModel(
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      memberPlan: user.memberPlan,
      onboardingDone: user.onboardingDone,
    );
  }

  AppUser toAppUser() {
    return AppUser(
      nickname: nickname,
      avatarUrl: avatarUrl,
      memberPlan: memberPlan,
      onboardingDone: onboardingDone,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'memberPlan': memberPlan,
      'onboardingDone': onboardingDone,
    };
  }

  factory StoredUserProfileModel.fromJson(Map<String, dynamic> json) {
    return StoredUserProfileModel(
      nickname: (json['nickname'] as String? ?? '').trim(),
      avatarUrl: (json['avatarUrl'] as String? ?? '').trim(),
      memberPlan: (json['memberPlan'] as String? ?? 'free').trim(),
      onboardingDone: json['onboardingDone'] as bool? ?? false,
    );
  }
}

class LearningProgressStorageModel {
  const LearningProgressStorageModel({
    this.savedIds = const <int>[],
    this.dismissedIds = const <int>[],
    this.completedIds = const <int>[],
  });

  final List<int> savedIds;
  final List<int> dismissedIds;
  final List<int> completedIds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'savedIds': savedIds,
      'dismissedIds': dismissedIds,
      'completedIds': completedIds,
    };
  }

  factory LearningProgressStorageModel.fromJson(Map<String, dynamic> json) {
    return LearningProgressStorageModel(
      savedIds: _readIntList(json['savedIds']),
      dismissedIds: _readIntList(json['dismissedIds']),
      completedIds: _readIntList(json['completedIds']),
    );
  }
}

class StoredExpressionCardModel {
  const StoredExpressionCardModel({
    required this.id,
    required this.category,
    required this.title,
    required this.pattern,
    required this.image,
    required this.learnerCount,
    required this.difficultyLevel,
    required this.progress,
    required this.thumbHeight,
    required this.colorHex,
  });

  final String? id;
  final String category;
  final String title;
  final String pattern;
  final String image;
  final String learnerCount;
  final int difficultyLevel;
  final List<String> progress;
  final double thumbHeight;
  final String colorHex;

  factory StoredExpressionCardModel.fromCard(ExpressionCardData card) {
    return StoredExpressionCardModel(
      id: card.id,
      category: card.category,
      title: card.title,
      pattern: card.pattern,
      image: card.image,
      learnerCount: card.learnerCount,
      difficultyLevel: card.difficultyLevel,
      progress: card.progress
          .map((ProgressState state) => state.name)
          .toList(growable: false),
      thumbHeight: card.thumbHeight,
      colorHex: _colorToHex(card.color),
    );
  }

  ExpressionCardData toCardData() {
    return ExpressionCardData(
      id: id,
      category: category,
      title: title,
      pattern: pattern,
      image: image,
      learnerCount: learnerCount,
      difficultyLevel: difficultyLevel,
      progress: progress
          .map(
            (String value) => ProgressState.values.firstWhere(
              (ProgressState state) => state.name == value,
              orElse: () => ProgressState.idle,
            ),
          )
          .toList(growable: false),
      thumbHeight: thumbHeight,
      color: _parseColor(colorHex),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'title': title,
      'pattern': pattern,
      'image': image,
      'learnerCount': learnerCount,
      'difficultyLevel': difficultyLevel,
      'progress': progress,
      'thumbHeight': thumbHeight,
      'colorHex': colorHex,
    };
  }

  factory StoredExpressionCardModel.fromJson(Map<String, dynamic> json) {
    return StoredExpressionCardModel(
      id: json['id'] as String?,
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      image: json['image'] as String? ?? '',
      learnerCount: json['learnerCount'] as String? ?? '',
      difficultyLevel: _readInt(json['difficultyLevel'], fallback: 1),
      progress: _readStringList(json['progress']),
      thumbHeight: (json['thumbHeight'] as num?)?.toDouble() ?? 0,
      colorHex: json['colorHex'] as String? ?? 'FF4A7244',
    );
  }
}

class CachedCourseDataStorageModel {
  const CachedCourseDataStorageModel({required this.cards, this.cachedAt});

  final List<StoredExpressionCardModel> cards;
  final DateTime? cachedAt;

  factory CachedCourseDataStorageModel.fromCards(
    List<ExpressionCardData> cards, {
    DateTime? cachedAt,
  }) {
    return CachedCourseDataStorageModel(
      cards: cards
          .map(
            (ExpressionCardData card) =>
                StoredExpressionCardModel.fromCard(card),
          )
          .toList(growable: false),
      cachedAt: cachedAt,
    );
  }

  List<ExpressionCardData> toCards() {
    return cards
        .map((StoredExpressionCardModel card) => card.toCardData())
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cards': cards
          .map((StoredExpressionCardModel card) => card.toJson())
          .toList(growable: false),
      'cachedAt': cachedAt?.toIso8601String(),
    };
  }

  factory CachedCourseDataStorageModel.fromJson(Map<String, dynamic> json) {
    return CachedCourseDataStorageModel(
      cards: _readMapList(
        json['cards'],
      ).map(StoredExpressionCardModel.fromJson).toList(growable: false),
      cachedAt: _readDateTime(json['cachedAt']),
    );
  }
}

class ConversationHistoryTurnStorageModel {
  const ConversationHistoryTurnStorageModel({
    required this.role,
    required this.text,
    this.note,
    this.mood,
    this.inputType,
    this.voiceDuration,
    this.accentColorHex,
  });

  final String role;
  final String text;
  final String? note;
  final String? mood;
  final String? inputType;
  final int? voiceDuration;
  final String? accentColorHex;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'text': text,
      'note': note,
      'mood': mood,
      'inputType': inputType,
      'voiceDuration': voiceDuration,
      'accentColorHex': accentColorHex,
    };
  }

  factory ConversationHistoryTurnStorageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ConversationHistoryTurnStorageModel(
      role: json['role'] as String? ?? '',
      text: json['text'] as String? ?? '',
      note: json['note'] as String?,
      mood: json['mood'] as String?,
      inputType: json['inputType'] as String?,
      voiceDuration: _readNullableInt(json['voiceDuration']),
      accentColorHex: json['accentColorHex'] as String?,
    );
  }
}

class ConversationHistoryStorageModel {
  const ConversationHistoryStorageModel({
    required this.sessionId,
    required this.messages,
    this.sceneTitle,
    this.npcName,
    this.updatedAt,
  });

  final String sessionId;
  final List<ConversationHistoryTurnStorageModel> messages;
  final String? sceneTitle;
  final String? npcName;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'sceneTitle': sceneTitle,
      'npcName': npcName,
      'messages': messages
          .map((ConversationHistoryTurnStorageModel turn) => turn.toJson())
          .toList(growable: false),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ConversationHistoryStorageModel.fromJson(Map<String, dynamic> json) {
    return ConversationHistoryStorageModel(
      sessionId: json['sessionId'] as String? ?? '',
      sceneTitle: json['sceneTitle'] as String?,
      npcName: json['npcName'] as String?,
      messages: _readMapList(json['messages'])
          .map(ConversationHistoryTurnStorageModel.fromJson)
          .toList(growable: false),
      updatedAt: _readDateTime(json['updatedAt']),
    );
  }
}

class LearningStatsCacheStorageModel {
  const LearningStatsCacheStorageModel({required this.stats, this.cachedAt});

  final LearningStatsModel stats;
  final DateTime? cachedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stats': stats.toJson(),
      'cachedAt': cachedAt?.toIso8601String(),
    };
  }

  factory LearningStatsCacheStorageModel.fromJson(Map<String, dynamic> json) {
    return LearningStatsCacheStorageModel(
      stats: LearningStatsModel.fromJson(
        (json['stats'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      cachedAt: _readDateTime(json['cachedAt']),
    );
  }
}

ThemeMode _parseThemeMode(String? value) {
  return ThemeMode.values.firstWhere(
    (ThemeMode mode) => mode.name == value,
    orElse: () => ThemeMode.light,
  );
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value
        .map((dynamic item) => '$item'.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

List<int> _readIntList(Object? value) {
  if (value is List) {
    final Set<int> unique = value
        .map((dynamic item) => int.tryParse('$item'))
        .whereType<int>()
        .toSet();
    final List<int> sorted = unique.toList()..sort();
    return sorted;
  }
  return const <int>[];
}

List<Map<String, dynamic>> _readMapList(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }
  return value
      .whereType<Map>()
      .map((Map item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

int _readInt(Object? value, {int fallback = 0}) {
  return _readNullableInt(value) ?? fallback;
}

int? _readNullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

DateTime? _readDateTime(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value.trim());
  }
  return null;
}

String _colorToHex(Color color) {
  return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
}

Color _parseColor(String raw) {
  final String normalized = raw
      .replaceFirst(RegExp('^0x', caseSensitive: false), '')
      .replaceAll('#', '')
      .trim();
  final String hex = switch (normalized.length) {
    6 => 'FF$normalized',
    8 => normalized,
    _ => 'FF4A7244',
  };
  return Color(int.parse(hex, radix: 16));
}
