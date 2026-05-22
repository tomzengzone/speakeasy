import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/api_client.dart';

enum _InterviewLlmSessionPurpose {
  question,
  hint,
  review,
  wiki,
  mastery,
  diagnosis,
}

class InterviewLlmScheduler {
  InterviewLlmScheduler();

  String _questionSessionId = '';
  String _hintSessionId = '';
  String _reviewSessionId = '';
  String _wikiSessionId = '';
  String _masterySessionId = '';
  String _diagnosisSessionId = '';
  final Map<_InterviewLlmSessionPurpose, Future<String>> _pendingSessionIds =
      <_InterviewLlmSessionPurpose, Future<String>>{};

  bool get hasSession =>
      _questionSessionId.isNotEmpty ||
      _hintSessionId.isNotEmpty ||
      _reviewSessionId.isNotEmpty ||
      _wikiSessionId.isNotEmpty ||
      _masterySessionId.isNotEmpty ||
      _diagnosisSessionId.isNotEmpty;

  Future<void> ensureSession() async {
    await _ensureSessionFor(_InterviewLlmSessionPurpose.question);
  }

  Future<String> _ensureSessionFor(_InterviewLlmSessionPurpose purpose) async {
    final String existing = _sessionIdFor(purpose);
    if (existing.isNotEmpty) {
      return existing;
    }
    final Future<String>? pending = _pendingSessionIds[purpose];
    if (pending != null) {
      return pending;
    }
    final Future<String> created = _createSessionFor(purpose);
    _pendingSessionIds[purpose] = created;
    try {
      return await created;
    } finally {
      _pendingSessionIds.remove(purpose);
    }
  }

  Future<String> _createSessionFor(_InterviewLlmSessionPurpose purpose) async {
    final Map<String, dynamic> data = await ApiClient.createAiSessionData(
      sceneTitle: _sessionTitleFor(purpose),
      sceneGoal: _sessionGoalFor(purpose),
      userRole: 'Candidate',
      relationship: 'Interviewer and candidate in a job interview',
      npcName: 'Alex',
      npcRole: _sessionNpcRoleFor(purpose),
      environment: 'Online job interview',
      challenge: _sessionChallengeFor(purpose),
      sceneSpec: SceneSpec(
        category: 'interview',
        timeContext: 'mock interview practice',
        tone: 'supportive and realistic',
        pressureLevel: 3,
        interruptionLevel: 1,
        followupDepth: 3,
        warmth: 3,
        responseLength: 'short',
        mustNot: const <String>[
          'Do not give a full model answer before the user tries.',
          'Do not ask more than one question at a time.',
          'Do not switch into a long grammar lesson during the interview.',
        ],
        mustInclude: _sessionMustIncludeFor(purpose),
        version: 1,
        plotDesign: purpose == _InterviewLlmSessionPurpose.question
            ? 'Opening, self introduction, background, project, strength, role fit, career plan, weakness, pressure, candidate questions, wrap-up.'
            : 'Support the local expression Wiki engine. Do not change the active target node.',
      ),
    );
    final String sessionId = (data['sessionId'] as String? ?? '').trim();
    _setSessionIdFor(purpose, sessionId);
    return sessionId;
  }

  String _sessionIdFor(_InterviewLlmSessionPurpose purpose) {
    return switch (purpose) {
      _InterviewLlmSessionPurpose.question => _questionSessionId,
      _InterviewLlmSessionPurpose.hint => _hintSessionId,
      _InterviewLlmSessionPurpose.review => _reviewSessionId,
      _InterviewLlmSessionPurpose.wiki => _wikiSessionId,
      _InterviewLlmSessionPurpose.mastery => _masterySessionId,
      _InterviewLlmSessionPurpose.diagnosis => _diagnosisSessionId,
    };
  }

  void _setSessionIdFor(_InterviewLlmSessionPurpose purpose, String sessionId) {
    switch (purpose) {
      case _InterviewLlmSessionPurpose.question:
        _questionSessionId = sessionId;
      case _InterviewLlmSessionPurpose.hint:
        _hintSessionId = sessionId;
      case _InterviewLlmSessionPurpose.review:
        _reviewSessionId = sessionId;
      case _InterviewLlmSessionPurpose.wiki:
        _wikiSessionId = sessionId;
      case _InterviewLlmSessionPurpose.mastery:
        _masterySessionId = sessionId;
      case _InterviewLlmSessionPurpose.diagnosis:
        _diagnosisSessionId = sessionId;
    }
  }

  String _sessionTitleFor(_InterviewLlmSessionPurpose purpose) {
    return switch (purpose) {
      _InterviewLlmSessionPurpose.question =>
        'English mock interview question planner',
      _InterviewLlmSessionPurpose.hint => 'English interview hint generator',
      _InterviewLlmSessionPurpose.review => 'English interview review writer',
      _InterviewLlmSessionPurpose.wiki => 'English growth wiki compiler',
      _InterviewLlmSessionPurpose.mastery => 'English expression mastery judge',
      _InterviewLlmSessionPurpose.diagnosis => 'English answer diagnosis coach',
    };
  }

  String _sessionGoalFor(_InterviewLlmSessionPurpose purpose) {
    return switch (purpose) {
      _InterviewLlmSessionPurpose.question =>
        'Lightly adapt local scene graph interview questions without changing the active target.',
      _InterviewLlmSessionPurpose.hint =>
        'Generate one concise candidate answer hint around the active target expression.',
      _InterviewLlmSessionPurpose.review =>
        'Write a short review from the completed interview turns.',
      _InterviewLlmSessionPurpose.wiki =>
        'Compile learner evidence into the personal growth wiki.',
      _InterviewLlmSessionPurpose.mastery =>
        'Judge whether the learner reproduced the active expression intent and core structure.',
      _InterviewLlmSessionPurpose.diagnosis =>
        'Diagnose one learner answer and create a targeted retry coaching message.',
    };
  }

  String _sessionNpcRoleFor(_InterviewLlmSessionPurpose purpose) {
    return switch (purpose) {
      _InterviewLlmSessionPurpose.question => 'Interviewer question adapter',
      _InterviewLlmSessionPurpose.hint => 'Interview hint coach',
      _InterviewLlmSessionPurpose.review => 'Interview review coach',
      _InterviewLlmSessionPurpose.wiki => 'Learning wiki compiler',
      _InterviewLlmSessionPurpose.mastery => 'Expression mastery judge',
      _InterviewLlmSessionPurpose.diagnosis => 'Private spoken English coach',
    };
  }

  String _sessionChallengeFor(_InterviewLlmSessionPurpose purpose) {
    return switch (purpose) {
      _InterviewLlmSessionPurpose.question =>
        'Rewrite only the provided local fallback interview question. Preserve the same target node and answer focus.',
      _InterviewLlmSessionPurpose.hint =>
        'Generate a candidate answer hint only. Do not create interviewer questions.',
      _InterviewLlmSessionPurpose.review =>
        'Summarize learning state without asking new interview questions.',
      _InterviewLlmSessionPurpose.wiki =>
        'Extract durable learner facts and expression evidence. Return only the requested wiki format.',
      _InterviewLlmSessionPurpose.mastery =>
        'Return only the requested mastery judgement. Do not coach or ask questions.',
      _InterviewLlmSessionPurpose.diagnosis =>
        'Return one structured diagnosis and one concise retry instruction. Do not ask the next interview question.',
    };
  }

  List<String> _sessionMustIncludeFor(_InterviewLlmSessionPurpose purpose) {
    return switch (purpose) {
      _InterviewLlmSessionPurpose.question => const <String>[
        'Use the local fallback question as the source of truth.',
        'Ask one concise natural interview question.',
        'Keep the active expression target unchanged.',
      ],
      _InterviewLlmSessionPurpose.hint => const <String>[
        'Return a candidate-facing hint or suggested answer only.',
        'Use the active target expression.',
      ],
      _InterviewLlmSessionPurpose.review => const <String>[
        'Mention mastered expression progress.',
        'Mention next learning focus.',
      ],
      _InterviewLlmSessionPurpose.wiki => const <String>[
        'Preserve user evidence.',
        'Use structured durable learning state.',
      ],
      _InterviewLlmSessionPurpose.mastery => const <String>[
        'Judge intent and core structure.',
        'Return strict structured judgement.',
      ],
      _InterviewLlmSessionPurpose.diagnosis => const <String>[
        'Diagnose the actual learner answer.',
        'Coach one fix at a time.',
        'Return strict structured diagnosis.',
      ],
    };
  }

  Future<String?> adaptNextQuestion({
    required InterviewPracticeSession session,
    required InterviewQuestionPlan plan,
    required String userText,
    required List<InterviewChatMessage> messages,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    if (plan.action == 'wrap_up') {
      return null;
    }
    try {
      final String sessionId = await _ensureSessionFor(
        _InterviewLlmSessionPurpose.question,
      );
      if (sessionId.isEmpty) {
        return null;
      }
      final List<InterviewChatMessage> recentMessages = messages.length > 10
          ? messages.sublist(messages.length - 10)
          : messages;
      final List<Map<String, dynamic>> history = recentMessages
          .map(
            (InterviewChatMessage message) => <String, dynamic>{
              'role': message.role == 'assistant' ? 'assistant' : 'user',
              'text': message.text,
            },
          )
          .toList(growable: false);
      final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
        sessionId,
        _buildQuestionPlanPrompt(
          session: session,
          plan: plan,
          userText: userText,
          memoryPack: memoryPack,
        ),
        draft: _interviewDraft(session),
        history: history,
      );
      final String reply = _cleanReply(
        (response['reply'] as String? ?? '').trim(),
      );
      if (_questionFitsPlan(reply, plan)) {
        return reply;
      }
    } catch (error, stackTrace) {
      debugPrint('[InterviewLlmScheduler] question adaptation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  Future<String?> generateOpeningQuestion({
    required InterviewPracticeSession session,
    required InterviewQuestionPlan plan,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    try {
      final String sessionId = await _ensureSessionFor(
        _InterviewLlmSessionPurpose.question,
      );
      if (sessionId.isEmpty) {
        return null;
      }
      final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
        sessionId,
        _buildQuestionPlanPrompt(
          session: session,
          plan: plan,
          userText: '',
          memoryPack: memoryPack,
          isOpening: true,
        ),
        draft: _interviewDraft(session),
        history: const <Map<String, dynamic>>[],
      );
      final String reply = _cleanReply(
        (response['reply'] as String? ?? '').trim(),
      );
      if (_questionFitsPlan(reply, plan)) {
        return reply;
      }
    } catch (error, stackTrace) {
      debugPrint('[InterviewLlmScheduler] opening question failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  Future<String?> generateReviewNote({
    required InterviewPracticeSession session,
    required InterviewReview review,
  }) async {
    try {
      final String sessionId = await _ensureSessionFor(
        _InterviewLlmSessionPurpose.review,
      );
      if (sessionId.isEmpty || session.turns.isEmpty) {
        return null;
      }
      final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
        sessionId,
        _buildReviewPrompt(session: session, review: review),
        draft: _interviewDraft(session),
        history: session.turns
            .take(12)
            .map(
              (InterviewTurnRecord turn) => <String, dynamic>{
                'role': 'user',
                'text': turn.userText,
              },
            )
            .toList(growable: false),
      );
      final String reply = _cleanReply(
        (response['reply'] as String? ?? '').trim(),
      );
      if (reply.isNotEmpty) {
        return reply;
      }
    } catch (error, stackTrace) {
      debugPrint('[InterviewLlmScheduler] review note failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  Future<InterviewCompiledWiki?> compilePersonalWiki({
    required InterviewPracticeSession session,
    required InterviewReview review,
    required List<InterviewPersonalWikiExpression> masteredExpressions,
    required InterviewCompiledWiki existingWiki,
  }) async {
    try {
      final String sessionId = await _ensureSessionFor(
        _InterviewLlmSessionPurpose.wiki,
      );
      if (sessionId.isEmpty || session.turns.isEmpty) {
        return null;
      }
      final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
        sessionId,
        _buildWikiCompilePrompt(
          session: session,
          review: review,
          masteredExpressions: masteredExpressions,
          existingWiki: existingWiki,
        ),
        draft: _interviewDraft(session),
        history: session.turns
            .take(14)
            .map(
              (InterviewTurnRecord turn) => <String, dynamic>{
                'role': 'user',
                'text': turn.userText,
              },
            )
            .toList(growable: false),
      );
      return _decodeCompiledWiki((response['reply'] as String? ?? '').trim());
    } catch (error, stackTrace) {
      debugPrint('[InterviewLlmScheduler] wiki compilation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  Future<String?> generateContextualHint({
    required InterviewPracticeSession session,
    required String question,
    required String answerFocus,
    required String learnerDraft,
    required InterviewExpression targetExpression,
    required List<InterviewChatMessage> messages,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    try {
      final String sessionId = await _ensureSessionFor(
        _InterviewLlmSessionPurpose.hint,
      );
      if (sessionId.isEmpty || question.trim().isEmpty) {
        return null;
      }
      final List<InterviewChatMessage> recentMessages = messages.length > 8
          ? messages.sublist(messages.length - 8)
          : messages;
      final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
        sessionId,
        _buildHintPrompt(
          session: session,
          question: question,
          answerFocus: answerFocus,
          learnerDraft: learnerDraft,
          targetExpression: targetExpression,
          memoryPack: memoryPack,
        ),
        draft: _interviewDraft(session),
        history: recentMessages
            .map(
              (InterviewChatMessage message) => <String, dynamic>{
                'role': message.role == 'assistant' ? 'assistant' : 'user',
                'text': message.text,
              },
            )
            .toList(growable: false),
      );
      final String? hint = _validatedHintFromReply(
        (response['reply'] as String? ?? '').trim(),
        question: question,
        targetExpression: targetExpression,
      );
      if (hint != null && hint.isNotEmpty) {
        return hint;
      }
    } catch (error, stackTrace) {
      debugPrint('[InterviewLlmScheduler] contextual hint failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  Future<InterviewExpressionMasteryResult?> judgeExpressionMastery({
    required InterviewPracticeSession session,
    required InterviewExpression targetExpression,
    required String question,
    required String userText,
    required InterviewExpressionMasteryResult localResult,
    InterviewExpressionNode? node,
  }) async {
    if (!localResult.lowConfidence) {
      return null;
    }
    try {
      final String sessionId = await _ensureSessionFor(
        _InterviewLlmSessionPurpose.mastery,
      );
      if (sessionId.isEmpty) {
        return null;
      }
      final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
        sessionId,
        _buildMasteryJudgePrompt(
          session: session,
          targetExpression: targetExpression,
          question: question,
          userText: userText,
          localResult: localResult,
          node: node,
        ),
        draft: _interviewDraft(session),
        history: const <Map<String, dynamic>>[],
      );
      return _decodeMasteryJudgeReply(
        (response['reply'] as String? ?? '').trim(),
      );
    } catch (error, stackTrace) {
      debugPrint('[InterviewLlmScheduler] mastery judge failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  Future<InterviewAnswerDiagnosis?> diagnoseAnswerForCoach({
    required InterviewPracticeSession session,
    required InterviewExpression targetExpression,
    required String question,
    required String userText,
    required InterviewExpressionMasteryResult localResult,
    required int attemptNumber,
    required List<InterviewChatMessage> messages,
    PronunciationScore? pronunciationScore,
    int? grammarScore,
    List<String> grammarIssues = const <String>[],
    String grammarCorrection = '',
    InterviewExpressionNode? node,
    InterviewWikiMemoryPack? memoryPack,
  }) async {
    try {
      final String sessionId = await _ensureSessionFor(
        _InterviewLlmSessionPurpose.diagnosis,
      );
      if (sessionId.isEmpty || userText.trim().isEmpty) {
        return null;
      }
      final List<InterviewChatMessage> recentMessages = messages.length > 8
          ? messages.sublist(messages.length - 8)
          : messages;
      final Map<String, dynamic> response = await ApiClient.sendSceneMessage(
        sessionId,
        _buildAnswerDiagnosisPrompt(
          session: session,
          targetExpression: targetExpression,
          question: question,
          userText: userText,
          localResult: localResult,
          attemptNumber: attemptNumber,
          pronunciationScore: pronunciationScore,
          grammarScore: grammarScore,
          grammarIssues: grammarIssues,
          grammarCorrection: grammarCorrection,
          node: node,
          memoryPack: memoryPack,
        ),
        draft: _interviewDraft(session),
        history: recentMessages
            .map(
              (InterviewChatMessage message) => <String, dynamic>{
                'role': message.role == 'assistant' ? 'assistant' : 'user',
                'text': message.text,
              },
            )
            .toList(growable: false),
      );
      return _decodeAnswerDiagnosisReply(
        (response['reply'] as String? ?? '').trim(),
      );
    } catch (error, stackTrace) {
      debugPrint('[InterviewLlmScheduler] answer diagnosis failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }

  @visibleForTesting
  String? validateHintReplyForTesting(
    String raw, {
    required String question,
    required InterviewExpression targetExpression,
  }) {
    return _validatedHintFromReply(
      raw,
      question: question,
      targetExpression: targetExpression,
    );
  }

  @visibleForTesting
  bool questionFitsPlanForTesting(String value, InterviewQuestionPlan plan) {
    return _questionFitsPlan(value, plan);
  }

  @visibleForTesting
  InterviewAnswerDiagnosis? decodeAnswerDiagnosisForTesting(String raw) {
    return _decodeAnswerDiagnosisReply(raw);
  }

  SceneDraft _interviewDraft(InterviewPracticeSession session) {
    if (_isOnboardingSession(session)) {
      return SceneDraft(
        title: 'English onboarding introduction',
        emoji: '🤝',
        tags: const <String>['入职', '团队介绍', '职场口语'],
        userRole: 'New teammate',
        relationship: 'Onboarding mentor and new teammate',
        goal:
            'Help the learner handle first-day onboarding introductions and team alignment conversations in spoken English.',
        npcName: 'Maya',
        npcRole: 'Onboarding mentor',
        environment: 'First-day onboarding conversation',
        challenge:
            'Current stage: ${stageLabels[session.currentStage] ?? session.currentStage}. Ask one concise onboarding question.',
        sceneSpec: const SceneSpec(
          category: 'workplace_onboarding',
          timeContext: 'first-day onboarding practice',
          tone: 'warm, collaborative, and realistic',
          pressureLevel: 2,
          interruptionLevel: 1,
          followupDepth: 3,
          warmth: 4,
          responseLength: 'short',
          mustNot: <String>[
            'Do not give a full model answer before the user tries.',
            'Do not ask more than one question at a time.',
          ],
          mustInclude: <String>[
            'Ask one onboarding conversation question.',
            'Keep the wording concise, natural, and teammate-like.',
          ],
          version: 1,
          plotDesign:
              'Structured English onboarding introduction and team alignment practice.',
        ),
      );
    }
    return SceneDraft(
      title: 'English mock interview',
      emoji: '💼',
      tags: const <String>['面试', '口语练习', 'AI 调度'],
      userRole: 'Candidate',
      relationship: 'Job interviewer and candidate',
      goal:
          'Help the learner answer job interview questions in spoken English.',
      npcName: 'Alex',
      npcRole: 'Interview coach',
      environment: 'Online job interview',
      challenge:
          'Current stage: ${stageLabels[session.currentStage] ?? session.currentStage}. Ask one concise question.',
      sceneSpec: const SceneSpec(
        category: 'interview',
        timeContext: 'mock interview practice',
        tone: 'supportive and realistic',
        pressureLevel: 3,
        interruptionLevel: 1,
        followupDepth: 3,
        warmth: 3,
        responseLength: 'short',
        mustNot: <String>[
          'Do not give a full model answer before the user tries.',
          'Do not ask more than one question at a time.',
        ],
        mustInclude: <String>[
          'Ask one interview question.',
          'Keep the wording concise and natural.',
        ],
        version: 1,
        plotDesign: 'Structured English job interview practice.',
      ),
    );
  }

  bool _isOnboardingSession(InterviewPracticeSession session) {
    return session.publicSceneId.trim() == 'onboarding_introduction';
  }

  String _sceneRuntimeInstruction(InterviewPracticeSession session) {
    if (!_isOnboardingSession(session)) {
      return '''
Active scene: job interview.
Role: realistic interviewer speaking to a candidate.
Do not drift into onboarding, classroom, or generic chat.
''';
    }
    return '''
Active scene: onboarding introduction.
Role: warm onboarding mentor or team lead speaking to a new teammate.
This is not a job interview. Do not use interviewer/candidate framing.
Keep the conversation like a first-day team onboarding, with warmth, clarity, responsibility alignment, and collaboration norms.
''';
  }

  String _buildQuestionPlanPrompt({
    required InterviewPracticeSession session,
    required InterviewQuestionPlan plan,
    required String userText,
    InterviewWikiMemoryPack? memoryPack,
    bool isOpening = false,
  }) {
    final String targetBlock = plan.targetExpression == null
        ? '(none)'
        : '''
id: ${plan.targetExpression!.id}
text: ${plan.targetExpression!.text}
tag: ${plan.targetExpression!.tag}
use_case: ${plan.targetExpression!.useCase}
coach_context:
${plan.targetExpression!.coachContext.isEmpty ? '(none)' : plan.targetExpression!.coachContext}
''';
    return '''
$interviewSystemPrompt

${_sceneRuntimeInstruction(session)}

${isOpening ? 'This is the first question of a newly opened practice round. There is no user answer in this round yet.' : 'The learner\'s actual latest answer is between the tags below. Treat it as the user turn and do not invent or replace it.'}
<user_answer>
$userText
</user_answer>

QuestionPlan decided by the local learning engine:
- action: ${plan.action}
- stage: ${plan.stage}
- practice focus: ${plan.practiceFocus}
- coverage: ${plan.coverageStatus.isEmpty ? '(opening)' : plan.coverageStatus}
- predicted tag: ${plan.predictedTag}
- question intent: ${plan.questionIntent}
- must ask about: ${plan.mustAskAbout}
- local fallback question: ${plan.localFallbackQuestion}

Hidden target expression, if any. Use this only to shape the context. Do not mention it verbatim and do not give a sample answer:
$targetBlock

Retrieved learner memory for this turn:
${_memoryPackBlock(memoryPack)}

	Rules:
	- Follow the QuestionPlan exactly. Do not choose a different teaching action.
		- Treat the local fallback question as the source of truth. You may only lightly rewrite it into natural scene wording.
	- Use coach_context silently to choose a realistic, patient, professional tone.
		- Ask only one concise scene question in English, preserving the same answer focus as the local fallback.
		- If this is an opening or resumed round, sound like the scene role above, not like a classroom exercise.
	- Do not ask "how would you respond" unless the local fallback explicitly requires it.
	- Never output generic coaching commands such as "Give me your direct answer first", "Answer directly", "Try again", or "Say it again".
	- If you are unsure, output the local fallback question exactly.
	- Do not include JSON, labels, Chinese explanation, or a sample answer.
	- Do not reveal the hidden target expression or the scheduling logic.
		- Keep the question natural for the active scene.
''';
  }

  String _buildReviewPrompt({
    required InterviewPracticeSession session,
    required InterviewReview review,
  }) {
    final String turnBlock = session.turns
        .map(
          (InterviewTurnRecord turn) =>
              '- ${stageLabels[turn.stage] ?? turn.stage}: ${turn.userText}',
        )
        .join('\n');
    return '''
You are now in review mode after a mock interview.

Learning state based only on reproduced Wiki expressions:
- mastered this round: ${review.masteredThisRoundCount}
- total mastery: ${review.totalMasteredCount}/${review.totalExpressionCount}
- weak tags: ${review.weakTags.join(', ')}
- next round focus: ${review.nextRoundMode == InterviewNextRoundMode.review ? 'spaced repetition review' : 'new expression expansion'}
- next round message: ${review.nextRoundMessage}
- due review expressions: ${review.dueReviewCount}

Learner turns:
$turnBlock

Write a short bilingual review in 2 bullets. Do not mention grammar scores. Be direct and beginner-friendly. Keep it under 70 words.
''';
  }

  String _buildHintPrompt({
    required InterviewPracticeSession session,
    required String question,
    required String answerFocus,
    required String learnerDraft,
    required InterviewExpression targetExpression,
    InterviewWikiMemoryPack? memoryPack,
  }) {
    final String expressionBlock =
        '''
expression_id: ${targetExpression.id}
expression_text: ${targetExpression.text}
tag: ${targetExpression.tag}
use_case: ${targetExpression.useCase}
coach_context:
${targetExpression.coachContext.isEmpty ? '(none)' : targetExpression.coachContext}
''';
    return '''
You are generating one just-in-time spoken English hint for a mock interview.

${_sceneRuntimeInstruction(session)}

Current stage: ${stageLabels[session.currentStage] ?? session.currentStage}
Current practice focus: ${session.roundMode == InterviewNextRoundMode.review ? 'spaced repetition review' : 'new expression expansion'}
Current interviewer question:
$question

Underlying answer focus:
${answerFocus.trim().isEmpty ? '(infer from current stage)' : answerFocus}

Learner current draft or latest answer:
${learnerDraft.isEmpty ? '(empty)' : learnerDraft}

Target expression chosen by the local learning engine. The interviewer question was designed to help the learner say this expression:
$expressionBlock

Retrieved learner memory for this turn:
${_memoryPackBlock(memoryPack)}

Rules:
- This is a hint, not a lesson. No grammar explanation.
- Use the target expression above. Do not choose a different expression.
- Use coach_context to decide whether the learner needs a smaller step, a more professional tone, or a spoken retry.
- The target expression may contain bracket placeholders like [real weakness + action]. In suggested_reply, replace every placeholder with specific, natural content. Never output brackets or placeholder text.
- If the learner draft already answers the question reasonably, polish their idea around the target expression.
	- If the current interviewer question is overly brief or directive, answer the underlying answer focus instead of copying the surface wording.
- If the learner is empty or stuck, build a direct answer to the current question and underlying focus with the target expression.
- Transition expressions may be included only as a lead-in, not as the whole answer.
- suggested_reply must be 1-2 short English sentences, directly answer the question, and use the selected expression naturally.
- Do not mention scores, tags, or stage names.

Return only strict JSON:
{
  "suggested_reply": "1-2 sentence English answer"
}
''';
  }

  String _buildMasteryJudgePrompt({
    required InterviewPracticeSession session,
    required InterviewExpression targetExpression,
    required String question,
    required String userText,
    required InterviewExpressionMasteryResult localResult,
    InterviewExpressionNode? node,
  }) {
    final String variants = node == null
        ? '(none)'
        : node.expectedVariants
              .take(6)
              .map((InterviewExpectedVariant item) => '- ${item.text}')
              .join('\n');
    final String missingMoves = localResult.missingCoreMoves.isEmpty
        ? '(none)'
        : localResult.missingCoreMoves.join(', ');
    return '''
You are a strict but fair evaluator for English interview expression mastery.

${_sceneRuntimeInstruction(session)}

Current stage: ${stageLabels[session.currentStage] ?? session.currentStage}
Interviewer question:
$question

Target expression:
id: ${targetExpression.id}
text: ${targetExpression.text}
intent: ${node?.intent ?? targetExpression.useCase}
meaning: ${node?.meaning ?? ''}
natural_timing: ${node?.naturalTiming ?? ''}
coach_context:
${node?.coachContext.isNotEmpty == true
        ? node!.coachContext
        : targetExpression.coachContext.isEmpty
        ? '(none)'
        : targetExpression.coachContext}

Expected variants:
$variants

Learner answer:
$userText

Local heuristic result:
status: ${localResult.status.name}
confidence: ${localResult.confidence}
missing_core_moves: $missingMoves

Judging rules:
- Judge whether the learner answered the interviewer question and naturally used the target expression's intent plus core structure.
- Apply coach_context as a rubric, but stay fair: accept natural variants that meet the communicative move.
- Small grammar mistakes, minor word order issues, or synonyms are acceptable.
- Do not require exact wording.
- Do not mark as mastered if the learner only matched the general topic but missed the target expression's core move.
- If the learner is close but incomplete, use "nearMiss".
- If the learner repeats the interviewer question, asks an unrelated question, or is off-topic, use "missed".
- Do not generate a hint or corrected answer.

Return only strict JSON:
{
  "mastery_status": "mastered|nearMiss|missed",
  "confidence": 0.0,
  "reason": "short reason",
  "matched_variant": "matched target or variant, empty if none",
  "missing_core_moves": ["short missing move"]
}
''';
  }

  String _buildAnswerDiagnosisPrompt({
    required InterviewPracticeSession session,
    required InterviewExpression targetExpression,
    required String question,
    required String userText,
    required InterviewExpressionMasteryResult localResult,
    required int attemptNumber,
    PronunciationScore? pronunciationScore,
    int? grammarScore,
    List<String> grammarIssues = const <String>[],
    String grammarCorrection = '',
    InterviewExpressionNode? node,
    InterviewWikiMemoryPack? memoryPack,
  }) {
    final String variants = node == null
        ? '(none)'
        : node.expectedVariants
              .take(5)
              .map((InterviewExpectedVariant item) => '- ${item.text}')
              .join('\n');
    final String missingMoves = localResult.missingCoreMoves.isEmpty
        ? '(none)'
        : localResult.missingCoreMoves.join(', ');
    final String pronunciationBlock = pronunciationScore == null
        ? '(not available)'
        : '''
overall: ${pronunciationScore.overall}
accuracy: ${_scoreValue(pronunciationScore.accuracy)}
fluency: ${_scoreValue(pronunciationScore.fluency)}
completeness: ${_scoreValue(pronunciationScore.completeness)}
source: ${pronunciationScore.source.isEmpty ? '(unknown)' : pronunciationScore.source}
''';
    final String grammarBlock =
        grammarScore == null &&
            grammarIssues.isEmpty &&
            grammarCorrection.trim().isEmpty
        ? '(not available)'
        : '''
score: ${_scoreValue(grammarScore)}
issues: ${grammarIssues.isEmpty ? '(none)' : grammarIssues.take(3).join(' | ')}
correction: ${grammarCorrection.trim().isEmpty ? '(none)' : grammarCorrection.trim()}
''';
    return '''
You are diagnosing one learner answer for a patient, professional private English speaking coach.

${_sceneRuntimeInstruction(session)}

Current stage: ${stageLabels[session.currentStage] ?? session.currentStage}
Attempt number for this same target: $attemptNumber
Interviewer question:
$question

Learner answer:
$userText

Target expression selected by the local scene Wiki:
id: ${targetExpression.id}
text: ${targetExpression.text}
intent: ${node?.intent ?? targetExpression.useCase}
meaning: ${node?.meaning ?? ''}
tag: ${targetExpression.tag}
coach_context:
${node?.coachContext.isNotEmpty == true
        ? node!.coachContext
        : targetExpression.coachContext.isEmpty
        ? '(none)'
        : targetExpression.coachContext}

Expected natural variants:
$variants

Local mastery signal:
status: ${localResult.status.name}
confidence: ${localResult.confidence}
reason: ${localResult.reason.isEmpty ? '(none)' : localResult.reason}
missing_core_moves: $missingMoves

Pronunciation signal:
$pronunciationBlock

Grammar signal:
$grammarBlock

Retrieved learner memory:
${_memoryPackBlock(memoryPack)}

Diagnosis rules:
- Diagnose the learner's actual answer, not a generic interview skill.
- Treat the target expression as a model answer tier, not a script to memorize.
- Preserve the learner's real role, company, project, result, and metrics when suggesting a repair.
- If the target example's role or field does not match the learner, reuse only its frame and ask the learner to fill in their own facts.
- Pick exactly one main issue_type: missing_intent, grammar, tone, too_short, pronunciation, fluency, off_topic, question_echo, or complete.
- Prioritize communicative intent and target expression use over grammar perfection.
- If pronunciation or grammar scores are clearly weak, use them only when they are the main blocker for this turn.
- The coach_message must be Chinese, concrete, and short. It should name one issue and ask for one retry.
- attempt_number 1: do not reveal the full target sentence; give only a micro-fix phrase if useful.
- attempt_number 2: give a short starter frame.
- attempt_number 3 or higher: you may give one complete model sentence.
- Do not ask the next interview question.
- Do not lecture. Do not mention JSON, local engine, Wiki, or hidden target.
- suggested_reply must be empty unless attempt_number is 3 or higher.

Return only strict JSON:
{
  "issue_type": "missing_intent|grammar|tone|too_short|pronunciation|fluency|off_topic|question_echo|complete",
  "did_well": "one short thing the learner did well, Chinese",
  "main_issue": "the single blocker, Chinese",
  "micro_fix": "one phrase or move to add, Chinese plus short English if useful",
  "retry_mode": "say_again|add_one_phrase|use_starter|repeat_model|move_on",
  "coach_message": "2-3 short Chinese lines for the learner",
  "suggested_reply": "",
  "confidence": 0.0
}
''';
  }

  String _buildWikiCompilePrompt({
    required InterviewPracticeSession session,
    required InterviewReview review,
    required List<InterviewPersonalWikiExpression> masteredExpressions,
    required InterviewCompiledWiki existingWiki,
  }) {
    final String turnBlock = session.turns
        .map(
          (InterviewTurnRecord turn) =>
              '- stage=${stageLabels[turn.stage] ?? turn.stage}; answer="${turn.userText}"; coverage=${turn.coverageStatus}; tags=${turn.predictedTags.join(', ')}',
        )
        .join('\n');
    final String masteredBlock = masteredExpressions
        .take(20)
        .map(
          (InterviewPersonalWikiExpression item) =>
              '- ${item.text} | tag=${item.tag} | user_example=${item.userExample}',
        )
        .join('\n');
    return '''
You compile a learner's long-term interview speaking Wiki from one mock interview.

Existing compiled Wiki:
${_wikiContextBlock(existingWiki)}

Current round signals:
- mastered this round: ${review.masteredThisRoundCount}
- total mastery: ${review.totalMasteredCount}/${review.totalExpressionCount}
- weak tags: ${review.weakTags.join(', ')}
- due review expressions: ${review.dueReviewCount}

Learner turns:
$turnBlock

Mastered expression records:
$masteredBlock

Compile only durable, reusable knowledge. Do not invent facts. Prefer concise English with short Chinese labels only when helpful.

Return only strict JSON with this shape:
{
  "summary": "1-2 sentence long-term learner profile for future interview practice",
  "personal_facts": [
    {"title": "short label", "body": "durable fact about the learner", "tag": "one interview tag", "evidence": "short quote or paraphrase"}
  ],
  "interview_stories": [
    {"title": "story label", "body": "STAR-style reusable interview story or material", "tag": "one interview tag", "evidence": "short quote or paraphrase"}
  ],
  "weak_patterns": [
    {"title": "pattern label", "body": "recurring weakness, stuck point, or underdeveloped answer pattern", "tag": "one interview tag", "evidence": "short quote or paraphrase"}
  ],
  "next_targets": [
    {"title": "target label", "body": "next expression or answer move to practice", "tag": "one interview tag", "evidence": "why this target matters"}
  ]
}
Keep each list to at most 4 items.
''';
  }

  String _wikiContextBlock(InterviewCompiledWiki? wiki) {
    if (wiki == null || wiki.isEmpty) {
      return '(empty)';
    }
    final List<String> lines = <String>[];
    if (wiki.summary.trim().isNotEmpty) {
      lines.add('summary: ${wiki.summary.trim()}');
    }
    lines.addAll(_wikiItemLines('personal facts', wiki.personalFacts));
    lines.addAll(_wikiItemLines('interview stories', wiki.interviewStories));
    lines.addAll(_wikiItemLines('weak patterns', wiki.weakPatterns));
    lines.addAll(_wikiItemLines('next targets', wiki.nextTargets));
    return lines.take(14).join('\n');
  }

  String _memoryPackBlock(InterviewWikiMemoryPack? pack) {
    if (pack == null || pack.isEmpty) {
      return '(empty)';
    }
    final List<String> lines = <String>[];
    final InterviewWikiActionItem? primaryAction = pack.primaryAction;
    if (primaryAction != null) {
      lines.add('primary action: ${primaryAction.promptLine}');
    }
    lines.addAll(
      pack.promptContext
          .where((InterviewWikiActionItem item) => item != primaryAction)
          .take(2)
          .map(
            (InterviewWikiActionItem item) =>
                'supporting context: ${item.promptLine}',
          ),
    );
    if (pack.summary.trim().isNotEmpty) {
      lines.add('profile: ${pack.summary.trim()}');
    }
    lines.addAll(
      pack.dueExpressions.take(2).map((String item) => 'due expression: $item'),
    );
    lines.addAll(
      pack.relevantFacts.take(2).map((String item) => 'relevant fact: $item'),
    );
    lines.addAll(
      pack.relevantStories.take(1).map((String item) => 'useful story: $item'),
    );
    lines.addAll(
      pack.weakPatterns.take(2).map((String item) => 'weak pattern: $item'),
    );
    lines.addAll(
      pack.nextTargets.take(2).map((String item) => 'next target: $item'),
    );
    lines.addAll(
      pack.weakExpressions
          .take(2)
          .map((String item) => 'weak expression: $item'),
    );
    lines.addAll(
      pack.commonErrors.take(2).map((String item) => 'common error: $item'),
    );
    lines.addAll(
      pack.pronunciationNotes
          .take(1)
          .map((String item) => 'pronunciation profile: $item'),
    );
    lines.addAll(
      pack.grammarNotes.take(1).map((String item) => 'grammar profile: $item'),
    );
    return lines.take(10).join('\n');
  }

  List<String> _wikiItemLines(
    String label,
    List<InterviewCompiledWikiItem> items,
  ) {
    return items
        .take(4)
        .map(
          (InterviewCompiledWikiItem item) =>
              '- $label: ${item.title}: ${item.body}${item.tag.isEmpty ? '' : ' [${item.tag}]'}',
        )
        .toList(growable: false);
  }

  InterviewCompiledWiki? _decodeCompiledWiki(String raw) {
    final Map<String, dynamic>? json = _decodeHintJson(raw);
    if (json == null) {
      return null;
    }
    final DateTime now = DateTime.now();
    final InterviewCompiledWiki wiki = InterviewCompiledWiki(
      updatedAt: now,
      summary: (json['summary'] as String? ?? '').trim(),
      personalFacts: _compiledWikiItemsFromJson(
        json['personal_facts'],
        section: 'fact',
        now: now,
      ),
      interviewStories: _compiledWikiItemsFromJson(
        json['interview_stories'],
        section: 'story',
        now: now,
      ),
      weakPatterns: _compiledWikiItemsFromJson(
        json['weak_patterns'],
        section: 'weak',
        now: now,
      ),
      nextTargets: _compiledWikiItemsFromJson(
        json['next_targets'],
        section: 'target',
        now: now,
      ),
    );
    return wiki.isEmpty ? null : wiki;
  }

  InterviewExpressionMasteryResult? _decodeMasteryJudgeReply(String raw) {
    final Map<String, dynamic>? json = _decodeHintJson(raw);
    if (json == null) {
      return null;
    }
    final String rawStatus =
        (json['mastery_status'] as String? ?? json['status'] as String? ?? '')
            .trim();
    final InterviewExpressionMasteryStatus? status = switch (rawStatus) {
      'mastered' => InterviewExpressionMasteryStatus.mastered,
      'nearMiss' ||
      'near_miss' ||
      'partial' => InterviewExpressionMasteryStatus.nearMiss,
      'missed' || 'miss' => InterviewExpressionMasteryStatus.missed,
      _ => null,
    };
    if (status == null) {
      return null;
    }
    final List<String> missingCoreMoves = <String>[];
    final Object? rawMissing = json['missing_core_moves'];
    if (rawMissing is List) {
      missingCoreMoves.addAll(
        rawMissing
            .whereType<String>()
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty),
      );
    }
    final double confidence = ((json['confidence'] as num?)?.toDouble() ?? 0.6)
        .clamp(0, 1)
        .toDouble();
    return InterviewExpressionMasteryResult(
      status: status,
      confidence: confidence,
      matchedVariant: (json['matched_variant'] as String? ?? '').trim(),
      missingCoreMoves: List<String>.unmodifiable(missingCoreMoves),
      reason: (json['reason'] as String? ?? 'llm mastery judge').trim(),
    );
  }

  InterviewAnswerDiagnosis? _decodeAnswerDiagnosisReply(String raw) {
    final Map<String, dynamic>? json = _decodeHintJson(raw);
    if (json == null) {
      return null;
    }
    final String issueType = _diagnosisString(
      json['issue_type'] ?? json['issueType'],
    ).toLowerCase();
    if (issueType.isEmpty) {
      return null;
    }
    final String coachMessage = _cleanCoachMessage(
      _diagnosisString(json['coach_message'] ?? json['coachMessage']),
    );
    final String mainIssue = _diagnosisString(
      json['main_issue'] ?? json['mainIssue'],
    );
    final String microFix = _diagnosisString(
      json['micro_fix'] ?? json['microFix'],
    );
    final String suggestedReply = _cleanSuggestedReply(
      _diagnosisString(json['suggested_reply'] ?? json['suggestedReply']),
    );
    if (coachMessage.isEmpty && mainIssue.isEmpty && microFix.isEmpty) {
      return null;
    }
    return InterviewAnswerDiagnosis(
      issueType: issueType,
      didWell: _diagnosisString(json['did_well'] ?? json['didWell']),
      mainIssue: mainIssue,
      microFix: microFix,
      retryMode: _diagnosisString(json['retry_mode'] ?? json['retryMode']),
      coachMessage: coachMessage,
      suggestedReply: suggestedReply,
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0.6)
          .clamp(0, 1)
          .toDouble(),
    );
  }

  List<InterviewCompiledWikiItem> _compiledWikiItemsFromJson(
    dynamic raw, {
    required String section,
    required DateTime now,
  }) {
    if (raw is! List) {
      return const <InterviewCompiledWikiItem>[];
    }
    final List<InterviewCompiledWikiItem> result =
        <InterviewCompiledWikiItem>[];
    for (final Object? item in raw.take(4)) {
      if (item is! Map) {
        continue;
      }
      final Map<String, dynamic> json = item.cast<String, dynamic>();
      final String title = (json['title'] as String? ?? '').trim();
      final String body = (json['body'] as String? ?? '').trim();
      if (title.isEmpty && body.isEmpty) {
        continue;
      }
      final String tag = (json['tag'] as String? ?? '').trim();
      result.add(
        InterviewCompiledWikiItem(
          id: _compiledWikiItemId(section, title, body, tag),
          title: title.isEmpty ? body : title,
          body: body,
          tag: tag,
          evidence: (json['evidence'] as String? ?? '').trim(),
          updatedAt: now,
        ),
      );
    }
    return result;
  }

  String _compiledWikiItemId(
    String section,
    String title,
    String body,
    String tag,
  ) {
    final String slug = '$tag $title $body'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isEmpty) {
      return '${section}_${DateTime.now().microsecondsSinceEpoch}';
    }
    return '${section}_${slug.length > 48 ? slug.substring(0, 48) : slug}';
  }

  String _cleanReply(String raw) {
    final int metadataStart = raw.indexOf(
      RegExp(r'\{\s*"(summary|mood|coach|event)"'),
    );
    final String text = metadataStart >= 0
        ? raw.substring(0, metadataStart)
        : raw;
    return text.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _validatedHintFromReply(
    String raw, {
    required String question,
    required InterviewExpression targetExpression,
  }) {
    final Map<String, dynamic>? json = _decodeHintJson(raw);
    final String suggestedReply = _cleanSuggestedReply(
      _extractSuggestedReply(raw, json),
    );
    if (suggestedReply.isEmpty) {
      return _rejectHintReply('empty suggested_reply', raw);
    }
    if (_containsPlaceholder(suggestedReply)) {
      return _rejectHintReply('suggested_reply contains placeholder', raw);
    }
    if (!_replyLooksLikeAnswer(suggestedReply)) {
      return _rejectHintReply(
        'suggested_reply does not look like an answer',
        raw,
      );
    }
    if (!_replyUsesExpression(
      expressionText: targetExpression.text,
      suggestedReply: suggestedReply,
    )) {
      debugPrint(
        '[InterviewLlmScheduler] contextual hint weak expression match accepted: '
        'target="${_shortLogValue(targetExpression.text)}", '
        'reply="${_shortLogValue(suggestedReply)}"',
      );
    }
    _logIgnoredHintExpressionMismatch(json, targetExpression);
    if (json == null) {
      debugPrint(
        '[InterviewLlmScheduler] contextual hint accepted from plain text reply',
      );
    }
    return <String>[
      '可以用：${targetExpression.text}',
      '可以这样答：$suggestedReply',
    ].join('\n');
  }

  String _extractSuggestedReply(String raw, Map<String, dynamic>? json) {
    if (json == null) {
      return raw;
    }
    for (final String key in const <String>[
      'suggested_reply',
      'suggestedReply',
      'reply',
      'answer',
    ]) {
      final Object? value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  String? _rejectHintReply(String reason, String raw) {
    debugPrint(
      '[InterviewLlmScheduler] contextual hint rejected: $reason; '
      'raw="${_shortLogValue(raw)}"',
    );
    return null;
  }

  void _logIgnoredHintExpressionMismatch(
    Map<String, dynamic>? json,
    InterviewExpression targetExpression,
  ) {
    if (json == null) {
      return;
    }
    final String expressionId = (json['expression_id'] as String? ?? '').trim();
    if (targetExpression.id.isNotEmpty &&
        expressionId.isNotEmpty &&
        expressionId != targetExpression.id) {
      debugPrint(
        '[InterviewLlmScheduler] contextual hint expression_id mismatch ignored: '
        '"$expressionId" != "${targetExpression.id}"',
      );
    }
    final String expressionText = (json['expression_text'] as String? ?? '')
        .trim();
    if (expressionText.isNotEmpty && expressionText != targetExpression.text) {
      debugPrint(
        '[InterviewLlmScheduler] contextual hint expression_text mismatch ignored: '
        '"${_shortLogValue(expressionText)}" != '
        '"${_shortLogValue(targetExpression.text)}"',
      );
    }
  }

  String _shortLogValue(String value) {
    final String normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 160) {
      return normalized;
    }
    return '${normalized.substring(0, 157)}...';
  }

  String _scoreValue(int? value) => value == null ? '(none)' : '$value';

  String _diagnosisString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  String _cleanCoachMessage(String raw) {
    final String text = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.length <= 220) {
      return text;
    }
    return '${text.substring(0, 220).trim()}...';
  }

  Map<String, dynamic>? _decodeHintJson(String raw) {
    String text = raw.trim().replaceAll('```json', '').replaceAll('```', '');
    final int start = text.indexOf('{');
    final int end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      text = text.substring(start, end + 1);
    }
    try {
      final Object? decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } catch (_) {}
    return null;
  }

  String _cleanSuggestedReply(String raw) {
    String text = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\-•]\s*'), '')
        .trim();
    for (final String prefix in const <String>[
      'Try starting with:',
      'Try saying:',
      '可以这样答：',
      '可以这样答:',
    ]) {
      if (text.toLowerCase().startsWith(prefix.toLowerCase())) {
        text = text.substring(prefix.length).trim();
        break;
      }
    }
    return text
        .replaceAll(RegExp("^[\"“”']+"), '')
        .replaceAll(RegExp("[\"“”']+\$"), '')
        .trim();
  }

  bool _containsPlaceholder(String value) {
    if (value.contains('[') || value.contains(']')) {
      return true;
    }
    final String lower = value.toLowerCase();
    return lower.contains('real weakness + action') ||
        lower.contains('specific motivation') ||
        lower.contains('task/responsibility') ||
        lower.contains('placeholder');
  }

  bool _replyUsesExpression({
    required String expressionText,
    required String suggestedReply,
  }) {
    final String expression = expressionText
        .toLowerCase()
        .replaceAll(RegExp(r'\[[^\]]+\]'), ' ')
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final String reply = suggestedReply
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final Set<String> expressionTokens = expression
        .split(' ')
        .where((String token) => token.length > 3)
        .toSet();
    if (expressionTokens.isEmpty) {
      return reply.contains(expression);
    }
    final Set<String> replyTokens = reply.split(' ').toSet();
    final int hits = expressionTokens.intersection(replyTokens).length;
    return hits / expressionTokens.length >= 0.55;
  }

  bool _replyLooksLikeAnswer(String suggestedReply) {
    final String normalized = suggestedReply.trim();
    if (normalized.length < 12 || normalized.length > 360) {
      return false;
    }
    if (normalized.contains('{') || normalized.contains('```')) {
      return false;
    }
    if (normalized.endsWith('?')) {
      return false;
    }
    if (RegExp(
      r'^(what|which|where|when|why|how|do|does|did|can|could|would|will|are|is|give|tell|ask|please)\b',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return false;
    }
    return _contentTokens(normalized).length >= 2;
  }

  Set<String> _contentTokens(String value) {
    const Set<String> stopWords = <String>{
      'what',
      'which',
      'where',
      'when',
      'why',
      'how',
      'the',
      'and',
      'you',
      'your',
      'this',
      'that',
      'about',
      'most',
      'part',
      'role',
      'job',
      'company',
    };
    return RegExp(r"[a-zA-Z']+")
        .allMatches(value.toLowerCase())
        .map((RegExpMatch match) => _stemContentToken(match.group(0)!))
        .where((String token) => token.length > 3 && !stopWords.contains(token))
        .toSet();
  }

  String _stemContentToken(String token) {
    if (token.length > 5 && token.endsWith('ing')) {
      return token.substring(0, token.length - 3);
    }
    if (token.length > 4 && token.endsWith('ed')) {
      return token.substring(0, token.length - 2);
    }
    if (token.length > 4 && token.endsWith('es')) {
      return token.substring(0, token.length - 2);
    }
    if (token.length > 4 && token.endsWith('s')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  bool _looksLikeSingleQuestion(String value) {
    final String text = value.trim();
    if (text.isEmpty || text.length > 220) {
      return false;
    }
    if (text.contains('{') || text.contains('```')) {
      return false;
    }
    final String lower = text.toLowerCase();
    return text.endsWith('?') ||
        RegExp(
          r"^(tell me|walk me through|describe|share|could you|can you|would you|please tell me|let us talk|let's talk|give me an example)\b",
        ).hasMatch(lower);
  }

  bool _questionFitsPlan(String value, InterviewQuestionPlan plan) {
    if (!_looksLikeSingleQuestion(value)) {
      return _rejectQuestionReply('not a concise interviewer question', value);
    }
    final String lower = _normalizeQuestionText(value);
    if (lower.contains('you could also say') ||
        lower.contains('for example') ||
        lower.contains('sample answer')) {
      return _rejectQuestionReply('looks like a sample answer', value);
    }
    if (_isGenericQuestionDirective(lower)) {
      return _rejectQuestionReply('generic coaching directive', value);
    }
    final String target = plan.targetExpressionText
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (target.isNotEmpty && target.length >= 12 && lower.contains(target)) {
      return _rejectQuestionReply('reveals target expression', value);
    }
    if (!_questionMatchesPlan(lower, plan)) {
      return _rejectQuestionReply('does not match local question plan', value);
    }
    return true;
  }

  bool _rejectQuestionReply(String reason, String value) {
    debugPrint(
      '[InterviewLlmScheduler] question reply rejected: $reason; '
      'reply="${_shortLogValue(value)}"',
    );
    return false;
  }

  String _normalizeQuestionText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9'\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isGenericQuestionDirective(String normalized) {
    const List<String> blockedPhrases = <String>[
      'give me your direct answer first',
      'give me a direct answer first',
      'direct answer first',
      'answer directly',
      'please answer directly',
      'give me your answer',
      'try again',
      'say it again',
      'repeat after me',
      'use the expression',
      'use this expression',
      'can you answer this part of the interview',
    ];
    return blockedPhrases.any(normalized.contains);
  }

  bool _questionMatchesPlan(
    String normalizedQuestion,
    InterviewQuestionPlan plan,
  ) {
    final String normalizedFallback = _normalizeQuestionText(
      plan.localFallbackQuestion,
    );
    if (normalizedFallback.isNotEmpty &&
        normalizedQuestion == normalizedFallback) {
      return true;
    }
    final Set<String> planTokens = _questionPlanKeywords(plan);
    if (planTokens.isEmpty) {
      return true;
    }
    final Set<String> questionTokens = _questionKeywordTokens(
      normalizedQuestion,
    );
    if (planTokens.intersection(questionTokens).isNotEmpty) {
      return true;
    }
    return _matchesQuestionSynonymGroup(
      planTokens: planTokens,
      normalizedQuestion: normalizedQuestion,
      questionTokens: questionTokens,
    );
  }

  Set<String> _questionPlanKeywords(InterviewQuestionPlan plan) {
    final String source = <String>[
      plan.localFallbackQuestion,
      plan.questionIntent,
      plan.mustAskAbout,
      plan.targetExpression?.useCase ?? '',
      plan.predictedTag,
    ].join(' ');
    return _questionKeywordTokens(_normalizeQuestionText(source));
  }

  Set<String> _questionKeywordTokens(String normalized) {
    const Set<String> stopWords = <String>{
      'about',
      'after',
      'again',
      'answer',
      'around',
      'before',
      'candidate',
      'could',
      'current',
      'exactly',
      'expression',
      'fallback',
      'interview',
      'interviewer',
      'learner',
      'local',
      'natural',
      'question',
      'should',
      'target',
      'their',
      'there',
      'these',
      'thing',
      'things',
      'would',
      'your',
      'yourself',
    };
    return RegExp(r"[a-z][a-z']+")
        .allMatches(normalized)
        .map((RegExpMatch match) => match.group(0) ?? '')
        .map(_stemQuestionKeyword)
        .where((String token) => token.length >= 4)
        .where((String token) => !stopWords.contains(token))
        .toSet();
  }

  String _stemQuestionKeyword(String token) {
    if (token == 'strengths') {
      return 'strength';
    }
    if (token == 'abilities') {
      return 'ability';
    }
    if (token == 'questions') {
      return 'question';
    }
    if (token == 'introducing' || token == 'introduction') {
      return 'introduce';
    }
    if (token == 'experiences') {
      return 'experience';
    }
    if (token == 'examples') {
      return 'example';
    }
    if (token.length > 5 && token.endsWith('ing')) {
      return token.substring(0, token.length - 3);
    }
    if (token.length > 4 && token.endsWith('ed')) {
      return token.substring(0, token.length - 2);
    }
    if (token.length > 4 && token.endsWith('es')) {
      return token.substring(0, token.length - 2);
    }
    if (token.length > 4 && token.endsWith('s')) {
      return token.substring(0, token.length - 1);
    }
    return token;
  }

  bool _matchesQuestionSynonymGroup({
    required Set<String> planTokens,
    required String normalizedQuestion,
    required Set<String> questionTokens,
  }) {
    const List<Set<String>> groups = <Set<String>>[
      <String>{'background', 'experience', 'introduce', 'intro', 'role'},
      <String>{'strength', 'ability', 'good', 'skill'},
      <String>{'weakness', 'improve', 'improving'},
      <String>{'pressure', 'pushback', 'stress', 'challenge'},
      <String>{'project', 'example', 'work'},
      <String>{'company', 'role', 'position', 'job'},
      <String>{'career', 'future', 'plan'},
      <String>{'motivation', 'excite', 'interested'},
      <String>{'question', 'next', 'steps', 'ask'},
      <String>{'greeting', 'greet', 'welcome', 'introduce', 'thank'},
    ];
    for (final Set<String> group in groups) {
      if (!planTokens.any(group.contains)) {
        continue;
      }
      if (questionTokens.any(group.contains)) {
        return true;
      }
      if (group.any(normalizedQuestion.contains)) {
        return true;
      }
    }
    return false;
  }
}
