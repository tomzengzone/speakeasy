import 'dart:io';

import 'package:flutter/material.dart';

import 'package:speakeasy/application/contracts/app_repository.dart';
import 'package:speakeasy/config/payment_config.dart';
import 'package:speakeasy/core/constants/avatar_defaults.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/utils/error_handler.dart';

class DemoAppRepository implements AppRepository {
  const DemoAppRepository();

  static const Set<String> _validPlans = <String>{
    ...PaymentConfig.validPlanIds,
  };

  @override
  Future<AppUser> signIn(LoginSubmission submission) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));

    final String nickname = switch (submission.provider) {
      LoginProvider.wechat => '微信用户',
      LoginProvider.apple => 'Apple 用户',
      LoginProvider.phone => _phoneNickname(submission.phone),
      LoginProvider.email => _emailNickname(
        email: submission.email,
        nickname: submission.nickname,
      ),
    };

    return AppUser(
      nickname: nickname,
      avatarUrl: defaultAvatarUrls.first,
      memberPlan: 'free',
    );
  }

  @override
  Future<AppUser> changeMembership({
    required AppUser user,
    required String planId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!_validPlans.contains(planId)) {
      throw Exception('无效的会员方案');
    }

    return user.copyWith(memberPlan: planId);
  }

  @override
  Future<void> syncRoleProfiles(List<Map<String, dynamic>> roles) async {}

  @override
  Future<RoleMemorySummary?> fetchRoleMemory(String roleId) async {
    return RoleMemorySummary(
      roleId: roleId,
      name: 'Role',
      summary: 'This role is still building continuity with you.',
      relationshipStage: 'early familiarity',
    );
  }

  @override
  Future<LearningProfileSummary?> fetchLearningProfile() async {
    return const LearningProfileSummary(
      summary:
          'Recent speaking practice is accumulating, but there is not enough real evidence yet.',
    );
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

    await Future<void>.delayed(const Duration(milliseconds: 900));
    final int round = history
        .where((SceneHistoryTurn t) => t.role == 'user')
        .length;
    const List<String> npcReplies = <String>[
      'Understood. Be specific about the recovery plan and give me one concrete milestone.',
      'That is clearer. Now tell me what you will say if the client asks who is accountable.',
      'Better. I still need a date, an owner, and the message you will send after this call.',
    ];
    const List<String> coachHints = <String>['不要过度解释', '直接给时间点', '先稳住，再给动作'];
    const List<(String, Color)> events = <(String, Color)>[
      ('对方要求直接回答', Color(0xFF8BA8E0)),
      ('对方继续追问责任归属', Color(0xFFE8855A)),
      ('对话节奏正在变快', Color(0xFF7ACFBD)),
    ];
    if (round.isEven) {
      final (String label, Color color) = events[round % events.length];
      return SceneReply(
        npcText: npcReplies[round % npcReplies.length],
        eventLabel: label,
        eventColor: color,
        mood: round.isEven ? '变得不耐烦' : '等待你的直接回答',
      );
    }
    return SceneReply(
      npcText: npcReplies[round % npcReplies.length],
      coachHint: coachHints[round % coachHints.length],
      mood: '等待你的直接回答',
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
      return PronunciationScore(
        overall: (score['overall'] as num?)?.toInt() ?? 0,
        accuracy: (score['accuracy'] as num?)?.toInt(),
        fluency: (score['fluency'] as num?)?.toInt(),
        completeness: (score['completeness'] as num?)?.toInt(),
        grammar: (score['grammar'] as num?)?.toInt(),
      );
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error,
        stackTrace: stackTrace,
        context: 'Pronunciation scoring request failed',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    final int base = 68 + (expectedText.length % 28);
    return PronunciationScore(
      overall: base,
      accuracy: base + 4 > 100 ? 100 : base + 4,
      fluency: base - 6 < 0 ? 0 : base - 6,
      completeness: base + 2 > 100 ? 100 : base + 2,
    );
  }

  @override
  Future<SceneFeedback> generateSceneFeedback({
    required SceneDraft draft,
    required List<SceneHistoryTurn> history,
    List<SceneFeedbackVoiceTurn> voiceTurns = const <SceneFeedbackVoiceTurn>[],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final int rounds = history
        .where((SceneHistoryTurn t) => t.role == 'user')
        .length;
    final int overall = (62 + rounds * 4).clamp(62, 95);
    return SceneFeedback(
      overallScore: overall,
      headline: rounds >= 4 ? '核心任务完成，细节还可以打磨 ✨' : '已经开了个好头，继续练习会更流畅 💪',
      summary:
          '你完成了 $rounds 轮对话，整体表达清楚。在 ${draft.npcName} 的追问下保持了基本节奏，继续多练高压场景会更稳。',
      metrics: const <SceneFeedbackMetric>[
        SceneFeedbackMetric(label: '清晰度', score: 85, color: Color(0xFF4A7C6F)),
        SceneFeedbackMetric(label: '结构感', score: 78, color: Color(0xFF5A6FA8)),
        SceneFeedbackMetric(label: '临场应对', score: 72, color: Color(0xFFA0622A)),
      ],
      coachTip: '下一轮把恢复方案提前说出来，再补一句具体时间点，表达会更像真实职场风格。',
      improvements: const <(String, String, String)>[
        ('🎯', '先说补救动作', '先解释原因容易让对方觉得在推卸责任，把行动方案放在句子开头压力会明显下降。'),
        ('🧭', '给出具体时间点', '模糊的"稍后""很快"远不如"今晚 6 点前"有说服力，时间承诺让对方更有安全感。'),
        ('🗣️', '减少解释腔', '连续使用 because 会显得在辩解，拆成两句先担责再给方案会更自然。'),
      ],
      turnReviews: voiceTurns
          .map(
            (SceneFeedbackVoiceTurn turn) => SceneFeedbackTurnReview(
              turnIndex: turn.turnIndex,
              originalText: turn.text,
              pronunciationScore: 78,
              pronunciationComment: '整体可懂度不错，注意重音和尾音再更清楚一点。',
              grammarComment: '语法基本通顺，但句子还可以再更紧凑。',
              expressionComment: '意思表达到了，不过可以更像真实商务沟通。',
              betterExpression:
                  'Let me give you the key update first, then I will explain the cause and next step.',
              betterExpressionTranslation: '我先给你关键更新，再说明原因和下一步。',
            ),
          )
          .toList(growable: false),
    );
  }

  String _phoneNickname(String? phone) {
    final String value = (phone ?? '').trim();
    if (value.length < 4) {
      return '学习者';
    }
    return '用户${value.substring(value.length - 4)}';
  }

  String _emailNickname({String? email, String? nickname}) {
    final String customNickname = (nickname ?? '').trim();
    if (customNickname.isNotEmpty) {
      return customNickname;
    }

    final String value = (email ?? '').trim();
    if (value.contains('@')) {
      return value.split('@').first;
    }
    return '学习者';
  }
}
