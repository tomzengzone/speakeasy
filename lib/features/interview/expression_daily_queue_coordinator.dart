import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_wiki_store.dart';

typedef InterviewSceneGraphLoader =
    Future<InterviewSceneGraph> Function({String sceneId});
typedef InterviewWikiStoreFactory = InterviewWikiStore Function(String sceneId);

class ExpressionDailyQueueScene {
  const ExpressionDailyQueueScene({
    required this.sceneId,
    required this.targetLevel,
    required this.title,
    required this.order,
  });

  final String sceneId;
  final String targetLevel;
  final String title;
  final int order;
}

class ExpressionDailyQueueItem {
  const ExpressionDailyQueueItem({
    required this.sceneId,
    required this.targetLevel,
    required this.nodeId,
    required this.kind,
    required this.practiceText,
    required this.translation,
    required this.sourceLabel,
    required this.priorityDueAt,
    this.practiceMode = practiceModeShadow,
    this.variantOfNodeId = '',
  });

  static const String kindReview = 'review';
  static const String kindWeak = 'weak';
  static const String kindProgress = 'progress';
  static const String kindNew = 'new';
  static const String kindVariant = 'variant';

  static const String practiceModeShadow = 'shadow';
  static const String practiceModeEchoRecall = 'echoRecall';
  static const String practiceModeClozeRecall = 'clozeRecall';
  static const String practiceModeIntentRecall = 'intentRecall';
  static const String practiceModeCueResponse = 'cueResponse';
  static const String practiceModeChunkRecall = 'chunkRecall';
  static const String practiceModeSlotPersonalize = 'slotPersonalize';
  static const String practiceModeMistakeRepair = 'mistakeRepair';
  static const String practiceModeVariantParaphrase = 'variantParaphrase';
  static const String practiceModeFluencySprint = 'fluencySprint';
  static const String practiceModeMeaningChoice = 'meaningChoice';
  static const String practiceModeCueChoice = 'cueChoice';
  static const String practiceModeRepairChoice = 'repairChoice';

  final String sceneId;
  final String targetLevel;
  final String nodeId;
  final String kind;
  final String practiceText;
  final String translation;
  final String sourceLabel;
  final DateTime? priorityDueAt;
  final String practiceMode;
  final String variantOfNodeId;

  bool get isVariant => variantOfNodeId.trim().isNotEmpty;
}

class ExpressionDailyQueueCoordinator {
  const ExpressionDailyQueueCoordinator({
    InterviewSceneGraphLoader graphLoader = loadInterviewSceneGraph,
    InterviewWikiStoreFactory storeFactory = _defaultStoreFactory,
  }) : _graphLoader = graphLoader,
       _storeFactory = storeFactory;

  final InterviewSceneGraphLoader _graphLoader;
  final InterviewWikiStoreFactory _storeFactory;

  Future<List<ExpressionDailyQueueItem>> buildQueue({
    required List<ExpressionDailyQueueScene> scenes,
    DateTime? now,
  }) async {
    if (scenes.isEmpty) {
      return const <ExpressionDailyQueueItem>[];
    }
    final DateTime referenceTime = now ?? DateTime.now();
    final List<_RankedQueueItem> ranked = <_RankedQueueItem>[];
    for (final ExpressionDailyQueueScene scene in scenes) {
      final String sceneId = scene.sceneId.trim();
      if (sceneId.isEmpty) {
        continue;
      }
      final InterviewSceneGraph graph = await _graphLoader(sceneId: sceneId);
      ranked.addAll(
        _itemsForScene(scene: scene, graph: graph, now: referenceTime),
      );
    }
    ranked.sort(_compareRankedItems);

    final Set<String> seen = <String>{};
    final List<_RankedQueueItem> deduped = <_RankedQueueItem>[];
    for (final _RankedQueueItem item in ranked) {
      if (item.item.practiceText.trim().isEmpty) {
        continue;
      }
      final String key =
          '${item.item.sceneId}|${item.item.nodeId}|${item.item.kind}|${item.item.practiceText.toLowerCase()}';
      if (!seen.add(key)) {
        continue;
      }
      deduped.add(item);
    }
    return deduped
        .map((_RankedQueueItem ranked) => ranked.item)
        .toList(growable: false);
  }

  List<_RankedQueueItem> _itemsForScene({
    required ExpressionDailyQueueScene scene,
    required InterviewSceneGraph graph,
    required DateTime now,
  }) {
    final InterviewWikiStore store = _storeFactory(scene.sceneId);
    final List<String> activeNodeIds = graph.flowNodeIdsForLevel(
      scene.targetLevel,
    );
    final Set<String> activeNodeIdSet = activeNodeIds.toSet();
    final List<InterviewPersonalWikiExpression> mastered = store
        .loadMasteredExpressions(sourceSceneId: scene.sceneId);
    final Set<String> masteredNodeIds = mastered
        .map(_nodeIdForMasteredExpression)
        .where(activeNodeIdSet.contains)
        .toSet();
    final Map<String, InterviewExpressionLearningProgress> progressByNode =
        <String, InterviewExpressionLearningProgress>{
          for (final InterviewExpressionLearningProgress progress
              in store.loadExpressionLearningProgress(
                sourceSceneId: scene.sceneId,
              ))
            progress.nodeId: progress,
        };
    final InterviewUserGrowthWiki growthWiki = store.loadUserGrowthWiki();
    final List<_RankedQueueItem> result = <_RankedQueueItem>[];
    final Set<String> claimedPrimaryNodes = <String>{};

    for (final InterviewPersonalWikiExpression item in mastered) {
      final String nodeId = _nodeIdForMasteredExpression(item);
      if (!activeNodeIdSet.contains(nodeId) ||
          item.text.trim().isEmpty ||
          item.nextReviewAt.isAfter(now)) {
        continue;
      }
      final InterviewExpressionNode? node = graph.nodeById(nodeId);
      result.add(
        _ranked(
          scene: scene,
          node: node,
          nodeId: nodeId,
          kind: ExpressionDailyQueueItem.kindReview,
          practiceText: item.text,
          translation: node?.meaning ?? '',
          priorityDueAt: item.nextReviewAt,
        ),
      );
      claimedPrimaryNodes.add(nodeId);
    }

    final List<InterviewWeakExpressionState> weakExpressions =
        growthWiki.weakExpressions
            .where((InterviewWeakExpressionState item) {
              final String nodeId = _nodeIdForWeakExpression(item);
              return item.sourceSceneId == scene.sceneId &&
                  activeNodeIdSet.contains(nodeId) &&
                  !masteredNodeIds.contains(nodeId);
            })
            .toList(growable: false)
          ..sort(
            (InterviewWeakExpressionState a, InterviewWeakExpressionState b) =>
                b.lastSeenAt.compareTo(a.lastSeenAt),
          );
    for (final InterviewWeakExpressionState weak in weakExpressions) {
      final String nodeId = _nodeIdForWeakExpression(weak);
      if (claimedPrimaryNodes.contains(nodeId)) {
        continue;
      }
      final InterviewExpressionLearningProgress? progress =
          progressByNode[nodeId];
      if (_isWeakPracticeResolved(weak, progress)) {
        continue;
      }
      final InterviewExpressionNode? node = graph.nodeById(nodeId);
      result.add(
        _ranked(
          scene: scene,
          node: node,
          nodeId: nodeId,
          kind: ExpressionDailyQueueItem.kindWeak,
          practiceText: weak.targetText.isNotEmpty
              ? weak.targetText
              : node?.targetText ?? '',
          translation: node?.meaning ?? weak.reason,
          priorityDueAt: weak.lastSeenAt,
          priorityScore: _weakPriorityScore(weak, progress: progress),
        ),
      );
      claimedPrimaryNodes.add(nodeId);
    }

    for (final String nodeId in activeNodeIds) {
      final InterviewExpressionNode? node = graph.nodeById(nodeId);
      if (node == null) {
        continue;
      }
      for (final _PracticeVariantCandidate variant in _practiceVariantsForNode(
        node,
      )) {
        final String variantNodeId = _variantProgressNodeId(
          node.id,
          variant.storageKey,
        );
        if (_isVariantPracticeComplete(progressByNode[variantNodeId])) {
          continue;
        }
        result.add(
          _ranked(
            scene: scene,
            node: node,
            nodeId: variantNodeId,
            kind: ExpressionDailyQueueItem.kindVariant,
            practiceText: variant.text,
            translation: variant.meaning.isNotEmpty
                ? variant.meaning
                : node.meaning,
            priorityDueAt: null,
            variantOfNodeId: node.id,
          ),
        );
        break;
      }
    }

    return result;
  }

  _RankedQueueItem _ranked({
    required ExpressionDailyQueueScene scene,
    required InterviewExpressionNode? node,
    required String nodeId,
    required String kind,
    required String practiceText,
    required String translation,
    required DateTime? priorityDueAt,
    int priorityScore = 0,
    String variantOfNodeId = '',
  }) {
    final String resolvedPracticeText = practiceText.trim();
    if (resolvedPracticeText.isEmpty) {
      return _RankedQueueItem.empty;
    }
    final String stageLabel = node?.stageLabel.trim() ?? '';
    final String sourceLabel = <String>[
      scene.title.trim(),
      if (stageLabel.isNotEmpty) stageLabel,
    ].where((String value) => value.isNotEmpty).join(' · ');
    return _RankedQueueItem(
      item: ExpressionDailyQueueItem(
        sceneId: scene.sceneId,
        targetLevel: scene.targetLevel,
        nodeId: nodeId,
        kind: kind,
        practiceText: resolvedPracticeText,
        translation: translation.trim(),
        sourceLabel: sourceLabel,
        priorityDueAt: priorityDueAt,
        practiceMode: _practiceModeForQueueItem(
          kind: kind,
          node: node,
          nodeId: nodeId,
          practiceText: resolvedPracticeText,
          variantOfNodeId: variantOfNodeId,
        ),
        variantOfNodeId: variantOfNodeId,
      ),
      sceneOrder: scene.order,
      nodeSlot: node?.slot ?? 10000,
      priorityScore: priorityScore,
    );
  }
}

InterviewWikiStore _defaultStoreFactory(String sceneId) {
  return InterviewWikiStore(sceneId: sceneId);
}

String _nodeIdForMasteredExpression(InterviewPersonalWikiExpression item) {
  return item.sourceNodeId.isNotEmpty
      ? item.sourceNodeId
      : item.sourceExpressionId;
}

String _nodeIdForWeakExpression(InterviewWeakExpressionState item) {
  return item.sourceNodeId.isNotEmpty
      ? item.sourceNodeId
      : item.sourceExpressionId;
}

bool _isPracticeVariant(
  InterviewExpressionNode node,
  InterviewExpectedVariant variant,
) {
  final String text = variant.text.trim();
  if (text.isEmpty) {
    return false;
  }
  if (text.toLowerCase() == node.targetText.trim().toLowerCase()) {
    return false;
  }
  return variant.kind != 'starter';
}

List<_PracticeVariantCandidate> _practiceVariantsForNode(
  InterviewExpressionNode node,
) {
  final List<_IndexedPracticeVariant> explicitVariants =
      <_IndexedPracticeVariant>[
        for (int index = 0; index < node.practiceVariants.length; index += 1)
          _IndexedPracticeVariant(node.practiceVariants[index], index),
      ]..sort((_IndexedPracticeVariant a, _IndexedPracticeVariant b) {
        final int byPriority = a.variant.priority.compareTo(b.variant.priority);
        if (byPriority != 0) {
          return byPriority;
        }
        return a.index.compareTo(b.index);
      });
  final List<_PracticeVariantCandidate> candidates =
      <_PracticeVariantCandidate>[
        for (final _IndexedPracticeVariant entry in explicitVariants)
          if (_isExplicitPracticeVariant(node, entry.variant))
            _PracticeVariantCandidate(
              text: entry.variant.text,
              meaning: entry.variant.meaning,
              storageKey: entry.variant.id.isNotEmpty
                  ? entry.variant.id
                  : _stableTextHash(entry.variant.text),
            ),
      ];
  if (candidates.isNotEmpty) {
    return candidates;
  }
  return <_PracticeVariantCandidate>[
    for (final InterviewExpectedVariant variant in node.expectedVariants)
      if (_isPracticeVariant(node, variant))
        _PracticeVariantCandidate(
          text: variant.text,
          meaning: node.meaning,
          storageKey: _stableTextHash(variant.text),
        ),
  ];
}

bool _isExplicitPracticeVariant(
  InterviewExpressionNode node,
  InterviewPracticeVariant variant,
) {
  final String text = variant.text.trim();
  if (text.isEmpty) {
    return false;
  }
  return text.toLowerCase() != node.targetText.trim().toLowerCase();
}

bool _isVariantPracticeComplete(InterviewExpressionLearningProgress? progress) {
  if (progress == null) {
    return false;
  }
  return progress.hasMinimumWarmup ||
      progress.status == InterviewExpressionLearningStatus.prepared ||
      progress.status == InterviewExpressionLearningStatus.dueReview ||
      progress.status == InterviewExpressionLearningStatus.masteredLinked;
}

bool _isWeakPracticeResolved(
  InterviewWeakExpressionState weak,
  InterviewExpressionLearningProgress? progress,
) {
  if (progress == null) {
    return false;
  }
  final DateTime? lastPracticedAt = progress.lastPracticedAt;
  if (lastPracticedAt == null || lastPracticedAt.isBefore(weak.lastSeenAt)) {
    return false;
  }
  final bool completed =
      progress.isMasteredLinked ||
      progress.isPrepared ||
      progress.hasMinimumWarmup;
  return completed && (progress.lastPassed == true || progress.bestScore >= 72);
}

int _weakPriorityScore(
  InterviewWeakExpressionState weak, {
  required InterviewExpressionLearningProgress? progress,
}) {
  int score = _weakReasonScore(weak.reason);
  score += _hintLevelScore(weak.lastHintLevel);
  score += weak.attempts.clamp(0, 6).toInt() * 8;
  if (weak.lastUserExample.trim().isEmpty) {
    score += 6;
  }
  if (progress != null) {
    score += progress.attempts.clamp(0, 5).toInt() * 5;
    if (progress.bestScore > 0) {
      score += (78 - progress.bestScore).clamp(0, 30).round();
    } else if (progress.attempts > 0) {
      score += 12;
    }
    if (progress.status == InterviewExpressionLearningStatus.learning) {
      score += 8;
    }
  }
  return score;
}

int _weakReasonScore(String reason) {
  final String value = reason.trim();
  if (value.contains('卡住')) {
    return 70;
  }
  if (value.contains('部分')) {
    return 50;
  }
  if (value.contains('高阶提示') || value.contains('依赖')) {
    return 42;
  }
  if (value.contains('未确认')) {
    return 28;
  }
  return 24;
}

int _hintLevelScore(String hintLevel) {
  return switch (hintLevel.trim().toUpperCase()) {
    'L4' => 36,
    'L3' => 28,
    'L2' => 12,
    'L1' => 4,
    _ => 0,
  };
}

String _practiceModeForQueueItem({
  required String kind,
  required InterviewExpressionNode? node,
  required String nodeId,
  required String practiceText,
  required String variantOfNodeId,
}) {
  final String seed = '$kind|$nodeId|$practiceText|$variantOfNodeId';
  switch (kind) {
    case ExpressionDailyQueueItem.kindReview:
      return _pickPracticeMode(seed, const <String>[
        ExpressionDailyQueueItem.practiceModeMeaningChoice,
        ExpressionDailyQueueItem.practiceModeIntentRecall,
        ExpressionDailyQueueItem.practiceModeChunkRecall,
        ExpressionDailyQueueItem.practiceModeFluencySprint,
      ]);
    case ExpressionDailyQueueItem.kindWeak:
      if ((node?.errors.isNotEmpty ?? false) ||
          (node?.resolvedLearningMaterial.commonMistakes.isNotEmpty ?? false)) {
        return _pickPracticeMode(seed, const <String>[
          ExpressionDailyQueueItem.practiceModeRepairChoice,
          ExpressionDailyQueueItem.practiceModeMistakeRepair,
          ExpressionDailyQueueItem.practiceModeClozeRecall,
        ]);
      }
      return _pickPracticeMode(seed, const <String>[
        ExpressionDailyQueueItem.practiceModeClozeRecall,
        ExpressionDailyQueueItem.practiceModeIntentRecall,
        ExpressionDailyQueueItem.practiceModeSlotPersonalize,
      ]);
    case ExpressionDailyQueueItem.kindVariant:
      return _pickPracticeMode(seed, const <String>[
        ExpressionDailyQueueItem.practiceModeCueChoice,
        ExpressionDailyQueueItem.practiceModeCueResponse,
        ExpressionDailyQueueItem.practiceModeVariantParaphrase,
      ]);
    case ExpressionDailyQueueItem.kindProgress:
      return _pickPracticeMode(seed, const <String>[
        ExpressionDailyQueueItem.practiceModeMeaningChoice,
        ExpressionDailyQueueItem.practiceModeClozeRecall,
        ExpressionDailyQueueItem.practiceModeIntentRecall,
        ExpressionDailyQueueItem.practiceModeSlotPersonalize,
      ]);
    case ExpressionDailyQueueItem.kindNew:
      return _pickPracticeMode(seed, const <String>[
        ExpressionDailyQueueItem.practiceModeShadow,
        ExpressionDailyQueueItem.practiceModeMeaningChoice,
        ExpressionDailyQueueItem.practiceModeEchoRecall,
        ExpressionDailyQueueItem.practiceModeChunkRecall,
      ]);
  }
  return ExpressionDailyQueueItem.practiceModeShadow;
}

String _pickPracticeMode(String seed, List<String> modes) {
  if (modes.isEmpty) {
    return ExpressionDailyQueueItem.practiceModeShadow;
  }
  final int hash = int.tryParse(_stableTextHash(seed), radix: 16) ?? 0;
  return modes[hash.abs() % modes.length];
}

String _variantProgressNodeId(String nodeId, String variantKey) {
  final String stableKey = _safeVariantStorageKey(variantKey);
  return '$nodeId#variant_$stableKey';
}

String _safeVariantStorageKey(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return 'empty';
  }
  final String safe = trimmed
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isNotEmpty && safe.length <= 40) {
    return safe;
  }
  return _stableTextHash(trimmed);
}

class _PracticeVariantCandidate {
  const _PracticeVariantCandidate({
    required this.text,
    required this.meaning,
    required this.storageKey,
  });

  final String text;
  final String meaning;
  final String storageKey;
}

class _IndexedPracticeVariant {
  const _IndexedPracticeVariant(this.variant, this.index);

  final InterviewPracticeVariant variant;
  final int index;
}

String _stableTextHash(String value) {
  int hash = 0x811c9dc5;
  for (final int codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

int _compareRankedItems(_RankedQueueItem a, _RankedQueueItem b) {
  if (identical(a, _RankedQueueItem.empty)) {
    return 1;
  }
  if (identical(b, _RankedQueueItem.empty)) {
    return -1;
  }
  final int byKind = _kindRank(a.item.kind).compareTo(_kindRank(b.item.kind));
  if (byKind != 0) {
    return byKind;
  }
  if (_priorityScoreKinds.contains(a.item.kind)) {
    final int byPriority = b.priorityScore.compareTo(a.priorityScore);
    if (byPriority != 0) {
      return byPriority;
    }
  }
  final DateTime aDue =
      a.item.priorityDueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final DateTime bDue =
      b.item.priorityDueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  final int byDue = _ascendingKinds.contains(a.item.kind)
      ? aDue.compareTo(bDue)
      : bDue.compareTo(aDue);
  if (byDue != 0) {
    return byDue;
  }
  final int byScene = a.sceneOrder.compareTo(b.sceneOrder);
  if (byScene != 0) {
    return byScene;
  }
  return a.nodeSlot.compareTo(b.nodeSlot);
}

const Set<String> _ascendingKinds = <String>{
  ExpressionDailyQueueItem.kindReview,
};

const Set<String> _priorityScoreKinds = <String>{
  ExpressionDailyQueueItem.kindWeak,
};

int _kindRank(String kind) {
  return switch (kind) {
    ExpressionDailyQueueItem.kindReview => 0,
    ExpressionDailyQueueItem.kindWeak => 1,
    ExpressionDailyQueueItem.kindVariant => 2,
    ExpressionDailyQueueItem.kindProgress => 3,
    ExpressionDailyQueueItem.kindNew => 4,
    _ => 5,
  };
}

class _RankedQueueItem {
  const _RankedQueueItem({
    required this.item,
    required this.sceneOrder,
    required this.nodeSlot,
    required this.priorityScore,
  });

  static final _RankedQueueItem empty = _RankedQueueItem(
    item: ExpressionDailyQueueItem(
      sceneId: '',
      targetLevel: '',
      nodeId: '',
      kind: '',
      practiceText: '',
      translation: '',
      sourceLabel: '',
      priorityDueAt: null,
    ),
    sceneOrder: 10000,
    nodeSlot: 10000,
    priorityScore: 0,
  );

  final ExpressionDailyQueueItem item;
  final int sceneOrder;
  final int nodeSlot;
  final int priorityScore;
}
