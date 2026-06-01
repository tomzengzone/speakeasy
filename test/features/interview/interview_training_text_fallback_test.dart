import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';
import 'package:speakeasy/features/interview/interview_training_session_view.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-007 ASR failure enables text fallback without learner fail', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession();

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: const InterviewTrainingAttemptResult(
        outcome: InterviewTrainingAttemptOutcome.asrFailed,
        completionStatus: InterviewTrainingSignalStatus.unknown,
        taskStatus: InterviewTrainingSignalStatus.unknown,
      ),
    );
    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(next.textFallbackAvailable, isTrue);
    expect(next.failureCount, 0);
    expect(decision.reasonCode, 'asr_failed_text_fallback_available');
  });

  testWidgets('TC-P01-007 text fallback is visible only as fallback path', (
    WidgetTester tester,
  ) async {
    String typed = '';
    int fallbackCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterviewTrainingSessionView(
            session: p01TrainingSession(textFallbackAvailable: true),
            onTextChanged: (String value) => typed = value,
            onTextFallback: () => fallbackCount += 1,
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(
        const ValueKey<String>('interview_training_text_fallback_field'),
      ),
      'I am excited to discuss the role.',
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('interview_training_text_fallback_button'),
      ),
    );

    expect(typed, 'I am excited to discuss the role.');
    expect(fallbackCount, 1);
    expect(find.textContaining('Fallback path'), findsOneWidget);
  });

  testWidgets('TC-P01-007 default voice path hides text fallback field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterviewTrainingSessionView(session: p01TrainingSession()),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('interview_training_text_fallback_field'),
      ),
      findsNothing,
    );
  });
}
