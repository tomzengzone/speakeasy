import 'dart:io';

import 'package:flutter/material.dart';

import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/utils/error_handler.dart';

/// 场景对话 Repository —— 所有 AI 调用通过后端代理，无直连
class OpenAiAppRepository implements AppRepository {
  OpenAiAppRepository({required this.apiKey});

  final String apiKey;

  @override
  Future<AppUser> signIn(LoginSubmission submission) =>
      const DemoAppRepository().signIn(submission);

  @override
  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  }) => const DemoAppRepository().changeMembership(user: user, planId: planId);

  @override
  Future<SceneReply> sendSceneMessage({
    required String sessionId,
    required String userText,
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) async {
    if (sessionId.isNotEmpty) {
      try {
        final String reply = await ApiClient.sendMessage(sessionId, userText);
        if (reply.trim().isNotEmpty) {
          return SceneReply(npcText: reply.trim());
        }
      } catch (error, stackTrace) {
        ErrorHandler.handleError(
          error,
          stackTrace: stackTrace,
          context: 'Scene message proxy request failed',
        );
      }
    }

    // 后端不可用时回退到 Demo 数据
    return const DemoAppRepository().sendSceneMessage(
      sessionId: sessionId,
      userText: userText,
      draft: draft,
      history: history,
    );
  }

  @override
  Future<PronunciationScore> scorePronunciation({
    required String audioPath,
    required String expectedText,
  }) async {
    try {
      final Map<String, dynamic> score = await ApiClient.scoreAudio(
        File(audioPath),
        expectedText,
      );
      return _scoreFromJson(score);
    } catch (_) {
      return const DemoAppRepository().scorePronunciation(
        audioPath: audioPath,
        expectedText: expectedText,
      );
    }
  }

  @override
  Future<SceneFeedback> generateSceneFeedback({
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
  }) async {
    if (history.isEmpty) {
      return const DemoAppRepository().generateSceneFeedback(
        draft: draft,
        history: history,
      );
    }

    // 通过后端 /ai/feedback 接口调用 LLM 生成反馈
    try {
      final List<Map<String, dynamic>> historyList = history
          .map((SceneHistoryTurn t) => <String, dynamic>{
                'role': t.role,
                'text': t.text,
              })
          .toList();

      final Map<String, dynamic> res = await ApiClient.generateFeedback(
        title: draft.title,
        goal: draft.goal,
        npcName: draft.npcName,
        history: historyList,
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
    }

    // 回退到 Demo
    return const DemoAppRepository().generateSceneFeedback(
      draft: draft,
      history: history,
    );
  }

  static SceneFeedback _feedbackFromJson(Map<String, dynamic> j) {
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
    );
  }
}

PronunciationScore _scoreFromJson(Map<String, dynamic> score) {
  return PronunciationScore(
    overall: (score['overall'] as num?)?.toInt() ?? 0,
    accuracy: (score['accuracy'] as num?)?.toInt(),
    fluency: (score['fluency'] as num?)?.toInt(),
    completeness: (score['completeness'] as num?)?.toInt(),
  );
}
