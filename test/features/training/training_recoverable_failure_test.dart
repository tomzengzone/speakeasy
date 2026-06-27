import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/training/training_contract.dart';
import 'package:speakeasy/features/training/training_session_view.dart';

import 'training_test_helpers.dart';

void main() {
  testWidgets('TC-P01-011 recoverable state keeps retry and continue exits', (
    WidgetTester tester,
  ) async {
    int retryCount = 0;
    int continueCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainingSessionView(
            session: p01TrainingSession(
              status: TrainingSessionStatus.recoverableError,
              lastFeedback: p01FeedbackCandidate(),
            ).copyWith(lastReasonCode: 'llm_schema_invalid'),
            onRetry: () => retryCount += 1,
            onContinue: () => continueCount += 1,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('training_error_banner')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('training_retry_button')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('training_continue_button')),
    );

    expect(retryCount, 1);
    expect(continueCount, 1);
  });
}
