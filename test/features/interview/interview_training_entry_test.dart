import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_training_agent.dart';
import 'package:speakeasy/features/interview/interview_training_session_view.dart';

import 'interview_training_test_helpers.dart';

void main() {
  test('TC-P01-001 official scenes create or resume training sessions', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();

    final InterviewTrainingSessionStartResult jobStart = agent.startSession(
      userId: 'u1',
      sceneId: 'job_interview',
      levelCode: 'beginner',
    );
    final InterviewTrainingSessionStartResult onboardingStart = agent
        .startSession(
          userId: 'u1',
          sceneId: 'onboarding_introduction',
          levelCode: 'L2',
        );

    expect(jobStart.created, isTrue);
    expect(jobStart.session?.status, InterviewTrainingSessionStatus.ready);
    expect(onboardingStart.created, isTrue);
    expect(onboardingStart.session?.levelCode, 'intermediate');

    final InterviewTrainingSessionStartResult resumed = agent.startSession(
      userId: 'u1',
      sceneId: 'job_interview',
      levelCode: 'beginner',
      existingSession: jobStart.session,
    );

    expect(resumed.resumed, isTrue);
    expect(resumed.session, same(jobStart.session));
  });

  test('TC-P01-001 unsupported scene does not create a session', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();

    final InterviewTrainingSessionStartResult result = agent.startSession(
      userId: 'u1',
      sceneId: 'travel_small_talk',
      levelCode: 'beginner',
    );

    expect(result.created, isFalse);
    expect(result.session, isNull);
    expect(
      result.rejection?.type,
      InterviewTrainingDecisionType.unsupportedScene,
    );
  });

  test('TC-P01-001 blank scene id does not default into official training', () {
    const InterviewTrainingAgent agent = InterviewTrainingAgent();

    final InterviewTrainingSessionStartResult result = agent.startSession(
      userId: 'u1',
      sceneId: '   ',
      levelCode: 'beginner',
    );

    expect(result.created, isFalse);
    expect(result.session, isNull);
    expect(result.rejection?.reasonCode, 'out_of_scope_scene');
  });

  testWidgets('TC-P01-001 unsupported scene renders unavailable state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InterviewTrainingSessionView(
            session: null,
            rejection: const InterviewTrainingPlannerDecision(
              type: InterviewTrainingDecisionType.unsupportedScene,
              nextStatus: InterviewTrainingSessionStatus.unsupportedScene,
              nextStep: InterviewTrainingActionStep.opening,
              nextMicroAction: InterviewTrainingMicroAction.sayOne,
              nextHintLevel: InterviewTrainingHintLevel.none,
              reasonCode: 'out_of_scope_scene',
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('interview_training_unsupported_scene'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('out_of_scope_scene'), findsOneWidget);
  });

  testWidgets('TC-P01-001 ready session renders current step and action', (
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
        const ValueKey<String>('interview_training_action_step_label'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('interview_training_micro_action')),
      findsOneWidget,
    );
    expect(find.text('SayOne'), findsOneWidget);
  });
}
