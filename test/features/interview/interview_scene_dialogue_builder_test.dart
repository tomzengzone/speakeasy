import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_scene_dialogue_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds a level dialogue from interview wiki nodes', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph(
      sceneId: defaultInterviewSceneId,
    );

    final List<InterviewSceneDialogueTurn> turns =
        buildInterviewSceneDialogueTurns(graph, 'beginner');

    expect(turns.length, greaterThan(4));
    expect(turns.first.role, InterviewSceneDialogueRole.interviewer);
    expect(turns[1].role, InterviewSceneDialogueRole.candidate);
    expect(turns.first.nodeId, turns[1].nodeId);
    expect(turns.first.text, isNotEmpty);
    expect(turns[1].text, isNotEmpty);
  });

  test(
    'builds onboarding dialogue without relying on hard-coded scene data',
    () async {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph(
        sceneId: 'onboarding_introduction',
      );

      final List<InterviewSceneDialogueTurn> turns =
          buildInterviewSceneDialogueTurns(graph, 'beginner');

      expect(turns.length, greaterThan(4));
      expect(
        turns.where(
          (InterviewSceneDialogueTurn turn) =>
              turn.role == InterviewSceneDialogueRole.candidate,
        ),
        isNotEmpty,
      );
    },
  );
}
