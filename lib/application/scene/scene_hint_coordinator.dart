import 'dart:convert';

import 'package:speakeasy/features/scenario/scene_runtime_models.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/domain/scene/scene_models.dart';
import 'package:speakeasy/services/api_client.dart';

abstract class SceneHintRemoteApi {
  Future<Map<String, dynamic>> createAiSessionData({
    required String sceneTitle,
    required String sceneGoal,
    String? roleId,
    String? userRole,
    String? relationship,
    required String npcName,
    required String npcRole,
    required String environment,
    required String challenge,
    SceneSpec? sceneSpec,
    SceneBlueprint? sceneBlueprint,
  });

  Future<Map<String, dynamic>> sendSceneMessage(
    String sessionId,
    String text, {
    SceneDraft? draft,
    List<Map<String, dynamic>>? history,
  });
}

class ApiClientSceneHintRemoteApi implements SceneHintRemoteApi {
  const ApiClientSceneHintRemoteApi();

  @override
  Future<Map<String, dynamic>> createAiSessionData({
    required String sceneTitle,
    required String sceneGoal,
    String? roleId,
    String? userRole,
    String? relationship,
    required String npcName,
    required String npcRole,
    required String environment,
    required String challenge,
    SceneSpec? sceneSpec,
    SceneBlueprint? sceneBlueprint,
  }) {
    return ApiClient.createAiSessionData(
      sceneTitle: sceneTitle,
      sceneGoal: sceneGoal,
      roleId: roleId,
      userRole: userRole,
      relationship: relationship,
      npcName: npcName,
      npcRole: npcRole,
      environment: environment,
      challenge: challenge,
      sceneSpec: sceneSpec,
      sceneBlueprint: sceneBlueprint,
    );
  }

  @override
  Future<Map<String, dynamic>> sendSceneMessage(
    String sessionId,
    String text, {
    SceneDraft? draft,
    List<Map<String, dynamic>>? history,
  }) {
    return ApiClient.sendSceneMessage(
      sessionId,
      text,
      draft: draft,
      history: history,
    );
  }
}

class SceneHintRequest {
  const SceneHintRequest({
    required this.draft,
    required this.contract,
    required this.fallbackHint,
    required this.recentTurns,
  });

  final SceneDraft draft;
  final SceneTurnRuntimeContract contract;
  final SceneResponseHint fallbackHint;
  final List<SceneHistoryTurn> recentTurns;
}

class SceneHintCoordinator {
  const SceneHintCoordinator({
    SceneHintRemoteApi remoteApi = const ApiClientSceneHintRemoteApi(),
  }) : _remoteApi = remoteApi;

  final SceneHintRemoteApi _remoteApi;

  Future<SceneResponseHint?> generateHint(SceneHintRequest request) async {
    final SceneSpec hintSpec = _hintSceneSpec();
    final Map<String, dynamic> sessionData = await _remoteApi
        .createAiSessionData(
          sceneTitle: 'English Reply Hint Generator',
          sceneGoal: 'Generate one natural English learner reply hint as JSON.',
          userRole: 'Product assistant',
          relationship: 'Internal helper',
          npcName: 'Hint Coach',
          npcRole: 'English speaking coach',
          environment: 'Return compact JSON only.',
          challenge: 'Return JSON with starter, sample, and keywords.',
          sceneSpec: hintSpec,
        );
    final String sessionId = (sessionData['sessionId'] as String? ?? '').trim();
    if (sessionId.isEmpty) {
      return null;
    }

    final Map<String, dynamic> replyData = await _remoteApi.sendSceneMessage(
      sessionId,
      _buildPrompt(request),
      draft: _draftWithSceneSpec(request.draft, hintSpec),
    );
    final String rawReply = (replyData['reply'] as String? ?? '').trim();
    final Map<String, dynamic>? decoded = _decodeHintJson(rawReply);
    if (decoded == null) {
      return null;
    }

    final String starter = (decoded['starter'] as String? ?? '').trim();
    final String sample = (decoded['sample'] as String? ?? '').trim();
    final List<String> keywords =
        ((decoded['keywords'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic item) => '$item'.trim())
            .where((String item) => item.isNotEmpty)
            .take(4)
            .toList(growable: false);
    if (starter.isEmpty || sample.isEmpty) {
      return null;
    }

    return SceneResponseHint(
      stageLabel: request.fallbackHint.stageLabel,
      questionFocus: request.fallbackHint.questionFocus,
      backgroundFocus: request.fallbackHint.backgroundFocus,
      goalHint: request.fallbackHint.goalHint,
      keywords: keywords.isEmpty ? request.fallbackHint.keywords : keywords,
      starter: starter,
      sampleAnswer: sample,
    );
  }

  SceneSpec _hintSceneSpec() {
    return const SceneSpec(
      category: 'general',
      timeContext: 'This is a helper task that generates a learner reply hint.',
      tone: 'direct',
      pressureLevel: 1,
      interruptionLevel: 1,
      followupDepth: 1,
      warmth: 4,
      responseLength: 'short',
      mustNot: <String>['不要继续扮演场景 NPC', '不要输出解释', '不要输出多段内容', '不要输出 markdown'],
      mustInclude: <String>['只返回 JSON', '字段必须是 starter sample keywords'],
      version: 1,
      plotDesign: '',
      plotBeats: <String>[],
      lastUserIntent: 'Generate a natural English learner reply hint.',
    );
  }

  String _buildPrompt(SceneHintRequest request) {
    final StringBuffer prompt = StringBuffer()
      ..writeln(
        'You generate a learner reply hint for an English speaking practice app.',
      )
      ..writeln('Return JSON only with this exact shape:')
      ..writeln(
        '{"starter":"...","sample":"...","keywords":["...","...","..."]}',
      )
      ..writeln('Rules:')
      ..writeln('- starter must be one short natural reply.')
      ..writeln('- sample must be 1 or 2 short sentences.')
      ..writeln('- keywords must contain 2 to 4 short cues.')
      ..writeln(
        '- Follow the current turn exactly. Do not answer a different question.',
      )
      ..writeln('- If only one detail is being asked, answer only that detail.')
      ..writeln('- Do not repeat already confirmed details unless necessary.')
      ..writeln('- Do not use markdown or any extra text outside JSON.')
      ..writeln()
      ..writeln('Scene:')
      ..writeln('- title: ${request.draft.title}')
      ..writeln('- user role: ${request.draft.userRole}')
      ..writeln('- npc role: ${request.draft.npcRole}')
      ..writeln('- goal: ${request.draft.goal}')
      ..writeln()
      ..writeln('Unified turn contract:')
      ..writeln('- stage: ${request.contract.stageLabel}')
      ..writeln('- learner task en: ${request.contract.learnerTaskEn}')
      ..writeln('- learner goal zh: ${request.contract.learnerGoalZh}')
      ..writeln('- question focus: ${request.contract.questionFocus}')
      ..writeln('- npc summary: ${request.contract.npcTurnSummary}')
      ..writeln('- npc instruction: ${request.contract.npcTurnInstruction}')
      ..writeln(
        '- confirmed facts: ${request.contract.confirmedFacts.isEmpty ? 'none' : request.contract.confirmedFacts.join('; ')}',
      )
      ..writeln(
        '- must ask: ${request.contract.mustAsk.isEmpty ? 'none' : request.contract.mustAsk.join(', ')}',
      )
      ..writeln(
        '- must avoid: ${request.contract.mustAvoid.isEmpty ? 'none' : request.contract.mustAvoid.join(', ')}',
      )
      ..writeln('- target starter: ${request.contract.starter}')
      ..writeln('- target sample: ${request.contract.sampleAnswer}')
      ..writeln()
      ..writeln('Recent conversation:')
      ..writeln(
        request.recentTurns.isEmpty
            ? '- none'
            : request.recentTurns
                  .map(
                    (SceneHistoryTurn turn) =>
                        '- ${turn.role == 'user' ? 'Learner' : request.draft.npcName}: ${turn.text.trim()}',
                  )
                  .join('\n'),
      )
      ..writeln()
      ..writeln('Current local guidance:')
      ..writeln('- coach hint zh: ${request.contract.learnerGoalZh}')
      ..writeln('- npc question: ${request.contract.questionFocus}')
      ..writeln('- target starter: ${request.contract.starter}')
      ..writeln('- target sample: ${request.contract.sampleAnswer}');
    return prompt.toString();
  }

  SceneDraft _draftWithSceneSpec(SceneDraft draft, SceneSpec sceneSpec) {
    return SceneDraft(
      title: draft.title,
      emoji: draft.emoji,
      tags: draft.tags,
      userRole: draft.userRole,
      relationship: draft.relationship,
      goal: draft.goal,
      npcName: draft.npcName,
      npcRole: draft.npcRole,
      environment: draft.environment,
      challenge: draft.challenge,
      plotDesign: draft.plotDesign,
      sceneSpec: sceneSpec,
    );
  }

  Map<String, dynamic>? _decodeHintJson(String rawText) {
    final String trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final List<String> candidates = <String>[
      trimmed,
      ...RegExp(r'```(?:json)?\s*([\s\S]*?)```', multiLine: true)
          .allMatches(trimmed)
          .map((RegExpMatch match) => (match.group(1) ?? '').trim()),
    ].where((String item) => item.isNotEmpty).toList(growable: false);
    final RegExp objectPattern = RegExp(r'\{[\s\S]*\}');
    for (final String candidate in candidates) {
      for (final String attempt in <String>[
        candidate,
        (objectPattern.firstMatch(candidate)?.group(0) ?? '').trim(),
      ]) {
        if (attempt.isEmpty) {
          continue;
        }
        try {
          final dynamic decoded = jsonDecode(attempt);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          if (decoded is Map) {
            return decoded.cast<String, dynamic>();
          }
        } catch (_) {}
      }
    }
    return null;
  }
}
