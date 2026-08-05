import 'package:flutter_test/flutter_test.dart';
import 'package:speakeasy/features/interview/expression_scene_orchestrator.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('orchestrator starts from first unmastered node', () async {
    final ExpressionSceneGraph graph =
        ExpressionSceneGraph.fromInterviewSceneGraph(
          await loadInterviewSceneGraph(),
        );
    const ExpressionSceneOrchestrator orchestrator =
        ExpressionSceneOrchestrator();

    final List<String> planned = orchestrator.plannedNodeIds(
      graph: graph,
      targetLevel: 'A2',
      mode: ExpressionScenePracticeMode.newLesson,
      learnerStates: const <ExpressionSceneLearnerNodeState>[
        ExpressionSceneLearnerNodeState(nodeId: 'A2_01', mastered: true),
      ],
    );

    expect(planned.first, 'A2_02');
    expect(planned, isNot(contains('A2_01')));
  });

  test('orchestrator prioritizes due review nodes', () async {
    final ExpressionSceneGraph graph =
        ExpressionSceneGraph.fromInterviewSceneGraph(
          await loadInterviewSceneGraph(),
        );
    const ExpressionSceneOrchestrator orchestrator =
        ExpressionSceneOrchestrator();

    final List<String> planned = orchestrator.plannedNodeIds(
      graph: graph,
      targetLevel: 'A2',
      mode: ExpressionScenePracticeMode.review,
      learnerStates: const <ExpressionSceneLearnerNodeState>[
        ExpressionSceneLearnerNodeState(nodeId: 'A2_01', mastered: true),
        ExpressionSceneLearnerNodeState(
          nodeId: 'A2_06',
          mastered: true,
          due: true,
        ),
      ],
    );

    expect(planned.first, 'A2_06');
    expect(planned, isNot(contains('A2_01')));
  });

  test(
    'orchestrator prioritizes prepared nodes without skipping them',
    () async {
      final ExpressionSceneGraph graph =
          ExpressionSceneGraph.fromInterviewSceneGraph(
            await loadInterviewSceneGraph(),
          );
      const ExpressionSceneOrchestrator orchestrator =
          ExpressionSceneOrchestrator();

      final List<String> planned = orchestrator.plannedNodeIds(
        graph: graph,
        targetLevel: 'A2',
        mode: ExpressionScenePracticeMode.newLesson,
        learnerStates: const <ExpressionSceneLearnerNodeState>[
          ExpressionSceneLearnerNodeState(nodeId: 'A2_01', mastered: true),
          ExpressionSceneLearnerNodeState(nodeId: 'A2_05', prepared: true),
        ],
      );

      expect(planned.first, 'A2_05');
      expect(planned, contains('A2_05'));
      expect(planned, isNot(contains('A2_01')));
    },
  );

  test(
    'orchestrator prioritizes weak nodes before prepared and new nodes',
    () async {
      final ExpressionSceneGraph graph =
          ExpressionSceneGraph.fromInterviewSceneGraph(
            await loadInterviewSceneGraph(),
          );
      const ExpressionSceneOrchestrator orchestrator =
          ExpressionSceneOrchestrator();

      final List<String> planned = orchestrator.plannedNodeIds(
        graph: graph,
        targetLevel: 'A2',
        mode: ExpressionScenePracticeMode.newLesson,
        learnerStates: const <ExpressionSceneLearnerNodeState>[
          ExpressionSceneLearnerNodeState(nodeId: 'A2_01', mastered: true),
          ExpressionSceneLearnerNodeState(nodeId: 'A2_05', prepared: true),
          ExpressionSceneLearnerNodeState(nodeId: 'A2_06', weak: true),
        ],
      );

      expect(planned.first, 'A2_06');
      expect(planned[1], 'A2_05');
      expect(planned, isNot(contains('A2_01')));
    },
  );

  test('orchestrator opening fallback is natural interview language', () async {
    final ExpressionSceneGraph graph =
        ExpressionSceneGraph.fromInterviewSceneGraph(
          await loadInterviewSceneGraph(),
        );
    final ExpressionSceneNode node = graph.nodeById('A2_01')!;
    const ExpressionSceneOrchestrator orchestrator =
        ExpressionSceneOrchestrator();

    final ExpressionSceneTurnPlan plan = orchestrator.openingPlan(
      node: node,
      mode: ExpressionScenePracticeMode.newLesson,
      openingType: ExpressionSceneOpeningType.coldStart,
    );

    expect(plan.localFallbackQuestion, contains('Welcome'));
    expect(
      plan.localFallbackQuestion,
      isNot(contains('How would you respond')),
    );
    expect(plan.action, 'cold_start_opening');
  });

  test('orchestrator activates delayed reuse within two nodes', () async {
    final ExpressionSceneGraph graph =
        ExpressionSceneGraph.fromInterviewSceneGraph(
          await loadInterviewSceneGraph(),
        );
    final ExpressionSceneNode delayed = graph.nodeById('A2_01')!;
    final ExpressionSceneNode current = graph.nodeById('A2_03')!;
    const ExpressionSceneOrchestrator orchestrator =
        ExpressionSceneOrchestrator();

    expect(
      orchestrator.shouldActivateDelayedReuse(
        currentIndex: 2,
        eligibleIndex: 1,
        delayedNode: delayed,
        currentNode: current,
      ),
      isTrue,
    );
  });

  test(
    'orchestrator navigation separates public map from round plan',
    () async {
      final ExpressionSceneGraph graph =
          ExpressionSceneGraph.fromInterviewSceneGraph(
            await loadInterviewSceneGraph(),
          );
      const ExpressionSceneOrchestrator orchestrator =
          ExpressionSceneOrchestrator();

      final ExpressionSceneNavigationState state = orchestrator.navigationState(
        graph: graph,
        targetLevel: 'A2',
        currentNodeId: 'A2_02',
        roundNodeIds: const <String>['A2_02', 'A2_06'],
        masteredNodeIds: const <String>{'A2_01'},
        preparedNodeIds: const <String>{'A2_05'},
        dueNodeIds: const <String>{'A2_06'},
        weakNodeIds: const <String>{},
      );

      expect(state.publicTotal, 13);
      expect(state.roundTotal, 2);
      expect(state.masteredCount, 1);
      expect(state.nodes.first.inRound, isFalse);
      expect(state.nodes.first.mastered, isTrue);
      expect(
        state.nodes
            .firstWhere(
              (ExpressionSceneNavigationNodeState item) =>
                  item.node.id == 'A2_05',
            )
            .prepared,
        isTrue,
      );
      expect(
        state.nodes
            .firstWhere(
              (ExpressionSceneNavigationNodeState item) =>
                  item.node.id == 'A2_06',
            )
            .inRound,
        isTrue,
      );
    },
  );
}
