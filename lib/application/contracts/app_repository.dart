import 'package:flutter/material.dart';

import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/models/app_models.dart';

class RoleMemorySummary {
  const RoleMemorySummary({
    required this.roleId,
    required this.name,
    required this.summary,
    required this.relationshipStage,
    this.rememberedFacts = const <String>[],
    this.preferredTopics = const <String>[],
    this.unfinishedTopics = const <String>[],
    this.interactionStyle = '',
    this.updatedAt,
  });

  final String roleId;
  final String name;
  final String summary;
  final String relationshipStage;
  final List<String> rememberedFacts;
  final List<String> preferredTopics;
  final List<String> unfinishedTopics;
  final String interactionStyle;
  final DateTime? updatedAt;

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => '$item'.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  factory RoleMemorySummary.fromJson(Map<String, dynamic> json) {
    return RoleMemorySummary(
      roleId: (json['roleId'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      summary: (json['summary'] as String? ?? '').trim(),
      relationshipStage: (json['relationshipStage'] as String? ?? '').trim(),
      rememberedFacts: _readStringList(json['rememberedFacts']),
      preferredTopics: _readStringList(json['preferredTopics']),
      unfinishedTopics: _readStringList(json['unfinishedTopics']),
      interactionStyle: (json['interactionStyle'] as String? ?? '').trim(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()),
    );
  }
}

class LearningProfileSummary {
  const LearningProfileSummary({
    required this.summary,
    this.strengths = const <String>[],
    this.weaknesses = const <String>[],
    this.progress = const <String>[],
    this.nextFocus = const <String>[],
    this.evidenceCount = 0,
    this.updatedAt,
  });

  final String summary;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> progress;
  final List<String> nextFocus;
  final int evidenceCount;
  final DateTime? updatedAt;

  static List<String> _readStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) => '$item'.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  factory LearningProfileSummary.fromJson(Map<String, dynamic> json) {
    return LearningProfileSummary(
      summary: (json['summary'] as String? ?? '').trim(),
      strengths: _readStringList(json['strengths']),
      weaknesses: _readStringList(json['weaknesses']),
      progress: _readStringList(json['progress']),
      nextFocus: _readStringList(json['nextFocus']),
      evidenceCount: (json['evidenceCount'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()),
    );
  }
}

class SceneReply {
  const SceneReply({
    required this.npcText,
    this.coachHint,
    this.eventLabel,
    this.eventColor,
    this.mood,
    this.summary,
    this.turnContract,
    this.sceneState,
    this.roleMemoryHints = const <String>[],
    this.learningProfileHints = const <String>[],
  });

  final String npcText;
  final String? coachHint;
  final String? eventLabel;
  final Color? eventColor;
  final String? mood;
  final String? summary;
  final SceneTurnContract? turnContract;
  final SceneStateSnapshot? sceneState;
  final List<String> roleMemoryHints;
  final List<String> learningProfileHints;
}

class SceneFeedbackMetric {
  const SceneFeedbackMetric({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'score': score,
      'color': color.toARGB32(),
    };
  }

  factory SceneFeedbackMetric.fromJson(Map<String, dynamic> json) {
    return SceneFeedbackMetric(
      label: (json['label'] as String? ?? '').trim(),
      score: (json['score'] as num?)?.toInt() ?? 0,
      color: Color((json['color'] as num?)?.toInt() ?? 0xFF4A7C6F),
    );
  }
}

class SceneFeedback {
  const SceneFeedback({
    required this.overallScore,
    required this.headline,
    required this.summary,
    required this.metrics,
    required this.coachTip,
    required this.improvements,
    this.turnReviews = const <SceneFeedbackTurnReview>[],
  });

  final int overallScore;
  final String headline;
  final String summary;
  final List<SceneFeedbackMetric> metrics;
  final String coachTip;
  final List<(String, String, String)> improvements;
  final List<SceneFeedbackTurnReview> turnReviews;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'overallScore': overallScore,
      'headline': headline,
      'summary': summary,
      'metrics': metrics
          .map((SceneFeedbackMetric item) => item.toJson())
          .toList(growable: false),
      'coachTip': coachTip,
      'improvements': improvements
          .map(
            ((String, String, String) item) => <String, dynamic>{
              'emoji': item.$1,
              'title': item.$2,
              'detail': item.$3,
            },
          )
          .toList(growable: false),
      'turnReviews': turnReviews
          .map((SceneFeedbackTurnReview item) => item.toJson())
          .toList(growable: false),
    };
  }

  factory SceneFeedback.fromJson(Map<String, dynamic> json) {
    return SceneFeedback(
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 0,
      headline: (json['headline'] as String? ?? '').trim(),
      summary: (json['summary'] as String? ?? '').trim(),
      metrics: (json['metrics'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) =>
                SceneFeedbackMetric.fromJson(item.cast<String, dynamic>()),
          )
          .toList(growable: false),
      coachTip: (json['coachTip'] as String? ?? '').trim(),
      improvements:
          (json['improvements'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((Map item) {
                final Map<String, dynamic> data = item.cast<String, dynamic>();
                return (
                  (data['emoji'] as String? ?? '').trim(),
                  (data['title'] as String? ?? '').trim(),
                  (data['detail'] as String? ?? '').trim(),
                );
              })
              .toList(growable: false),
      turnReviews: (json['turnReviews'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (Map item) => SceneFeedbackTurnReview.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
    );
  }
}

abstract class AppRepository {
  Future<AppUser> signIn(LoginSubmission submission);

  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  });

  Future<void> syncRoleProfiles(List<Map<String, dynamic>> roles);

  Future<RoleMemorySummary?> fetchRoleMemory(String roleId);

  Future<LearningProfileSummary?> fetchLearningProfile();

  Future<SceneReply> sendSceneMessage({
    required String sessionId,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  });

  Future<SceneFeedback> generateSceneFeedback({
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
    List<SceneFeedbackVoiceTurn> voiceTurns = const <SceneFeedbackVoiceTurn>[],
  });
}
