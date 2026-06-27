import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

import 'package:speakeasy/config/app_config.dart';
import 'package:speakeasy/services/storage_service.dart';

import 'support/mvp_e2e_test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'TC-MVP-E2E-008: practice UI and deterministic coach feedback evidence',
    (WidgetTester tester) async {
      await launchAndCompleteOnboarding(tester);

      final Finder practiceButton = find.byKey(
        const ValueKey<String>('home_hero_practice_button'),
      );
      await pumpUntilFound(tester, practiceButton);
      await tapAndPump(tester, practiceButton);

      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('interview_realtime_status_header')),
        timeout: const Duration(seconds: 45),
      );
      expect(
        find.byKey(const ValueKey<String>('interview_voice_idle_controls')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interview_target_progress_band')),
        findsOneWidget,
      );

      final Map<String, dynamic> start =
          await _postJson('/practice/sessions', <String, dynamic>{
            'schema_version': 1,
            'scenario_id': 'job_interview',
            'level_code': 'L1',
            'resume_existing': false,
          });
      final Map<String, dynamic> session = (start['session'] as Map)
          .cast<String, dynamic>();
      final String sessionId = (session['session_id'] as String).trim();
      expect(sessionId, isNotEmpty);

      final Map<String, dynamic> turn = await _postJson(
        '/practice/sessions/$sessionId/turns',
        <String, dynamic>{
          'schema_version': 1,
          'transcript': 'I worked on a project that improved our workflow.',
          'client_state_version': 1,
        },
        extraHeaders: const <String, String>{
          'Idempotency-Key': 'tc-mvp-e2e-008-turn-1',
        },
      );
      final Map<String, dynamic> feedback = (turn['coach_feedback'] as Map)
          .cast<String, dynamic>();
      expect(feedback['summary'], '表达清楚，可以更自然地说明你的贡献。');
      expect(feedback['validation_status'], 'valid');
      expect(feedback['provider_status'], 'success');
      expect(turn['learning_evidence_candidates'], isNotEmpty);

      final Map<String, dynamic> complete = await _postJson(
        '/practice/sessions/$sessionId/complete',
        const <String, dynamic>{},
      );
      final Map<String, dynamic> summary = (complete['summary'] as Map)
          .cast<String, dynamic>();
      expect(summary['learned_items'], isNotEmpty);
      expect(summary['weak_points'], isNotEmpty);
      expect(summary['next_focus'], isNotEmpty);
    },
  );
}

Future<Map<String, dynamic>> _postJson(
  String path,
  Map<String, dynamic> body, {
  Map<String, String> extraHeaders = const <String, String>{},
}) async {
  final String? token = StorageService.instance.getAuthSession()?.token;
  if (token == null || token.isEmpty) {
    fail('Missing auth token for deterministic practice API check');
  }

  final http.Response response = await http
      .post(
        Uri.parse('${AppConfig.apiBaseUrl}$path'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          ...extraHeaders,
        },
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 15));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    fail('POST $path failed: ${response.statusCode} ${response.body}');
  }
  return (jsonDecode(response.body) as Map).cast<String, dynamic>();
}
