import 'dart:io';

import 'package:flutter/material.dart';

import 'package:speakeasy/application/contracts/app_repository.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/infrastructure/repositories/demo_app_repository.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/oral_assessment_service.dart';
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
  static final Map<String, PronunciationScore> _pronunciationScoreCache =
      <String, PronunciationScore>{};
  static final Map<String, Future<PronunciationScore?>> _scoreInFlight =
      <String, Future<PronunciationScore?>>{};

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
  Future<PronunciationScore> scorePronunciation({
    required String audioPath,
    required String expectedText,
  }) async {
    final PronunciationScore? localScore =
        await OralAssessmentService.scorePronunciation(
          audioPath: audioPath,
          expectedText: expectedText,
        );
    if (localScore != null) {
      return localScore;
    }

    try {
      final Map<String, dynamic> score = await ApiClient.scoreAudio(
        File(audioPath),
        expectedText,
      );
      return _scoreFromJson(score);
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Pronunciation scoring via backend failed',
      );
      rethrow;
    }
  }

  Future<PronunciationScore?> _scorePronunciationCached({
    required String audioPath,
    required String expectedText,
  }) async {
    final String cacheKey = '$audioPath|$expectedText';
    final PronunciationScore? cached = _pronunciationScoreCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final Future<PronunciationScore?>? inFlight = _scoreInFlight[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final Future<PronunciationScore?> future = () async {
      try {
        if (!File(audioPath).existsSync()) {
          return null;
        }
        final PronunciationScore score = await scorePronunciation(
          audioPath: audioPath,
          expectedText: expectedText,
        );
        _pronunciationScoreCache[cacheKey] = score;
        return score;
      } catch (_) {
        return null;
      } finally {
        _scoreInFlight.remove(cacheKey);
      }
    }();

    _scoreInFlight[cacheKey] = future;
    return future;
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

      final Future<List<Map<String, dynamic>>> scoreFuture =
          Future.wait(
            limitedVoiceTurns.map((SceneFeedbackVoiceTurn turn) async {
              final String text = turn.text.trim();
              if (text.isEmpty) {
                return null;
              }
              PronunciationScore? score;
              final String? audioPath = turn.audioPath?.trim();
              if (audioPath != null && audioPath.isNotEmpty) {
                score = await _scorePronunciationCached(
                  audioPath: audioPath,
                  expectedText: text,
                );
              }
              return <String, dynamic>{
                'turnIndex': turn.turnIndex,
                'text': text,
                if (score != null)
                  'pronunciation': <String, dynamic>{
                    'overall': score.overall,
                    if (score.accuracy != null) 'accuracy': score.accuracy,
                    if (score.fluency != null) 'fluency': score.fluency,
                    if (score.completeness != null)
                      'completeness': score.completeness,
                    if (score.grammar != null) 'grammar': score.grammar,
                  },
              };
            }),
          ).then(
            (List<Map<String, dynamic>?> turns) =>
                turns.whereType<Map<String, dynamic>>().toList(growable: false),
          );

      final List<Map<String, dynamic>> voiceTurnPayload = await scoreFuture
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => baseVoiceTurnPayload,
          );
      final Map<String, dynamic> res = await ApiClient.generateFeedback(
        title: draft.title,
        goal: draft.goal,
        npcName: draft.npcName,
        history: historyList,
        voiceTurns: voiceTurnPayload,
      );

      if (res['code'] == 0 && res['data'] != null) {
        return _feedbackFromJson(
          res['data'] as Map<String, dynamic>,
          scoredVoiceTurns: voiceTurnPayload,
        );
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

  static SceneFeedback _feedbackFromJson(
    Map<String, dynamic> j, {
    List<Map<String, dynamic>> scoredVoiceTurns =
        const <Map<String, dynamic>>[],
  }) {
    final List<Map<String, dynamic>> turnReviewMaps =
        (j['turnReviews'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map((Map item) => item.cast<String, dynamic>())
            .toList(growable: false);
    final Map<int, Map<String, dynamic>> scoredVoiceTurnMap =
        <int, Map<String, dynamic>>{
          for (final Map<String, dynamic> turn in scoredVoiceTurns)
            (turn['turnIndex'] as num?)?.toInt() ?? -1: turn,
        }..remove(-1);
    final List<SceneFeedbackTurnReview> turnReviews = turnReviewMaps
        .map((Map<String, dynamic> item) {
          final int turnIndex = (item['turnIndex'] as num?)?.toInt() ?? 0;
          final Map<String, dynamic>? scoredTurn =
              scoredVoiceTurnMap[turnIndex];
          final Map<String, dynamic>? pronunciation =
              scoredTurn?['pronunciation'] as Map<String, dynamic>?;
          return SceneFeedbackTurnReview(
            turnIndex: turnIndex,
            originalText: (item['originalText'] as String? ?? '').trim(),
            pronunciationScore:
                (pronunciation?['overall'] as num?)?.toInt() ?? 0,
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
    final List<SceneFeedbackTurnReview> resolvedTurnReviews =
        turnReviews.isNotEmpty
        ? turnReviews
        : scoredVoiceTurns
              .map((Map<String, dynamic> item) {
                final int turnIndex = (item['turnIndex'] as num?)?.toInt() ?? 0;
                final Map<String, dynamic>? pronunciation =
                    item['pronunciation'] as Map<String, dynamic>?;
                return SceneFeedbackTurnReview(
                  turnIndex: turnIndex,
                  originalText: (item['text'] as String? ?? '').trim(),
                  pronunciationScore:
                      (pronunciation?['overall'] as num?)?.toInt() ?? 0,
                  pronunciationComment: '发音整体可懂，继续把重音和连读练得更稳定。',
                  grammarComment: '语法基本成立，但还可以更简洁。',
                  expressionComment: '表达能传达意思，不过自然度还能再提升。',
                  betterExpression: (item['text'] as String? ?? '').trim(),
                  betterExpressionTranslation: null,
                );
              })
              .where(
                (SceneFeedbackTurnReview item) => item.originalText.isNotEmpty,
              )
              .toList(growable: false);
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

PronunciationScore _scoreFromJson(Map<String, dynamic> score) {
  final String source =
      (score['provider'] as String? ?? score['source'] as String? ?? '').trim();
  return PronunciationScore(
    overall: (score['overall'] as num?)?.toInt() ?? 0,
    accuracy: (score['accuracy'] as num?)?.toInt(),
    fluency: (score['fluency'] as num?)?.toInt(),
    completeness: (score['completeness'] as num?)?.toInt(),
    grammar: (score['grammar'] as num?)?.toInt(),
    source: source.isEmpty ? 'backend_score' : source,
  );
}
