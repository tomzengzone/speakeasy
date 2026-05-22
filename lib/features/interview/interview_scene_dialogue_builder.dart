import 'package:speakeasy/features/interview/interview_models.dart';

enum InterviewSceneDialogueRole { interviewer, candidate }

class InterviewSceneDialogueTurn {
  const InterviewSceneDialogueTurn({
    required this.id,
    required this.nodeId,
    required this.role,
    required this.roleLabel,
    required this.stageLabel,
    required this.text,
  });

  final String id;
  final String nodeId;
  final InterviewSceneDialogueRole role;
  final String roleLabel;
  final String stageLabel;
  final String text;
}

List<InterviewSceneDialogueTurn> buildInterviewSceneDialogueTurns(
  InterviewSceneGraph graph,
  String targetLevel,
) {
  final List<InterviewSceneDialogueTurn> turns = <InterviewSceneDialogueTurn>[];
  final List<InterviewExpressionNode> nodes = graph
      .flowNodeIdsForLevel(targetLevel)
      .map(graph.nodeById)
      .whereType<InterviewExpressionNode>()
      .toList(growable: false);
  for (final InterviewExpressionNode node in nodes) {
    final InterviewExpressionLearningMaterial material =
        node.resolvedLearningMaterial;
    final String question = node.question.trim().isNotEmpty
        ? node.question.trim()
        : material.scenePrompt.trim();
    if (question.isNotEmpty) {
      turns.add(
        InterviewSceneDialogueTurn(
          id: '${node.id}-question',
          nodeId: node.id,
          role: InterviewSceneDialogueRole.interviewer,
          roleLabel: 'Emma Carter',
          stageLabel: node.stageLabel,
          text: question,
        ),
      );
    }
    final String answer = material.targetExpression.trim().isNotEmpty
        ? material.targetExpression.trim()
        : node.targetText.trim();
    if (answer.isNotEmpty) {
      turns.add(
        InterviewSceneDialogueTurn(
          id: '${node.id}-answer',
          nodeId: node.id,
          role: InterviewSceneDialogueRole.candidate,
          roleLabel: 'Candidate',
          stageLabel: node.stageLabel,
          text: answer,
        ),
      );
    }
  }
  return List<InterviewSceneDialogueTurn>.unmodifiable(turns);
}
