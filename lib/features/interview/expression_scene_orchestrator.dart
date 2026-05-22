import 'package:speakeasy/features/interview/interview_models.dart';

enum ExpressionScenePracticeMode { review, newLesson }

enum ExpressionSceneOpeningType {
  coldStart,
  resumeSession,
  newRoundAfterReview,
  manualJump,
}

class ExpressionSceneGraph {
  const ExpressionSceneGraph({
    required this.id,
    required this.title,
    required this.tracks,
    required this.nodes,
  });

  final String id;
  final String title;
  final List<ExpressionSceneTrack> tracks;
  final List<ExpressionSceneNode> nodes;

  factory ExpressionSceneGraph.fromInterviewSceneGraph(
    InterviewSceneGraph graph,
  ) {
    return ExpressionSceneGraph(
      id: graph.id,
      title: graph.titleCn,
      tracks: graph.tracks
          .map(ExpressionSceneTrack.fromInterviewTrack)
          .toList(growable: false),
      nodes: graph.nodes
          .map(ExpressionSceneNode.fromInterviewNode)
          .toList(growable: false),
    );
  }

  ExpressionSceneNode? nodeById(String id) {
    for (final ExpressionSceneNode node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  List<String> nodeIdsForLevel(String targetLevel) {
    final String normalizedLevel = _normalizeExpressionSceneLevel(targetLevel);
    for (final ExpressionSceneTrack track in tracks) {
      if (track.targetLevel == normalizedLevel || track.id == normalizedLevel) {
        return track.nodeIds
            .where((String id) => nodeById(id) != null)
            .toList(growable: false);
      }
    }
    final String trackId = switch (normalizedLevel) {
      'advanced' => 'L3',
      'intermediate' => 'L2',
      _ => 'L1',
    };
    for (final ExpressionSceneTrack track in tracks) {
      if (track.id == trackId) {
        return track.nodeIds
            .where((String id) => nodeById(id) != null)
            .toList(growable: false);
      }
    }
    return nodes.map((ExpressionSceneNode node) => node.id).toList();
  }
}

class ExpressionSceneTrack {
  const ExpressionSceneTrack({
    required this.id,
    required this.title,
    required this.targetLevel,
    required this.nodeIds,
  });

  final String id;
  final String title;
  final String targetLevel;
  final List<String> nodeIds;

  factory ExpressionSceneTrack.fromInterviewTrack(InterviewSceneTrack track) {
    return ExpressionSceneTrack(
      id: track.id,
      title: track.title,
      targetLevel: track.targetLevel,
      nodeIds: track.nodeIds,
    );
  }
}

class ExpressionSceneNode {
  const ExpressionSceneNode({
    required this.id,
    required this.targetLevel,
    required this.stageLabel,
    required this.tag,
    required this.phaseId,
    required this.intent,
    required this.naturalTiming,
    required this.question,
    required this.followupQuestion,
    required this.targetText,
    required this.dependencies,
    required this.previousIds,
    required this.nextIds,
  });

  final String id;
  final String targetLevel;
  final String stageLabel;
  final String tag;
  final String phaseId;
  final String intent;
  final String naturalTiming;
  final String question;
  final String followupQuestion;
  final String targetText;
  final List<String> dependencies;
  final List<String> previousIds;
  final List<String> nextIds;

  factory ExpressionSceneNode.fromInterviewNode(InterviewExpressionNode node) {
    return ExpressionSceneNode(
      id: node.id,
      targetLevel: node.targetLevel,
      stageLabel: node.stageLabel,
      tag: node.tag,
      phaseId: node.phaseId,
      intent: node.intent,
      naturalTiming: node.naturalTiming,
      question: node.question,
      followupQuestion: node.followupQuestion,
      targetText: node.targetText,
      dependencies: node.dependencies,
      previousIds: node.previousIds,
      nextIds: node.nextIds,
    );
  }
}

class ExpressionSceneLearnerNodeState {
  const ExpressionSceneLearnerNodeState({
    required this.nodeId,
    this.mastered = false,
    this.prepared = false,
    this.due = false,
    this.weak = false,
  });

  final String nodeId;
  final bool mastered;
  final bool prepared;
  final bool due;
  final bool weak;
}

class ExpressionSceneTurnPlan {
  const ExpressionSceneTurnPlan({
    required this.action,
    required this.nodeId,
    required this.questionIntent,
    required this.mustAskAbout,
    required this.localFallbackQuestion,
    required this.practiceFocus,
    required this.predictedTag,
    this.openingType,
  });

  final String action;
  final String nodeId;
  final String questionIntent;
  final String mustAskAbout;
  final String localFallbackQuestion;
  final String practiceFocus;
  final String predictedTag;
  final ExpressionSceneOpeningType? openingType;
}

class ExpressionSceneNavigationNodeState {
  const ExpressionSceneNavigationNodeState({
    required this.node,
    required this.current,
    required this.inRound,
    required this.mastered,
    required this.prepared,
    required this.due,
    required this.weak,
    required this.unlocked,
  });

  final ExpressionSceneNode node;
  final bool current;
  final bool inRound;
  final bool mastered;
  final bool prepared;
  final bool due;
  final bool weak;
  final bool unlocked;
}

class ExpressionSceneNavigationState {
  const ExpressionSceneNavigationState({
    required this.nodes,
    required this.currentPublicIndex,
    required this.currentRoundIndex,
    required this.publicTotal,
    required this.roundTotal,
    required this.masteredCount,
  });

  final List<ExpressionSceneNavigationNodeState> nodes;
  final int currentPublicIndex;
  final int currentRoundIndex;
  final int publicTotal;
  final int roundTotal;
  final int masteredCount;
}

class ExpressionSceneOrchestrator {
  const ExpressionSceneOrchestrator();

  List<String> plannedNodeIds({
    required ExpressionSceneGraph graph,
    required String targetLevel,
    required ExpressionScenePracticeMode mode,
    required Iterable<ExpressionSceneLearnerNodeState> learnerStates,
  }) {
    final List<String> levelNodeIds = graph.nodeIdsForLevel(targetLevel);
    final Map<String, ExpressionSceneLearnerNodeState> statesByNode =
        <String, ExpressionSceneLearnerNodeState>{
          for (final ExpressionSceneLearnerNodeState state in learnerStates)
            if (state.nodeId.isNotEmpty) state.nodeId: state,
        };
    if (mode == ExpressionScenePracticeMode.review) {
      final List<String> dueIds = levelNodeIds
          .where((String id) => statesByNode[id]?.due == true)
          .toList(growable: false);
      if (dueIds.isNotEmpty) {
        return _uniqueIds(dueIds);
      }
      final List<String> masteredIds = levelNodeIds
          .where((String id) => statesByNode[id]?.mastered == true)
          .toList(growable: false);
      if (masteredIds.isNotEmpty) {
        return _uniqueIds(masteredIds.take(5));
      }
    }
    final List<String> unmasteredIds = levelNodeIds
        .where((String id) => statesByNode[id]?.mastered != true)
        .toList(growable: false);
    if (unmasteredIds.isNotEmpty) {
      final List<String> weakIds = unmasteredIds
          .where((String id) => statesByNode[id]?.weak == true)
          .toList(growable: false);
      final List<String> preparedIds = unmasteredIds
          .where(
            (String id) =>
                statesByNode[id]?.prepared == true &&
                statesByNode[id]?.weak != true,
          )
          .toList(growable: false);
      final List<String> newIds = unmasteredIds
          .where(
            (String id) =>
                statesByNode[id]?.prepared != true &&
                statesByNode[id]?.weak != true,
          )
          .toList(growable: false);
      return _uniqueIds(<String>[...weakIds, ...preparedIds, ...newIds]);
    }
    return _uniqueIds(levelNodeIds);
  }

  ExpressionSceneTurnPlan openingPlan({
    required ExpressionSceneNode node,
    required ExpressionScenePracticeMode mode,
    required ExpressionSceneOpeningType openingType,
    bool hasLearnerHistory = false,
    bool hasDueReview = false,
  }) {
    final String action = switch (openingType) {
      ExpressionSceneOpeningType.resumeSession => 'resume_session',
      ExpressionSceneOpeningType.newRoundAfterReview =>
        mode == ExpressionScenePracticeMode.review
            ? 'warm_start_due_review'
            : 'expand_new_expression',
      ExpressionSceneOpeningType.manualJump => 'manual_scene_jump',
      ExpressionSceneOpeningType.coldStart =>
        hasDueReview
            ? 'warm_start_due_review'
            : hasLearnerHistory
            ? 'personalized_warm_start'
            : 'cold_start_opening',
    };
    return ExpressionSceneTurnPlan(
      action: action,
      nodeId: node.id,
      questionIntent: _questionIntentFor(action: action, node: node),
      mustAskAbout: node.naturalTiming.isNotEmpty
          ? node.naturalTiming
          : node.intent,
      localFallbackQuestion: fallbackQuestionFor(
        node,
        openingType: openingType,
      ),
      practiceFocus: mode == ExpressionScenePracticeMode.review
          ? 'spaced repetition review'
          : 'new expression expansion',
      predictedTag: node.tag,
      openingType: openingType,
    );
  }

  String fallbackQuestionFor(
    ExpressionSceneNode node, {
    ExpressionSceneOpeningType openingType =
        ExpressionSceneOpeningType.coldStart,
  }) {
    final String question = _naturalQuestionForNode(node);
    return switch (openingType) {
      ExpressionSceneOpeningType.resumeSession =>
        'Let\'s continue from where we left off. $question',
      ExpressionSceneOpeningType.newRoundAfterReview =>
        'Let\'s start the next round with a focused interview question. $question',
      ExpressionSceneOpeningType.manualJump =>
        'Let\'s take a related interview question next. $question',
      ExpressionSceneOpeningType.coldStart => _coldStartQuestionForNode(node),
    };
  }

  bool shouldActivateDelayedReuse({
    required int currentIndex,
    required int eligibleIndex,
    required ExpressionSceneNode delayedNode,
    required ExpressionSceneNode currentNode,
  }) {
    if (eligibleIndex < 0 || currentIndex < eligibleIndex) {
      return false;
    }
    if (delayedNode.tag.isNotEmpty && delayedNode.tag == currentNode.tag) {
      return true;
    }
    if (delayedNode.phaseId.isNotEmpty &&
        delayedNode.phaseId == currentNode.phaseId) {
      return true;
    }
    return currentIndex >= eligibleIndex + 1;
  }

  ExpressionSceneNavigationState navigationState({
    required ExpressionSceneGraph graph,
    required String targetLevel,
    required String currentNodeId,
    required List<String> roundNodeIds,
    required Set<String> masteredNodeIds,
    Set<String> preparedNodeIds = const <String>{},
    required Set<String> dueNodeIds,
    required Set<String> weakNodeIds,
  }) {
    final Set<String> roundSet = roundNodeIds.toSet();
    final List<ExpressionSceneNavigationNodeState> states = graph
        .nodeIdsForLevel(targetLevel)
        .map(graph.nodeById)
        .whereType<ExpressionSceneNode>()
        .map((ExpressionSceneNode node) {
          final bool inRound = roundSet.contains(node.id);
          final bool mastered = masteredNodeIds.contains(node.id);
          final bool prepared = preparedNodeIds.contains(node.id);
          final bool due = dueNodeIds.contains(node.id);
          final bool weak = weakNodeIds.contains(node.id);
          final int plannedIndex = roundNodeIds.indexOf(node.id);
          final int currentRoundIndex = roundNodeIds.indexOf(currentNodeId);
          final bool plannedAndReached =
              plannedIndex >= 0 &&
              currentRoundIndex >= 0 &&
              plannedIndex <= currentRoundIndex;
          return ExpressionSceneNavigationNodeState(
            node: node,
            current: node.id == currentNodeId,
            inRound: inRound,
            mastered: mastered,
            prepared: prepared,
            due: due,
            weak: weak,
            unlocked: plannedAndReached || mastered || prepared || due || weak,
          );
        })
        .toList(growable: false);
    return ExpressionSceneNavigationState(
      nodes: states,
      currentPublicIndex: states.indexWhere(
        (ExpressionSceneNavigationNodeState state) => state.current,
      ),
      currentRoundIndex: roundNodeIds.indexOf(currentNodeId),
      publicTotal: states.length,
      roundTotal: roundNodeIds.length,
      masteredCount: states
          .where((ExpressionSceneNavigationNodeState state) => state.mastered)
          .length,
    );
  }

  String _coldStartQuestionForNode(ExpressionSceneNode node) {
    final String target = node.targetText.toLowerCase();
    if (target.contains('thank') ||
        node.id.endsWith('_01') ||
        node.stageLabel.contains('开场')) {
      return 'Welcome, thanks for coming in today. Could you start with a quick greeting and a short introduction?';
    }
    return _naturalQuestionForNode(node);
  }

  String _naturalQuestionForNode(ExpressionSceneNode node) {
    final String question = node.question.trim();
    if (question.isEmpty) {
      return node.intent.trim().isEmpty
          ? 'Could you answer this part of the interview?'
          : 'Could you tell me about ${node.intent.trim()}?';
    }
    return question
        .replaceAll(
          'How would you respond at the start of the interview?',
          'Could you start with a quick greeting and a short introduction?',
        )
        .replaceAll(
          'How would you greet the interviewer in a more formal way?',
          'Could you greet the interviewer in a professional way?',
        );
  }

  String _questionIntentFor({
    required String action,
    required ExpressionSceneNode node,
  }) {
    return switch (action) {
      'cold_start_opening' =>
        'start a natural conversation while creating context for the first target expression',
      'resume_session' =>
        'continue the unfinished scene without repeating the previous prompt',
      'warm_start_due_review' =>
        'create a natural context for a due expression without naming it',
      'manual_scene_jump' =>
        'transition naturally to the selected public wiki node',
      'personalized_warm_start' =>
        'start from learner memory while keeping the current target node',
      'expand_new_expression' =>
        'open a context where the target expression would be useful',
      _ =>
        node.intent.isEmpty
            ? 'ask one concise question for ${node.tag}'
            : node.intent,
    };
  }

  List<String> _uniqueIds(Iterable<String> ids) {
    final Set<String> seen = <String>{};
    return ids
        .where((String id) => id.trim().isNotEmpty && seen.add(id))
        .toList(growable: false);
  }
}

String _normalizeExpressionSceneLevel(String value) {
  final String normalized = value.trim();
  return switch (normalized) {
    'L2' || 'intermediate' => 'intermediate',
    'L3' || 'advanced' => 'advanced',
    _ => 'beginner',
  };
}
