import 'package:speakeasy/features/interview/interview_coach_schema.dart';

enum InterviewNextRoundMode {
  review,
  newLesson;

  String get label {
    return switch (this) {
      InterviewNextRoundMode.review => '复习模式',
      InterviewNextRoundMode.newLesson => '新课模式',
    };
  }

  String get message {
    return switch (this) {
      InterviewNextRoundMode.review => '下一轮帮你复习已学内容，巩固熟练度',
      InterviewNextRoundMode.newLesson => '下一轮学习新的面试表达，扩充你的话术库',
    };
  }
}

const String defaultInterviewSceneId = 'job_interview';

String _normalizeSceneTargetLevel(dynamic raw) {
  final String value = raw is String ? raw.trim() : '';
  return switch (value) {
    'L1' || 'beginner' => 'beginner',
    'L2' || 'intermediate' => 'intermediate',
    'L3' || 'advanced' => 'advanced',
    'scene_wiki' => 'beginner',
    _ => 'beginner',
  };
}

class InterviewSceneCatalog {
  const InterviewSceneCatalog({
    required this.schemaVersion,
    required this.defaultSceneId,
    required this.scenes,
  });

  final int schemaVersion;
  final String defaultSceneId;
  final List<InterviewSceneCatalogEntry> scenes;

  factory InterviewSceneCatalog.fromJson(Map<String, dynamic> json) {
    return InterviewSceneCatalog(
      schemaVersion: ((json['schemaVersion'] as num?)?.round() ?? 1).toInt(),
      defaultSceneId:
          (json['defaultSceneId'] as String? ?? defaultInterviewSceneId).trim(),
      scenes: List<InterviewSceneCatalogEntry>.unmodifiable(
        _mapList(json['scenes']).map(InterviewSceneCatalogEntry.fromJson),
      ),
    );
  }

  InterviewSceneCatalogEntry? entryById(String sceneId) {
    final String normalized = sceneId.trim().isEmpty
        ? defaultSceneId
        : sceneId.trim();
    for (final InterviewSceneCatalogEntry entry in scenes) {
      if (entry.id == normalized) {
        return entry;
      }
    }
    return null;
  }
}

class InterviewSceneCatalogEntry {
  const InterviewSceneCatalogEntry({
    required this.id,
    required this.titleCn,
    required this.titleEn,
    required this.description,
    required this.tags,
    required this.assetPath,
  });

  final String id;
  final String titleCn;
  final String titleEn;
  final String description;
  final List<String> tags;
  final String assetPath;

  factory InterviewSceneCatalogEntry.fromJson(Map<String, dynamic> json) {
    return InterviewSceneCatalogEntry(
      id: (json['id'] as String? ?? '').trim(),
      titleCn: (json['titleCn'] as String? ?? '').trim(),
      titleEn: (json['titleEn'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      tags: List<String>.unmodifiable(_stringList(json['tags'])),
      assetPath: (json['assetPath'] as String? ?? '').trim(),
    );
  }
}

class InterviewSceneGraph {
  const InterviewSceneGraph({
    required this.schemaVersion,
    required this.id,
    required this.titleCn,
    required this.titleEn,
    required this.description,
    required this.tags,
    required this.phases,
    required this.tracks,
    required this.nodes,
    required this.flow,
    required this.transitionPolicy,
  });

  final int schemaVersion;
  final String id;
  final String titleCn;
  final String titleEn;
  final String description;
  final List<String> tags;
  final List<InterviewScenePhase> phases;
  final List<InterviewSceneTrack> tracks;
  final List<InterviewExpressionNode> nodes;
  final List<String> flow;
  final InterviewTransitionPolicy transitionPolicy;

  factory InterviewSceneGraph.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> meta =
        _map(json['meta']) ?? const <String, dynamic>{};
    return InterviewSceneGraph(
      schemaVersion: ((json['schemaVersion'] as num?)?.round() ?? 1).toInt(),
      id: (meta['id'] as String? ?? 'job_interview').trim(),
      titleCn: (meta['titleCn'] as String? ?? '英语面试').trim(),
      titleEn: (meta['titleEn'] as String? ?? 'Job Interview in English')
          .trim(),
      description: (meta['description'] as String? ?? '').trim(),
      tags: List<String>.unmodifiable(_stringList(meta['tags'])),
      phases: List<InterviewScenePhase>.unmodifiable(
        _mapList(json['phases']).map(InterviewScenePhase.fromJson),
      ),
      tracks: List<InterviewSceneTrack>.unmodifiable(
        _mapList(json['tracks']).map(InterviewSceneTrack.fromJson),
      ),
      nodes: List<InterviewExpressionNode>.unmodifiable(
        _mapList(json['nodes']).map(InterviewExpressionNode.fromJson),
      ),
      flow: List<String>.unmodifiable(_stringList(json['flow'])),
      transitionPolicy: InterviewTransitionPolicy.fromJson(
        _map(json['transitionPolicy']) ?? const <String, dynamic>{},
      ),
    );
  }

  InterviewExpressionNode? nodeById(String id) {
    for (final InterviewExpressionNode node in nodes) {
      if (node.id == id) {
        return node;
      }
    }
    return null;
  }

  List<String> get flowNodeIds {
    if (flow.isNotEmpty) {
      return flow
          .where((String id) => nodeById(id) != null)
          .toList(growable: false);
    }
    return nodes
        .map((InterviewExpressionNode node) => node.id)
        .toList(growable: false);
  }

  List<String> flowNodeIdsForLevel(String targetLevel) {
    final String normalizedLevel = _normalizeSceneTargetLevel(targetLevel);
    final InterviewSceneTrack? matchedTrack = _trackForTargetLevel(
      normalizedLevel,
    );
    if (matchedTrack == null) {
      return flowNodeIds;
    }
    return matchedTrack.nodeIds
        .where((String id) => nodeById(id) != null)
        .toList(growable: false);
  }

  InterviewSceneTrack? _trackForTargetLevel(String targetLevel) {
    for (final InterviewSceneTrack track in tracks) {
      if (track.targetLevel == targetLevel || track.id == targetLevel) {
        return track;
      }
    }
    final String wikiLevel = switch (targetLevel) {
      'intermediate' => 'L2',
      'advanced' => 'L3',
      _ => 'L1',
    };
    for (final InterviewSceneTrack track in tracks) {
      if (track.id == wikiLevel) {
        return track;
      }
    }
    return null;
  }

  InterviewLibrary toLibrary() {
    final List<InterviewCorrection> corrections = <InterviewCorrection>[];
    for (final InterviewExpressionNode node in nodes) {
      for (int index = 0; index < node.errors.length; index += 1) {
        final InterviewErrorPattern error = node.errors[index];
        corrections.add(
          InterviewCorrection(
            id: '${node.id}-error-${index + 1}',
            category: node.intent,
            wrong: error.wrong,
            better: error.better,
            reason: error.reason,
          ),
        );
      }
    }
    return InterviewLibrary(
      expressions: nodes
          .map((InterviewExpressionNode node) => node.toExpression())
          .toList(growable: false),
      corrections: corrections,
    );
  }
}

class InterviewSceneTrack {
  const InterviewSceneTrack({
    required this.id,
    required this.title,
    required this.targetLevel,
    required this.nodeIds,
  });

  final String id;
  final String title;
  final String targetLevel;
  final List<String> nodeIds;

  factory InterviewSceneTrack.fromJson(Map<String, dynamic> json) {
    return InterviewSceneTrack(
      id: (json['id'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      targetLevel: _normalizeSceneTargetLevel(json['targetLevel']),
      nodeIds: List<String>.unmodifiable(_stringList(json['nodeIds'])),
    );
  }
}

class InterviewScenePhase {
  const InterviewScenePhase({
    required this.id,
    required this.title,
    required this.nodeIds,
  });

  final String id;
  final String title;
  final List<String> nodeIds;

  factory InterviewScenePhase.fromJson(Map<String, dynamic> json) {
    return InterviewScenePhase(
      id: (json['id'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      nodeIds: List<String>.unmodifiable(_stringList(json['nodeIds'])),
    );
  }
}

class InterviewTransitionPolicy {
  const InterviewTransitionPolicy({
    this.afterEvery = 2,
    this.messages = const <String>[],
  });

  final int afterEvery;
  final List<String> messages;

  factory InterviewTransitionPolicy.fromJson(Map<String, dynamic> json) {
    return InterviewTransitionPolicy(
      afterEvery: ((json['afterEvery'] as num?)?.round() ?? 2)
          .clamp(1, 10)
          .toInt(),
      messages: List<String>.unmodifiable(_stringList(json['messages'])),
    );
  }
}

class InterviewCapability {
  const InterviewCapability({
    required this.primaryIntent,
    required this.subSkills,
  });

  final String primaryIntent;
  final List<String> subSkills;

  factory InterviewCapability.fromJson(Map<String, dynamic> json) {
    return InterviewCapability(
      primaryIntent: (json['primaryIntent'] as String? ?? '').trim(),
      subSkills: List<String>.unmodifiable(_stringList(json['subSkills'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'primaryIntent': primaryIntent,
      'subSkills': subSkills,
    };
  }
}

class InterviewExpressionNode {
  const InterviewExpressionNode({
    required this.id,
    required this.level,
    required this.targetLevel,
    required this.slot,
    required this.isRescue,
    required this.targetText,
    required this.intent,
    required this.naturalTiming,
    required this.tag,
    required this.stageLabel,
    required this.question,
    required this.followupQuestion,
    required this.meaning,
    required this.usage,
    required this.pragmaticNote,
    required this.dependencies,
    required this.previousIds,
    required this.nextIds,
    required this.phaseId,
    required this.hooks,
    required this.expectedVariants,
    required this.practiceVariants,
    required this.nearMissVariants,
    required this.equivalentIds,
    required this.slots,
    required this.errors,
    required this.coachRubric,
    required this.coachMoves,
    required this.capability,
    required this.communicativeIntent,
    required this.narrative,
    required this.teachingVisibility,
    required this.correctionPolicy,
    required this.delayedFeedback,
    required this.allowedMoves,
    required this.nodeInputs,
    required this.adaptivePolicy,
    required this.speechFocus,
    required this.contextVariants,
    required this.expressionContextAnalysis,
    required this.personalizationCues,
    required this.hintTree,
    required this.learningMaterial,
  });

  final String id;
  final String level;
  final String targetLevel;
  final int slot;
  final bool isRescue;
  final String targetText;
  final String intent;
  final String naturalTiming;
  final String tag;
  final String stageLabel;
  final String question;
  final String followupQuestion;
  final String meaning;
  final String usage;
  final String pragmaticNote;
  final List<String> dependencies;
  final List<String> previousIds;
  final List<String> nextIds;
  final String phaseId;
  final List<InterviewHook> hooks;
  final List<InterviewExpectedVariant> expectedVariants;
  final List<InterviewPracticeVariant> practiceVariants;
  final List<InterviewExpectedVariant> nearMissVariants;
  final List<String> equivalentIds;
  final List<InterviewExpressionSlot> slots;
  final List<InterviewErrorPattern> errors;
  final InterviewCoachRubric coachRubric;
  final InterviewCoachMoves coachMoves;
  final InterviewCapability capability;
  final Map<String, dynamic> communicativeIntent;
  final Map<String, dynamic> narrative;
  final Map<String, dynamic> teachingVisibility;
  final Map<String, dynamic> correctionPolicy;
  final Map<String, dynamic> delayedFeedback;
  final List<String> allowedMoves;
  final InterviewCoachMoveInputs nodeInputs;
  final Map<String, String> adaptivePolicy;
  final InterviewSpeechFocus speechFocus;
  final List<String> contextVariants;
  final Map<String, String> expressionContextAnalysis;
  final List<String> personalizationCues;
  final InterviewHintTree hintTree;
  final InterviewExpressionLearningMaterial learningMaterial;

  factory InterviewExpressionNode.fromJson(Map<String, dynamic> json) {
    final InterviewCoachMoves coachMoves = InterviewCoachMoves.fromJson(
      _map(json['coachMoves']) ?? const <String, dynamic>{},
    );
    final InterviewCoachMoveInputs parsedNodeInputs =
        InterviewCoachMoveInputs.fromJson(
          _map(json['nodeInputs']) ?? const <String, dynamic>{},
        );
    final List<String> parsedAllowedMoves =
        InterviewCoachSchema.safeCoachMoveIds(
          _stringList(json['allowedMoves']),
        );
    return InterviewExpressionNode(
      id: (json['id'] as String? ?? '').trim(),
      level: (json['level'] as String? ?? '').trim(),
      targetLevel: _normalizeSceneTargetLevel(json['targetLevel']),
      slot: ((json['slot'] as num?)?.round() ?? 0).toInt(),
      isRescue: json['isRescue'] == true,
      targetText: (json['targetText'] as String? ?? '').trim(),
      intent: (json['intent'] as String? ?? '').trim(),
      naturalTiming: (json['naturalTiming'] as String? ?? '').trim(),
      tag: (json['tag'] as String? ?? '').trim(),
      stageLabel: (json['stageLabel'] as String? ?? '').trim(),
      question: (json['question'] as String? ?? '').trim(),
      followupQuestion: (json['followupQuestion'] as String? ?? '').trim(),
      meaning: (json['meaning'] as String? ?? '').trim(),
      usage: (json['usage'] as String? ?? '').trim(),
      pragmaticNote: (json['pragmaticNote'] as String? ?? '').trim(),
      dependencies: List<String>.unmodifiable(
        _stringList(json['dependencies']),
      ),
      previousIds: List<String>.unmodifiable(_stringList(json['previousIds'])),
      nextIds: List<String>.unmodifiable(_stringList(json['nextIds'])),
      phaseId: (json['phaseId'] as String? ?? '').trim(),
      hooks: List<InterviewHook>.unmodifiable(
        _mapList(json['hooks']).map(InterviewHook.fromJson),
      ),
      expectedVariants: List<InterviewExpectedVariant>.unmodifiable(
        _mapList(json['expectedVariants'])
            .map(InterviewExpectedVariant.fromJson)
            .where((InterviewExpectedVariant item) => item.text.isNotEmpty),
      ),
      practiceVariants: List<InterviewPracticeVariant>.unmodifiable(
        _mapList(json['practiceVariants'])
            .map(InterviewPracticeVariant.fromJson)
            .where((InterviewPracticeVariant item) => item.text.isNotEmpty),
      ),
      nearMissVariants: List<InterviewExpectedVariant>.unmodifiable(
        _mapList(json['nearMissVariants'])
            .map(InterviewExpectedVariant.fromJson)
            .where((InterviewExpectedVariant item) => item.text.isNotEmpty),
      ),
      equivalentIds: List<String>.unmodifiable(
        _stringList(json['equivalentIds']),
      ),
      slots: List<InterviewExpressionSlot>.unmodifiable(
        _mapList(json['slots']).map(InterviewExpressionSlot.fromJson),
      ),
      errors: List<InterviewErrorPattern>.unmodifiable(
        _mapList(json['errors']).map(InterviewErrorPattern.fromJson),
      ),
      coachRubric: InterviewCoachRubric.fromJson(
        _map(json['coachRubric']) ?? const <String, dynamic>{},
      ),
      coachMoves: coachMoves,
      capability: InterviewCapability.fromJson(
        _map(json['capability']) ?? const <String, dynamic>{},
      ),
      communicativeIntent: Map<String, dynamic>.unmodifiable(
        _map(json['communicativeIntent']) ?? const <String, dynamic>{},
      ),
      narrative: Map<String, dynamic>.unmodifiable(
        _map(json['narrative']) ?? const <String, dynamic>{},
      ),
      teachingVisibility: Map<String, dynamic>.unmodifiable(
        _map(json['teachingVisibility']) ?? const <String, dynamic>{},
      ),
      correctionPolicy: Map<String, dynamic>.unmodifiable(
        _map(json['correctionPolicy']) ?? const <String, dynamic>{},
      ),
      delayedFeedback: Map<String, dynamic>.unmodifiable(
        _map(json['delayedFeedback']) ?? const <String, dynamic>{},
      ),
      allowedMoves: List<String>.unmodifiable(
        parsedAllowedMoves.isNotEmpty
            ? parsedAllowedMoves
            : coachMoves.moveSet
                  .map((InterviewStructuredCoachMove item) => item.id)
                  .where((String value) => value.isNotEmpty)
                  .toSet()
                  .toList(growable: false),
      ),
      nodeInputs: parsedNodeInputs.isEmpty
          ? InterviewCoachMoveInputs.merged(
              coachMoves.moveSet.map(
                (InterviewStructuredCoachMove item) => item.inputs,
              ),
            )
          : parsedNodeInputs,
      adaptivePolicy: Map<String, String>.unmodifiable(
        _validatedStringMap(
          json['adaptivePolicy'],
          InterviewCoachSchema.isAdaptivePolicyAction,
        ),
      ),
      speechFocus: InterviewSpeechFocus.fromJson(
        _map(json['speechFocus']) ?? const <String, dynamic>{},
      ),
      contextVariants: List<String>.unmodifiable(
        _stringList(json['contextVariants']),
      ),
      expressionContextAnalysis: Map<String, String>.unmodifiable(
        _stringMap(json['expressionContextAnalysis']),
      ),
      personalizationCues: List<String>.unmodifiable(
        _stringList(json['personalizationCues']),
      ),
      hintTree: InterviewHintTree.fromJson(
        _map(json['hintTree']) ?? const <String, dynamic>{},
      ),
      learningMaterial: InterviewExpressionLearningMaterial.fromJson(
        _map(json['learningMaterial']) ?? const <String, dynamic>{},
      ),
    );
  }

  InterviewExpression toExpression() {
    return InterviewExpression(
      id: id,
      level: targetLevel,
      levelLabel: level.isEmpty ? 'Scene Wiki' : level,
      section: stageLabel.isEmpty ? phaseId : stageLabel,
      text: targetText,
      tag: tag,
      useCase: intent,
      coachContext: coachContext,
    );
  }

  List<String> get reproducibleTexts {
    return <String>[
      targetText,
      ...expectedVariants.map((InterviewExpectedVariant item) => item.text),
      ...practiceVariants.map((InterviewPracticeVariant item) => item.text),
    ].where((String text) => text.trim().isNotEmpty).toList(growable: false);
  }

  String hintForLevel(String level) {
    return hintTree.forLevel(level);
  }

  String get coachContext {
    final List<String> lines = <String>[];
    lines.addAll(coachRubric.promptLines);
    lines.addAll(coachMoves.promptLines);
    lines.addAll(speechFocus.promptLines);
    if (contextVariants.isNotEmpty) {
      lines.add('realistic contexts: ${contextVariants.take(3).join(' | ')}');
    }
    if (personalizationCues.isNotEmpty) {
      lines.add(
        'personalization cues: ${personalizationCues.take(3).join(' | ')}',
      );
    }
    return lines.join('\n');
  }

  InterviewExpressionLearningMaterial get resolvedLearningMaterial =>
      learningMaterial.isEmpty
      ? InterviewExpressionLearningMaterial.fallbackForNode(this)
      : learningMaterial.resolvedForNode(this);
}

class InterviewExpressionLearningMaterial {
  const InterviewExpressionLearningMaterial({
    required this.intentCn,
    required this.scenePrompt,
    required this.targetExpression,
    required this.nativeNotes,
    required this.chunks,
    required this.commonMistakes,
    required this.speakingTasks,
  });

  final String intentCn;
  final String scenePrompt;
  final String targetExpression;
  final String nativeNotes;
  final List<String> chunks;
  final List<String> commonMistakes;
  final List<InterviewExpressionSpeakingTask> speakingTasks;

  bool get isEmpty =>
      intentCn.isEmpty &&
      scenePrompt.isEmpty &&
      targetExpression.isEmpty &&
      nativeNotes.isEmpty &&
      chunks.isEmpty &&
      commonMistakes.isEmpty &&
      speakingTasks.isEmpty;

  factory InterviewExpressionLearningMaterial.fromJson(
    Map<String, dynamic> json,
  ) {
    return InterviewExpressionLearningMaterial(
      intentCn: (json['intentCn'] as String? ?? '').trim(),
      scenePrompt: (json['scenePrompt'] as String? ?? '').trim(),
      targetExpression: (json['targetExpression'] as String? ?? '').trim(),
      nativeNotes: (json['nativeNotes'] as String? ?? '').trim(),
      chunks: List<String>.unmodifiable(_stringList(json['chunks'])),
      commonMistakes: List<String>.unmodifiable(
        _stringList(json['commonMistakes']),
      ),
      speakingTasks: List<InterviewExpressionSpeakingTask>.unmodifiable(
        _mapList(
          json['speakingTasks'],
        ).map(InterviewExpressionSpeakingTask.fromJson),
      ),
    );
  }

  factory InterviewExpressionLearningMaterial.fallbackForNode(
    InterviewExpressionNode node,
  ) {
    final String intentCn = node.meaning.trim().isNotEmpty
        ? node.meaning.trim()
        : node.intent.trim();
    final String scenePrompt = node.question.trim().isNotEmpty
        ? node.question.trim()
        : node.usage.trim();
    final List<String> chunks = _splitExpressionChunks(node.targetText);
    final String slotPrompt = node.slots.isNotEmpty
        ? '把 ${node.slots.first.name} 换成你的真实信息，比如 ${node.slots.first.example}。'
        : '把其中一个信息换成你的真实经历或岗位。';
    return InterviewExpressionLearningMaterial(
      intentCn: intentCn,
      scenePrompt: scenePrompt,
      targetExpression: node.targetText,
      nativeNotes: node.pragmaticNote,
      chunks: chunks,
      commonMistakes: List<String>.unmodifiable(
        node.errors
            .take(3)
            .map(
              (InterviewErrorPattern item) =>
                  item.reason.isNotEmpty ? item.reason : item.better,
            )
            .where((String value) => value.trim().isNotEmpty),
      ),
      speakingTasks: <InterviewExpressionSpeakingTask>[
        InterviewExpressionSpeakingTask(
          type: 'listen',
          title: '听一句',
          prompt: intentCn.isEmpty ? '先听目标表达的自然说法。' : intentCn,
          targetText: node.targetText,
        ),
        InterviewExpressionSpeakingTask(
          type: 'shadow',
          title: '跟说一次',
          prompt: node.speechFocus.rhythm.isEmpty
              ? '跟着读一遍，先保证完整和顺。'
              : node.speechFocus.rhythm,
          targetText: node.targetText,
        ),
        InterviewExpressionSpeakingTask(
          type: 'slot_replace',
          title: '替换一个槽位',
          prompt: slotPrompt,
          targetText: node.targetText,
          slotName: node.slots.isNotEmpty ? node.slots.first.name : '',
          slotExample: node.slots.isNotEmpty ? node.slots.first.example : '',
        ),
        InterviewExpressionSpeakingTask(
          type: 'scene_transfer',
          title: '去场景里用',
          prompt: scenePrompt.isEmpty ? '进入模拟里自然用出来。' : scenePrompt,
          targetText: node.targetText,
        ),
      ],
    );
  }

  InterviewExpressionLearningMaterial resolvedForNode(
    InterviewExpressionNode node,
  ) {
    final InterviewExpressionLearningMaterial fallback =
        InterviewExpressionLearningMaterial.fallbackForNode(node);
    return InterviewExpressionLearningMaterial(
      intentCn: intentCn.isEmpty ? fallback.intentCn : intentCn,
      scenePrompt: scenePrompt.isEmpty ? fallback.scenePrompt : scenePrompt,
      targetExpression: targetExpression.isEmpty
          ? fallback.targetExpression
          : targetExpression,
      nativeNotes: nativeNotes.isEmpty ? fallback.nativeNotes : nativeNotes,
      chunks: chunks.isEmpty ? fallback.chunks : chunks,
      commonMistakes: commonMistakes.isEmpty
          ? fallback.commonMistakes
          : commonMistakes,
      speakingTasks: speakingTasks.isEmpty
          ? fallback.speakingTasks
          : speakingTasks,
    );
  }

  InterviewExpressionSpeakingTask taskFor(String type) {
    for (final InterviewExpressionSpeakingTask task in speakingTasks) {
      if (task.type == type) {
        return task;
      }
    }
    return const InterviewExpressionSpeakingTask(
      type: '',
      title: '',
      prompt: '',
      targetText: '',
    );
  }
}

class InterviewExpressionSpeakingTask {
  const InterviewExpressionSpeakingTask({
    required this.type,
    required this.title,
    required this.prompt,
    required this.targetText,
    this.slotName = '',
    this.slotExample = '',
  });

  final String type;
  final String title;
  final String prompt;
  final String targetText;
  final String slotName;
  final String slotExample;

  factory InterviewExpressionSpeakingTask.fromJson(Map<String, dynamic> json) {
    return InterviewExpressionSpeakingTask(
      type: (json['type'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      prompt: (json['prompt'] as String? ?? '').trim(),
      targetText: (json['targetText'] as String? ?? '').trim(),
      slotName: (json['slotName'] as String? ?? '').trim(),
      slotExample: (json['slotExample'] as String? ?? '').trim(),
    );
  }
}

class InterviewExpressionSlot {
  const InterviewExpressionSlot({required this.name, required this.example});

  final String name;
  final String example;

  factory InterviewExpressionSlot.fromJson(Map<String, dynamic> json) {
    return InterviewExpressionSlot(
      name: (json['name'] as String? ?? '').trim(),
      example: (json['example'] as String? ?? '').trim(),
    );
  }
}

class InterviewHook {
  const InterviewHook({
    required this.id,
    required this.type,
    required this.text,
  });

  final String id;
  final String type;
  final String text;

  factory InterviewHook.fromJson(Map<String, dynamic> json) {
    return InterviewHook(
      id: (json['id'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
    );
  }
}

class InterviewExpectedVariant {
  const InterviewExpectedVariant({required this.text, required this.kind});

  final String text;
  final String kind;

  factory InterviewExpectedVariant.fromJson(Map<String, dynamic> json) {
    return InterviewExpectedVariant(
      text: (json['text'] as String? ?? '').trim(),
      kind: (json['kind'] as String? ?? 'variant').trim(),
    );
  }
}

class InterviewPracticeVariant {
  const InterviewPracticeVariant({
    required this.id,
    required this.text,
    required this.meaning,
    required this.type,
    required this.priority,
    required this.contextAnalysis,
  });

  final String id;
  final String text;
  final String meaning;
  final String type;
  final int priority;
  final Map<String, String> contextAnalysis;

  factory InterviewPracticeVariant.fromJson(Map<String, dynamic> json) {
    final String type =
        (json['type'] as String? ?? json['kind'] as String? ?? '').trim();
    return InterviewPracticeVariant(
      id: (json['id'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      meaning:
          (json['meaning'] as String? ?? json['translation'] as String? ?? '')
              .trim(),
      type: type.isEmpty ? 'variant' : type,
      priority: ((json['priority'] as num?)?.round() ?? 1000).toInt(),
      contextAnalysis: Map<String, String>.unmodifiable(
        _stringMap(json['contextAnalysis']),
      ),
    );
  }
}

class InterviewErrorPattern {
  const InterviewErrorPattern({
    required this.wrong,
    required this.better,
    required this.reason,
  });

  final String wrong;
  final String better;
  final String reason;

  factory InterviewErrorPattern.fromJson(Map<String, dynamic> json) {
    return InterviewErrorPattern(
      wrong: (json['wrong'] as String? ?? '').trim(),
      better: (json['better'] as String? ?? '').trim(),
      reason: (json['reason'] as String? ?? '').trim(),
    );
  }
}

class InterviewCoachRubric {
  const InterviewCoachRubric({
    this.mustCover = const <String>[],
    this.masterySignals = const <String>[],
    this.nearMissSignals = const <String>[],
    this.missSignals = const <String>[],
  });

  final List<String> mustCover;
  final List<String> masterySignals;
  final List<String> nearMissSignals;
  final List<String> missSignals;

  factory InterviewCoachRubric.fromJson(Map<String, dynamic> json) {
    return InterviewCoachRubric(
      mustCover: List<String>.unmodifiable(_stringList(json['mustCover'])),
      masterySignals: List<String>.unmodifiable(
        _stringList(json['masterySignals']),
      ),
      nearMissSignals: List<String>.unmodifiable(
        _stringList(json['nearMissSignals']),
      ),
      missSignals: List<String>.unmodifiable(_stringList(json['missSignals'])),
    );
  }

  List<String> get promptLines {
    final List<String> lines = <String>[];
    if (mustCover.isNotEmpty) {
      lines.add('rubric must cover: ${mustCover.take(4).join(' | ')}');
    }
    if (masterySignals.isNotEmpty) {
      lines.add('mastery signals: ${masterySignals.take(3).join(' | ')}');
    }
    if (nearMissSignals.isNotEmpty) {
      lines.add('near-miss signals: ${nearMissSignals.take(3).join(' | ')}');
    }
    if (missSignals.isNotEmpty) {
      lines.add('miss signals: ${missSignals.take(3).join(' | ')}');
    }
    return lines;
  }
}

class InterviewCoachMoves {
  const InterviewCoachMoves({
    this.schemaVersion = 0,
    this.moveSet = const <InterviewStructuredCoachMove>[],
    this.masteryRubric = const InterviewStructuredMasteryRubric(),
    this.transferTasks = const <InterviewCoachTransferTask>[],
    this.firstResponse = '',
    this.ifTooShort = '',
    this.ifGrammarIssue = '',
    this.ifUnnatural = '',
    this.ifStuck = '',
    this.retryInstruction = '',
  });

  final int schemaVersion;
  final List<InterviewStructuredCoachMove> moveSet;
  final InterviewStructuredMasteryRubric masteryRubric;
  final List<InterviewCoachTransferTask> transferTasks;
  final String firstResponse;
  final String ifTooShort;
  final String ifGrammarIssue;
  final String ifUnnatural;
  final String ifStuck;
  final String retryInstruction;

  factory InterviewCoachMoves.fromJson(Map<String, dynamic> json) {
    return InterviewCoachMoves(
      schemaVersion: ((json['schemaVersion'] as num?)?.round() ?? 0)
          .clamp(0, 100)
          .toInt(),
      moveSet: List<InterviewStructuredCoachMove>.unmodifiable(
        _mapList(json['moveSet'])
            .map(InterviewStructuredCoachMove.fromJson)
            .where((InterviewStructuredCoachMove item) => item.id.isNotEmpty),
      ),
      masteryRubric: InterviewStructuredMasteryRubric.fromJson(
        _map(json['masteryRubric']) ?? const <String, dynamic>{},
      ),
      transferTasks: List<InterviewCoachTransferTask>.unmodifiable(
        _mapList(json['transferTasks'])
            .map(InterviewCoachTransferTask.fromJson)
            .where((InterviewCoachTransferTask item) => item.id.isNotEmpty),
      ),
      firstResponse: (json['firstResponse'] as String? ?? '').trim(),
      ifTooShort: (json['ifTooShort'] as String? ?? '').trim(),
      ifGrammarIssue: (json['ifGrammarIssue'] as String? ?? '').trim(),
      ifUnnatural: (json['ifUnnatural'] as String? ?? '').trim(),
      ifStuck: (json['ifStuck'] as String? ?? '').trim(),
      retryInstruction: (json['retryInstruction'] as String? ?? '').trim(),
    );
  }

  List<String> get promptLines {
    return <String>[
      if (firstResponse.isNotEmpty) 'coach first response: $firstResponse',
      if (ifTooShort.isNotEmpty) 'if learner is too short: $ifTooShort',
      if (ifGrammarIssue.isNotEmpty) 'if grammar issue: $ifGrammarIssue',
      if (ifUnnatural.isNotEmpty) 'if unnatural: $ifUnnatural',
      if (ifStuck.isNotEmpty) 'if stuck: $ifStuck',
      if (retryInstruction.isNotEmpty) 'retry instruction: $retryInstruction',
    ];
  }

  Map<String, dynamic> toRuntimeJson({
    required String targetText,
    required InterviewCapability capability,
    required Map<String, dynamic> communicativeIntent,
    required Map<String, dynamic> narrative,
    required Map<String, dynamic> teachingVisibility,
    required Map<String, dynamic> correctionPolicy,
    required Map<String, dynamic> delayedFeedback,
    required List<String> allowedMoves,
    required InterviewCoachMoveInputs nodeInputs,
    required Map<String, String> adaptivePolicy,
    required List<InterviewExpectedVariant> expectedVariants,
    required InterviewCoachRubric fallbackRubric,
    required InterviewSpeechFocus speechFocus,
    required List<String> contextVariants,
  }) {
    final InterviewStructuredMasteryRubric resolvedRubric =
        masteryRubric.isEmpty
        ? InterviewStructuredMasteryRubric.fromFallback(
            targetText: targetText,
            expectedVariants: expectedVariants,
            rubric: fallbackRubric,
          )
        : masteryRubric.withAcceptedVariants(<String>[
            targetText,
            ...expectedVariants.map(
              (InterviewExpectedVariant item) => item.text,
            ),
          ]);
    return <String, dynamic>{
      'schemaVersion': schemaVersion == 0
          ? InterviewCoachSchema.schemaVersion
          : schemaVersion,
      'capability': capability.toJson(),
      'communicativeIntent': communicativeIntent,
      'narrative': narrative,
      'teachingVisibility': teachingVisibility,
      'correctionPolicy': correctionPolicy,
      'delayedFeedback': delayedFeedback,
      'allowedMoves': (allowedMoves.isNotEmpty
          ? InterviewCoachSchema.safeCoachMoveIds(allowedMoves)
          : moveSet
                .map((InterviewStructuredCoachMove item) => item.id)
                .where((String value) => value.isNotEmpty)
                .toSet()
                .toList(growable: false)),
      'nodeInputs': nodeInputs.toJson(),
      'adaptivePolicy': adaptivePolicy,
      'masteryRubric': resolvedRubric.toJson(),
      'speechFocus': speechFocus.toJson(),
      'contextVariants': contextVariants.take(2).toList(growable: false),
      if (transferTasks.isNotEmpty)
        'transferTaskHints': transferTasks
            .take(2)
            .map(
              (InterviewCoachTransferTask item) => <String, dynamic>{
                'id': item.id,
                'when': item.when,
              },
            )
            .toList(growable: false),
    };
  }
}

class InterviewStructuredCoachMove {
  const InterviewStructuredCoachMove({
    required this.id,
    required this.when,
    required this.priority,
    required this.stage,
    required this.goal,
    required this.inputs,
    required this.plannerPolicy,
    required this.generatorGuidance,
  });

  final String id;
  final List<String> when;
  final int priority;
  final String stage;
  final String goal;
  final InterviewCoachMoveInputs inputs;
  final InterviewCoachPlannerPolicy plannerPolicy;
  final InterviewCoachGeneratorGuidance generatorGuidance;

  factory InterviewStructuredCoachMove.fromJson(Map<String, dynamic> json) {
    return InterviewStructuredCoachMove(
      id: InterviewCoachSchema.safeCoachMoveId(
        (json['id'] as String? ?? '').trim(),
      ),
      when: InterviewCoachSchema.safeTriggerCodes(_stringList(json['when'])),
      priority: ((json['priority'] as num?)?.round() ?? 0)
          .clamp(0, 1000)
          .toInt(),
      stage: InterviewCoachSchema.safeTeachingStage(
        (json['stage'] as String? ?? '').trim(),
        fallback: TeachingStage.scaffold,
      ),
      goal: (json['goal'] as String? ?? '').trim(),
      inputs: InterviewCoachMoveInputs.fromJson(
        _map(json['inputs']) ?? const <String, dynamic>{},
      ),
      plannerPolicy: InterviewCoachPlannerPolicy.fromJson(
        _map(json['plannerPolicy']) ?? const <String, dynamic>{},
      ),
      generatorGuidance: InterviewCoachGeneratorGuidance.fromJson(
        _map(json['generatorGuidance']) ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'when': when,
      'priority': priority,
      'stage': stage,
      if (goal.isNotEmpty) 'goal': goal,
      'inputs': inputs.toJson(),
      'plannerPolicy': plannerPolicy.toJson(),
      'generatorGuidance': generatorGuidance.toJson(),
    };
  }
}

class InterviewCoachMoveInputs {
  const InterviewCoachMoveInputs({
    this.frames = const <String>[],
    this.choices = const <String>[],
    this.chunks = const <String>[],
    this.contrast = const <String>[],
    this.naturalnessTips = const <String>[],
    this.pronunciationTips = const <String>[],
    this.transferPrompts = const <String>[],
  });

  final List<String> frames;
  final List<String> choices;
  final List<String> chunks;
  final List<String> contrast;
  final List<String> naturalnessTips;
  final List<String> pronunciationTips;
  final List<String> transferPrompts;

  factory InterviewCoachMoveInputs.fromJson(Map<String, dynamic> json) {
    return InterviewCoachMoveInputs(
      frames: List<String>.unmodifiable(_stringList(json['frames'])),
      choices: List<String>.unmodifiable(_stringList(json['choices'])),
      chunks: List<String>.unmodifiable(_stringList(json['chunks'])),
      contrast: List<String>.unmodifiable(_stringList(json['contrast'])),
      naturalnessTips: List<String>.unmodifiable(
        _stringList(json['naturalnessTips']),
      ),
      pronunciationTips: List<String>.unmodifiable(
        _stringList(json['pronunciationTips']),
      ),
      transferPrompts: List<String>.unmodifiable(
        _stringList(json['transferPrompts']),
      ),
    );
  }

  factory InterviewCoachMoveInputs.merged(
    Iterable<InterviewCoachMoveInputs> items,
  ) {
    final Set<String> frames = <String>{};
    final Set<String> choices = <String>{};
    final Set<String> chunks = <String>{};
    final Set<String> contrast = <String>{};
    final Set<String> naturalnessTips = <String>{};
    final Set<String> pronunciationTips = <String>{};
    final Set<String> transferPrompts = <String>{};
    for (final InterviewCoachMoveInputs item in items) {
      frames.addAll(item.frames);
      choices.addAll(item.choices);
      chunks.addAll(item.chunks);
      contrast.addAll(item.contrast);
      naturalnessTips.addAll(item.naturalnessTips);
      pronunciationTips.addAll(item.pronunciationTips);
      transferPrompts.addAll(item.transferPrompts);
    }
    return InterviewCoachMoveInputs(
      frames: frames.take(4).toList(growable: false),
      choices: choices.take(4).toList(growable: false),
      chunks: chunks.take(5).toList(growable: false),
      contrast: contrast.take(2).toList(growable: false),
      naturalnessTips: naturalnessTips.take(3).toList(growable: false),
      pronunciationTips: pronunciationTips.take(3).toList(growable: false),
      transferPrompts: transferPrompts.take(3).toList(growable: false),
    );
  }

  bool get isEmpty =>
      frames.isEmpty &&
      choices.isEmpty &&
      chunks.isEmpty &&
      contrast.isEmpty &&
      naturalnessTips.isEmpty &&
      pronunciationTips.isEmpty &&
      transferPrompts.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (frames.isNotEmpty) 'frames': frames,
      if (choices.isNotEmpty) 'choices': choices,
      if (chunks.isNotEmpty) 'chunks': chunks,
      if (contrast.isNotEmpty) 'contrast': contrast,
      if (naturalnessTips.isNotEmpty) 'naturalnessTips': naturalnessTips,
      if (pronunciationTips.isNotEmpty) 'pronunciationTips': pronunciationTips,
      if (transferPrompts.isNotEmpty) 'transferPrompts': transferPrompts,
    };
  }
}

class InterviewCoachPlannerPolicy {
  const InterviewCoachPlannerPolicy({
    this.maxAttempts = 1,
    this.afterSuccess = CoachNextAction.askFollowup,
    this.afterFail = CoachNextAction.scaffold,
  });

  final int maxAttempts;
  final String afterSuccess;
  final String afterFail;

  factory InterviewCoachPlannerPolicy.fromJson(Map<String, dynamic> json) {
    return InterviewCoachPlannerPolicy(
      maxAttempts: ((json['maxAttempts'] as num?)?.round() ?? 1)
          .clamp(1, 10)
          .toInt(),
      afterSuccess: InterviewCoachSchema.safeNextAction(
        (json['afterSuccess'] as String? ?? '').trim(),
        fallback: CoachNextAction.askFollowup,
      ),
      afterFail: InterviewCoachSchema.safeNextAction(
        (json['afterFail'] as String? ?? '').trim(),
        fallback: CoachNextAction.scaffold,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'maxAttempts': maxAttempts,
      'afterSuccess': afterSuccess,
      'afterFail': afterFail,
    };
  }
}

class InterviewCoachGeneratorGuidance {
  const InterviewCoachGeneratorGuidance({
    this.coachTone = '',
    this.maxChineseChars = 60,
    this.separateFormalQuestion = true,
  });

  final String coachTone;
  final int maxChineseChars;
  final bool separateFormalQuestion;

  factory InterviewCoachGeneratorGuidance.fromJson(Map<String, dynamic> json) {
    return InterviewCoachGeneratorGuidance(
      coachTone: (json['coachTone'] as String? ?? '').trim(),
      maxChineseChars: ((json['maxChineseChars'] as num?)?.round() ?? 60)
          .clamp(20, 160)
          .toInt(),
      separateFormalQuestion: json['separateFormalQuestion'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (coachTone.isNotEmpty) 'coachTone': coachTone,
      'maxChineseChars': maxChineseChars,
      'separateFormalQuestion': separateFormalQuestion,
    };
  }
}

class InterviewMasterySignal {
  const InterviewMasterySignal({
    required this.id,
    this.match = 'semantic_or_example',
    this.weight = 1,
    this.examples = const <String>[],
    this.scoring = '',
  });

  final String id;
  final String match;
  final num weight;
  final List<String> examples;
  final String scoring;

  factory InterviewMasterySignal.fromJson(Map<String, dynamic> json) {
    return InterviewMasterySignal(
      id: (json['id'] as String? ?? '').trim(),
      match: (json['match'] as String? ?? 'semantic_or_example').trim(),
      weight: (json['weight'] as num?) ?? 1,
      examples: List<String>.unmodifiable(_stringList(json['examples'])),
      scoring: (json['scoring'] as String? ?? '').trim(),
    );
  }

  factory InterviewMasterySignal.fromLegacyText(String text, int index) {
    final String normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final int endIndex = normalized.length > 48 ? 48 : normalized.length;
    return InterviewMasterySignal(
      id: normalized.isNotEmpty
          ? normalized.substring(0, endIndex)
          : 'legacy_signal_$index',
      examples: <String>[text],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'match': match,
      'weight': weight,
      if (examples.isNotEmpty) 'examples': examples,
      if (scoring.isNotEmpty) 'scoring': scoring,
    };
  }
}

class InterviewStructuredMasteryRubric {
  const InterviewStructuredMasteryRubric({
    this.requiredSignals = const <InterviewMasterySignal>[],
    this.acceptedVariants = const <String>[],
    this.nearMissSignals = const <InterviewMasterySignal>[],
    this.missSignals = const <InterviewMasterySignal>[],
    this.nearMissScoring = const <String, dynamic>{},
  });

  final List<InterviewMasterySignal> requiredSignals;
  final List<String> acceptedVariants;
  final List<InterviewMasterySignal> nearMissSignals;
  final List<InterviewMasterySignal> missSignals;
  final Map<String, dynamic> nearMissScoring;

  bool get isEmpty =>
      requiredSignals.isEmpty &&
      acceptedVariants.isEmpty &&
      nearMissSignals.isEmpty &&
      missSignals.isEmpty;

  factory InterviewStructuredMasteryRubric.fromJson(Map<String, dynamic> json) {
    return InterviewStructuredMasteryRubric(
      requiredSignals: List<InterviewMasterySignal>.unmodifiable(
        _masterySignalList(json['requiredSignals']),
      ),
      acceptedVariants: List<String>.unmodifiable(
        _stringList(json['acceptedVariants']),
      ),
      nearMissSignals: List<InterviewMasterySignal>.unmodifiable(
        _masterySignalList(json['nearMissSignals']),
      ),
      missSignals: List<InterviewMasterySignal>.unmodifiable(
        _masterySignalList(json['missSignals']),
      ),
      nearMissScoring: Map<String, dynamic>.unmodifiable(
        _map(json['nearMissScoring']) ?? const <String, dynamic>{},
      ),
    );
  }

  factory InterviewStructuredMasteryRubric.fromFallback({
    required String targetText,
    required List<InterviewExpectedVariant> expectedVariants,
    required InterviewCoachRubric rubric,
  }) {
    return InterviewStructuredMasteryRubric(
      requiredSignals: <InterviewMasterySignal>[
        for (int index = 0; index < rubric.mustCover.length; index += 1)
          InterviewMasterySignal.fromLegacyText(rubric.mustCover[index], index),
      ],
      acceptedVariants: <String>{
        targetText,
        ...expectedVariants.map((InterviewExpectedVariant item) => item.text),
      }.where((String value) => value.trim().isNotEmpty).toList(),
      nearMissSignals: <InterviewMasterySignal>[
        for (int index = 0; index < rubric.nearMissSignals.length; index += 1)
          InterviewMasterySignal.fromLegacyText(
            rubric.nearMissSignals[index],
            index,
          ),
      ],
      missSignals: <InterviewMasterySignal>[
        for (int index = 0; index < rubric.missSignals.length; index += 1)
          InterviewMasterySignal.fromLegacyText(
            rubric.missSignals[index],
            index,
          ),
      ],
    );
  }

  InterviewStructuredMasteryRubric withAcceptedVariants(
    Iterable<String> extraVariants,
  ) {
    return InterviewStructuredMasteryRubric(
      requiredSignals: requiredSignals,
      acceptedVariants: <String>{
        ...acceptedVariants,
        ...extraVariants,
      }.where((String value) => value.trim().isNotEmpty).toList(),
      nearMissSignals: nearMissSignals,
      missSignals: missSignals,
      nearMissScoring: nearMissScoring,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requiredSignals': requiredSignals
          .map((InterviewMasterySignal item) => item.toJson())
          .toList(growable: false),
      'acceptedVariants': acceptedVariants,
      'nearMissSignals': nearMissSignals
          .map((InterviewMasterySignal item) => item.toJson())
          .toList(growable: false),
      'missSignals': missSignals
          .map((InterviewMasterySignal item) => item.toJson())
          .toList(growable: false),
      if (nearMissScoring.isNotEmpty) 'nearMissScoring': nearMissScoring,
    };
  }
}

class InterviewCoachTransferTask {
  const InterviewCoachTransferTask({
    required this.id,
    required this.when,
    required this.prompt,
  });

  final String id;
  final List<String> when;
  final String prompt;

  factory InterviewCoachTransferTask.fromJson(Map<String, dynamic> json) {
    return InterviewCoachTransferTask(
      id: (json['id'] as String? ?? '').trim(),
      when: InterviewCoachSchema.safeTriggerCodes(_stringList(json['when'])),
      prompt: (json['prompt'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'when': when, 'prompt': prompt};
  }
}

class InterviewSpeechFocus {
  const InterviewSpeechFocus({
    this.stress = const <String>[],
    this.pronunciation = const <String>[],
    this.rhythm = '',
    this.tone = '',
  });

  final List<String> stress;
  final List<String> pronunciation;
  final String rhythm;
  final String tone;

  factory InterviewSpeechFocus.fromJson(Map<String, dynamic> json) {
    return InterviewSpeechFocus(
      stress: List<String>.unmodifiable(_stringList(json['stress'])),
      pronunciation: List<String>.unmodifiable(
        _stringList(json['pronunciation']),
      ),
      rhythm: (json['rhythm'] as String? ?? '').trim(),
      tone: (json['tone'] as String? ?? '').trim(),
    );
  }

  List<String> get promptLines {
    return <String>[
      if (stress.isNotEmpty) 'speech stress: ${stress.take(4).join(' | ')}',
      if (pronunciation.isNotEmpty)
        'pronunciation focus: ${pronunciation.take(4).join(' | ')}',
      if (rhythm.isNotEmpty) 'speech rhythm: $rhythm',
      if (tone.isNotEmpty) 'spoken tone: $tone',
    ];
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (stress.isNotEmpty) 'stress': stress,
      if (pronunciation.isNotEmpty) 'pronunciation': pronunciation,
      if (rhythm.isNotEmpty) 'rhythm': rhythm,
      if (tone.isNotEmpty) 'tone': tone,
    };
  }
}

class InterviewHintTree {
  const InterviewHintTree({
    this.l1 = '',
    this.l2 = '',
    this.l3 = '',
    this.l4 = '',
  });

  final String l1;
  final String l2;
  final String l3;
  final String l4;

  factory InterviewHintTree.fromJson(Map<String, dynamic> json) {
    return InterviewHintTree(
      l1: (json['L1'] as String? ?? '').trim(),
      l2: (json['L2'] as String? ?? '').trim(),
      l3: (json['L3'] as String? ?? '').trim(),
      l4: (json['L4'] as String? ?? '').trim(),
    );
  }

  String forLevel(String level) {
    return switch (level) {
      'L1' => l1,
      'L2' => l2.isNotEmpty ? l2 : l1,
      'L3' =>
        l3.isNotEmpty
            ? l3
            : l2.isNotEmpty
            ? l2
            : l1,
      'L4' =>
        l4.isNotEmpty
            ? l4
            : l3.isNotEmpty
            ? l3
            : l2.isNotEmpty
            ? l2
            : l1,
      _ => l1,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (l1.isNotEmpty) 'L1': l1,
      if (l2.isNotEmpty) 'L2': l2,
      if (l3.isNotEmpty) 'L3': l3,
      if (l4.isNotEmpty) 'L4': l4,
    };
  }
}

class InterviewExpression {
  const InterviewExpression({
    required this.id,
    required this.level,
    required this.levelLabel,
    required this.section,
    required this.text,
    required this.tag,
    required this.useCase,
    this.coachContext = '',
  });

  final String id;
  final String level;
  final String levelLabel;
  final String section;
  final String text;
  final String tag;
  final String useCase;
  final String coachContext;

  factory InterviewExpression.fromJson(Map<String, dynamic> json) {
    return InterviewExpression(
      id: (json['id'] as String? ?? '').trim(),
      level: (json['level'] as String? ?? '').trim(),
      levelLabel: (json['level_label'] as String? ?? '').trim(),
      section: (json['section'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      tag: (json['tag'] as String? ?? '').trim(),
      useCase: (json['use_case'] as String? ?? '').trim(),
      coachContext:
          (json['coach_context'] as String? ??
                  json['coachContext'] as String? ??
                  '')
              .trim(),
    );
  }

  factory InterviewExpression.fromPersonalWiki(
    InterviewPersonalWikiExpression item,
  ) {
    return InterviewExpression(
      id: item.sourceExpressionId.isNotEmpty
          ? item.sourceExpressionId
          : item.id,
      level: 'wiki',
      levelLabel: 'Personal Wiki',
      section: 'Personal Wiki',
      text: item.text,
      tag: item.tag,
      useCase: item.userExample,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'level': level,
      'level_label': levelLabel,
      'section': section,
      'text': text,
      'tag': tag,
      'use_case': useCase,
      if (coachContext.isNotEmpty) 'coach_context': coachContext,
    };
  }
}

enum InterviewExpressionLearningStatus {
  newItem,
  learning,
  prepared,
  dueReview,
  masteredLinked;

  static InterviewExpressionLearningStatus fromJson(Object? raw) {
    final String value = raw is String ? raw.trim() : '';
    for (final InterviewExpressionLearningStatus status in values) {
      if (status.name == value) {
        return status;
      }
    }
    return InterviewExpressionLearningStatus.newItem;
  }
}

enum InterviewExpressionLearningStep {
  listen,
  shadow,
  recall;

  static InterviewExpressionLearningStep fromJson(Object? raw) {
    final String value = raw is String ? raw.trim() : '';
    for (final InterviewExpressionLearningStep step in values) {
      if (step.name == value) {
        return step;
      }
    }
    return InterviewExpressionLearningStep.listen;
  }
}

class InterviewExpressionLearningProgress {
  const InterviewExpressionLearningProgress({
    required this.sceneId,
    required this.nodeId,
    required this.targetLevel,
    this.status = InterviewExpressionLearningStatus.newItem,
    this.currentStep = InterviewExpressionLearningStep.listen,
    this.attempts = 0,
    this.bestScore = 0,
    this.lastPracticedAt,
    this.nextReviewAt,
    this.lastTranscript = '',
    this.lastScore,
    this.lastTextMatch,
    this.lastPronunciationScore,
    this.lastPassed,
    this.lastScoredAt,
    this.bestTranscript = '',
    this.bestTextMatch,
    this.bestPronunciationScore,
    this.bestScoredAt,
    this.completedWarmupSteps = const <String>[],
  });

  final String sceneId;
  final String nodeId;
  final String targetLevel;
  final InterviewExpressionLearningStatus status;
  final InterviewExpressionLearningStep currentStep;
  final int attempts;
  final double bestScore;
  final DateTime? lastPracticedAt;
  final DateTime? nextReviewAt;
  final String lastTranscript;
  final double? lastScore;
  final double? lastTextMatch;
  final double? lastPronunciationScore;
  final bool? lastPassed;
  final DateTime? lastScoredAt;
  final String bestTranscript;
  final double? bestTextMatch;
  final double? bestPronunciationScore;
  final DateTime? bestScoredAt;
  final List<String> completedWarmupSteps;

  String get key =>
      storageKey(sceneId: sceneId, nodeId: nodeId, targetLevel: targetLevel);

  bool get isPrepared =>
      status == InterviewExpressionLearningStatus.prepared ||
      status == InterviewExpressionLearningStatus.dueReview;

  bool get isMasteredLinked =>
      status == InterviewExpressionLearningStatus.masteredLinked;

  bool get hasMinimumWarmup =>
      hasCompletedWarmupStep('listen') && hasCompletedWarmupStep('shadow');

  bool hasCompletedWarmupStep(String step) {
    final String normalized = step.trim();
    if (normalized.isEmpty) {
      return false;
    }
    return completedWarmupSteps.contains(normalized) ||
        (normalized == 'listen' &&
            currentStep != InterviewExpressionLearningStep.listen) ||
        (normalized == 'shadow' &&
            (currentStep == InterviewExpressionLearningStep.recall ||
                status == InterviewExpressionLearningStatus.prepared ||
                status == InterviewExpressionLearningStatus.dueReview ||
                status == InterviewExpressionLearningStatus.masteredLinked));
  }

  static String storageKey({
    required String sceneId,
    required String nodeId,
    required String targetLevel,
  }) {
    return '${sceneId.trim().isEmpty ? defaultInterviewSceneId : sceneId.trim()}|${nodeId.trim()}|${_normalizeSceneTargetLevel(targetLevel)}';
  }

  factory InterviewExpressionLearningProgress.fromJson(
    Map<String, dynamic> json,
  ) {
    return InterviewExpressionLearningProgress(
      sceneId: (json['sceneId'] as String? ?? defaultInterviewSceneId).trim(),
      nodeId: (json['nodeId'] as String? ?? '').trim(),
      targetLevel: _normalizeSceneTargetLevel(json['targetLevel']),
      status: InterviewExpressionLearningStatus.fromJson(json['status']),
      currentStep: InterviewExpressionLearningStep.fromJson(
        json['currentStep'],
      ),
      attempts: ((json['attempts'] as num?)?.round().clamp(0, 100000) ?? 0)
          .toInt(),
      bestScore: ((json['bestScore'] as num?)?.toDouble() ?? 0)
          .clamp(0, 100)
          .toDouble(),
      lastPracticedAt: DateTime.tryParse(
        (json['lastPracticedAt'] as String? ?? '').trim(),
      ),
      nextReviewAt: DateTime.tryParse(
        (json['nextReviewAt'] as String? ?? '').trim(),
      ),
      lastTranscript: (json['lastTranscript'] as String? ?? '').trim(),
      lastScore: _nullableScore(json['lastScore']),
      lastTextMatch: _nullableRatio(json['lastTextMatch']),
      lastPronunciationScore: _nullableScore(json['lastPronunciationScore']),
      lastPassed: json['lastPassed'] is bool
          ? json['lastPassed'] as bool
          : null,
      lastScoredAt: DateTime.tryParse(
        (json['lastScoredAt'] as String? ?? '').trim(),
      ),
      bestTranscript: (json['bestTranscript'] as String? ?? '').trim(),
      bestTextMatch: _nullableRatio(json['bestTextMatch']),
      bestPronunciationScore: _nullableScore(json['bestPronunciationScore']),
      bestScoredAt: DateTime.tryParse(
        (json['bestScoredAt'] as String? ?? '').trim(),
      ),
      completedWarmupSteps: List<String>.unmodifiable(
        _stringList(json['completedWarmupSteps']),
      ),
    );
  }

  InterviewExpressionLearningProgress copyWith({
    String? sceneId,
    String? nodeId,
    String? targetLevel,
    InterviewExpressionLearningStatus? status,
    InterviewExpressionLearningStep? currentStep,
    int? attempts,
    double? bestScore,
    DateTime? lastPracticedAt,
    DateTime? nextReviewAt,
    String? lastTranscript,
    double? lastScore,
    double? lastTextMatch,
    double? lastPronunciationScore,
    bool? lastPassed,
    DateTime? lastScoredAt,
    String? bestTranscript,
    double? bestTextMatch,
    double? bestPronunciationScore,
    DateTime? bestScoredAt,
    List<String>? completedWarmupSteps,
    bool clearNextReviewAt = false,
  }) {
    return InterviewExpressionLearningProgress(
      sceneId: sceneId ?? this.sceneId,
      nodeId: nodeId ?? this.nodeId,
      targetLevel: targetLevel ?? this.targetLevel,
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      attempts: attempts ?? this.attempts,
      bestScore: bestScore ?? this.bestScore,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
      nextReviewAt: clearNextReviewAt
          ? null
          : nextReviewAt ?? this.nextReviewAt,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      lastScore: lastScore ?? this.lastScore,
      lastTextMatch: lastTextMatch ?? this.lastTextMatch,
      lastPronunciationScore:
          lastPronunciationScore ?? this.lastPronunciationScore,
      lastPassed: lastPassed ?? this.lastPassed,
      lastScoredAt: lastScoredAt ?? this.lastScoredAt,
      bestTranscript: bestTranscript ?? this.bestTranscript,
      bestTextMatch: bestTextMatch ?? this.bestTextMatch,
      bestPronunciationScore:
          bestPronunciationScore ?? this.bestPronunciationScore,
      bestScoredAt: bestScoredAt ?? this.bestScoredAt,
      completedWarmupSteps: completedWarmupSteps ?? this.completedWarmupSteps,
    );
  }

  InterviewExpressionLearningProgress withCompletedWarmupStep(String step) {
    final String normalized = step.trim();
    if (normalized.isEmpty || completedWarmupSteps.contains(normalized)) {
      return this;
    }
    return copyWith(
      completedWarmupSteps: List<String>.unmodifiable(<String>[
        ...completedWarmupSteps,
        normalized,
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sceneId': sceneId,
      'nodeId': nodeId,
      'targetLevel': targetLevel,
      'status': status.name,
      'currentStep': currentStep.name,
      'attempts': attempts,
      'bestScore': bestScore,
      if (lastPracticedAt != null)
        'lastPracticedAt': lastPracticedAt!.toIso8601String(),
      if (nextReviewAt != null) 'nextReviewAt': nextReviewAt!.toIso8601String(),
      if (lastTranscript.isNotEmpty) 'lastTranscript': lastTranscript,
      if (lastScore != null) 'lastScore': lastScore,
      if (lastTextMatch != null) 'lastTextMatch': lastTextMatch,
      if (lastPronunciationScore != null)
        'lastPronunciationScore': lastPronunciationScore,
      if (lastPassed != null) 'lastPassed': lastPassed,
      if (lastScoredAt != null) 'lastScoredAt': lastScoredAt!.toIso8601String(),
      if (bestTranscript.isNotEmpty) 'bestTranscript': bestTranscript,
      if (bestTextMatch != null) 'bestTextMatch': bestTextMatch,
      if (bestPronunciationScore != null)
        'bestPronunciationScore': bestPronunciationScore,
      if (bestScoredAt != null) 'bestScoredAt': bestScoredAt!.toIso8601String(),
      if (completedWarmupSteps.isNotEmpty)
        'completedWarmupSteps': completedWarmupSteps,
    };
  }
}

double? _nullableScore(Object? raw) {
  final double? value = (raw as num?)?.toDouble();
  return value?.clamp(0, 100).toDouble();
}

double? _nullableRatio(Object? raw) {
  final double? value = (raw as num?)?.toDouble();
  return value?.clamp(0, 1).toDouble();
}

class InterviewCorrection {
  const InterviewCorrection({
    required this.id,
    required this.category,
    required this.wrong,
    required this.better,
    required this.reason,
  });

  final String id;
  final String category;
  final String wrong;
  final String better;
  final String reason;

  factory InterviewCorrection.fromJson(Map<String, dynamic> json) {
    return InterviewCorrection(
      id: (json['id'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? '').trim(),
      wrong: (json['wrong'] as String? ?? '').trim(),
      better: (json['better'] as String? ?? '').trim(),
      reason: (json['reason'] as String? ?? '').trim(),
    );
  }
}

class InterviewLibrary {
  const InterviewLibrary({
    required this.expressions,
    required this.corrections,
  });

  final List<InterviewExpression> expressions;
  final List<InterviewCorrection> corrections;

  factory InterviewLibrary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawExpressions =
        json['expressions'] as List<dynamic>? ?? const <dynamic>[];
    final List<dynamic> rawCorrections =
        json['corrections'] as List<dynamic>? ?? const <dynamic>[];
    return InterviewLibrary(
      expressions: rawExpressions
          .whereType<Map>()
          .map(
            (Map item) =>
                InterviewExpression.fromJson(item.cast<String, dynamic>()),
          )
          .where((InterviewExpression item) => item.text.isNotEmpty)
          .toList(growable: false),
      corrections: rawCorrections
          .whereType<Map>()
          .map(
            (Map item) =>
                InterviewCorrection.fromJson(item.cast<String, dynamic>()),
          )
          .where(
            (InterviewCorrection item) =>
                item.wrong.isNotEmpty || item.better.isNotEmpty,
          )
          .toList(growable: false),
    );
  }

  List<InterviewExpression> expressionsForTag(
    String tag, {
    String targetLevel = 'beginner',
    int limit = 4,
  }) {
    final List<InterviewExpression> exactLevel = expressions
        .where(
          (InterviewExpression item) =>
              item.tag == tag && item.level == targetLevel,
        )
        .toList(growable: false);
    final List<InterviewExpression> candidates = exactLevel.isNotEmpty
        ? exactLevel
        : expressions
              .where((InterviewExpression item) => item.tag == tag)
              .toList(growable: false);
    return candidates.take(limit).toList(growable: false);
  }

  InterviewCorrection? correctionById(String id) {
    for (final InterviewCorrection correction in corrections) {
      if (correction.id == id) {
        return correction;
      }
    }
    return null;
  }
}

class InterviewTurnAnalysis {
  const InterviewTurnAnalysis({
    required this.predictedTag,
    required this.secondaryTags,
    required this.confidence,
    required this.coverageStatus,
    required this.coverageCredit,
    required this.stuckState,
    required this.needsFollowup,
    required this.correctionHits,
    required this.languageMixRatio,
  });

  final String predictedTag;
  final List<String> secondaryTags;
  final double confidence;
  final String coverageStatus;
  final double coverageCredit;
  final bool stuckState;
  final bool needsFollowup;
  final List<InterviewCorrectionHit> correctionHits;
  final double languageMixRatio;
}

class InterviewCorrectionHit {
  const InterviewCorrectionHit({
    required this.id,
    this.wrong,
    this.better,
    required this.reason,
  });

  final String id;
  final String? wrong;
  final String? better;
  final String reason;
}

class InterviewTurnRecord {
  const InterviewTurnRecord({
    required this.stage,
    required this.question,
    required this.userText,
    required this.predictedTags,
    required this.correctionHitIds,
    required this.coverageStatus,
    required this.coverageCredit,
    required this.confidence,
    required this.createdAt,
    this.pronunciationScore,
    this.grammarScore,
  });

  final String stage;
  final String question;
  final String userText;
  final List<String> predictedTags;
  final List<String> correctionHitIds;
  final String coverageStatus;
  final double coverageCredit;
  final double confidence;
  final DateTime createdAt;
  final int? pronunciationScore;
  final int? grammarScore;

  factory InterviewTurnRecord.fromJson(Map<String, dynamic> json) {
    return InterviewTurnRecord(
      stage: (json['stage'] as String? ?? '').trim(),
      question: (json['question'] as String? ?? '').trim(),
      userText: (json['userText'] as String? ?? '').trim(),
      predictedTags: _stringList(json['predictedTags']),
      correctionHitIds: _stringList(json['correctionHitIds']),
      coverageStatus: (json['coverageStatus'] as String? ?? '').trim(),
      coverageCredit: ((json['coverageCredit'] as num?)?.toDouble() ?? 0)
          .clamp(0, 1)
          .toDouble(),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0)
          .clamp(0, 1)
          .toDouble(),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      pronunciationScore: (json['pronunciationScore'] as num?)?.toInt(),
      grammarScore: (json['grammarScore'] as num?)?.toInt(),
    );
  }

  int? get voiceCompositeScore {
    final List<int> scores = <int>[
      if (grammarScore != null) grammarScore!.clamp(0, 100),
      if (pronunciationScore != null) pronunciationScore!.clamp(0, 100),
    ];
    if (scores.isEmpty) {
      return null;
    }
    return (scores.reduce((int a, int b) => a + b) / scores.length).round();
  }

  InterviewTurnRecord copyWith({int? pronunciationScore, int? grammarScore}) {
    return InterviewTurnRecord(
      stage: stage,
      question: question,
      userText: userText,
      predictedTags: predictedTags,
      correctionHitIds: correctionHitIds,
      coverageStatus: coverageStatus,
      coverageCredit: coverageCredit,
      confidence: confidence,
      createdAt: createdAt,
      pronunciationScore: pronunciationScore ?? this.pronunciationScore,
      grammarScore: grammarScore ?? this.grammarScore,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'stage': stage,
      'question': question,
      'userText': userText,
      'predictedTags': predictedTags,
      'correctionHitIds': correctionHitIds,
      'coverageStatus': coverageStatus,
      'coverageCredit': coverageCredit,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
      if (pronunciationScore != null) 'pronunciationScore': pronunciationScore,
      if (grammarScore != null) 'grammarScore': grammarScore,
    };
  }
}

class InterviewPracticeSession {
  InterviewPracticeSession({
    required this.sessionId,
    required this.userId,
    this.publicSceneId = defaultInterviewSceneId,
    required this.jobFamily,
    required this.mode,
    required this.userTier,
    required this.targetLevel,
    required this.plannedStages,
    this.roundMode = InterviewNextRoundMode.newLesson,
  });

  final String sessionId;
  final String userId;
  final String publicSceneId;
  final String jobFamily;
  final String mode;
  final String userTier;
  final String targetLevel;
  List<String> plannedStages;
  final InterviewNextRoundMode roundMode;
  int stageIndex = 0;
  final List<InterviewTurnRecord> turns = <InterviewTurnRecord>[];
  final Map<String, int> stageAttempts = <String, int>{};
  final Map<String, double> stageBestCoverage = <String, double>{};
  final Map<String, String> stagePrimaryTags = <String, String>{};
  final Map<String, String> stageHintLevels = <String, String>{};
  final Map<String, int> stageFollowups = <String, int>{};
  final Map<String, String> stageTeachingStages = <String, String>{};
  final Map<String, String> stageLastCoachMoveIds = <String, String>{};
  final Map<String, String> stageLastNextActions = <String, String>{};
  final Map<String, InterviewExpression> stageExpressionTargets =
      <String, InterviewExpression>{};
  final Set<String> masteredExpressionIds = <String>{};
  final Set<String> roundMasteredExpressionIds = <String>{};
  final Set<String> completedTargetExpressionIds = <String>{};
  InterviewExpression? pendingReuseTarget;
  bool pendingReuseTargetForced = false;
  InterviewExpression? delayedReuseTarget;
  int delayedReuseEligibleStageIndex = -1;
  int consecutiveStuckCount = 0;
  bool simplifiedMode = false;

  String get currentStage {
    if (stageIndex >= plannedStages.length) {
      return 'wrap_up';
    }
    return plannedStages[stageIndex];
  }

  double get progress {
    if (plannedStages.isEmpty) {
      return 0;
    }
    return (stageIndex + 1).clamp(0, plannedStages.length) /
        plannedStages.length;
  }

  factory InterviewPracticeSession.fromJson(Map<String, dynamic> json) {
    final InterviewPracticeSession session = InterviewPracticeSession(
      sessionId: (json['sessionId'] as String? ?? '').trim(),
      userId: (json['userId'] as String? ?? '').trim(),
      publicSceneId:
          (json['publicSceneId'] as String? ?? defaultInterviewSceneId).trim(),
      jobFamily: (json['jobFamily'] as String? ?? 'general').trim(),
      mode: (json['mode'] as String? ?? 'full_mock').trim(),
      userTier: (json['userTier'] as String? ?? 'newbie').trim(),
      targetLevel: (json['targetLevel'] as String? ?? 'beginner').trim(),
      plannedStages: _stringList(json['plannedStages']),
      roundMode: _roundModeFromJson(json['roundMode']),
    );
    session.stageIndex = ((json['stageIndex'] as num?)?.round() ?? 0)
        .clamp(0, session.plannedStages.length)
        .toInt();
    session.turns.addAll(
      _mapList(json['turns']).map(InterviewTurnRecord.fromJson),
    );
    session.stageAttempts.addAll(_intMap(json['stageAttempts']));
    session.stageBestCoverage.addAll(_doubleMap(json['stageBestCoverage']));
    session.stagePrimaryTags.addAll(_stringMap(json['stagePrimaryTags']));
    session.stageHintLevels.addAll(_stringMap(json['stageHintLevels']));
    session.stageFollowups.addAll(_intMap(json['stageFollowups']));
    session.stageTeachingStages.addAll(
      _validatedStringMap(
        json['stageTeachingStages'],
        InterviewCoachSchema.isTeachingStage,
      ),
    );
    session.stageLastCoachMoveIds.addAll(
      _validatedStringMap(
        json['stageLastCoachMoveIds'],
        InterviewCoachSchema.isCoachMoveId,
      ),
    );
    session.stageLastNextActions.addAll(
      _validatedStringMap(
        json['stageLastNextActions'],
        InterviewCoachSchema.isNextAction,
      ),
    );
    session.stageExpressionTargets.addAll(
      _expressionMap(json['stageExpressionTargets']),
    );
    session.masteredExpressionIds.addAll(_stringList(json['masteredIds']));
    session.roundMasteredExpressionIds.addAll(
      _stringList(json['roundMasteredIds']),
    );
    session.completedTargetExpressionIds.addAll(
      _stringList(json['completedTargetExpressionIds']),
    );
    final Map<String, dynamic>? pendingTarget = _map(
      json['pendingReuseTarget'],
    );
    if (pendingTarget != null) {
      final InterviewExpression expression = InterviewExpression.fromJson(
        pendingTarget,
      );
      if (expression.text.isNotEmpty) {
        session.pendingReuseTarget = expression;
      }
    }
    session.pendingReuseTargetForced = json['pendingReuseTargetForced'] == true;
    final Map<String, dynamic>? delayedTarget = _map(
      json['delayedReuseTarget'],
    );
    if (delayedTarget != null) {
      final InterviewExpression expression = InterviewExpression.fromJson(
        delayedTarget,
      );
      if (expression.text.isNotEmpty) {
        session.delayedReuseTarget = expression;
      }
    }
    session.delayedReuseEligibleStageIndex =
        ((json['delayedReuseEligibleStageIndex'] as num?)?.round() ?? -1)
            .clamp(-1, session.plannedStages.length)
            .toInt();
    session.consecutiveStuckCount =
        ((json['consecutiveStuckCount'] as num?)?.round() ?? 0)
            .clamp(0, 100)
            .toInt();
    session.simplifiedMode = json['simplifiedMode'] == true;
    return session;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'userId': userId,
      'publicSceneId': publicSceneId,
      'jobFamily': jobFamily,
      'mode': mode,
      'userTier': userTier,
      'targetLevel': targetLevel,
      'plannedStages': plannedStages,
      'roundMode': roundMode.name,
      'stageIndex': stageIndex,
      'turns': turns.map((InterviewTurnRecord turn) => turn.toJson()).toList(),
      'stageAttempts': stageAttempts,
      'stageBestCoverage': stageBestCoverage,
      'stagePrimaryTags': stagePrimaryTags,
      'stageHintLevels': stageHintLevels,
      'stageFollowups': stageFollowups,
      'stageTeachingStages': stageTeachingStages,
      'stageLastCoachMoveIds': stageLastCoachMoveIds,
      'stageLastNextActions': stageLastNextActions,
      'stageExpressionTargets': stageExpressionTargets.map(
        (String key, InterviewExpression value) =>
            MapEntry<String, dynamic>(key, value.toJson()),
      ),
      'masteredIds': masteredExpressionIds.toList(growable: false),
      'roundMasteredIds': roundMasteredExpressionIds.toList(growable: false),
      'completedTargetExpressionIds': completedTargetExpressionIds.toList(
        growable: false,
      ),
      'pendingReuseTarget': pendingReuseTarget?.toJson(),
      'pendingReuseTargetForced': pendingReuseTargetForced,
      'delayedReuseTarget': delayedReuseTarget?.toJson(),
      'delayedReuseEligibleStageIndex': delayedReuseEligibleStageIndex,
      'consecutiveStuckCount': consecutiveStuckCount,
      'simplifiedMode': simplifiedMode,
    };
  }
}

class InterviewCoachReply {
  const InterviewCoachReply({
    required this.predictedTag,
    required this.secondaryTags,
    required this.coverageStatus,
    required this.hintState,
    required this.nextAction,
    required this.assistantMessage,
    required this.confidence,
    required this.correctionHits,
    required this.coverageCredit,
    required this.stage,
    this.alignmentExpression,
    this.masteredExpressions = const <InterviewExpression>[],
    this.masteryResults = const <String, InterviewExpressionMasteryResult>{},
  });

  final String predictedTag;
  final List<String> secondaryTags;
  final String coverageStatus;
  final String hintState;
  final String nextAction;
  final String assistantMessage;
  final double confidence;
  final List<InterviewCorrectionHit> correctionHits;
  final double coverageCredit;
  final String stage;
  final InterviewExpression? alignmentExpression;
  final List<InterviewExpression> masteredExpressions;
  final Map<String, InterviewExpressionMasteryResult> masteryResults;

  bool get isSessionEnd => nextAction == 'end_session';
}

enum InterviewExpressionMasteryStatus { mastered, nearMiss, missed }

class InterviewExpressionMasteryResult {
  const InterviewExpressionMasteryResult({
    required this.status,
    required this.confidence,
    this.matchedVariant = '',
    this.missingCoreMoves = const <String>[],
    this.reason = '',
  });

  final InterviewExpressionMasteryStatus status;
  final double confidence;
  final String matchedVariant;
  final List<String> missingCoreMoves;
  final String reason;

  bool get mastered => status == InterviewExpressionMasteryStatus.mastered;
  bool get nearMiss => status == InterviewExpressionMasteryStatus.nearMiss;
  bool get missed => status == InterviewExpressionMasteryStatus.missed;
  bool get lowConfidence => confidence > 0.35 && confidence < 0.78;

  InterviewExpressionMasteryResult copyWith({
    InterviewExpressionMasteryStatus? status,
    double? confidence,
    String? matchedVariant,
    List<String>? missingCoreMoves,
    String? reason,
  }) {
    return InterviewExpressionMasteryResult(
      status: status ?? this.status,
      confidence: confidence ?? this.confidence,
      matchedVariant: matchedVariant ?? this.matchedVariant,
      missingCoreMoves: missingCoreMoves ?? this.missingCoreMoves,
      reason: reason ?? this.reason,
    );
  }
}

class InterviewAnswerDiagnosis {
  const InterviewAnswerDiagnosis({
    required this.issueType,
    this.didWell = '',
    this.mainIssue = '',
    this.microFix = '',
    this.retryMode = '',
    this.coachMessage = '',
    this.suggestedReply = '',
    this.confidence = 0,
  });

  final String issueType;
  final String didWell;
  final String mainIssue;
  final String microFix;
  final String retryMode;
  final String coachMessage;
  final String suggestedReply;
  final double confidence;

  bool get isComplete => normalizedIssueType == 'complete';

  bool get hasCoachMessage => coachMessage.trim().isNotEmpty;

  String get normalizedIssueType => issueType.trim().toLowerCase();
}

class InterviewQuestionPlan {
  const InterviewQuestionPlan({
    required this.action,
    required this.stage,
    required this.questionIntent,
    required this.mustAskAbout,
    required this.localFallbackQuestion,
    required this.practiceFocus,
    this.predictedTag = '',
    this.coverageStatus = '',
    this.targetExpression,
  });

  final String action;
  final String stage;
  final String questionIntent;
  final String mustAskAbout;
  final String localFallbackQuestion;
  final String practiceFocus;
  final String predictedTag;
  final String coverageStatus;
  final InterviewExpression? targetExpression;

  String get targetExpressionText => targetExpression?.text ?? '';

  String get targetExpressionTag => targetExpression?.tag ?? predictedTag;
}

class InterviewHint {
  const InterviewHint({
    required this.level,
    required this.type,
    required this.text,
  });

  final String level;
  final String type;
  final String text;
}

class InterviewReview {
  const InterviewReview({
    required this.score,
    required this.coveredCount,
    required this.totalCount,
    required this.strongTags,
    required this.focusTags,
    required this.corrections,
    required this.suggestedExpressions,
    required this.masteredThisRoundCount,
    required this.totalMasteredCount,
    required this.totalExpressionCount,
    required this.weakTags,
    required this.nextRoundMode,
    this.dueReviewCount = 0,
    this.nextDueReviewAt,
  });

  final int score;
  final int coveredCount;
  final int totalCount;
  final List<String> strongTags;
  final List<String> focusTags;
  final List<InterviewCorrection> corrections;
  final List<InterviewExpression> suggestedExpressions;
  final int masteredThisRoundCount;
  final int totalMasteredCount;
  final int totalExpressionCount;
  final List<String> weakTags;
  final InterviewNextRoundMode nextRoundMode;
  final int dueReviewCount;
  final DateTime? nextDueReviewAt;

  double get masteryRatio {
    if (totalExpressionCount == 0) {
      return 0;
    }
    return totalMasteredCount / totalExpressionCount;
  }

  String get nextRoundMessage => nextRoundMode.message;
}

class InterviewChatMessage {
  const InterviewChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
    this.stage = '',
    this.status = '',
    this.tag = '',
    this.isHint = false,
    this.hintLevel = '',
    this.isAlignment = false,
    this.isMastered = false,
    this.targetExpression,
    this.questionPlanAction = '',
    this.mustAskAbout = '',
    this.voiceAudioPath = '',
    this.pronunciationScore,
    this.grammarScore,
    this.pronunciationSource = '',
    this.pronunciationAccuracy,
    this.pronunciationFluency,
    this.pronunciationCompleteness,
    this.grammarIssues = const <String>[],
    this.grammarCorrection = '',
    this.grammarProvider = '',
    this.expressionSuggestionText = '',
    this.expressionSuggestionTag = '',
  });

  final String role;
  final String text;
  final DateTime createdAt;
  final String stage;
  final String status;
  final String tag;
  final bool isHint;
  final String hintLevel;
  final bool isAlignment;
  final bool isMastered;
  final InterviewExpression? targetExpression;
  final String questionPlanAction;
  final String mustAskAbout;
  final String voiceAudioPath;
  final int? pronunciationScore;
  final int? grammarScore;
  final String pronunciationSource;
  final int? pronunciationAccuracy;
  final int? pronunciationFluency;
  final int? pronunciationCompleteness;
  final List<String> grammarIssues;
  final String grammarCorrection;
  final String grammarProvider;
  final String expressionSuggestionText;
  final String expressionSuggestionTag;

  bool get isVoice => voiceAudioPath.trim().isNotEmpty;
  bool get hasExpressionSuggestion =>
      expressionSuggestionText.trim().isNotEmpty;

  factory InterviewChatMessage.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? targetJson = _map(json['targetExpression']);
    final InterviewExpression? targetExpression = targetJson == null
        ? null
        : InterviewExpression.fromJson(targetJson);
    return InterviewChatMessage(
      role: (json['role'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      stage: (json['stage'] as String? ?? '').trim(),
      status: (json['status'] as String? ?? '').trim(),
      tag: (json['tag'] as String? ?? '').trim(),
      isHint: json['isHint'] == true,
      hintLevel: (json['hintLevel'] as String? ?? '').trim(),
      isAlignment: json['isAlignment'] == true,
      isMastered: json['isMastered'] == true,
      targetExpression:
          targetExpression != null && targetExpression.text.isNotEmpty
          ? targetExpression
          : null,
      questionPlanAction: (json['questionPlanAction'] as String? ?? '').trim(),
      mustAskAbout: (json['mustAskAbout'] as String? ?? '').trim(),
      voiceAudioPath: (json['voiceAudioPath'] as String? ?? '').trim(),
      pronunciationScore: (json['pronunciationScore'] as num?)?.toInt(),
      grammarScore: (json['grammarScore'] as num?)?.toInt(),
      pronunciationSource: (json['pronunciationSource'] as String? ?? '')
          .trim(),
      pronunciationAccuracy: (json['pronunciationAccuracy'] as num?)?.toInt(),
      pronunciationFluency: (json['pronunciationFluency'] as num?)?.toInt(),
      pronunciationCompleteness: (json['pronunciationCompleteness'] as num?)
          ?.toInt(),
      grammarIssues: (json['grammarIssues'] as List? ?? const <dynamic>[])
          .map((dynamic item) => item.toString().trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false),
      grammarCorrection: (json['grammarCorrection'] as String? ?? '').trim(),
      grammarProvider: (json['grammarProvider'] as String? ?? '').trim(),
      expressionSuggestionText:
          (json['expressionSuggestionText'] as String? ?? '').trim(),
      expressionSuggestionTag:
          (json['expressionSuggestionTag'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'stage': stage,
      'status': status,
      'tag': tag,
      'isHint': isHint,
      'hintLevel': hintLevel,
      'isAlignment': isAlignment,
      'isMastered': isMastered,
      'targetExpression': targetExpression?.toJson(),
      'questionPlanAction': questionPlanAction,
      'mustAskAbout': mustAskAbout,
      'voiceAudioPath': voiceAudioPath,
      if (pronunciationScore != null) 'pronunciationScore': pronunciationScore,
      if (grammarScore != null) 'grammarScore': grammarScore,
      if (pronunciationSource.isNotEmpty)
        'pronunciationSource': pronunciationSource,
      if (pronunciationAccuracy != null)
        'pronunciationAccuracy': pronunciationAccuracy,
      if (pronunciationFluency != null)
        'pronunciationFluency': pronunciationFluency,
      if (pronunciationCompleteness != null)
        'pronunciationCompleteness': pronunciationCompleteness,
      if (grammarIssues.isNotEmpty) 'grammarIssues': grammarIssues,
      if (grammarCorrection.isNotEmpty) 'grammarCorrection': grammarCorrection,
      if (grammarProvider.isNotEmpty) 'grammarProvider': grammarProvider,
      if (expressionSuggestionText.isNotEmpty)
        'expressionSuggestionText': expressionSuggestionText,
      if (expressionSuggestionTag.isNotEmpty)
        'expressionSuggestionTag': expressionSuggestionTag,
    };
  }
}

class InterviewActiveSessionSnapshot {
  const InterviewActiveSessionSnapshot({
    required this.session,
    required this.messages,
    required this.updatedAt,
  });

  final InterviewPracticeSession session;
  final List<InterviewChatMessage> messages;
  final DateTime updatedAt;

  factory InterviewActiveSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return InterviewActiveSessionSnapshot(
      session: InterviewPracticeSession.fromJson(
        _map(json['session']) ?? const <String, dynamic>{},
      ),
      messages: _mapList(
        json['messages'],
      ).map(InterviewChatMessage.fromJson).toList(growable: false),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'session': session.toJson(),
      'messages': messages
          .map((InterviewChatMessage message) => message.toJson())
          .toList(growable: false),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class InterviewPersonalWikiExpression {
  const InterviewPersonalWikiExpression({
    required this.id,
    this.sourceSceneId = defaultInterviewSceneId,
    required this.sourceExpressionId,
    this.sourceNodeId = '',
    required this.text,
    required this.tag,
    required this.stage,
    required this.masteredAt,
    required this.userExample,
    required this.firstMasteredAt,
    required this.lastReviewedAt,
    required this.nextReviewAt,
    this.reviewCount = 1,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
  });

  final String id;
  final String sourceSceneId;
  final String sourceExpressionId;
  final String sourceNodeId;
  final String text;
  final String tag;
  final String stage;
  final DateTime masteredAt;
  final String userExample;
  final DateTime firstMasteredAt;
  final DateTime lastReviewedAt;
  final DateTime nextReviewAt;
  final int reviewCount;
  final double easeFactor;
  final int intervalDays;

  factory InterviewPersonalWikiExpression.fromJson(Map<String, dynamic> json) {
    final DateTime masteredAt =
        DateTime.tryParse((json['masteredAt'] as String? ?? '').trim()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final int intervalDays =
        ((json['intervalDays'] as num?)?.round().clamp(1, 365) ?? 1).toInt();
    final DateTime firstMasteredAt =
        DateTime.tryParse((json['firstMasteredAt'] as String? ?? '').trim()) ??
        masteredAt;
    final DateTime lastReviewedAt =
        DateTime.tryParse((json['lastReviewedAt'] as String? ?? '').trim()) ??
        masteredAt;
    final DateTime nextReviewAt =
        DateTime.tryParse((json['nextReviewAt'] as String? ?? '').trim()) ??
        lastReviewedAt.add(Duration(days: intervalDays));
    return InterviewPersonalWikiExpression(
      id: (json['id'] as String? ?? '').trim(),
      sourceSceneId:
          (json['sourceSceneId'] as String? ?? defaultInterviewSceneId).trim(),
      sourceExpressionId: (json['sourceExpressionId'] as String? ?? '').trim(),
      sourceNodeId:
          ((json['sourceNodeId'] as String?) ??
                  (json['sourceExpressionId'] as String?) ??
                  '')
              .trim(),
      text: (json['text'] as String? ?? '').trim(),
      tag: (json['tag'] as String? ?? '').trim(),
      stage: (json['stage'] as String? ?? '').trim(),
      masteredAt: masteredAt,
      userExample: (json['userExample'] as String? ?? '').trim(),
      firstMasteredAt: firstMasteredAt,
      lastReviewedAt: lastReviewedAt,
      nextReviewAt: nextReviewAt,
      reviewCount: ((json['reviewCount'] as num?)?.round().clamp(1, 1000) ?? 1)
          .toInt(),
      easeFactor: ((json['easeFactor'] as num?)?.toDouble() ?? 2.5)
          .clamp(1.3, 3.0)
          .toDouble(),
      intervalDays: intervalDays,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sourceSceneId': sourceSceneId,
      'sourceExpressionId': sourceExpressionId,
      'sourceNodeId': sourceNodeId.isNotEmpty
          ? sourceNodeId
          : sourceExpressionId,
      'text': text,
      'tag': tag,
      'stage': stage,
      'masteredAt': masteredAt.toIso8601String(),
      'userExample': userExample,
      'firstMasteredAt': firstMasteredAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt.toIso8601String(),
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'reviewCount': reviewCount,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
    };
  }
}

class InterviewCompiledWikiItem {
  const InterviewCompiledWikiItem({
    required this.id,
    required this.title,
    required this.body,
    required this.tag,
    required this.evidence,
    required this.updatedAt,
    this.source = 'llm',
  });

  final String id;
  final String title;
  final String body;
  final String tag;
  final String evidence;
  final DateTime updatedAt;
  final String source;

  factory InterviewCompiledWikiItem.fromJson(Map<String, dynamic> json) {
    return InterviewCompiledWikiItem(
      id: (json['id'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      body: (json['body'] as String? ?? '').trim(),
      tag: (json['tag'] as String? ?? '').trim(),
      evidence: (json['evidence'] as String? ?? '').trim(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      source: (json['source'] as String? ?? 'llm').trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'tag': tag,
      'evidence': evidence,
      'updatedAt': updatedAt.toIso8601String(),
      'source': source,
    };
  }
}

class InterviewCompiledWiki {
  const InterviewCompiledWiki({
    required this.updatedAt,
    this.summary = '',
    this.personalFacts = const <InterviewCompiledWikiItem>[],
    this.interviewStories = const <InterviewCompiledWikiItem>[],
    this.weakPatterns = const <InterviewCompiledWikiItem>[],
    this.nextTargets = const <InterviewCompiledWikiItem>[],
    this.compileCount = 0,
  });

  final DateTime updatedAt;
  final String summary;
  final List<InterviewCompiledWikiItem> personalFacts;
  final List<InterviewCompiledWikiItem> interviewStories;
  final List<InterviewCompiledWikiItem> weakPatterns;
  final List<InterviewCompiledWikiItem> nextTargets;
  final int compileCount;

  bool get isEmpty =>
      summary.trim().isEmpty &&
      personalFacts.isEmpty &&
      interviewStories.isEmpty &&
      weakPatterns.isEmpty &&
      nextTargets.isEmpty;

  factory InterviewCompiledWiki.empty() {
    return InterviewCompiledWiki(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory InterviewCompiledWiki.fromJson(Map<String, dynamic> json) {
    return InterviewCompiledWiki(
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      summary: (json['summary'] as String? ?? '').trim(),
      personalFacts: _wikiItemsFromJson(json['personalFacts']),
      interviewStories: _wikiItemsFromJson(json['interviewStories']),
      weakPatterns: _wikiItemsFromJson(json['weakPatterns']),
      nextTargets: _wikiItemsFromJson(json['nextTargets']),
      compileCount:
          ((json['compileCount'] as num?)?.round().clamp(0, 100000) ?? 0)
              .toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'updatedAt': updatedAt.toIso8601String(),
      'summary': summary,
      'personalFacts': personalFacts
          .map((InterviewCompiledWikiItem item) => item.toJson())
          .toList(growable: false),
      'interviewStories': interviewStories
          .map((InterviewCompiledWikiItem item) => item.toJson())
          .toList(growable: false),
      'weakPatterns': weakPatterns
          .map((InterviewCompiledWikiItem item) => item.toJson())
          .toList(growable: false),
      'nextTargets': nextTargets
          .map((InterviewCompiledWikiItem item) => item.toJson())
          .toList(growable: false),
      'compileCount': compileCount,
    };
  }

  static List<InterviewCompiledWikiItem> _wikiItemsFromJson(dynamic raw) {
    if (raw is! List) {
      return const <InterviewCompiledWikiItem>[];
    }
    return raw
        .whereType<Map>()
        .map(
          (Map item) =>
              InterviewCompiledWikiItem.fromJson(item.cast<String, dynamic>()),
        )
        .where(
          (InterviewCompiledWikiItem item) =>
              item.title.isNotEmpty || item.body.isNotEmpty,
        )
        .toList(growable: false);
  }
}

class InterviewWeakExpressionState {
  const InterviewWeakExpressionState({
    required this.sourceSceneId,
    required this.sourceNodeId,
    required this.sourceExpressionId,
    required this.targetText,
    required this.tag,
    required this.reason,
    required this.lastUserExample,
    required this.lastHintLevel,
    required this.attempts,
    required this.lastSeenAt,
  });

  final String sourceSceneId;
  final String sourceNodeId;
  final String sourceExpressionId;
  final String targetText;
  final String tag;
  final String reason;
  final String lastUserExample;
  final String lastHintLevel;
  final int attempts;
  final DateTime lastSeenAt;

  String get key =>
      '${sourceSceneId.trim()}|${sourceNodeId.trim()}|${sourceExpressionId.trim()}';

  factory InterviewWeakExpressionState.fromJson(Map<String, dynamic> json) {
    return InterviewWeakExpressionState(
      sourceSceneId:
          (json['sourceSceneId'] as String? ?? defaultInterviewSceneId).trim(),
      sourceNodeId: (json['sourceNodeId'] as String? ?? '').trim(),
      sourceExpressionId: (json['sourceExpressionId'] as String? ?? '').trim(),
      targetText: (json['targetText'] as String? ?? '').trim(),
      tag: (json['tag'] as String? ?? '').trim(),
      reason: (json['reason'] as String? ?? '').trim(),
      lastUserExample: (json['lastUserExample'] as String? ?? '').trim(),
      lastHintLevel: (json['lastHintLevel'] as String? ?? '').trim(),
      attempts: ((json['attempts'] as num?)?.round().clamp(0, 1000) ?? 0)
          .toInt(),
      lastSeenAt:
          DateTime.tryParse((json['lastSeenAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceSceneId': sourceSceneId,
      'sourceNodeId': sourceNodeId,
      'sourceExpressionId': sourceExpressionId,
      'targetText': targetText,
      'tag': tag,
      'reason': reason,
      'lastUserExample': lastUserExample,
      'lastHintLevel': lastHintLevel,
      'attempts': attempts,
      'lastSeenAt': lastSeenAt.toIso8601String(),
    };
  }
}

class InterviewUserErrorPattern {
  const InterviewUserErrorPattern({
    required this.id,
    required this.category,
    required this.title,
    required this.detail,
    required this.correction,
    required this.sourceSceneId,
    required this.tag,
    required this.evidence,
    required this.count,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  final String id;
  final String category;
  final String title;
  final String detail;
  final String correction;
  final String sourceSceneId;
  final String tag;
  final String evidence;
  final int count;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  factory InterviewUserErrorPattern.fromJson(Map<String, dynamic> json) {
    final DateTime lastSeenAt =
        DateTime.tryParse((json['lastSeenAt'] as String? ?? '').trim()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return InterviewUserErrorPattern(
      id: (json['id'] as String? ?? '').trim(),
      category: (json['category'] as String? ?? '').trim(),
      title: (json['title'] as String? ?? '').trim(),
      detail: (json['detail'] as String? ?? '').trim(),
      correction: (json['correction'] as String? ?? '').trim(),
      sourceSceneId:
          (json['sourceSceneId'] as String? ?? defaultInterviewSceneId).trim(),
      tag: (json['tag'] as String? ?? '').trim(),
      evidence: (json['evidence'] as String? ?? '').trim(),
      count: ((json['count'] as num?)?.round().clamp(1, 100000) ?? 1).toInt(),
      firstSeenAt:
          DateTime.tryParse((json['firstSeenAt'] as String? ?? '').trim()) ??
          lastSeenAt,
      lastSeenAt: lastSeenAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'title': title,
      'detail': detail,
      'correction': correction,
      'sourceSceneId': sourceSceneId,
      'tag': tag,
      'evidence': evidence,
      'count': count,
      'firstSeenAt': firstSeenAt.toIso8601String(),
      'lastSeenAt': lastSeenAt.toIso8601String(),
    };
  }
}

class InterviewPronunciationProfile {
  const InterviewPronunciationProfile({
    required this.updatedAt,
    this.sampleCount = 0,
    this.averageOverall = 0,
    this.averageAccuracy = 0,
    this.averageFluency = 0,
    this.averageCompleteness = 0,
    this.notes = const <String>[],
  });

  final DateTime updatedAt;
  final int sampleCount;
  final double averageOverall;
  final double averageAccuracy;
  final double averageFluency;
  final double averageCompleteness;
  final List<String> notes;

  bool get isEmpty => sampleCount <= 0 && notes.isEmpty;

  factory InterviewPronunciationProfile.empty() {
    return InterviewPronunciationProfile(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory InterviewPronunciationProfile.fromJson(Map<String, dynamic> json) {
    return InterviewPronunciationProfile(
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      sampleCount:
          ((json['sampleCount'] as num?)?.round().clamp(0, 100000) ?? 0)
              .toInt(),
      averageOverall: ((json['averageOverall'] as num?)?.toDouble() ?? 0)
          .clamp(0, 100)
          .toDouble(),
      averageAccuracy: ((json['averageAccuracy'] as num?)?.toDouble() ?? 0)
          .clamp(0, 100)
          .toDouble(),
      averageFluency: ((json['averageFluency'] as num?)?.toDouble() ?? 0)
          .clamp(0, 100)
          .toDouble(),
      averageCompleteness:
          ((json['averageCompleteness'] as num?)?.toDouble() ?? 0)
              .clamp(0, 100)
              .toDouble(),
      notes: List<String>.unmodifiable(_stringList(json['notes'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'updatedAt': updatedAt.toIso8601String(),
      'sampleCount': sampleCount,
      'averageOverall': averageOverall,
      'averageAccuracy': averageAccuracy,
      'averageFluency': averageFluency,
      'averageCompleteness': averageCompleteness,
      'notes': notes,
    };
  }
}

class InterviewGrammarProfile {
  const InterviewGrammarProfile({
    required this.updatedAt,
    this.issueCount = 0,
    this.recurringIssues = const <String>[],
    this.notes = const <String>[],
  });

  final DateTime updatedAt;
  final int issueCount;
  final List<String> recurringIssues;
  final List<String> notes;

  bool get isEmpty =>
      issueCount <= 0 && recurringIssues.isEmpty && notes.isEmpty;

  factory InterviewGrammarProfile.empty() {
    return InterviewGrammarProfile(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory InterviewGrammarProfile.fromJson(Map<String, dynamic> json) {
    return InterviewGrammarProfile(
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      issueCount: ((json['issueCount'] as num?)?.round().clamp(0, 100000) ?? 0)
          .toInt(),
      recurringIssues: List<String>.unmodifiable(
        _stringList(json['recurringIssues']),
      ),
      notes: List<String>.unmodifiable(_stringList(json['notes'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'updatedAt': updatedAt.toIso8601String(),
      'issueCount': issueCount,
      'recurringIssues': recurringIssues,
      'notes': notes,
    };
  }
}

class InterviewSceneProgressState {
  const InterviewSceneProgressState({
    required this.sourceSceneId,
    required this.masteredCount,
    required this.totalCount,
    required this.weakCount,
    required this.lastNodeId,
    required this.nextRoundMode,
    required this.lastPracticedAt,
  });

  final String sourceSceneId;
  final int masteredCount;
  final int totalCount;
  final int weakCount;
  final String lastNodeId;
  final InterviewNextRoundMode nextRoundMode;
  final DateTime lastPracticedAt;

  factory InterviewSceneProgressState.fromJson(Map<String, dynamic> json) {
    return InterviewSceneProgressState(
      sourceSceneId:
          (json['sourceSceneId'] as String? ?? defaultInterviewSceneId).trim(),
      masteredCount:
          ((json['masteredCount'] as num?)?.round().clamp(0, 100000) ?? 0)
              .toInt(),
      totalCount: ((json['totalCount'] as num?)?.round().clamp(0, 100000) ?? 0)
          .toInt(),
      weakCount: ((json['weakCount'] as num?)?.round().clamp(0, 100000) ?? 0)
          .toInt(),
      lastNodeId: (json['lastNodeId'] as String? ?? '').trim(),
      nextRoundMode: _roundModeFromJson(json['nextRoundMode']),
      lastPracticedAt:
          DateTime.tryParse(
            (json['lastPracticedAt'] as String? ?? '').trim(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceSceneId': sourceSceneId,
      'masteredCount': masteredCount,
      'totalCount': totalCount,
      'weakCount': weakCount,
      'lastNodeId': lastNodeId,
      'nextRoundMode': nextRoundMode.name,
      'lastPracticedAt': lastPracticedAt.toIso8601String(),
    };
  }
}

class InterviewLearningEvidenceRef {
  const InterviewLearningEvidenceRef({
    required this.id,
    required this.type,
    required this.sourceSceneId,
    required this.sourceNodeId,
    required this.stage,
    required this.text,
    required this.score,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String sourceSceneId;
  final String sourceNodeId;
  final String stage;
  final String text;
  final double score;
  final DateTime createdAt;

  factory InterviewLearningEvidenceRef.fromJson(Map<String, dynamic> json) {
    return InterviewLearningEvidenceRef(
      id: (json['id'] as String? ?? '').trim(),
      type: (json['type'] as String? ?? '').trim(),
      sourceSceneId:
          (json['sourceSceneId'] as String? ?? defaultInterviewSceneId).trim(),
      sourceNodeId: (json['sourceNodeId'] as String? ?? '').trim(),
      stage: (json['stage'] as String? ?? '').trim(),
      text: (json['text'] as String? ?? '').trim(),
      score: ((json['score'] as num?)?.toDouble() ?? 0)
          .clamp(0, 100)
          .toDouble(),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'sourceSceneId': sourceSceneId,
      'sourceNodeId': sourceNodeId,
      'stage': stage,
      'text': text,
      'score': score,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class InterviewUserGrowthWiki {
  const InterviewUserGrowthWiki({
    required this.updatedAt,
    this.profileSummary = '',
    this.personalFacts = const <InterviewCompiledWikiItem>[],
    this.interviewStories = const <InterviewCompiledWikiItem>[],
    this.masteredExpressions = const <InterviewPersonalWikiExpression>[],
    this.weakExpressions = const <InterviewWeakExpressionState>[],
    this.errorPatterns = const <InterviewUserErrorPattern>[],
    this.pronunciationProfile,
    this.grammarProfile,
    this.sceneProgress = const <InterviewSceneProgressState>[],
    this.evidenceRefs = const <InterviewLearningEvidenceRef>[],
    this.compileCount = 0,
  });

  final DateTime updatedAt;
  final String profileSummary;
  final List<InterviewCompiledWikiItem> personalFacts;
  final List<InterviewCompiledWikiItem> interviewStories;
  final List<InterviewPersonalWikiExpression> masteredExpressions;
  final List<InterviewWeakExpressionState> weakExpressions;
  final List<InterviewUserErrorPattern> errorPatterns;
  final InterviewPronunciationProfile? pronunciationProfile;
  final InterviewGrammarProfile? grammarProfile;
  final List<InterviewSceneProgressState> sceneProgress;
  final List<InterviewLearningEvidenceRef> evidenceRefs;
  final int compileCount;

  bool get isEmpty =>
      profileSummary.trim().isEmpty &&
      personalFacts.isEmpty &&
      interviewStories.isEmpty &&
      masteredExpressions.isEmpty &&
      weakExpressions.isEmpty &&
      errorPatterns.isEmpty &&
      (pronunciationProfile?.isEmpty ?? true) &&
      (grammarProfile?.isEmpty ?? true) &&
      sceneProgress.isEmpty &&
      evidenceRefs.isEmpty;

  factory InterviewUserGrowthWiki.empty() {
    return InterviewUserGrowthWiki(
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory InterviewUserGrowthWiki.fromJson(Map<String, dynamic> json) {
    return InterviewUserGrowthWiki(
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String? ?? '').trim()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      profileSummary: (json['profileSummary'] as String? ?? '').trim(),
      personalFacts: InterviewCompiledWiki._wikiItemsFromJson(
        json['personalFacts'],
      ),
      interviewStories: InterviewCompiledWiki._wikiItemsFromJson(
        json['interviewStories'],
      ),
      masteredExpressions: _mapList(
        json['masteredExpressions'],
      ).map(InterviewPersonalWikiExpression.fromJson).toList(growable: false),
      weakExpressions: _mapList(
        json['weakExpressions'],
      ).map(InterviewWeakExpressionState.fromJson).toList(growable: false),
      errorPatterns: _mapList(
        json['errorPatterns'],
      ).map(InterviewUserErrorPattern.fromJson).toList(growable: false),
      pronunciationProfile: _map(json['pronunciationProfile']) == null
          ? null
          : InterviewPronunciationProfile.fromJson(
              _map(json['pronunciationProfile'])!,
            ),
      grammarProfile: _map(json['grammarProfile']) == null
          ? null
          : InterviewGrammarProfile.fromJson(_map(json['grammarProfile'])!),
      sceneProgress: _mapList(
        json['sceneProgress'],
      ).map(InterviewSceneProgressState.fromJson).toList(growable: false),
      evidenceRefs: _mapList(
        json['evidenceRefs'],
      ).map(InterviewLearningEvidenceRef.fromJson).toList(growable: false),
      compileCount:
          ((json['compileCount'] as num?)?.round().clamp(0, 100000) ?? 0)
              .toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'updatedAt': updatedAt.toIso8601String(),
      'profileSummary': profileSummary,
      'personalFacts': personalFacts
          .map((InterviewCompiledWikiItem item) => item.toJson())
          .toList(growable: false),
      'interviewStories': interviewStories
          .map((InterviewCompiledWikiItem item) => item.toJson())
          .toList(growable: false),
      'masteredExpressions': masteredExpressions
          .map((InterviewPersonalWikiExpression item) => item.toJson())
          .toList(growable: false),
      'weakExpressions': weakExpressions
          .map((InterviewWeakExpressionState item) => item.toJson())
          .toList(growable: false),
      'errorPatterns': errorPatterns
          .map((InterviewUserErrorPattern item) => item.toJson())
          .toList(growable: false),
      'pronunciationProfile': pronunciationProfile?.toJson(),
      'grammarProfile': grammarProfile?.toJson(),
      'sceneProgress': sceneProgress
          .map((InterviewSceneProgressState item) => item.toJson())
          .toList(growable: false),
      'evidenceRefs': evidenceRefs
          .map((InterviewLearningEvidenceRef item) => item.toJson())
          .toList(growable: false),
      'compileCount': compileCount,
    };
  }
}

class InterviewWikiActionItem {
  const InterviewWikiActionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.sourceSceneId,
    required this.sourceNodeId,
    required this.priority,
    required this.reason,
    required this.evidence,
    required this.suggestedUse,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String sourceSceneId;
  final String sourceNodeId;
  final int priority;
  final String reason;
  final String evidence;
  final String suggestedUse;

  String get promptLine {
    final List<String> parts = <String>[
      type,
      title,
      if (body.trim().isNotEmpty) body,
      if (reason.trim().isNotEmpty) 'reason: $reason',
      if (suggestedUse.trim().isNotEmpty) 'action: $suggestedUse',
      if (evidence.trim().isNotEmpty) 'evidence: $evidence',
    ];
    return parts.join(' | ');
  }
}

class InterviewWikiActionPlan {
  const InterviewWikiActionPlan({
    required this.generatedAt,
    this.primaryAction,
    this.reviewQueue = const <InterviewWikiActionItem>[],
    this.weaknessQueue = const <InterviewWikiActionItem>[],
    this.personalMaterialHints = const <InterviewWikiActionItem>[],
    this.promptContext = const <InterviewWikiActionItem>[],
  });

  final InterviewWikiActionItem? primaryAction;
  final List<InterviewWikiActionItem> reviewQueue;
  final List<InterviewWikiActionItem> weaknessQueue;
  final List<InterviewWikiActionItem> personalMaterialHints;
  final List<InterviewWikiActionItem> promptContext;
  final DateTime generatedAt;

  bool get isEmpty =>
      primaryAction == null &&
      reviewQueue.isEmpty &&
      weaknessQueue.isEmpty &&
      personalMaterialHints.isEmpty &&
      promptContext.isEmpty;
}

class InterviewWikiMemoryPack {
  const InterviewWikiMemoryPack({
    this.summary = '',
    this.dueExpressions = const <String>[],
    this.relevantFacts = const <String>[],
    this.relevantStories = const <String>[],
    this.weakPatterns = const <String>[],
    this.nextTargets = const <String>[],
    this.weakExpressions = const <String>[],
    this.commonErrors = const <String>[],
    this.pronunciationNotes = const <String>[],
    this.grammarNotes = const <String>[],
    this.primaryAction,
    this.actionItems = const <InterviewWikiActionItem>[],
    this.promptContext = const <InterviewWikiActionItem>[],
  });

  final String summary;
  final List<String> dueExpressions;
  final List<String> relevantFacts;
  final List<String> relevantStories;
  final List<String> weakPatterns;
  final List<String> nextTargets;
  final List<String> weakExpressions;
  final List<String> commonErrors;
  final List<String> pronunciationNotes;
  final List<String> grammarNotes;
  final InterviewWikiActionItem? primaryAction;
  final List<InterviewWikiActionItem> actionItems;
  final List<InterviewWikiActionItem> promptContext;

  bool get isEmpty =>
      summary.trim().isEmpty &&
      dueExpressions.isEmpty &&
      relevantFacts.isEmpty &&
      relevantStories.isEmpty &&
      weakPatterns.isEmpty &&
      nextTargets.isEmpty &&
      weakExpressions.isEmpty &&
      commonErrors.isEmpty &&
      pronunciationNotes.isEmpty &&
      grammarNotes.isEmpty &&
      primaryAction == null &&
      actionItems.isEmpty &&
      promptContext.isEmpty;
}

Map<String, dynamic>? _map(dynamic raw) {
  if (raw is! Map) {
    return null;
  }
  return raw.cast<String, dynamic>();
}

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) {
    return const <Map<String, dynamic>>[];
  }
  return raw
      .whereType<Map>()
      .map((Map item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw
      .whereType<String>()
      .map((String item) => item.trim())
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _splitExpressionChunks(String text) {
  final String normalized = text.trim();
  if (normalized.isEmpty) {
    return const <String>[];
  }
  final List<String> sentenceChunks = normalized
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
  if (sentenceChunks.length > 1) {
    return sentenceChunks;
  }
  final List<String> words = normalized.split(RegExp(r'\s+'));
  if (words.length <= 5) {
    return <String>[normalized];
  }
  final int midpoint = (words.length / 2).ceil();
  return <String>[
    words.take(midpoint).join(' '),
    words.skip(midpoint).join(' '),
  ];
}

List<InterviewMasterySignal> _masterySignalList(dynamic raw) {
  if (raw is! List) {
    return const <InterviewMasterySignal>[];
  }
  final List<InterviewMasterySignal> result = <InterviewMasterySignal>[];
  for (int index = 0; index < raw.length; index += 1) {
    final dynamic item = raw[index];
    if (item is Map) {
      final InterviewMasterySignal signal = InterviewMasterySignal.fromJson(
        item.cast<String, dynamic>(),
      );
      if (signal.id.isNotEmpty) {
        result.add(signal);
      }
    } else if (item is String && item.trim().isNotEmpty) {
      result.add(InterviewMasterySignal.fromLegacyText(item.trim(), index));
    }
  }
  return result;
}

Map<String, String> _stringMap(dynamic raw) {
  if (raw is! Map) {
    return const <String, String>{};
  }
  return raw.map(
    (Object? key, Object? value) => MapEntry<String, String>(
      key.toString(),
      value is String ? value.trim() : value?.toString().trim() ?? '',
    ),
  )..removeWhere((String key, String value) => key.trim().isEmpty);
}

Map<String, String> _validatedStringMap(
  dynamic raw,
  bool Function(String value) isValid,
) {
  final Map<String, String> result = Map<String, String>.from(_stringMap(raw));
  result.removeWhere(
    (String key, String value) => key.trim().isEmpty || !isValid(value),
  );
  return result;
}

Map<String, int> _intMap(dynamic raw) {
  if (raw is! Map) {
    return const <String, int>{};
  }
  final Map<String, int> result = <String, int>{};
  raw.forEach((Object? key, Object? value) {
    final String normalizedKey = key.toString().trim();
    if (normalizedKey.isEmpty) {
      return;
    }
    final int normalizedValue = value is num
        ? value.round()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    result[normalizedKey] = normalizedValue;
  });
  return result;
}

Map<String, double> _doubleMap(dynamic raw) {
  if (raw is! Map) {
    return const <String, double>{};
  }
  final Map<String, double> result = <String, double>{};
  raw.forEach((Object? key, Object? value) {
    final String normalizedKey = key.toString().trim();
    if (normalizedKey.isEmpty) {
      return;
    }
    final double normalizedValue = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    result[normalizedKey] = normalizedValue;
  });
  return result;
}

Map<String, InterviewExpression> _expressionMap(dynamic raw) {
  if (raw is! Map) {
    return const <String, InterviewExpression>{};
  }
  final Map<String, InterviewExpression> result =
      <String, InterviewExpression>{};
  raw.forEach((Object? key, Object? value) {
    final String normalizedKey = key.toString().trim();
    final Map<String, dynamic>? json = _map(value);
    if (normalizedKey.isEmpty || json == null) {
      return;
    }
    final InterviewExpression expression = InterviewExpression.fromJson(json);
    if (expression.text.isNotEmpty) {
      result[normalizedKey] = expression;
    }
  });
  return result;
}

InterviewNextRoundMode _roundModeFromJson(dynamic raw) {
  final String value = raw is String ? raw.trim() : '';
  return InterviewNextRoundMode.values.firstWhere(
    (InterviewNextRoundMode mode) => mode.name == value,
    orElse: () => InterviewNextRoundMode.newLesson,
  );
}
