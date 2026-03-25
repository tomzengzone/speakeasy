import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/utils/error_handler.dart';

class OpenAiAppRepository implements AppRepository {
  OpenAiAppRepository({required this.apiKey});

  final String apiKey;

  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o-mini';

  static String _systemPrompt(SceneDraft draft) {
    return '''You are ${draft.npcName}, a ${draft.npcRole}.
Setting: ${draft.environment}.
Learner goal: ${draft.goal}.
Challenge: ${draft.challenge}.

Rules:
1. Reply ONLY as ${draft.npcName}, stay fully in character.
2. Keep every reply under 40 words.
3. Respond in English only.
4. After your NPC line, on a NEW line, append a single JSON object:
   {"mood":"<1-8 Chinese chars>","coach":"<optional short Chinese tip>","event":"<optional short Chinese scene event>"}
   Omit "coach" or "event" keys if not applicable. Never include eventColor.''';
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
        // Fall through to the direct OpenAI call when the proxy fails.
      }
    }

    final List<Map<String, String>> msgs = <Map<String, String>>[
      <String, String>{'role': 'system', 'content': _systemPrompt(draft)},
      for (final SceneHistoryTurn t in history)
        <String, String>{
          'role': t.role == 'user' ? 'user' : 'assistant',
          'content': t.text,
        },
      <String, String>{'role': 'user', 'content': userText},
    ];

    final http.Response res = await http
        .post(
          Uri.parse(_endpoint),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(<String, dynamic>{
            'model': _model,
            'messages': msgs,
            'temperature': 0.85,
            'max_tokens': 160,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw Exception('OpenAI ${res.statusCode}: ${res.body}');
    }

    final Map<String, dynamic> body =
        jsonDecode(res.body) as Map<String, dynamic>;
    final String raw =
        ((body['choices'] as List<dynamic>).first
                as Map<String, dynamic>)['message']['content']
            as String;

    return _parseReply(raw);
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

    final StringBuffer transcript = StringBuffer();
    for (final SceneHistoryTurn t in history) {
      transcript.writeln(
        '${t.role == 'user' ? 'Learner' : draft.npcName}: ${t.text}',
      );
    }

    final String prompt =
        '''
Analyse this English speaking practice session and respond with ONLY a JSON object.

Scene: ${draft.title}
Goal: ${draft.goal}
Transcript:
$transcript

Respond with exactly this JSON shape (all strings in Chinese, scores 0-100):
{
  "overallScore": <int>,
  "headline": "<12-20 chars, encouraging summary>",
  "summary": "<2 sentences about performance>",
  "clarity": <int>,
  "structure": <int>,
  "adaptability": <int>,
  "coachTip": "<1-2 sentences of concrete advice>",
  "imp1emoji": "<emoji>", "imp1title": "<title>", "imp1detail": "<detail>",
  "imp2emoji": "<emoji>", "imp2title": "<title>", "imp2detail": "<detail>",
  "imp3emoji": "<emoji>", "imp3title": "<title>", "imp3detail": "<detail>"
}
''';

    try {
      final http.Response res = await http
          .post(
            Uri.parse(_endpoint),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode(<String, dynamic>{
              'model': _model,
              'messages': <Map<String, String>>[
                <String, String>{'role': 'user', 'content': prompt},
              ],
              'temperature': 0.4,
              'max_tokens': 400,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode != 200) {
        throw Exception('OpenAI ${res.statusCode}');
      }

      final Map<String, dynamic> body =
          jsonDecode(res.body) as Map<String, dynamic>;
      final String raw =
          ((body['choices'] as List<dynamic>).first
                  as Map<String, dynamic>)['message']['content']
              as String;

      final int start = raw.indexOf('{');
      final int end = raw.lastIndexOf('}');
      if (start == -1 || end <= start) {
        throw const FormatException('no JSON');
      }

      final Map<String, dynamic> j =
          jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;

      return SceneFeedback(
        overallScore: (j['overallScore'] as num).toInt(),
        headline: j['headline'] as String,
        summary: j['summary'] as String,
        metrics: <SceneFeedbackMetric>[
          SceneFeedbackMetric(
            label: '清晰度',
            score: (j['clarity'] as num).toInt(),
            color: const Color(0xFF4A7C6F),
          ),
          SceneFeedbackMetric(
            label: '结构感',
            score: (j['structure'] as num).toInt(),
            color: const Color(0xFF5A6FA8),
          ),
          SceneFeedbackMetric(
            label: '临场应对',
            score: (j['adaptability'] as num).toInt(),
            color: const Color(0xFFA0622A),
          ),
        ],
        coachTip: j['coachTip'] as String,
        improvements: <(String, String, String)>[
          (
            j['imp1emoji'] as String,
            j['imp1title'] as String,
            j['imp1detail'] as String,
          ),
          (
            j['imp2emoji'] as String,
            j['imp2title'] as String,
            j['imp2detail'] as String,
          ),
          (
            j['imp3emoji'] as String,
            j['imp3title'] as String,
            j['imp3detail'] as String,
          ),
        ],
      );
    } catch (_) {
      return const DemoAppRepository().generateSceneFeedback(
        draft: draft,
        history: history,
      );
    }
  }

  static SceneReply _parseReply(String raw) {
    final int jsonStart = raw.lastIndexOf('{');
    final int jsonEnd = raw.lastIndexOf('}');

    String npcText = raw.trim();
    String? mood;
    String? coachHint;
    String? eventLabel;

    if (jsonStart != -1 && jsonEnd > jsonStart) {
      npcText = raw.substring(0, jsonStart).trim();
      final String jsonStr = raw.substring(jsonStart, jsonEnd + 1);
      try {
        final Map<String, dynamic> meta =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        mood = meta['mood'] as String?;
        coachHint = meta['coach'] as String?;
        eventLabel = meta['event'] as String?;
      } catch (_) {
        // Trailing metadata is optional; keep the NPC text when the JSON
        // decoration is malformed.
      }
    }

    Color? eventColor;
    if (eventLabel != null) {
      const List<Color> palette = <Color>[
        Color(0xFF8BA8E0),
        Color(0xFFE8855A),
        Color(0xFF7ACFBD),
        Color(0xFFB08FD8),
      ];
      eventColor = palette[eventLabel.codeUnits.first % palette.length];
    }

    return SceneReply(
      npcText: npcText.isEmpty ? '...' : npcText,
      mood: mood,
      coachHint: coachHint,
      eventLabel: eventLabel,
      eventColor: eventColor,
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
