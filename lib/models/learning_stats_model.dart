import 'package:flutter/material.dart';

class LearningStatsModel {
  const LearningStatsModel({
    this.totalSessions = 0,
    this.totalLearningDays = 0,
    this.currentStreak = 0,
    this.bestScore = 0,
    this.totalMinutes = 0,
    this.masteredPhrases = 0,
    this.accuracyRate,
    this.experiencePoints = 0,
    this.level,
    this.weekActivity = const <bool>[
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
    this.skillLevels = const <SkillLevelModel>[],
    this.recentPractices = const <PracticeHistoryModel>[],
    this.updatedAt,
  });

  final int totalSessions;
  final int totalLearningDays;
  final int currentStreak;
  final int bestScore;
  final int totalMinutes;
  final int masteredPhrases;
  final int? accuracyRate;
  final int experiencePoints;
  final int? level;
  final List<bool> weekActivity;
  final List<SkillLevelModel> skillLevels;
  final List<PracticeHistoryModel> recentPractices;
  final DateTime? updatedAt;

  int get displayLearningDays =>
      totalLearningDays > 0 ? totalLearningDays : currentStreak;

  double get totalHours => totalMinutes / 60;

  bool get hasOverviewData {
    return totalSessions > 0 ||
        totalLearningDays > 0 ||
        currentStreak > 0 ||
        bestScore > 0 ||
        totalMinutes > 0 ||
        masteredPhrases > 0 ||
        accuracyRate != null ||
        experiencePoints > 0 ||
        (level ?? 0) > 0 ||
        weekActivity.any((bool active) => active) ||
        skillLevels.isNotEmpty ||
        recentPractices.isNotEmpty;
  }

  LearningStatsModel copyWith({
    int? totalSessions,
    int? totalLearningDays,
    int? currentStreak,
    int? bestScore,
    int? totalMinutes,
    int? masteredPhrases,
    int? accuracyRate,
    bool clearAccuracyRate = false,
    int? experiencePoints,
    int? level,
    bool clearLevel = false,
    List<bool>? weekActivity,
    List<SkillLevelModel>? skillLevels,
    List<PracticeHistoryModel>? recentPractices,
    DateTime? updatedAt,
    bool clearUpdatedAt = false,
  }) {
    return LearningStatsModel(
      totalSessions: totalSessions ?? this.totalSessions,
      totalLearningDays: totalLearningDays ?? this.totalLearningDays,
      currentStreak: currentStreak ?? this.currentStreak,
      bestScore: bestScore ?? this.bestScore,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      masteredPhrases: masteredPhrases ?? this.masteredPhrases,
      accuracyRate: clearAccuracyRate
          ? null
          : accuracyRate ?? this.accuracyRate,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: clearLevel ? null : level ?? this.level,
      weekActivity: weekActivity ?? this.weekActivity,
      skillLevels: skillLevels ?? this.skillLevels,
      recentPractices: recentPractices ?? this.recentPractices,
      updatedAt: clearUpdatedAt ? null : updatedAt ?? this.updatedAt,
    );
  }

  LearningStatsModel recordLocalSession({
    required int durationSeconds,
    required int score,
    required DateTime practicedAt,
    PracticeHistoryModel? recentPractice,
  }) {
    final int todayIndex = practicedAt.weekday - 1;
    final List<bool> nextWeekActivity = List<bool>.from(
      _normalizedWeekActivity,
    );
    final bool alreadyActiveToday = nextWeekActivity[todayIndex];
    nextWeekActivity[todayIndex] = true;
    final List<PracticeHistoryModel> nextRecentPractices =
        recentPractice == null
        ? recentPractices
        : <PracticeHistoryModel>[
            recentPractice,
            ...recentPractices.where(
              (PracticeHistoryModel item) =>
                  item.title != recentPractice.title ||
                  item.practicedAt != recentPractice.practicedAt,
            ),
          ].take(12).toList(growable: false);

    return copyWith(
      totalSessions: totalSessions + 1,
      totalLearningDays: totalLearningDays + (alreadyActiveToday ? 0 : 1),
      currentStreak: alreadyActiveToday
          ? (currentStreak == 0 ? 1 : currentStreak)
          : currentStreak + 1,
      bestScore: score > bestScore ? score : bestScore,
      totalMinutes: totalMinutes + (durationSeconds ~/ 60),
      weekActivity: nextWeekActivity,
      recentPractices: nextRecentPractices,
      updatedAt: practicedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'totalSessions': totalSessions,
      'totalLearningDays': totalLearningDays,
      'currentStreak': currentStreak,
      'bestScore': bestScore,
      'totalMinutes': totalMinutes,
      'masteredPhrases': masteredPhrases,
      'accuracyRate': accuracyRate,
      'experiencePoints': experiencePoints,
      'level': level,
      'weekActivity': _normalizedWeekActivity,
      'skillLevels': skillLevels
          .map((SkillLevelModel item) => item.toJson())
          .toList(),
      'recentPractices': recentPractices
          .map((PracticeHistoryModel item) => item.toJson())
          .toList(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LearningStatsModel.fromJson(Map<String, dynamic> json) {
    final List<bool> weekActivity = _parseWeekActivity(
      json['weekActivity'] ?? json['weeklyActivity'] ?? json['checkInDays'],
    );
    final List<SkillLevelModel> skillLevels = _parseSkillLevels(
      json['skillLevels'] ?? json['skills'] ?? json['abilityDistribution'],
    );
    final List<PracticeHistoryModel> recentPractices = _parseRecentPractices(
      json['recentPractices'] ??
          json['recentSessions'] ??
          json['practiceHistory'],
    );

    return LearningStatsModel(
      totalSessions: _readInt(json, <String>[
        'totalSessions',
        'practiceCount',
        'totalPractices',
      ]),
      totalLearningDays: _readInt(json, <String>[
        'totalLearningDays',
        'learningDays',
        'studyDays',
      ]),
      currentStreak: _readInt(json, <String>[
        'currentStreak',
        'streakDays',
        'checkInStreak',
      ]),
      bestScore: _readInt(json, <String>['bestScore', 'highestScore']),
      totalMinutes: _readInt(json, <String>[
        'totalMinutes',
        'studyMinutes',
        'practiceMinutes',
      ]),
      masteredPhrases: _readInt(json, <String>[
        'masteredPhrases',
        'masteredSentences',
        'phrasesMastered',
      ]),
      accuracyRate: _readNullableInt(json, <String>[
        'accuracyRate',
        'correctRate',
        'accuracy',
      ]),
      experiencePoints: _readInt(json, <String>[
        'experiencePoints',
        'xp',
        'totalXp',
      ]),
      level: _readNullableInt(json, <String>['level', 'userLevel']),
      weekActivity: weekActivity,
      skillLevels: skillLevels,
      recentPractices: recentPractices,
      updatedAt: _readDateTime(json, <String>[
        'updatedAt',
        'lastUpdatedAt',
        'statsUpdatedAt',
      ]),
    );
  }

  List<bool> get _normalizedWeekActivity {
    if (weekActivity.length == 7) {
      return weekActivity;
    }
    final List<bool> normalized = List<bool>.filled(7, false);
    for (int i = 0; i < weekActivity.length && i < 7; i++) {
      normalized[i] = weekActivity[i];
    }
    return normalized;
  }
}

class SkillLevelModel {
  const SkillLevelModel({required this.label, required this.level, this.color});

  final String label;
  final int level;
  final Color? color;

  bool get hasContent => label.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'level': level,
      'color': color == null ? null : _colorToHex(color!),
    };
  }

  factory SkillLevelModel.fromJson(Map<String, dynamic> json) {
    return SkillLevelModel(
      label: _readString(json, <String>['label', 'name', 'title']),
      level: _readInt(json, <String>['level', 'score', 'value']).clamp(0, 100),
      color: _readColor(json, <String>['color', 'colorHex']),
    );
  }
}

class PracticeHistoryModel {
  const PracticeHistoryModel({
    this.id,
    required this.title,
    this.timeLabel,
    this.score,
    this.emoji = '🎯',
    this.practicedAt,
    this.tags = const <String>[],
    this.feedbackStatus,
    this.feedbackData,
    this.promptText,
    this.sceneDraftData,
    this.feedbackContextData,
  });

  final String? id;
  final String title;
  final String? timeLabel;
  final int? score;
  final String emoji;
  final DateTime? practicedAt;
  final List<String> tags;
  final String? feedbackStatus;
  final Map<String, dynamic>? feedbackData;
  final String? promptText;
  final Map<String, dynamic>? sceneDraftData;
  final Map<String, dynamic>? feedbackContextData;

  PracticeHistoryModel copyWith({
    String? id,
    String? title,
    String? timeLabel,
    int? score,
    String? emoji,
    DateTime? practicedAt,
    List<String>? tags,
    String? feedbackStatus,
    bool clearFeedbackStatus = false,
    Map<String, dynamic>? feedbackData,
    bool clearFeedbackData = false,
    String? promptText,
    bool clearPromptText = false,
    Map<String, dynamic>? sceneDraftData,
    bool clearSceneDraftData = false,
    Map<String, dynamic>? feedbackContextData,
    bool clearFeedbackContextData = false,
  }) {
    return PracticeHistoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      timeLabel: timeLabel ?? this.timeLabel,
      score: score ?? this.score,
      emoji: emoji ?? this.emoji,
      practicedAt: practicedAt ?? this.practicedAt,
      tags: tags ?? this.tags,
      feedbackStatus: clearFeedbackStatus
          ? null
          : feedbackStatus ?? this.feedbackStatus,
      feedbackData: clearFeedbackData
          ? null
          : feedbackData ?? this.feedbackData,
      promptText: clearPromptText ? null : promptText ?? this.promptText,
      sceneDraftData: clearSceneDraftData
          ? null
          : sceneDraftData ?? this.sceneDraftData,
      feedbackContextData: clearFeedbackContextData
          ? null
          : feedbackContextData ?? this.feedbackContextData,
    );
  }

  bool get hasContent =>
      title.trim().isNotEmpty ||
      (timeLabel?.trim().isNotEmpty ?? false) ||
      score != null ||
      practicedAt != null ||
      tags.isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      if (id != null) 'id': id,
      'timeLabel': timeLabel,
      'score': score,
      'emoji': emoji,
      'practicedAt': practicedAt?.toIso8601String(),
      if (tags.isNotEmpty) 'tags': tags,
      if (feedbackStatus != null) 'feedbackStatus': feedbackStatus,
      if (feedbackData != null) 'feedback': feedbackData,
      if (promptText != null) 'promptText': promptText,
      if (sceneDraftData != null) 'sceneDraft': sceneDraftData,
      if (feedbackContextData != null) 'feedbackContext': feedbackContextData,
    };
  }

  factory PracticeHistoryModel.fromJson(Map<String, dynamic> json) {
    return PracticeHistoryModel(
      id: _readNullableString(json, <String>['id', 'practiceId', 'sessionId']),
      title: _readString(json, <String>[
        'title',
        'sceneTitle',
        'sessionTitle',
        'name',
      ]),
      timeLabel: _readNullableString(json, <String>[
        'timeLabel',
        'displayTime',
        'time',
      ]),
      score: _readNullableInt(json, <String>['score', 'bestScore', 'accuracy']),
      emoji: _readNullableString(json, <String>['emoji']) ?? '🎯',
      practicedAt: _readDateTime(json, <String>[
        'practicedAt',
        'completedAt',
        'createdAt',
      ]),
      tags: _readStringList(json['tags']),
      feedbackStatus: _readNullableString(
        json,
        <String>['feedbackStatus', 'reviewStatus'],
      ),
      feedbackData: _asMap(json['feedback']),
      promptText: _readNullableString(
        json,
        <String>['promptText', 'prompt', 'scenePrompt'],
      ),
      sceneDraftData: _asMap(
        json['sceneDraft'] ?? json['sceneDraftSnapshot'] ?? json['draft'],
      ),
      feedbackContextData: _asMap(
        json['feedbackContext'] ?? json['feedbackPayload'] ?? json['reviewContext'],
      ),
    );
  }
}

extension LearningStatsRecentPracticeX on LearningStatsModel {
  LearningStatsModel upsertRecentPractice(PracticeHistoryModel practice) {
    final String practiceTitle = practice.title.trim();
    if (practiceTitle.isEmpty) {
      return this;
    }

    final List<PracticeHistoryModel> next = <PracticeHistoryModel>[practice];
    final String practiceId = practice.id?.trim() ?? '';
    for (final PracticeHistoryModel item in recentPractices) {
      final bool sameId =
          practiceId.isNotEmpty &&
          (item.id?.trim().isNotEmpty ?? false) &&
          item.id!.trim() == practiceId;
      final bool sameTitlePending =
          practiceId.isEmpty &&
          item.title.trim() == practiceTitle &&
          (item.feedbackStatus == 'pending' || practice.feedbackStatus == 'pending');
      if (sameId || sameTitlePending) {
        continue;
      }
      next.add(item);
    }
    return copyWith(
      recentPractices: next.take(12).toList(growable: false),
    );
  }

  LearningStatsModel removeRecentPracticeGroup(String title) {
    final String trimmed = title.trim();
    if (trimmed.isEmpty) {
      return this;
    }
    return copyWith(
      recentPractices: recentPractices
          .where((PracticeHistoryModel item) => item.title.trim() != trimmed)
          .toList(growable: false),
    );
  }
}

List<SkillLevelModel> _parseSkillLevels(Object? value) {
  if (value is! List) {
    return const <SkillLevelModel>[];
  }
  return value
      .map((dynamic item) => _asMap(item))
      .where((Map<String, dynamic> item) => item.isNotEmpty)
      .map(SkillLevelModel.fromJson)
      .where((SkillLevelModel item) => item.hasContent)
      .toList(growable: false);
}

List<PracticeHistoryModel> _parseRecentPractices(Object? value) {
  if (value is! List) {
    return const <PracticeHistoryModel>[];
  }
  return value
      .map((dynamic item) => _asMap(item))
      .where((Map<String, dynamic> item) => item.isNotEmpty)
      .map(PracticeHistoryModel.fromJson)
      .where((PracticeHistoryModel item) => item.hasContent)
      .toList(growable: false);
}

List<bool> _parseWeekActivity(Object? value) {
  if (value is! List) {
    return List<bool>.filled(7, false);
  }
  final List<bool> normalized = List<bool>.filled(7, false);
  for (int i = 0; i < value.length && i < 7; i++) {
    final dynamic item = value[i];
    normalized[i] = switch (item) {
      bool boolValue => boolValue,
      num numValue => numValue != 0,
      String stringValue => stringValue == '1' || stringValue == 'true',
      _ => false,
    };
  }
  return normalized;
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

int _readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
  return _readNullableInt(json, keys) ?? fallback;
}

int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final int? parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
      final double? decimal = double.tryParse(value.trim());
      if (decimal != null) {
        return decimal.round();
      }
    }
  }
  return null;
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  return _readNullableString(json, keys) ?? '';
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value
      .map((dynamic item) => item.toString().trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

Color? _readColor(Map<String, dynamic> json, List<String> keys) {
  final String? raw = _readNullableString(json, keys);
  if (raw == null) {
    return null;
  }
  final String normalized = raw
      .replaceFirst(RegExp('^0x', caseSensitive: false), '')
      .replaceAll('#', '')
      .trim();
  final String hex = switch (normalized.length) {
    6 => 'FF$normalized',
    8 => normalized,
    _ => '',
  };
  if (hex.isEmpty) {
    return null;
  }
  return Color(int.parse(hex, radix: 16));
}

String _colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}
