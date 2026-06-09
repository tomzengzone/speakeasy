import 'package:flutter/material.dart';

import 'package:speakeasy/application/contracts/app_repository.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/infrastructure/repositories/demo_app_repository.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/utils/error_handler.dart';

class _ParsedSceneReply {
  const _ParsedSceneReply({
    required this.npcText,
    this.mood,
    this.summary,
    this.coachHint,
    this.eventLabel,
    this.eventColor,
  });

  final String npcText;
  final String? mood;
  final String? summary;
  final String? coachHint;
  final String? eventLabel;
  final Color? eventColor;
}

/// 场景对话 Repository —— 所有 AI 调用通过后端代理，无直连
class OpenAiAppRepository implements AppRepository {
  OpenAiAppRepository({required this.apiKey});

  final String apiKey;
  static const int _maxFeedbackHistoryTurns = 8;
  static const int _maxFeedbackVoiceTurns = 3;

  List<String> _sceneHintsFromDynamic(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((dynamic item) {
          if (item is String) {
            return item.trim();
          }
          if (item is Map<String, dynamic>) {
            return (item['text'] as String? ?? '').trim();
          }
          if (item is Map) {
            return (item['text'] as String? ?? '').trim();
          }
          return '';
        })
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<AppUser> signIn(LoginSubmission submission) =>
      const DemoAppRepository().signIn(submission);

  @override
  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  }) => const DemoAppRepository().changeMembership(user: user, planId: planId);

  @override
  Future<void> syncRoleProfiles(List<Map<String, dynamic>> roles) {
    return ApiClient.syncRoleProfiles(roles);
  }

  @override
  Future<RoleMemorySummary?> fetchRoleMemory(String roleId) async {
    final Map<String, dynamic>? data = await ApiClient.getRoleMemory(roleId);
    if (data == null || data.isEmpty) {
      return null;
    }
    return RoleMemorySummary.fromJson(data);
  }

  @override
  Future<LearningProfileSummary?> fetchLearningProfile() async {
    final Map<String, dynamic>? data = await ApiClient.getLearningProfile();
    if (data == null || data.isEmpty) {
      return null;
    }
    return LearningProfileSummary.fromJson(data);
  }

  @override
  Future<SceneReply> sendSceneMessage({
    required String sessionId,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) async {
    if (sessionId.isNotEmpty) {
      try {
        final List<Map<String, dynamic>> historyPayload = history
            .map(
              (SceneHistoryTurn turn) => <String, dynamic>{
                'role': turn.role,
                'text': turn.text,
              },
            )
            .toList(growable: false);
        final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
          sessionId,
          userText,
          draft: draft,
          history: historyPayload,
        );
        final String reply = (response['reply'] as String? ?? '').trim();
        if (reply.isNotEmpty) {
          final _ParsedSceneReply parsed = _parseSceneReply(reply);
          return SceneReply(
            npcText: parsed.npcText,
            mood: _nonEmpty(response['mood'] as String?) ?? parsed.mood,
            summary:
                _nonEmpty(response['summary'] as String?) ??
                parsed.summary ??
                _nonEmpty(response['mood'] as String?) ??
                parsed.mood,
            coachHint:
                _nonEmpty(response['coach'] as String?) ?? parsed.coachHint,
            eventLabel:
                _nonEmpty(response['event'] as String?) ?? parsed.eventLabel,
            eventColor: _nonEmpty(response['event'] as String?) != null
                ? const Color(0xFF8BA8E0)
                : parsed.eventColor,
            turnContract: _sceneTurnContractFromDynamic(
              response['turnContract'],
            ),
            sceneState: _sceneStateFromDynamic(response['sceneState']),
            roleMemoryHints: _sceneHintsFromDynamic(response['roleMemory']),
            learningProfileHints: _sceneHintsFromDynamic(
              response['learningProfileHints'],
            ),
          );
        }
        throw Exception('服务器未返回场景回复');
      } catch (error, stackTrace) {
        ErrorHandler.handleError(
          error,
          stackTrace: stackTrace,
          context: 'Scene message proxy request failed',
        );
        rethrow;
      }
    }

    throw Exception('场景会话未初始化');
  }

  _ParsedSceneReply _parseSceneReply(String rawReply) {
    final String trimmed = rawReply.trim();
    final int jsonStart = _findSceneMetadataStart(trimmed);
    if (jsonStart < 0) {
      return _ParsedSceneReply(npcText: trimmed);
    }

    final String suffix = trimmed.substring(jsonStart);
    final String npcText = trimmed.substring(0, jsonStart).trim();
    final Map<String, String> fields = _readLooseJsonFields(suffix);
    return _ParsedSceneReply(
      npcText: npcText.isEmpty ? trimmed : npcText,
      mood: _nonEmpty(fields['mood']),
      summary: _nonEmpty(fields['summary']) ?? _nonEmpty(fields['mood']),
      coachHint: _nonEmpty(fields['coach']),
      eventLabel: _nonEmpty(fields['event']),
      eventColor: _nonEmpty(fields['event']) != null
          ? const Color(0xFF8BA8E0)
          : null,
    );
  }

  Map<String, String> _readLooseJsonFields(String suffix) {
    final Map<String, String> values = <String, String>{};
    final RegExp pairPattern = RegExp(
      r'"(summary|mood|coach|event)"\s*:\s*"([^"]*)"',
      multiLine: true,
    );
    for (final RegExpMatch match in pairPattern.allMatches(suffix)) {
      values[match.group(1)!] = match.group(2)!.trim();
    }
    return values;
  }

  int _findSceneMetadataStart(String text) {
    final RegExp metadataPattern = RegExp(
      r'\{\s*"(?:summary|mood|coach|event)"[\s\S]*$',
      multiLine: true,
    );
    final RegExpMatch? match = metadataPattern.firstMatch(text);
    return match?.start ?? -1;
  }

  String? _nonEmpty(String? value) {
    final String normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  SceneTurnContract? _sceneTurnContractFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SceneTurnContract.fromJson(value);
    }
    if (value is Map) {
      return SceneTurnContract.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  SceneStateSnapshot? _sceneStateFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return SceneStateSnapshot.fromJson(value);
    }
    if (value is Map) {
      return SceneStateSnapshot.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  @override
  Future<SceneFeedback> generateSceneFeedback({
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
    List<SceneFeedbackVoiceTurn> voiceTurns = const <SceneFeedbackVoiceTurn>[],
  }) async {
    if (history.isEmpty) {
      return const DemoAppRepository().generateSceneFeedback(
        draft: draft,
        history: history,
        voiceTurns: voiceTurns,
      );
    }

    try {
      final List<SceneHistoryTurn> limitedHistory =
          history.length > _maxFeedbackHistoryTurns
          ? history.sublist(history.length - _maxFeedbackHistoryTurns)
          : history;
      final List<SceneFeedbackVoiceTurn> limitedVoiceTurns =
          voiceTurns.length > _maxFeedbackVoiceTurns
          ? voiceTurns.sublist(voiceTurns.length - _maxFeedbackVoiceTurns)
          : voiceTurns;

      final List<Map<String, dynamic>> historyList = limitedHistory
          .map(
            (SceneHistoryTurn t) => <String, dynamic>{
              'role': t.role,
              'text': t.text,
            },
          )
          .toList();
      final List<Map<String, dynamic>> baseVoiceTurnPayload = limitedVoiceTurns
          .map(
            (SceneFeedbackVoiceTurn turn) => <String, dynamic>{
              'turnIndex': turn.turnIndex,
              'text': turn.text.trim(),
            },
          )
          .where(
            (Map<String, dynamic> turn) =>
                (turn['text'] as String? ?? '').trim().isNotEmpty,
          )
          .toList(growable: false);

      final List<Map<String, dynamic>> voiceTurnPayload = baseVoiceTurnPayload;
      final Map<String, dynamic> res = await ApiClient.generateFeedback(
        title: draft.title,
        goal: draft.goal,
        npcName: draft.npcName,
        history: historyList,
        voiceTurns: voiceTurnPayload,
      );

      if (res['code'] == 0 && res['data'] != null) {
        return _feedbackFromJson(res['data'] as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Generate feedback via backend failed',
      );
      rethrow;
    }

    throw Exception('反馈生成失败');
  }

  static SceneFeedback _feedbackFromJson(Map<String, dynamic> j) {
    final List<Map<String, dynamic>> turnReviewMaps =
        (j['turnReviews'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map item) => item.cast<String, dynamic>())
            .toList(growable: false);
    final List<SceneFeedbackTurnReview> turnReviews = turnReviewMaps
        .map((Map<String, dynamic> item) {
          final int turnIndex = (item['turnIndex'] as num?)?.toInt() ?? 0;
          return SceneFeedbackTurnReview(
            turnIndex: turnIndex,
            originalText: (item['originalText'] as String? ?? '').trim(),
            pronunciationScore:
                (item['pronunciationScore'] as num?)?.toInt() ??
                (item['pronunciation_score'] as num?)?.toInt() ??
                0,
            pronunciationComment:
                (item['pronunciationComment'] as String? ?? '').trim(),
            grammarComment: (item['grammarComment'] as String? ?? '').trim(),
            expressionComment: (item['expressionComment'] as String? ?? '')
                .trim(),
            betterExpression: (item['betterExpression'] as String? ?? '')
                .trim(),
            betterExpressionTranslation:
                (item['betterExpressionTranslation'] as String?)?.trim(),
          );
        })
        .where((SceneFeedbackTurnReview item) => item.originalText.isNotEmpty)
        .toList(growable: false);
    final List<SceneFeedbackTurnReview> resolvedTurnReviews = turnReviews;
    return SceneFeedback(
      overallScore: (j['overallScore'] as num?)?.toInt() ?? 70,
      headline: (j['headline'] as String?) ?? '表现不错！',
      summary: (j['summary'] as String?) ?? '',
      metrics: <SceneFeedbackMetric>[
        SceneFeedbackMetric(
          label: '清晰度',
          score: (j['clarity'] as num?)?.toInt() ?? 75,
          color: const Color(0xFF4A7C6F),
        ),
        SceneFeedbackMetric(
          label: '结构感',
          score: (j['structure'] as num?)?.toInt() ?? 70,
          color: const Color(0xFF5A6FA8),
        ),
        SceneFeedbackMetric(
          label: '临场应对',
          score: (j['adaptability'] as num?)?.toInt() ?? 68,
          color: const Color(0xFFA0622A),
        ),
      ],
      coachTip: (j['coachTip'] as String?) ?? '',
      improvements: <(String, String, String)>[
        (
          (j['imp1emoji'] as String?) ?? '🎯',
          (j['imp1title'] as String?) ?? '',
          (j['imp1detail'] as String?) ?? '',
        ),
        (
          (j['imp2emoji'] as String?) ?? '🧭',
          (j['imp2title'] as String?) ?? '',
          (j['imp2detail'] as String?) ?? '',
        ),
        (
          (j['imp3emoji'] as String?) ?? '🗣️',
          (j['imp3title'] as String?) ?? '',
          (j['imp3detail'] as String?) ?? '',
        ),
      ],
      turnReviews: resolvedTurnReviews,
    );
  }
}
