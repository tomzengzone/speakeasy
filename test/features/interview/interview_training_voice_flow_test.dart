import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';
import 'package:speakeasy/features/interview/interview_training_session_view.dart';

import 'interview_training_test_helpers.dart';

void main() {
  testWidgets('TC-P01-006 spoken micro-action shows voice controls', (
    WidgetTester tester,
  ) async {
    int recordCount = 0;
    int cancelCount = 0;
    int submitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterviewTrainingSessionView(
            session: p01TrainingSession(
              currentMicroAction: InterviewTrainingMicroAction.sayOne,
            ),
            onRecord: () => recordCount += 1,
            onCancelRecording: () => cancelCount += 1,
            onSubmitRecording: () => submitCount += 1,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_training_record_button')),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('interview_training_cancel_recording_button'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('interview_training_submit_recording_button'),
      ),
    );

    expect(recordCount, 1);
    expect(cancelCount, 1);
    expect(submitCount, 1);
  });

  testWidgets('TC-P01-006 listening action offers playback recovery', (
    WidgetTester tester,
  ) async {
    int replayCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterviewTrainingSessionView(
            session: p01TrainingSession(
              currentMicroAction: InterviewTrainingMicroAction.listenOne,
            ),
            onReplay: () => replayCount += 1,
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('interview_training_replay_button')),
    );

    expect(replayCount, 1);
  });
}
