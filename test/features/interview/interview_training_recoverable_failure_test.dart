import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';
import 'package:speakeasy/features/interview/interview_training_session_view.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-011 service failure becomes recoverable state', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();
    final InterviewTrainingSessionState session = p01TrainingSession();

    final InterviewTrainingPlannerDecision decision = agent.decideNext(
      session: session,
      attempt: const InterviewTrainingAttemptResult(
        outcome: InterviewTrainingAttemptOutcome.recoverableFailure,
        completionStatus: InterviewTrainingSignalStatus.unknown,
        taskStatus: InterviewTrainingSignalStatus.unknown,
        recoverableErrorCode: 'tts_failed',
      ),
    );
    final InterviewTrainingSessionState next = agent.applyDecision(
      session: session,
      decision: decision,
    );

    expect(decision.type, InterviewTrainingDecisionType.recoverableError);
    expect(next.status, InterviewTrainingSessionStatus.recoverableError);
    expect(next.lastReasonCode, 'tts_failed');
  });

  testWidgets('TC-P01-011 recoverable state keeps retry and continue exits', (
    WidgetTester tester,
  ) async {
    int retryCount = 0;
    int continueCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterviewTrainingSessionView(
            session: p01TrainingSession(
              status: InterviewTrainingSessionStatus.recoverableError,
              lastFeedback: p01FeedbackCandidate(),
            ).copyWith(lastReasonCode: 'llm_schema_invalid'),
            onRetry: () => retryCount += 1,
            onContinue: () => continueCount += 1,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('interview_training_error_banner')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('interview_training_retry_button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('interview_training_continue_button')),
    );

    expect(retryCount, 1);
    expect(continueCount, 1);
  });
}
