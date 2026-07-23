import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:speakeasy/features/goal_autopilot/goal_autopilot_models.dart';
import 'package:speakeasy/features/goal_autopilot/goal_progress_surface.dart';
import 'package:speakeasy/features/interview/expression_daily_queue_coordinator.dart';
import 'package:speakeasy/features/interview/expression_shadow_scoring.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/storage_service.dart';

class InterviewExpressionLearningResult {
  const InterviewExpressionLearningResult({
    required this.sceneId,
    required this.targetLevel,
    required this.nodeId,
    required this.practiceScene,
  });

  final String sceneId;
  final String targetLevel;
  final String nodeId;
  final bool practiceScene;
}

class InterviewExpressionLearningPage extends StatelessWidget {
  const InterviewExpressionLearningPage({
    super.key,
    required this.sceneId,
    required this.targetLevel,
    required this.nodeId,
    this.quickWarmup = false,
    this.maxCards = 0,
    this.initialTaskType = '',
  });

  final String sceneId;
  final String targetLevel;
  final String nodeId;
  final bool quickWarmup;
  final int maxCards;
  final String initialTaskType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _expressionBg,
      appBar: AppBar(
        backgroundColor: _expressionBg,
        surfaceTintColor: _expressionBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          quickWarmup ? '开口热身' : '表达成长',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: InterviewExpressionWarmupDeckView(
          sceneId: sceneId,
          targetLevel: targetLevel,
          initialNodeId: nodeId,
          quickWarmup: quickWarmup,
          maxCards: maxCards,
          initialTaskType: initialTaskType,
          showHeader: true,
          onPracticeScene: (String nodeId) {
            Navigator.of(context).pop(
              InterviewExpressionLearningResult(
                sceneId: sceneId,
                targetLevel: targetLevel,
                nodeId: nodeId,
                practiceScene: true,
              ),
            );
          },
        ),
      ),
    );
  }
}

class InterviewExpressionWarmupDeckView extends StatefulWidget {
  const InterviewExpressionWarmupDeckView({
    super.key,
    required this.sceneId,
    required this.targetLevel,
    this.initialNodeId = '',
    this.quickWarmup = false,
    this.maxCards = 0,
    this.initialTaskType = '',
    this.showHeader = false,
    this.queueItems,
    this.goalProjection,
    this.onPracticeScene,
    this.onPracticeQueueItem,
    this.onRefreshQueue,
  });

  final String sceneId;
  final String targetLevel;
  final String initialNodeId;
  final bool quickWarmup;
  final int maxCards;
  final String initialTaskType;
  final bool showHeader;
  final List<ExpressionDailyQueueItem>? queueItems;
  final GoalProgressProjection? goalProjection;
  final void Function(String nodeId)? onPracticeScene;
  final void Function(ExpressionDailyQueueItem item)? onPracticeQueueItem;
  final Future<void> Function()? onRefreshQueue;

  @override
  State<InterviewExpressionWarmupDeckView> createState() =>
      _InterviewExpressionWarmupDeckViewState();
}

class _InterviewExpressionWarmupDeckViewState
    extends State<InterviewExpressionWarmupDeckView> {
  InterviewSceneGraph? _sceneGraph;
  List<_WarmupDeckItem> _items = const <_WarmupDeckItem>[];
  int _currentIndex = 0;
  int _dailyCardSequence = 0;
  bool _loading = true;
  bool _recording = false;
  bool _processingVoice = false;
  bool _playing = false;
  bool _dailyAutoPlayEnabled = false;
  String? _recordingTaskType;
  String? _manualTaskType;
  String? _errorText;
  String _lastAttemptScoreKey = '';
  double? _lastAttemptScore;
  List<String> _personalHints = const <String>[];
  Set<String> _favoriteExpressionIds = <String>{};
  Set<String> _savingFavoriteExpressionIds = <String>{};
  double _dailyVerticalDragDistance = 0;
  double _dailyPullOffset = 0;
  bool _dailyRefreshing = false;
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTimer;
  int _targetPlaybackTicket = 0;
  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _loadFavoriteExpressionIds();
    unawaited(_load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioService = AudioServiceScope.of(context);
  }

  @override
  void didUpdateWidget(InterviewExpressionWarmupDeckView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sceneId != widget.sceneId ||
        oldWidget.targetLevel != widget.targetLevel ||
        oldWidget.initialNodeId != widget.initialNodeId ||
        oldWidget.quickWarmup != widget.quickWarmup ||
        oldWidget.initialTaskType != widget.initialTaskType ||
        oldWidget.queueItems != widget.queueItems) {
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _targetPlaybackTicket++;
    _recordingTimer?.cancel();
    unawaited(_audioService?.stopPlayback(clearRealtimeBuffer: false));
    super.dispose();
  }

  _WarmupDeckItem? get _currentItem {
    if (_items.isEmpty || _currentIndex < 0 || _currentIndex >= _items.length) {
      return null;
    }
    return _items[_currentIndex];
  }

  bool get _usesExternalQueue => widget.queueItems != null;

  void _loadFavoriteExpressionIds() {
    try {
      _favoriteExpressionIds = StorageService.instance
          .getFavoriteExpressions()
          .map((FavoriteExpressionStorageModel item) => item.id)
          .toSet();
    } catch (_) {
      _favoriteExpressionIds = <String>{};
    }
  }

  bool _isFavorite(_WarmupDeckItem item) {
    return _favoriteExpressionIds.contains(_favoriteIdForItem(item));
  }

  bool _isSavingFavorite(_WarmupDeckItem item) {
    return _savingFavoriteExpressionIds.contains(_favoriteIdForItem(item));
  }

  String _favoriteIdForItem(_WarmupDeckItem item) {
    final InterviewExpressionLearningMaterial material = item.material;
    return FavoriteExpressionStorageModel.stableId(
      sceneId: item.progressSceneId(widget.sceneId),
      targetLevel: item.progressTargetLevel,
      nodeId: item.progressNodeId,
      practiceText: material.targetExpression,
    );
  }

  FavoriteExpressionStorageModel _favoriteForItem(_WarmupDeckItem item) {
    final InterviewExpressionLearningMaterial material = item.material;
    final ExpressionDailyQueueItem? queueItem = item.queueItem;
    return FavoriteExpressionStorageModel(
      id: _favoriteIdForItem(item),
      sceneId: item.progressSceneId(widget.sceneId),
      targetLevel: item.progressTargetLevel,
      nodeId: item.progressNodeId,
      kind: queueItem?.kind ?? 'expression',
      practiceText: material.targetExpression,
      translation: material.intentCn,
      sourceLabel: queueItem?.sourceLabel ?? item.node.stageLabel,
      savedAt: DateTime.now(),
      variantOfNodeId: queueItem?.variantOfNodeId ?? '',
      contextNote: queueItem == null
          ? item.node.usage
          : _dailyExpressionContextNote(
              queueItem: queueItem,
              node: item.node,
              material: material,
            ),
    );
  }

  Future<void> _toggleFavorite(_WarmupDeckItem item) async {
    final FavoriteExpressionStorageModel favorite = _favoriteForItem(item);
    if (_savingFavoriteExpressionIds.contains(favorite.id)) {
      return;
    }
    setState(() {
      _savingFavoriteExpressionIds = <String>{
        ..._savingFavoriteExpressionIds,
        favorite.id,
      };
      _errorText = null;
    });
    try {
      final List<FavoriteExpressionStorageModel> existing = StorageService
          .instance
          .getFavoriteExpressions();
      final bool alreadySaved = existing.any(
        (FavoriteExpressionStorageModel item) => item.id == favorite.id,
      );
      final List<FavoriteExpressionStorageModel> next = alreadySaved
          ? existing
                .where(
                  (FavoriteExpressionStorageModel item) =>
                      item.id != favorite.id,
                )
                .toList(growable: false)
          : <FavoriteExpressionStorageModel>[
              favorite,
              ...existing.where(
                (FavoriteExpressionStorageModel item) => item.id != favorite.id,
              ),
            ];
      await StorageService.instance.saveFavoriteExpressions(next);
      if (!mounted) {
        return;
      }
      setState(() {
        if (alreadySaved) {
          _favoriteExpressionIds = <String>{..._favoriteExpressionIds}
            ..remove(favorite.id);
        } else {
          _favoriteExpressionIds = <String>{
            ..._favoriteExpressionIds,
            favorite.id,
          };
        }
      });
      HapticFeedback.selectionClick();
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = '收藏失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _savingFavoriteExpressionIds = <String>{
            ..._savingFavoriteExpressionIds,
          }..remove(favorite.id);
        });
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorText = null;
      _currentIndex = 0;
      _dailyCardSequence = 0;
      _dailyPullOffset = 0;
      _dailyRefreshing = false;
      _lastAttemptScoreKey = '';
      _lastAttemptScore = null;
    });
    try {
      final List<ExpressionDailyQueueItem>? queueItems = widget.queueItems;
      if (queueItems != null) {
        await _loadExternalQueue(queueItems);
        return;
      }
      final InterviewSceneGraph graph = await loadInterviewSceneGraph(
        sceneId: widget.sceneId,
      );
      final InterviewWikiStore store = InterviewWikiStore(
        sceneId: widget.sceneId,
      );
      final List<String> personalHints = _warmupPersonalHints(
        store.loadUserGrowthWiki(),
      );
      final Map<String, InterviewExpressionLearningProgress> progressByKey =
          <String, InterviewExpressionLearningProgress>{
            for (final InterviewExpressionLearningProgress progress
                in store.loadExpressionLearningProgress(
                  sourceSceneId: widget.sceneId,
                ))
              progress.key: progress,
          };
      final Set<String> masteredNodeIds = store
          .loadMasteredExpressions(sourceSceneId: widget.sceneId)
          .map(
            (InterviewPersonalWikiExpression item) =>
                item.sourceNodeId.isNotEmpty
                ? item.sourceNodeId
                : item.sourceExpressionId,
          )
          .where((String id) => id.isNotEmpty)
          .toSet();
      final List<InterviewExpressionNode> nodes = graph
          .flowNodeIdsForLevel(widget.targetLevel)
          .map(graph.nodeById)
          .whereType<InterviewExpressionNode>()
          .toList(growable: false);
      final List<_WarmupDeckItem> items = nodes
          .map((InterviewExpressionNode node) {
            final String key = InterviewExpressionLearningProgress.storageKey(
              sceneId: widget.sceneId,
              nodeId: node.id,
              targetLevel: node.targetLevel,
            );
            return _WarmupDeckItem(
              node: node,
              progress: progressByKey[key],
              mastered: masteredNodeIds.contains(node.id),
            );
          })
          .toList(growable: false);
      items.sort(_compareWarmupItem);
      if (widget.initialNodeId.trim().isNotEmpty) {
        items.sort((_WarmupDeckItem a, _WarmupDeckItem b) {
          final int aWeight = a.node.id == widget.initialNodeId ? 0 : 1;
          final int bWeight = b.node.id == widget.initialNodeId ? 0 : 1;
          if (aWeight != bWeight) {
            return aWeight.compareTo(bWeight);
          }
          return _compareWarmupItem(a, b);
        });
      }
      final int limit = widget.maxCards > 0
          ? widget.maxCards
          : widget.quickWarmup
          ? 3
          : 24;
      if (!mounted) {
        return;
      }
      setState(() {
        _sceneGraph = graph;
        _items = items.take(limit).toList(growable: false);
        _personalHints = personalHints;
        _manualTaskType = _normalizedInitialTaskType();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorText = '开口热身加载失败：$error';
      });
    }
  }

  Future<void> _loadExternalQueue(
    List<ExpressionDailyQueueItem> queueItems,
  ) async {
    final Map<String, InterviewSceneGraph> graphByScene =
        <String, InterviewSceneGraph>{};
    final Map<String, InterviewWikiStore> storeByScene =
        <String, InterviewWikiStore>{};
    final Map<String, Map<String, InterviewExpressionLearningProgress>>
    progressByScene =
        <String, Map<String, InterviewExpressionLearningProgress>>{};
    final List<_WarmupDeckItem> items = <_WarmupDeckItem>[];

    for (final ExpressionDailyQueueItem queueItem in queueItems) {
      final String sceneId = queueItem.sceneId.trim();
      if (sceneId.isEmpty) {
        continue;
      }
      final InterviewSceneGraph graph =
          graphByScene[sceneId] ??
          await loadInterviewSceneGraph(sceneId: sceneId);
      graphByScene[sceneId] = graph;
      final String graphNodeId = queueItem.variantOfNodeId.trim().isNotEmpty
          ? queueItem.variantOfNodeId.trim()
          : queueItem.nodeId.trim();
      final InterviewExpressionNode? node = graph.nodeById(graphNodeId);
      if (node == null || queueItem.practiceText.trim().isEmpty) {
        continue;
      }
      final InterviewWikiStore store =
          storeByScene[sceneId] ?? InterviewWikiStore(sceneId: sceneId);
      storeByScene[sceneId] = store;
      final Map<String, InterviewExpressionLearningProgress> progressByNode =
          progressByScene[sceneId] ??
          <String, InterviewExpressionLearningProgress>{
            for (final InterviewExpressionLearningProgress progress
                in store.loadExpressionLearningProgress(sourceSceneId: sceneId))
              progress.nodeId: progress,
          };
      progressByScene[sceneId] = progressByNode;
      items.add(
        _WarmupDeckItem(
          node: node,
          progress: progressByNode[queueItem.nodeId],
          mastered: false,
          queueItem: queueItem,
        ),
      );
    }

    final InterviewUserGrowthWiki growthWiki = storeByScene.values.isEmpty
        ? InterviewUserGrowthWiki.empty()
        : storeByScene.values.first.loadUserGrowthWiki();
    if (!mounted) {
      return;
    }
    setState(() {
      _sceneGraph = graphByScene.values.isEmpty
          ? null
          : graphByScene.values.first;
      _items = items;
      _personalHints = _warmupPersonalHints(growthWiki);
      _manualTaskType = null;
      _loading = false;
    });
  }

  Future<void> _playTarget({bool markListenDone = false}) async {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null || _playing) {
      return;
    }
    final int playbackTicket = ++_targetPlaybackTicket;
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    setState(() {
      _playing = true;
      _errorText = null;
    });
    try {
      final bool played = await audioService.playCachedTts(
        item.material.targetExpression,
        sceneId: item.progressSceneId(widget.sceneId),
        targetLevel: item.progressTargetLevel,
        nodeId: item.progressNodeId,
      );
      if (!mounted || playbackTicket != _targetPlaybackTicket) {
        return;
      }
      if (played && markListenDone) {
        await _saveProgressForCurrent(
          status: InterviewExpressionLearningStatus.learning,
          currentStep: InterviewExpressionLearningStep.shadow,
          completedStep: 'listen',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = '播放失败：$error');
      }
    } finally {
      if (mounted && playbackTicket == _targetPlaybackTicket) {
        setState(() => _playing = false);
      }
    }
  }

  Future<void> _handleDailyPlayPressed() async {
    if (_playing) {
      await _stopTargetPlayback(disableDailyAutoPlay: true);
      return;
    }
    setState(() => _dailyAutoPlayEnabled = true);
    await _playTarget(markListenDone: false);
  }

  Future<void> _stopTargetPlayback({bool disableDailyAutoPlay = false}) async {
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    _targetPlaybackTicket++;
    if (mounted) {
      setState(() {
        _playing = false;
        if (disableDailyAutoPlay) {
          _dailyAutoPlayEnabled = false;
        }
      });
    } else if (disableDailyAutoPlay) {
      _dailyAutoPlayEnabled = false;
    }
    await audioService.stopPlayback(clearRealtimeBuffer: false);
  }

  void _cancelTargetPlayback() {
    _targetPlaybackTicket++;
    final AudioService? audioService = _audioService;
    if (audioService != null) {
      unawaited(audioService.stopPlayback(clearRealtimeBuffer: false));
    }
  }

  Future<void> _handlePrimaryAction() async {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final InterviewExpressionLearningProgress progress = item.effectiveProgress(
      widget.sceneId,
    );
    final String activeTaskType = _activeTaskTypeForProgress(progress);
    if (activeTaskType == 'listen') {
      await _playTarget(markListenDone: true);
      return;
    }
    if (activeTaskType == 'shadow') {
      await _toggleRecording('shadow');
      return;
    }
    if (activeTaskType == 'slot_replace') {
      await _toggleRecording('slot_replace');
      return;
    }
    _practiceScene();
  }

  Future<void> _handleDailyPrimaryAction() async {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null) {
      return;
    }
    await _toggleRecording(
      _DailyExpressionExercise.fromItem(item).practiceMode,
    );
  }

  Future<void> _handleDailyChoiceSelected({
    required _WarmupDeckItem item,
    required _DailyExpressionExercise exercise,
    required _DailyChoiceOption choice,
  }) async {
    if (_processingVoice || item != _currentItem) {
      return;
    }
    final bool correct = choice.correct;
    final double totalScore = correct ? 100 : 0;
    final ExpressionShadowScoreResult scoreResult = ExpressionShadowScoreResult(
      totalScore: totalScore,
      textMatch: correct ? 1 : 0,
      passed: correct,
    );
    final int completedAttemptCount =
        item.effectiveProgress(widget.sceneId).attempts + 1;
    if (mounted) {
      setState(() {
        _lastAttemptScoreKey = _scoreKeyForItem(item);
        _lastAttemptScore = totalScore;
        _errorText = correct ? null : '这个选项还不对，再看题干选一次。';
      });
    }
    await _saveProgressForCurrent(
      status: correct
          ? InterviewExpressionLearningStatus.prepared
          : InterviewExpressionLearningStatus.learning,
      currentStep: InterviewExpressionLearningStep.recall,
      attemptsDelta: 1,
      bestScore: math.max(item.progress?.bestScore ?? 0, totalScore),
      lastTranscript: choice.text,
      scoreResult: scoreResult,
      completedStep: correct ? exercise.practiceMode : null,
      nextReviewAt: correct
          ? DateTime.now().add(const Duration(days: 1))
          : null,
      clearError: correct,
    );
    if (correct && _usesExternalQueue) {
      await _completeDailyQueueItem(
        item,
        choice.text,
        scoreResult: scoreResult,
        attemptCount: completedAttemptCount,
      );
    }
    if (!mounted) {
      return;
    }
    if (correct) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _toggleRecording(String taskType) async {
    if (_recording) {
      await _stopRecording();
    } else {
      await _startRecording(taskType);
    }
  }

  Future<void> _startRecording(String taskType) async {
    if (_processingVoice || _currentItem == null) {
      return;
    }
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    final bool allowed = await audioService.requestPermission();
    if (!allowed) {
      if (mounted) {
        setState(() => _errorText = '需要麦克风权限才能练习。');
      }
      return;
    }
    _targetPlaybackTicket++;
    if (mounted && _playing) {
      setState(() => _playing = false);
    }
    await audioService.stopPlayback(clearRealtimeBuffer: false);
    await audioService.startRecording();
    HapticFeedback.lightImpact();
    _recordingTimer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _recording = true;
      _recordingTaskType = taskType;
      _recordingElapsed = Duration.zero;
      _errorText = null;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _recordingElapsed += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _stopRecording() async {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final AudioService audioService =
        _audioService ?? AudioServiceScope.of(context);
    _recordingTimer?.cancel();
    setState(() {
      _recording = false;
      _processingVoice = true;
    });
    try {
      final String? path = await audioService.stopRecording();
      if (path == null || path.trim().isEmpty) {
        throw Exception('没有录到有效语音');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = '语音识别已切换为可信上传流程，当前练习暂未接入后端音频提交。';
      });
      return;
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = '识别失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingVoice = false;
          _recordingTaskType = null;
        });
      }
    }
  }

  Future<void> _saveProgressForCurrent({
    required InterviewExpressionLearningStatus status,
    required InterviewExpressionLearningStep currentStep,
    int attemptsDelta = 0,
    double? bestScore,
    String? lastTranscript,
    ExpressionShadowScoreResult? scoreResult,
    String? completedStep,
    DateTime? nextReviewAt,
    bool clearError = true,
  }) async {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final String sceneId = item.progressSceneId(widget.sceneId);
    final InterviewExpressionLearningProgress currentProgress = item
        .effectiveProgress(sceneId);
    final DateTime now = DateTime.now();
    final double? scoredTotal = scoreResult?.totalScore
        .clamp(0, 100)
        .toDouble();
    final bool isBestAttempt =
        scoredTotal != null && scoredTotal >= currentProgress.bestScore;
    InterviewExpressionLearningProgress updated = currentProgress.copyWith(
      status: status,
      currentStep: currentStep,
      attempts: currentProgress.attempts + attemptsDelta,
      bestScore: bestScore ?? item.progress?.bestScore,
      lastPracticedAt: now,
      nextReviewAt: nextReviewAt ?? item.progress?.nextReviewAt,
      lastTranscript: lastTranscript ?? item.progress?.lastTranscript,
      lastScore: scoredTotal,
      lastTextMatch: scoreResult?.textMatch.clamp(0, 1).toDouble(),
      lastPronunciationScore: scoreResult?.pronunciationScore
          ?.clamp(0, 100)
          .toDouble(),
      lastPassed: scoreResult?.passed,
      lastScoredAt: scoreResult == null ? null : now,
      bestTranscript: isBestAttempt
          ? (lastTranscript ?? currentProgress.lastTranscript)
          : null,
      bestTextMatch: isBestAttempt
          ? scoreResult!.textMatch.clamp(0, 1).toDouble()
          : null,
      bestPronunciationScore: isBestAttempt
          ? scoreResult!.pronunciationScore?.clamp(0, 100).toDouble()
          : null,
      bestScoredAt: isBestAttempt ? now : null,
    );
    if (completedStep != null) {
      updated = updated.withCompletedWarmupStep(completedStep);
      if (completedStep == 'shadow') {
        updated = updated.withCompletedWarmupStep('listen');
      }
    }
    await InterviewWikiStore(
      sceneId: sceneId,
    ).saveExpressionLearningProgress(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      if (completedStep != null) {
        _manualTaskType = null;
      }
      _items = <_WarmupDeckItem>[
        for (int index = 0; index < _items.length; index += 1)
          if (index == _currentIndex)
            _items[index].copyWith(progress: updated)
          else
            _items[index],
      ];
      if (clearError) {
        _errorText = null;
      }
    });
  }

  Future<void> _completeDailyQueueItem(
    _WarmupDeckItem item,
    String transcript, {
    required ExpressionShadowScoreResult scoreResult,
    required int attemptCount,
  }) async {
    final ExpressionDailyQueueItem? queueItem = item.queueItem;
    if (queueItem == null ||
        queueItem.kind != ExpressionDailyQueueItem.kindReview) {
      return;
    }
    final String expressionNodeId = queueItem.variantOfNodeId.isNotEmpty
        ? queueItem.variantOfNodeId
        : item.node.id;
    await InterviewWikiStore(
      sceneId: queueItem.sceneId,
    ).upsertMasteredExpression(
      expression: InterviewExpression(
        id: expressionNodeId,
        level: queueItem.targetLevel,
        levelLabel: _levelLabel(queueItem.targetLevel),
        section: item.node.stageLabel,
        text: queueItem.practiceText,
        tag: item.node.tag,
        useCase: item.node.intent,
      ),
      stage: item.node.id,
      userExample: transcript.trim().isEmpty
          ? queueItem.practiceText
          : transcript.trim(),
      performanceScore: scoreResult.totalScore,
      textMatch: scoreResult.textMatch,
      attemptCount: attemptCount,
    );
  }

  Future<void> _handleRightSwipe() async {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final InterviewExpressionLearningProgress progress = item.effectiveProgress(
      widget.sceneId,
    );
    if (!progress.hasMinimumWarmup) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已跳过，未标记热身。')));
      _goNext();
      return;
    }
    if (!progress.isPrepared && !progress.isMasteredLinked) {
      await _saveProgressForCurrent(
        status: InterviewExpressionLearningStatus.prepared,
        currentStep: InterviewExpressionLearningStep.recall,
        nextReviewAt: DateTime.now().add(const Duration(days: 1)),
      );
    }
    _goNext();
  }

  void _goNext({String finishedMessage = '这一组表达已经热身完了。'}) {
    if (_currentIndex < _items.length - 1) {
      _cancelTargetPlayback();
      setState(() {
        _currentIndex += 1;
        _manualTaskType = null;
        _playing = false;
        _errorText = null;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(finishedMessage)));
    }
  }

  void _goNextDaily() {
    if (_items.isEmpty) {
      return;
    }
    final bool shouldAutoPlayNext = _dailyAutoPlayEnabled;
    _cancelTargetPlayback();
    setState(() {
      _currentIndex = (_currentIndex + 1) % _items.length;
      _dailyCardSequence += 1;
      _manualTaskType = null;
      _playing = false;
      _errorText = null;
    });
    if (shouldAutoPlayNext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_usesExternalQueue || !_dailyAutoPlayEnabled) {
          return;
        }
        unawaited(_playTarget(markListenDone: false));
      });
    }
  }

  Future<void> _refreshDailyQueue() async {
    final Future<void> Function()? onRefreshQueue = widget.onRefreshQueue;
    if (onRefreshQueue == null) {
      if (mounted) {
        setState(() => _dailyPullOffset = 0);
      }
      return;
    }
    if (_dailyRefreshing) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _dailyRefreshing = true;
      _dailyPullOffset = 54;
      _errorText = null;
    });
    try {
      await onRefreshQueue();
    } catch (error) {
      if (mounted) {
        setState(() => _errorText = '推荐更新失败：$error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _dailyRefreshing = false;
          _dailyPullOffset = 0;
        });
      }
    }
  }

  String _scoreKeyForItem(_WarmupDeckItem item) {
    return '${item.progressSceneId(widget.sceneId)}:${item.progressNodeId}';
  }

  double? _lastAttemptScoreFor(_WarmupDeckItem item) {
    return _lastAttemptScoreKey == _scoreKeyForItem(item)
        ? _lastAttemptScore
        : null;
  }

  void _showDailyScoreDetails({
    required _WarmupDeckItem item,
    required InterviewExpressionLearningProgress progress,
    required _DailyScoreDetailKind kind,
  }) {
    final _DailyScoreDetailData data = _DailyScoreDetailData.fromProgress(
      kind: kind,
      progress: progress,
      targetExpression: item.material.targetExpression,
    );
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) {
        return _DailyScoreDetailSheet(data: data);
      },
    );
  }

  void _practiceScene() {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final ExpressionDailyQueueItem? queueItem = item.queueItem;
    if (queueItem != null && widget.onPracticeQueueItem != null) {
      widget.onPracticeQueueItem!(queueItem);
      return;
    }
    widget.onPracticeScene?.call(item.practiceSceneNodeId);
  }

  String _activeTaskTypeForProgress(
    InterviewExpressionLearningProgress progress,
  ) {
    final bool hasListen = progress.hasCompletedWarmupStep('listen');
    final bool hasShadow = progress.hasCompletedWarmupStep('shadow');
    final bool hasSlot = progress.hasCompletedWarmupStep('slot_replace');
    final String defaultTaskType = !hasListen
        ? 'listen'
        : !hasShadow
        ? 'shadow'
        : !hasSlot
        ? 'slot_replace'
        : 'scene_transfer';
    final String? manualTaskType = _manualTaskType;
    if (manualTaskType == null) {
      return defaultTaskType;
    }
    if (manualTaskType == 'listen') {
      return manualTaskType;
    }
    if (manualTaskType == 'shadow' && widget.initialTaskType == 'shadow') {
      return manualTaskType;
    }
    if (manualTaskType == 'shadow' && hasListen) {
      return manualTaskType;
    }
    if (manualTaskType == 'slot_replace' && hasShadow) {
      return manualTaskType;
    }
    if (manualTaskType == 'scene_transfer' && hasSlot) {
      return manualTaskType;
    }
    return defaultTaskType;
  }

  String? _normalizedInitialTaskType() {
    final String value = widget.initialTaskType.trim();
    if (value == 'listen' ||
        value == 'shadow' ||
        value == 'slot_replace' ||
        value == 'scene_transfer') {
      return value;
    }
    return null;
  }

  void _selectTaskType(String taskType) {
    final _WarmupDeckItem? item = _currentItem;
    if (item == null) {
      return;
    }
    final InterviewExpressionLearningProgress progress = item.effectiveProgress(
      widget.sceneId,
    );
    final String allowedTaskType = _allowedManualTaskType(progress, taskType);
    setState(() {
      _manualTaskType = allowedTaskType;
      _errorText = null;
    });
  }

  String _allowedManualTaskType(
    InterviewExpressionLearningProgress progress,
    String taskType,
  ) {
    if (taskType == 'listen') {
      return 'listen';
    }
    if (taskType == 'shadow' && progress.hasCompletedWarmupStep('listen')) {
      return 'shadow';
    }
    if (taskType == 'slot_replace' &&
        progress.hasCompletedWarmupStep('shadow')) {
      return 'slot_replace';
    }
    if (taskType == 'scene_transfer' &&
        progress.hasCompletedWarmupStep('slot_replace')) {
      return 'scene_transfer';
    }
    return _activeTaskTypeForProgress(progress);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorText != null && _items.isEmpty) {
      return _ExpressionErrorState(text: _errorText!);
    }
    if (_items.isEmpty) {
      return _usesExternalQueue
          ? const _DailyExpressionEmptyState()
          : const _ExpressionEmptyState();
    }
    final _WarmupDeckItem item = _items[_currentIndex];
    final InterviewExpressionLearningProgress progress = item.effectiveProgress(
      item.progressSceneId(widget.sceneId),
    );
    if (_usesExternalQueue) {
      final Key dailyCardKey = ValueKey<String>(
        'daily-expression-$_dailyCardSequence-'
        '${item.progressSceneId(widget.sceneId)}-${item.node.id}-'
        '${item.queueItem?.nodeId ?? ''}',
      );
      final GoalProgressProjection? projection = widget.goalProjection;
      final bool hasQueueProjection =
          projection?.fragmentFor(GoalProgressSurface.queue) != null;
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double projectionSpace = hasQueueProjection ? 96 : 0;
            final double maxCardHeight = math.max(
              0,
              constraints.maxHeight - 44 - projectionSpace,
            );
            final double cardHeight = math.min(
              maxCardHeight,
              (constraints.maxHeight * 0.88).clamp(520.0, 690.0),
            );
            final double verticalSlack = math.max(
              0,
              constraints.maxHeight - cardHeight - 36,
            );
            final double topSpacer = verticalSlack * 0.64;
            final double bottomSpacer = verticalSlack - topSpacer;
            return Column(
              children: [
                SizedBox(height: topSpacer),
                if (projection != null && hasQueueProjection) ...[
                  GoalProgressQueueSurface(projection: projection),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  height: cardHeight,
                  child: GestureDetector(
                    key: const ValueKey<String>('daily_expression_card'),
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) {
                      _dailyVerticalDragDistance = 0;
                      if (!_dailyRefreshing) {
                        setState(() => _dailyPullOffset = 0);
                      }
                    },
                    onVerticalDragUpdate: (DragUpdateDetails details) {
                      _dailyVerticalDragDistance += details.primaryDelta ?? 0;
                      if (!_dailyRefreshing) {
                        final double pullDistance = _dailyVerticalDragDistance
                            .clamp(0.0, 140.0)
                            .toDouble();
                        final double nextOffset = math.sqrt(pullDistance) * 6;
                        if (nextOffset != _dailyPullOffset) {
                          setState(() => _dailyPullOffset = nextOffset);
                        }
                      }
                    },
                    onVerticalDragEnd: (DragEndDetails details) {
                      final double velocity = details.primaryVelocity ?? 0;
                      final bool draggedUpEnough =
                          _dailyVerticalDragDistance < -96;
                      final bool draggedDownEnough =
                          _dailyVerticalDragDistance > 96;
                      _dailyVerticalDragDistance = 0;
                      if (velocity < -420 || draggedUpEnough) {
                        setState(() => _dailyPullOffset = 0);
                        HapticFeedback.selectionClick();
                        _goNextDaily();
                      } else if (velocity > 420 || draggedDownEnough) {
                        unawaited(_refreshDailyQueue());
                      } else if (_dailyPullOffset != 0) {
                        setState(() => _dailyPullOffset = 0);
                      }
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          top: 12,
                          child: _DailyRefreshIndicator(
                            progress: (_dailyPullOffset / 54).clamp(0, 1),
                            refreshing: _dailyRefreshing,
                          ),
                        ),
                        Transform.translate(
                          offset: Offset(0, _dailyPullOffset),
                          child: ClipRect(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              reverseDuration: const Duration(
                                milliseconds: 230,
                              ),
                              layoutBuilder:
                                  (
                                    Widget? currentChild,
                                    List<Widget> previousChildren,
                                  ) => Stack(
                                    clipBehavior: Clip.hardEdge,
                                    children: <Widget>[
                                      ...previousChildren,
                                      ?currentChild,
                                    ],
                                  ),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    final bool entering =
                                        child.key == dailyCardKey;
                                    final Animation<double> curved =
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: entering
                                              ? Curves.easeOutCubic
                                              : Curves.easeInCubic,
                                        );
                                    final Tween<Offset> offsetTween =
                                        Tween<Offset>(
                                          begin: entering
                                              ? const Offset(0, 1.08)
                                              : const Offset(0, -1.08),
                                          end: Offset.zero,
                                        );
                                    return SlideTransition(
                                      position: offsetTween.animate(curved),
                                      child: child,
                                    );
                                  },
                              child: _DailyExpressionCard(
                                key: dailyCardKey,
                                item: item,
                                progress: progress,
                                recording: _recording,
                                processingVoice: _processingVoice,
                                recordingElapsed: _recordingElapsed,
                                attemptScore: _lastAttemptScoreFor(item),
                                playing: _playing,
                                errorText: _errorText,
                                isFavorite: _isFavorite(item),
                                favoriteSaving: _isSavingFavorite(item),
                                onPlay: () =>
                                    unawaited(_handleDailyPlayPressed()),
                                onPrimary: () =>
                                    unawaited(_handleDailyPrimaryAction()),
                                onChoiceSelected:
                                    (
                                      _DailyExpressionExercise exercise,
                                      _DailyChoiceOption choice,
                                    ) => unawaited(
                                      _handleDailyChoiceSelected(
                                        item: item,
                                        exercise: exercise,
                                        choice: choice,
                                      ),
                                    ),
                                onPractice: _practiceScene,
                                onToggleFavorite: () =>
                                    unawaited(_toggleFavorite(item)),
                                onShowAttemptScoreDetails: () =>
                                    _showDailyScoreDetails(
                                      item: item,
                                      progress: progress,
                                      kind: _DailyScoreDetailKind.attempt,
                                    ),
                                onShowBestScoreDetails: () =>
                                    _showDailyScoreDetails(
                                      item: item,
                                      progress: progress,
                                      kind: _DailyScoreDetailKind.best,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                const _DailySwipeHint(),
                SizedBox(height: bottomSpacer),
              ],
            );
          },
        ),
      );
    }
    final String activeTaskType = _activeTaskTypeForProgress(progress);
    return Column(
      children: [
        if (widget.showHeader)
          _DeckHeader(
            title: widget.quickWarmup ? '1 分钟热嘴' : '长期表达成长',
            subtitle: _sceneGraph == null
                ? _levelLabel(widget.targetLevel)
                : '${_sceneGraph!.titleCn} · ${_levelLabel(widget.targetLevel)}',
            current: _currentIndex + 1,
            total: _items.length,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: GestureDetector(
              onHorizontalDragEnd: (DragEndDetails details) {
                final double velocity = details.primaryVelocity ?? 0;
                if (velocity > 420) {
                  unawaited(_handleRightSwipe());
                } else if (velocity < -420) {
                  _goNext();
                }
              },
              child: _ExpressionWarmupCard(
                item: item,
                progress: progress,
                activeTaskType: activeTaskType,
                personalHints: _personalHints,
                recording: _recording,
                recordingTaskType: _recordingTaskType,
                processingVoice: _processingVoice,
                recordingElapsed: _recordingElapsed,
                playing: _playing,
                errorText: _errorText,
                onPlay: () => _playTarget(markListenDone: false),
                onPrimary: _handlePrimaryAction,
                onPractice: _practiceScene,
                onSelectTaskType: _selectTaskType,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WarmupDeckItem {
  const _WarmupDeckItem({
    required this.node,
    required this.progress,
    required this.mastered,
    this.queueItem,
  });

  final InterviewExpressionNode node;
  final InterviewExpressionLearningProgress? progress;
  final bool mastered;
  final ExpressionDailyQueueItem? queueItem;

  InterviewExpressionLearningMaterial get material {
    final ExpressionDailyQueueItem? item = queueItem;
    if (item == null) {
      return node.resolvedLearningMaterial;
    }
    final InterviewExpressionLearningMaterial base =
        node.resolvedLearningMaterial;
    final String targetExpression = item.practiceText.trim().isEmpty
        ? base.targetExpression
        : item.practiceText.trim();
    return InterviewExpressionLearningMaterial(
      intentCn: item.translation.trim().isEmpty
          ? base.intentCn
          : item.translation.trim(),
      scenePrompt: base.scenePrompt,
      targetExpression: targetExpression,
      nativeNotes: base.nativeNotes,
      chunks: targetExpression == base.targetExpression
          ? base.chunks
          : const <String>[],
      commonMistakes: base.commonMistakes,
      speakingTasks: base.speakingTasks
          .map(
            (InterviewExpressionSpeakingTask task) =>
                InterviewExpressionSpeakingTask(
                  type: task.type,
                  title: task.title,
                  prompt: task.prompt,
                  targetText: targetExpression,
                  slotName: task.slotName,
                  slotExample: task.slotExample,
                ),
          )
          .toList(growable: false),
    );
  }

  String progressSceneId(String fallbackSceneId) {
    final String sceneId = queueItem?.sceneId.trim() ?? '';
    return sceneId.isEmpty ? fallbackSceneId : sceneId;
  }

  String get progressNodeId {
    final String nodeId = queueItem?.nodeId.trim() ?? '';
    return nodeId.isEmpty ? node.id : nodeId;
  }

  String get progressTargetLevel {
    final String targetLevel = queueItem?.targetLevel.trim() ?? '';
    return targetLevel.isEmpty ? node.targetLevel : targetLevel;
  }

  String get practiceSceneNodeId {
    final String variantOfNodeId = queueItem?.variantOfNodeId.trim() ?? '';
    return variantOfNodeId.isEmpty ? node.id : variantOfNodeId;
  }

  _WarmupDeckItem copyWith({InterviewExpressionLearningProgress? progress}) {
    return _WarmupDeckItem(
      node: node,
      progress: progress ?? this.progress,
      mastered: mastered,
      queueItem: queueItem,
    );
  }

  InterviewExpressionLearningProgress effectiveProgress(String sceneId) {
    return progress ??
        InterviewExpressionLearningProgress(
          sceneId: sceneId,
          nodeId: progressNodeId,
          targetLevel: progressTargetLevel,
        );
  }
}

int _compareWarmupItem(_WarmupDeckItem a, _WarmupDeckItem b) {
  int weight(_WarmupDeckItem item) {
    if (item.mastered ||
        item.progress?.status ==
            InterviewExpressionLearningStatus.masteredLinked) {
      return 5;
    }
    if (item.progress?.status == InterviewExpressionLearningStatus.dueReview) {
      return 0;
    }
    if (item.progress?.status == InterviewExpressionLearningStatus.learning) {
      return 1;
    }
    if (item.progress?.status == InterviewExpressionLearningStatus.prepared) {
      return 3;
    }
    return 2;
  }

  final int byWeight = weight(a).compareTo(weight(b));
  if (byWeight != 0) {
    return byWeight;
  }
  return a.node.slot.compareTo(b.node.slot);
}

const Color _expressionBg = Color(0xFFFCFAF5);
const Color _expressionCard = Color(0xFFFFFFFF);
const Color _expressionText = Color(0xFF20231F);
const Color _expressionMuted = Color(0xFF878B83);
const Color _expressionGreen = Color(0xFF315A3A);
const Color _expressionLine = Color(0xFFE8E4DB);
const Color _expressionGold = Color(0xFFC99A4A);

String _levelLabel(String targetLevel) {
  return switch (targetLevel) {
    'intermediate' || 'L2' => 'L2 进阶',
    'advanced' || 'L3' => 'L3 精通',
    _ => 'L1 入门',
  };
}

List<String> _warmupPersonalHints(InterviewUserGrowthWiki wiki) {
  final List<String> candidates = <String>[
    ...wiki.personalFacts.map((InterviewCompiledWikiItem item) => item.body),
    ...wiki.personalFacts.map((InterviewCompiledWikiItem item) => item.title),
    ...wiki.interviewStories.map((InterviewCompiledWikiItem item) => item.body),
    ...wiki.interviewStories.map(
      (InterviewCompiledWikiItem item) => item.title,
    ),
    ...wiki.evidenceRefs.map((InterviewLearningEvidenceRef item) => item.text),
  ];
  final List<String> result = <String>[];
  for (final String value in candidates) {
    final String hint = _compactWarmupHint(value);
    if (hint.isEmpty || result.contains(hint)) {
      continue;
    }
    result.add(hint);
    if (result.length >= 3) {
      break;
    }
  }
  return result;
}

String _compactWarmupHint(String value) {
  String text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) {
    return '';
  }
  final List<String> parts = text.split(RegExp(r'[。.!?；;]'));
  if (parts.isNotEmpty && parts.first.trim().length >= 3) {
    text = parts.first.trim();
  }
  if (text.length > 34) {
    text = '${text.substring(0, 34).trim()}...';
  }
  return text;
}

String _slotPattern(
  String expression,
  InterviewExpressionSpeakingTask task,
  InterviewExpressionNode node,
) {
  final List<String> examples = <String>[
    task.slotExample,
    ...node.slots.map((InterviewExpressionSlot item) => item.example),
  ].where((String value) => value.trim().isNotEmpty).toList(growable: false);
  for (final String example in examples) {
    final RegExp pattern = RegExp(RegExp.escape(example), caseSensitive: false);
    if (pattern.hasMatch(expression)) {
      return expression.replaceFirst(pattern, '______');
    }
  }
  final String slotName = task.slotName.trim().isNotEmpty
      ? task.slotName.trim()
      : node.slots.isNotEmpty
      ? node.slots.first.name
      : '一个信息';
  return '$expression\n\n把 $slotName 换成你的真实信息。';
}

List<String> _slotSuggestions(
  InterviewExpressionSpeakingTask task,
  InterviewExpressionNode node,
  List<String> personalHints,
) {
  final List<String> candidates = <String>[
    ...personalHints,
    task.slotExample,
    ...node.slots.map((InterviewExpressionSlot item) => item.example),
    'making a quick plan',
    'focusing on priorities',
    'asking the right person for help',
  ];
  final List<String> result = <String>[];
  for (final String value in candidates) {
    final String cleaned = _compactWarmupHint(value);
    if (cleaned.isEmpty || result.contains(cleaned)) {
      continue;
    }
    result.add(cleaned);
    if (result.length >= 4) {
      break;
    }
  }
  return result;
}

class _DeckHeader extends StatelessWidget {
  const _DeckHeader({
    required this.title,
    required this.subtitle,
    required this.current,
    required this.total,
  });

  final String title;
  final String subtitle;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _expressionText,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _expressionMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _ExpressionTag(label: '$current/$total'),
        ],
      ),
    );
  }
}

class _ExpressionWarmupCard extends StatelessWidget {
  const _ExpressionWarmupCard({
    required this.item,
    required this.progress,
    required this.activeTaskType,
    required this.personalHints,
    required this.recording,
    required this.recordingTaskType,
    required this.processingVoice,
    required this.recordingElapsed,
    required this.playing,
    required this.errorText,
    required this.onPlay,
    required this.onPrimary,
    required this.onPractice,
    required this.onSelectTaskType,
  });

  final _WarmupDeckItem item;
  final InterviewExpressionLearningProgress progress;
  final String activeTaskType;
  final List<String> personalHints;
  final bool recording;
  final String? recordingTaskType;
  final bool processingVoice;
  final Duration recordingElapsed;
  final bool playing;
  final String? errorText;
  final VoidCallback onPlay;
  final VoidCallback onPrimary;
  final VoidCallback onPractice;
  final ValueChanged<String> onSelectTaskType;

  @override
  Widget build(BuildContext context) {
    final InterviewExpressionLearningMaterial material = item.material;
    final bool hasListen = progress.hasCompletedWarmupStep('listen');
    final bool hasShadow = progress.hasCompletedWarmupStep('shadow');
    final bool hasSlot = progress.hasCompletedWarmupStep('slot_replace');
    final InterviewExpressionSpeakingTask task = material.taskFor(
      activeTaskType,
    );
    final String title = task.title.isEmpty
        ? switch (activeTaskType) {
            'listen' => '听一句',
            'shadow' => '跟说一次',
            'slot_replace' => '换成自己的信息',
            _ => '去模拟里用',
          }
        : _displayTaskTitle(activeTaskType, task.title);
    final String prompt = _displayTaskPrompt(activeTaskType, task.prompt);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _expressionCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _expressionLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D2F2A1D),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExpressionProgressStrip(
            hasListen: hasListen,
            hasShadow: hasShadow,
            hasSlot: hasSlot,
            activeTaskType: activeTaskType,
            onSelect: onSelectTaskType,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _ExpressionTag(label: item.node.stageLabel),
              const SizedBox(width: 8),
              if (progress.isPrepared || progress.isMasteredLinked)
                const _ExpressionTag(label: '已热身'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: _expressionText,
              fontSize: 24,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            prompt.isEmpty ? '用英语自然完成这一步表达。' : prompt,
            style: const TextStyle(
              color: _expressionMuted,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          _StepContent(
            activeTaskType: activeTaskType,
            material: material,
            node: item.node,
            progress: progress,
            personalHints: personalHints,
            playing: playing,
            onPlay: activeTaskType == 'listen' ? onPrimary : onPlay,
          ),
          const Spacer(),
          if (errorText != null) ...[
            Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFF9D463F),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (progress.lastTranscript.isNotEmpty) ...[
            _TranscriptBox(text: progress.lastTranscript),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (activeTaskType != 'listen') ...[
                _SmallExpressionAction(
                  icon: playing ? Icons.graphic_eq_rounded : Icons.play_arrow,
                  label: playing ? '播放中' : '播放',
                  onTap: onPlay,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _PrimaryExpressionButton(
                  label: _primaryLabel(
                    activeTaskType: activeTaskType,
                    recording: recording,
                    recordingTaskType: recordingTaskType,
                    processingVoice: processingVoice,
                    recordingElapsed: recordingElapsed,
                  ),
                  icon: _primaryIcon(
                    activeTaskType,
                    recording,
                    processingVoice,
                  ),
                  onPressed: processingVoice ? null : onPrimary,
                ),
              ),
            ],
          ),
          if (hasShadow && activeTaskType != 'scene_transfer') ...[
            const SizedBox(height: 10),
            _SecondaryExpressionButton(
              label: '去模拟里用',
              icon: Icons.play_arrow_rounded,
              onPressed: onPractice,
            ),
          ],
          const SizedBox(height: 10),
          const Text(
            '右滑：已热身并下一张 · 左滑：稍后再练',
            style: TextStyle(
              color: _expressionMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyExpressionCard extends StatefulWidget {
  const _DailyExpressionCard({
    super.key,
    required this.item,
    required this.progress,
    required this.recording,
    required this.processingVoice,
    required this.recordingElapsed,
    required this.attemptScore,
    required this.playing,
    required this.errorText,
    required this.isFavorite,
    required this.favoriteSaving,
    required this.onPlay,
    required this.onPrimary,
    required this.onChoiceSelected,
    required this.onPractice,
    required this.onToggleFavorite,
    required this.onShowAttemptScoreDetails,
    required this.onShowBestScoreDetails,
  });

  final _WarmupDeckItem item;
  final InterviewExpressionLearningProgress progress;
  final bool recording;
  final bool processingVoice;
  final Duration recordingElapsed;
  final double? attemptScore;
  final bool playing;
  final String? errorText;
  final bool isFavorite;
  final bool favoriteSaving;
  final VoidCallback onPlay;
  final VoidCallback onPrimary;
  final void Function(_DailyExpressionExercise, _DailyChoiceOption)
  onChoiceSelected;
  final VoidCallback onPractice;
  final VoidCallback onToggleFavorite;
  final VoidCallback onShowAttemptScoreDetails;
  final VoidCallback onShowBestScoreDetails;

  @override
  State<_DailyExpressionCard> createState() => _DailyExpressionCardState();
}

class _DailyExpressionCardState extends State<_DailyExpressionCard> {
  bool _answerVisible = false;
  String _selectedChoiceId = '';

  @override
  void didUpdateWidget(_DailyExpressionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.progressNodeId != widget.item.progressNodeId ||
        oldWidget.item.queueItem?.practiceMode !=
            widget.item.queueItem?.practiceMode) {
      _answerVisible = false;
      _selectedChoiceId = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final _WarmupDeckItem item = widget.item;
    final InterviewExpressionLearningProgress progress = widget.progress;
    final bool recording = widget.recording;
    final bool processingVoice = widget.processingVoice;
    final Duration recordingElapsed = widget.recordingElapsed;
    final double? attemptScore = widget.attemptScore;
    final bool playing = widget.playing;
    final String? errorText = widget.errorText;
    final bool isFavorite = widget.isFavorite;
    final bool favoriteSaving = widget.favoriteSaving;
    final VoidCallback onPlay = widget.onPlay;
    final VoidCallback onPrimary = widget.onPrimary;
    final void Function(_DailyExpressionExercise, _DailyChoiceOption)
    onChoiceSelected = widget.onChoiceSelected;
    final VoidCallback onPractice = widget.onPractice;
    final VoidCallback onToggleFavorite = widget.onToggleFavorite;
    final VoidCallback onShowAttemptScoreDetails =
        widget.onShowAttemptScoreDetails;
    final VoidCallback onShowBestScoreDetails = widget.onShowBestScoreDetails;
    final ExpressionDailyQueueItem queueItem = item.queueItem!;
    final _DailyExpressionExercise exercise = _DailyExpressionExercise.fromItem(
      item,
    );
    final bool hasChoices = exercise.hasChoices;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18292218),
            blurRadius: 28,
            spreadRadius: -8,
            offset: Offset(0, 18),
          ),
          BoxShadow(
            color: Color(0x10FFFFFF),
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/expression_card_bg.png',
              key: const ValueKey<String>('daily_expression_card_background'),
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder:
                  (
                    BuildContext context,
                    Object error,
                    StackTrace? stackTrace,
                  ) => const ColoredBox(color: _expressionCard),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xDDF8FAF0),
                    Color(0xBBFFF8DD),
                    Color(0xF8FFFDF5),
                  ],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _DailyModeHeader(
                          icon: exercise.icon,
                          modeLabel: exercise.modeLabel,
                          kindLabel: _dailyKindLabel(queueItem.kind),
                          sourceLabel: queueItem.sourceLabel,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _DailyTopIconButton(
                        onPressed: onPractice,
                        tooltip: '进入场景练习',
                        icon: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DailyTopIconButton(
                        key: const ValueKey<String>(
                          'daily_expression_favorite_button',
                        ),
                        onPressed: favoriteSaving ? null : onToggleFavorite,
                        tooltip: isFavorite ? '取消收藏' : '收藏表达',
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 20,
                        ),
                        color: isFavorite ? const Color(0xFFE06B6B) : null,
                      ),
                    ],
                  ),
                  SizedBox(height: hasChoices ? 18 : 32),
                  _DailyPromptStage(
                    exercise: exercise,
                    answerVisible: _answerVisible,
                    selectedChoiceId: _selectedChoiceId,
                    onToggleAnswer: () {
                      setState(() => _answerVisible = !_answerVisible);
                    },
                    onChoiceSelected: (_DailyChoiceOption choice) {
                      setState(() => _selectedChoiceId = choice.id);
                      onChoiceSelected(exercise, choice);
                    },
                  ),
                  const Spacer(),
                  if (errorText != null) ...[
                    _DailyErrorBanner(text: errorText),
                    const SizedBox(height: 12),
                  ],
                  if (!hasChoices) ...[
                    _DailyExpressionScoreStrip(
                      attemptScore: attemptScore,
                      bestScore: progress.bestScore,
                      onAttemptTap: onShowAttemptScoreDetails,
                      onBestTap: onShowBestScoreDetails,
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (hasChoices)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DailySecondaryButton(
                          key: const ValueKey<String>(
                            'daily_expression_play_button',
                          ),
                          icon: playing
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_rounded,
                          label: playing ? '播放中' : exercise.playLabel,
                          onPressed: onPlay,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DailyChoiceStatusButton(
                            selectedChoice: exercise.choiceById(
                              _selectedChoiceId,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _DailySecondaryButton(
                          key: const ValueKey<String>(
                            'daily_expression_play_button',
                          ),
                          icon: playing
                              ? Icons.graphic_eq_rounded
                              : Icons.volume_up_rounded,
                          label: playing ? '播放中' : exercise.playLabel,
                          onPressed: onPlay,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DailyPrimaryButton(
                            key: const ValueKey<String>(
                              'daily_expression_shadow_button',
                            ),
                            recording: recording,
                            processingVoice: processingVoice,
                            recordingElapsed: recordingElapsed,
                            idleLabel: exercise.primaryLabel,
                            onPressed: processingVoice ? null : onPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyModeHeader extends StatelessWidget {
  const _DailyModeHeader({
    required this.icon,
    required this.modeLabel,
    required this.kindLabel,
    required this.sourceLabel,
  });

  final IconData icon;
  final String modeLabel;
  final String kindLabel;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF2F6840),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24315A3A),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 23, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      modeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _expressionText,
                        fontSize: 18,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (kindLabel.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _DailyMiniKindPill(label: kindLabel),
                  ],
                ],
              ),
              const SizedBox(height: 7),
              Text(
                sourceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _expressionMuted,
                  fontSize: 12.2,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyMiniKindPill extends StatelessWidget {
  const _DailyMiniKindPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFDD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _expressionGreen,
          fontSize: 10.5,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DailyTopIconButton extends StatelessWidget {
  const _DailyTopIconButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.color,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final Widget icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: icon,
      color: color ?? _expressionGreen,
      disabledColor: _expressionMuted.withValues(alpha: 0.45),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.8)),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
    );
  }
}

class _DailyPromptStage extends StatelessWidget {
  const _DailyPromptStage({
    required this.exercise,
    required this.answerVisible,
    required this.selectedChoiceId,
    required this.onToggleAnswer,
    required this.onChoiceSelected,
  });

  final _DailyExpressionExercise exercise;
  final bool answerVisible;
  final String selectedChoiceId;
  final VoidCallback onToggleAnswer;
  final ValueChanged<_DailyChoiceOption> onChoiceSelected;

  @override
  Widget build(BuildContext context) {
    final bool hasChoices = exercise.hasChoices;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: hasChoices ? 148 : 176,
          decoration: BoxDecoration(
            color: _expressionGreen,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.headerLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _expressionGreen,
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: hasChoices ? 9 : 13),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: hasChoices ? 82 : 156),
                child: _DailyFittingText(
                  key: const ValueKey<String>('daily_expression_target_text'),
                  text: exercise.promptText,
                  maxFontSize: exercise.promptMaxFontSize,
                  minFontSize: hasChoices ? 12.5 : 13,
                  style: const TextStyle(
                    color: _expressionText,
                    height: 1.08,
                    fontFamily: 'Georgia',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (exercise.chips.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DailyExerciseChips(chips: exercise.chips),
              ],
              if (hasChoices) ...[
                const SizedBox(height: 10),
                _DailyChoiceList(
                  choices: exercise.choices,
                  selectedChoiceId: selectedChoiceId,
                  onSelected: onChoiceSelected,
                ),
              ],
              if (!hasChoices) ...[
                const SizedBox(height: 14),
                Text(
                  exercise.supportingText,
                  key: const ValueKey<String>(
                    'daily_expression_translation_text',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _expressionMuted,
                    fontSize: 13,
                    height: 1.32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (exercise.hidesAnswer) ...[
                const SizedBox(height: 10),
                _DailyAnswerReveal(
                  answer: exercise.answerText,
                  visible: answerVisible,
                  onToggle: onToggleAnswer,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyErrorBanner extends StatelessWidget {
  const _DailyErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9DF).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8A091).withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF9D463F),
          fontSize: 12.3,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DailyChoiceOption {
  const _DailyChoiceOption({
    required this.id,
    required this.text,
    required this.correct,
  });

  final String id;
  final String text;
  final bool correct;
}

class _DailyChoiceList extends StatelessWidget {
  const _DailyChoiceList({
    required this.choices,
    required this.selectedChoiceId,
    required this.onSelected,
  });

  final List<_DailyChoiceOption> choices;
  final String selectedChoiceId;
  final ValueChanged<_DailyChoiceOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < choices.length; index += 1) ...[
          if (index > 0) const SizedBox(height: 7),
          _DailyChoiceTile(
            option: choices[index],
            index: index,
            selected: choices[index].id == selectedChoiceId,
            onTap: () => onSelected(choices[index]),
          ),
        ],
      ],
    );
  }
}

class _DailyChoiceTile extends StatelessWidget {
  const _DailyChoiceTile({
    required this.option,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final _DailyChoiceOption option;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = !selected
        ? Colors.white.withValues(alpha: 0.8)
        : option.correct
        ? _expressionGreen
        : const Color(0xFFE07C6B);
    final Color fillColor = !selected
        ? Colors.white.withValues(alpha: 0.58)
        : option.correct
        ? const Color(0xFFEAF3DF)
        : const Color(0xFFFFECE5);
    return Material(
      color: fillColor,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        key: ValueKey<String>('daily_expression_choice_${option.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? borderColor.withValues(alpha: 0.14)
                      : const Color(0xFFF0F2E8),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: selected ? borderColor : _expressionMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _expressionText,
                    fontSize: 12.2,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 7),
                Icon(
                  option.correct
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  size: 17,
                  color: borderColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyChoiceStatusButton extends StatelessWidget {
  const _DailyChoiceStatusButton({required this.selectedChoice});

  final _DailyChoiceOption? selectedChoice;

  @override
  Widget build(BuildContext context) {
    final _DailyChoiceOption? choice = selectedChoice;
    final String label = choice == null
        ? '点选答案'
        : choice.correct
        ? '回答正确'
        : '再选一次';
    final IconData icon = choice == null
        ? Icons.touch_app_rounded
        : choice.correct
        ? Icons.check_rounded
        : Icons.refresh_rounded;
    final Color start = choice == null
        ? const Color(0xFF6E7E56)
        : choice.correct
        ? const Color(0xFF426E3F)
        : const Color(0xFFB56852);
    final Color end = choice == null
        ? const Color(0xFF4F6842)
        : choice.correct
        ? const Color(0xFF275632)
        : const Color(0xFF934B3F);
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: [start, end]),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25315A3A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyFittingText extends StatelessWidget {
  const _DailyFittingText({
    super.key,
    required this.text,
    required this.style,
    required this.maxFontSize,
    required this.minFontSize,
  });

  final String text;
  final TextStyle style;
  final double maxFontSize;
  final double minFontSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final double maxHeight = constraints.maxHeight;
        final TextDirection direction = Directionality.of(context);
        double resolvedSize = maxFontSize;
        if (maxWidth > 0 && maxHeight.isFinite && maxHeight > 0) {
          double low = minFontSize;
          double high = maxFontSize;
          for (int i = 0; i < 10; i += 1) {
            final double mid = (low + high) / 2;
            final TextPainter painter = TextPainter(
              text: TextSpan(
                text: text,
                style: style.copyWith(fontSize: mid),
              ),
              textAlign: TextAlign.left,
              textDirection: direction,
            )..layout(maxWidth: maxWidth);
            if (painter.height <= maxHeight) {
              low = mid;
            } else {
              high = mid;
            }
          }
          resolvedSize = low;
        }
        return Text(
          text,
          textAlign: TextAlign.left,
          softWrap: true,
          overflow: TextOverflow.visible,
          style: style.copyWith(fontSize: resolvedSize),
        );
      },
    );
  }
}

class _DailyRefreshIndicator extends StatelessWidget {
  const _DailyRefreshIndicator({
    required this.progress,
    required this.refreshing,
  });

  final double progress;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final double opacity = refreshing ? 1 : progress.clamp(0, 1).toDouble();
    return Opacity(
      key: const ValueKey<String>('daily_expression_refresh_indicator'),
      opacity: opacity,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          shape: BoxShape.circle,
          border: Border.all(color: _expressionLine.withValues(alpha: 0.8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x102F2A1D),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: refreshing
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_expressionGreen),
                ),
              )
            : Transform.rotate(
                angle: progress.clamp(0, 1).toDouble() * math.pi,
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _expressionGreen,
                ),
              ),
      ),
    );
  }
}

class _DailySwipeHint extends StatelessWidget {
  const _DailySwipeHint();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey<String>('daily_expression_swipe_hint'),
      label: '上滑下一条',
      child: Icon(
        Icons.keyboard_double_arrow_up_rounded,
        size: 27,
        color: _expressionMuted.withValues(alpha: 0.7),
      ),
    );
  }
}

class _DailyExpressionExercise {
  const _DailyExpressionExercise({
    required this.practiceMode,
    required this.modeLabel,
    required this.headerLabel,
    required this.promptText,
    required this.supportingText,
    required this.answerText,
    required this.primaryLabel,
    required this.playLabel,
    required this.scoringTargets,
    required this.icon,
    this.choices = const <_DailyChoiceOption>[],
    this.hidesAnswer = false,
    this.promptMaxFontSize = 23.5,
    this.chips = const <String>[],
  });

  final String practiceMode;
  final String modeLabel;
  final String headerLabel;
  final String promptText;
  final String supportingText;
  final String answerText;
  final String primaryLabel;
  final String playLabel;
  final List<String> scoringTargets;
  final IconData icon;
  final List<_DailyChoiceOption> choices;
  final bool hidesAnswer;
  final double promptMaxFontSize;
  final List<String> chips;

  bool get hasChoices => choices.isNotEmpty;

  _DailyChoiceOption? choiceById(String id) {
    for (final _DailyChoiceOption choice in choices) {
      if (choice.id == id) {
        return choice;
      }
    }
    return null;
  }

  factory _DailyExpressionExercise.fromItem(_WarmupDeckItem item) {
    final ExpressionDailyQueueItem? queueItem = item.queueItem;
    final InterviewExpressionLearningMaterial material = item.material;
    final String target = material.targetExpression.trim();
    final String mode = _normalizeDailyPracticeMode(
      queueItem?.practiceMode ?? '',
    );
    final List<String> chunks = _dailyExerciseChunks(material, target);
    final String intentText = _firstNonEmpty(<String>[
      material.intentCn,
      item.node.meaning,
      item.node.intent,
      '练习这句在当前场景里的自然说法。',
    ]);
    final List<String> scoringTargets = _dailyExerciseScoringTargets(
      item: item,
      target: target,
      mode: mode,
    );
    _DailyExpressionExercise base({
      required String resolvedMode,
      required String modeLabel,
      required String headerLabel,
      required String promptText,
      required String supportingText,
      required String primaryLabel,
      String playLabel = '听答案',
      bool hidesAnswer = false,
      double promptMaxFontSize = 23.5,
      List<String> chips = const <String>[],
      List<_DailyChoiceOption> choices = const <_DailyChoiceOption>[],
    }) {
      return _DailyExpressionExercise(
        practiceMode: resolvedMode,
        modeLabel: modeLabel,
        headerLabel: headerLabel,
        promptText: promptText.trim().isEmpty ? target : promptText.trim(),
        supportingText: supportingText.trim().isEmpty
            ? intentText
            : supportingText.trim(),
        answerText: target,
        primaryLabel: primaryLabel,
        playLabel: playLabel,
        scoringTargets: scoringTargets,
        icon: _dailyExerciseIconForMode(resolvedMode),
        choices: choices,
        hidesAnswer: hidesAnswer,
        promptMaxFontSize: promptMaxFontSize,
        chips: chips,
      );
    }

    switch (mode) {
      case ExpressionDailyQueueItem.practiceModeMeaningChoice:
        return base(
          resolvedMode: mode,
          modeLabel: '选自然表达',
          headerLabel: '选择最自然的一句',
          promptText: intentText,
          supportingText: '不用开口，先判断哪一句最适合这个意思。',
          primaryLabel: '点选答案',
          playLabel: '听答案',
          promptMaxFontSize: 18.5,
          choices: _dailyChoiceOptions(
            target: target,
            node: item.node,
            mode: mode,
          ),
        );
      case ExpressionDailyQueueItem.practiceModeCueChoice:
        return base(
          resolvedMode: mode,
          modeLabel: '选择回应',
          headerLabel: '面试官说',
          promptText: _dailyCuePrompt(item.node, material),
          supportingText: '从下面选出最适合接上的一句。',
          primaryLabel: '点选答案',
          playLabel: '听答案',
          promptMaxFontSize: 17.5,
          choices: _dailyChoiceOptions(
            target: target,
            node: item.node,
            mode: mode,
          ),
        );
      case ExpressionDailyQueueItem.practiceModeRepairChoice:
        return base(
          resolvedMode: mode,
          modeLabel: '选正确版',
          headerLabel: '哪一句更自然',
          promptText: _dailyMistakePrompt(material, item.node),
          supportingText: '看清错误点，选出自然正确的表达。',
          primaryLabel: '点选答案',
          playLabel: '听答案',
          promptMaxFontSize: 17.5,
          choices: _dailyChoiceOptions(
            target: target,
            node: item.node,
            mode: mode,
          ),
        );
      case ExpressionDailyQueueItem.practiceModeEchoRecall:
        return base(
          resolvedMode: mode,
          modeLabel: '听后复述',
          headerLabel: '先听再说',
          promptText: '先点播放，听完后不看英文复述完整句。',
          supportingText: intentText,
          primaryLabel: '开始复述',
          hidesAnswer: true,
          promptMaxFontSize: 20,
        );
      case ExpressionDailyQueueItem.practiceModeClozeRecall:
        return base(
          resolvedMode: mode,
          modeLabel: '表达填空',
          headerLabel: '补全表达',
          promptText: _dailyClozeText(target, chunks),
          supportingText: '说出完整句，不只说空格里的部分。',
          primaryLabel: '说完整句',
          hidesAnswer: true,
          promptMaxFontSize: 22,
        );
      case ExpressionDailyQueueItem.practiceModeIntentRecall:
        return base(
          resolvedMode: mode,
          modeLabel: '意图回忆',
          headerLabel: '看到意思说英文',
          promptText: intentText,
          supportingText: '不要照着英文读，先从中文意图把表达想起来。',
          primaryLabel: '说英文',
          hidesAnswer: true,
          promptMaxFontSize: 20,
        );
      case ExpressionDailyQueueItem.practiceModeCueResponse:
        return base(
          resolvedMode: mode,
          modeLabel: '接下句',
          headerLabel: '面试官说',
          promptText: _dailyCuePrompt(item.node, material),
          supportingText: '你接一句自然回应，把目标表达说出来。',
          primaryLabel: '接一句',
          hidesAnswer: true,
          promptMaxFontSize: 18.5,
        );
      case ExpressionDailyQueueItem.practiceModeChunkRecall:
        return base(
          resolvedMode: mode,
          modeLabel: '短语背诵',
          headerLabel: '看提示背句子',
          promptText: intentText,
          supportingText: '根据关键词提示，把完整表达背出来。',
          primaryLabel: '背出来',
          hidesAnswer: true,
          promptMaxFontSize: 18.5,
          chips: _dailyKeywordHints(target, chunks),
        );
      case ExpressionDailyQueueItem.practiceModeSlotPersonalize:
        return base(
          resolvedMode: mode,
          modeLabel: '替换槽位',
          headerLabel: '换成你的信息',
          promptText: _slotPattern(
            target,
            material.taskFor('slot_replace'),
            item.node,
          ),
          supportingText: '保留句子主干，把一个信息换成你的真实经历或岗位。',
          primaryLabel: '替换后说',
          promptMaxFontSize: 19,
        );
      case ExpressionDailyQueueItem.practiceModeMistakeRepair:
        return base(
          resolvedMode: mode,
          modeLabel: '纠错复现',
          headerLabel: '把错误修自然',
          promptText: _dailyMistakePrompt(material, item.node),
          supportingText: '先理解错误点，再说出自然正确版本。',
          primaryLabel: '说正确版',
          hidesAnswer: true,
          promptMaxFontSize: 18.5,
        );
      case ExpressionDailyQueueItem.practiceModeVariantParaphrase:
        return base(
          resolvedMode: mode,
          modeLabel: '变体改写',
          headerLabel: '换一种说法',
          promptText: _dailyVariantPrompt(item.node, target),
          supportingText: '表达同一个意图，但不要只重复基础句。',
          primaryLabel: '说变体',
          hidesAnswer: true,
          promptMaxFontSize: 18.5,
        );
      case ExpressionDailyQueueItem.practiceModeFluencySprint:
        return base(
          resolvedMode: mode,
          modeLabel: '流利挑战',
          headerLabel: '一口气说顺',
          promptText: target,
          supportingText: '尽量连贯、少停顿地说完整句。',
          primaryLabel: '开始挑战',
          playLabel: '播放',
          promptMaxFontSize: 22,
        );
      case ExpressionDailyQueueItem.practiceModeShadow:
      default:
        return base(
          resolvedMode: ExpressionDailyQueueItem.practiceModeShadow,
          modeLabel: '跟读',
          headerLabel: '目标表达',
          promptText: target,
          supportingText: intentText,
          primaryLabel: '跟读',
          playLabel: '播放',
        );
    }
  }
}

String _normalizeDailyPracticeMode(String mode) {
  final String value = mode.trim();
  const Set<String> supported = <String>{
    ExpressionDailyQueueItem.practiceModeShadow,
    ExpressionDailyQueueItem.practiceModeEchoRecall,
    ExpressionDailyQueueItem.practiceModeClozeRecall,
    ExpressionDailyQueueItem.practiceModeIntentRecall,
    ExpressionDailyQueueItem.practiceModeCueResponse,
    ExpressionDailyQueueItem.practiceModeChunkRecall,
    ExpressionDailyQueueItem.practiceModeSlotPersonalize,
    ExpressionDailyQueueItem.practiceModeMistakeRepair,
    ExpressionDailyQueueItem.practiceModeVariantParaphrase,
    ExpressionDailyQueueItem.practiceModeFluencySprint,
    ExpressionDailyQueueItem.practiceModeMeaningChoice,
    ExpressionDailyQueueItem.practiceModeCueChoice,
    ExpressionDailyQueueItem.practiceModeRepairChoice,
  };
  return supported.contains(value)
      ? value
      : ExpressionDailyQueueItem.practiceModeShadow;
}

IconData _dailyExerciseIconForMode(String mode) {
  return switch (mode) {
    ExpressionDailyQueueItem.practiceModeMeaningChoice => Icons.rule_rounded,
    ExpressionDailyQueueItem.practiceModeCueChoice => Icons.fact_check_rounded,
    ExpressionDailyQueueItem.practiceModeRepairChoice =>
      Icons.check_circle_rounded,
    ExpressionDailyQueueItem.practiceModeEchoRecall => Icons.hearing_rounded,
    ExpressionDailyQueueItem.practiceModeClozeRecall => Icons.space_bar_rounded,
    ExpressionDailyQueueItem.practiceModeIntentRecall =>
      Icons.translate_rounded,
    ExpressionDailyQueueItem.practiceModeCueResponse => Icons.forum_rounded,
    ExpressionDailyQueueItem.practiceModeChunkRecall => Icons.style_rounded,
    ExpressionDailyQueueItem.practiceModeSlotPersonalize => Icons.tune_rounded,
    ExpressionDailyQueueItem.practiceModeMistakeRepair =>
      Icons.construction_rounded,
    ExpressionDailyQueueItem.practiceModeVariantParaphrase =>
      Icons.auto_awesome_motion_rounded,
    ExpressionDailyQueueItem.practiceModeFluencySprint => Icons.speed_rounded,
    _ => Icons.record_voice_over_rounded,
  };
}

List<String> _dailyExerciseChunks(
  InterviewExpressionLearningMaterial material,
  String target,
) {
  final List<String> chunks = material.chunks
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
  if (chunks.isNotEmpty) {
    return chunks;
  }
  return target
      .split(RegExp(r'(?<=[.!?])\s+|,\s+|;\s+'))
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
}

List<String> _dailyExerciseScoringTargets({
  required _WarmupDeckItem item,
  required String target,
  required String mode,
}) {
  if (mode == ExpressionDailyQueueItem.practiceModeVariantParaphrase) {
    return <String>{target}.toList(growable: false);
  }
  return <String>{
    target,
    ...item.node.reproducibleTexts,
  }.where((String value) => value.trim().isNotEmpty).toList(growable: false);
}

String _dailyClozeText(String target, List<String> chunks) {
  final List<String> usableChunks = chunks
      .where((String value) {
        final int wordCount = tokenizeInterviewWords(value).length;
        return value.length >= 5 && wordCount <= 8;
      })
      .toList(growable: false);
  if (usableChunks.isNotEmpty) {
    final String selected =
        usableChunks[_stableExerciseIndex(target, usableChunks.length)];
    return target.replaceFirst(
      RegExp(RegExp.escape(selected), caseSensitive: false),
      '______',
    );
  }
  final RegExpMatch? match = RegExp(r"[A-Za-z][A-Za-z']{3,}")
      .allMatches(target)
      .fold<RegExpMatch?>(null, (RegExpMatch? best, RegExpMatch candidate) {
        final String value = candidate.group(0) ?? '';
        if (_dailyLowValueWords.contains(value.toLowerCase())) {
          return best;
        }
        if (best == null || value.length > (best.group(0) ?? '').length) {
          return candidate;
        }
        return best;
      });
  if (match == null) {
    return '$target\n\n______';
  }
  return target.replaceRange(match.start, match.end, '______');
}

String _dailyCuePrompt(
  InterviewExpressionNode node,
  InterviewExpressionLearningMaterial material,
) {
  final String cue = _firstNonEmpty(<String>[
    material.scenePrompt,
    node.question,
    node.followupQuestion,
    node.usage,
    node.naturalTiming.isEmpty ? '' : '现在到了${node.naturalTiming}。',
  ]);
  if (cue.trim().isEmpty) {
    return '面试官给出一个与你当前场景相关的问题。';
  }
  return cue;
}

String _dailyMistakePrompt(
  InterviewExpressionLearningMaterial material,
  InterviewExpressionNode node,
) {
  final String mistake = _firstNonEmpty(<String>[
    ...material.commonMistakes,
    for (final InterviewErrorPattern error in node.errors)
      error.reason.isNotEmpty ? error.reason : error.better,
  ]).replaceAll('**', '');
  if (mistake.isEmpty) {
    return '把这句说得更自然、更完整。';
  }
  return mistake;
}

String _dailyVariantPrompt(InterviewExpressionNode node, String target) {
  final String base = node.targetText.trim();
  if (base.isNotEmpty && base.toLowerCase() != target.toLowerCase()) {
    return '基础表达：$base\n\n请说出同意图的另一种自然表达。';
  }
  return '请换一种自然说法表达同一个意思。';
}

List<String> _dailyKeywordHints(String target, List<String> chunks) {
  final List<String> sources = chunks.isNotEmpty ? chunks : <String>[target];
  final List<String> hints = <String>[];
  for (final String source in sources) {
    final List<String> words = RegExp(r"[A-Za-z][A-Za-z']+")
        .allMatches(source)
        .map((RegExpMatch match) => match.group(0) ?? '')
        .where((String value) {
          final String lower = value.toLowerCase();
          return value.length > 2 && !_dailyLowValueWords.contains(lower);
        })
        .take(3)
        .toList(growable: false);
    if (words.isEmpty) {
      continue;
    }
    final String hint = words.join(' / ');
    if (!hints.contains(hint)) {
      hints.add(hint);
    }
    if (hints.length >= 4) {
      break;
    }
  }
  if (hints.isNotEmpty) {
    return hints;
  }
  return tokenizeInterviewWords(target).take(4).toList(growable: false);
}

List<_DailyChoiceOption> _dailyChoiceOptions({
  required String target,
  required InterviewExpressionNode node,
  required String mode,
}) {
  final List<String> distractors = <String>[
    for (final InterviewErrorPattern error in node.errors) error.wrong,
    for (final InterviewExpectedVariant variant in node.nearMissVariants)
      variant.text,
    ..._dailyGeneratedChoiceDistractors(target),
  ];
  final List<String> uniqueDistractors = <String>[];
  final Set<String> seen = <String>{target.trim().toLowerCase()};
  for (final String distractor in distractors) {
    final String cleaned = _cleanDailyChoiceText(distractor);
    final String key = cleaned.toLowerCase();
    if (cleaned.isEmpty || !seen.add(key)) {
      continue;
    }
    uniqueDistractors.add(cleaned);
    if (uniqueDistractors.length >= 2) {
      break;
    }
  }
  final List<_DailyChoiceOption> choices = <_DailyChoiceOption>[];
  final int correctIndex = _stableExerciseIndex(
    '$target|$mode|choice',
    uniqueDistractors.length + 1,
  );
  for (int index = 0; index <= uniqueDistractors.length; index += 1) {
    if (index == correctIndex) {
      choices.add(
        _DailyChoiceOption(
          id: 'correct',
          text: _cleanDailyChoiceText(target),
          correct: true,
        ),
      );
    }
    if (index < uniqueDistractors.length) {
      choices.add(
        _DailyChoiceOption(
          id: 'wrong_$index',
          text: uniqueDistractors[index],
          correct: false,
        ),
      );
    }
  }
  return choices.take(4).toList(growable: false);
}

List<String> _dailyGeneratedChoiceDistractors(String target) {
  final List<String> result = <String>[];
  final String lower = target.toLowerCase();
  if (lower.contains("i'm")) {
    result.add(target.replaceFirst(RegExp(r"\bI'm\b"), 'I very'));
  }
  if (lower.contains(' for ')) {
    result.add(target.replaceFirst(RegExp(r'\bfor\b'), 'to'));
  }
  if (lower.contains(' to be ')) {
    result.add(target.replaceFirst(RegExp(r'\bto be\b'), 'to'));
  }
  if (lower.contains(' experience ')) {
    result.add(target.replaceFirst(RegExp(r'\bexperience\b'), 'experiences'));
  }
  result.addAll(const <String>[
    'I want to say this in a professional way.',
    'This is a good chance for me and I will work hard.',
    'I am very interesting in this role.',
  ]);
  return result;
}

String _cleanDailyChoiceText(String value) {
  return value.replaceAll('**', '').replaceAll(RegExp(r'\s+'), ' ').trim();
}

int _stableExerciseIndex(String seed, int length) {
  if (length <= 1) {
    return 0;
  }
  int hash = 0x811c9dc5;
  for (final int codeUnit in seed.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.abs() % length;
}

String _firstNonEmpty(Iterable<String> values) {
  for (final String value in values) {
    final String trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '';
}

const Set<String> _dailyLowValueWords = <String>{
  'the',
  'and',
  'for',
  'with',
  'that',
  'this',
  'you',
  'your',
  'are',
  'was',
  'were',
  'have',
  'has',
  'had',
  'can',
  'will',
  'would',
  'could',
  'should',
  'into',
  'from',
  'about',
  'today',
};

class _DailyExerciseChips extends StatelessWidget {
  const _DailyExerciseChips({required this.chips});

  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int index = 0; index < chips.length; index += 1) ...[
              if (index > 0) const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _expressionGreen.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  chips[index],
                  style: const TextStyle(
                    color: _expressionGreen,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyAnswerReveal extends StatelessWidget {
  const _DailyAnswerReveal({
    required this.answer,
    required this.visible,
    required this.onToggle,
  });

  final String answer;
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            key: const ValueKey<String>('daily_expression_answer_button'),
            onPressed: onToggle,
            icon: Icon(
              visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 16,
            ),
            label: Text(visible ? '隐藏答案' : '看答案'),
            style: TextButton.styleFrom(
              foregroundColor: _expressionGreen,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          if (visible)
            Container(
              key: const ValueKey<String>('daily_expression_answer_text'),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _expressionGreen.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                answer,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _expressionText,
                  fontSize: 12.2,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailySecondaryButton extends StatelessWidget {
  const _DailySecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        elevation: 10,
        shadowColor: const Color(0x222F2A1D),
        shape: const CircleBorder(side: BorderSide(color: Colors.white)),
        child: InkResponse(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: 50,
            child: Icon(icon, size: 23, color: _expressionGreen),
          ),
        ),
      ),
    );
  }
}

class _DailyPrimaryButton extends StatelessWidget {
  const _DailyPrimaryButton({
    super.key,
    required this.recording,
    required this.processingVoice,
    required this.recordingElapsed,
    required this.idleLabel,
    required this.onPressed,
  });

  final bool recording;
  final bool processingVoice;
  final Duration recordingElapsed;
  final String idleLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final String label = processingVoice
        ? '识别中'
        : recording
        ? '${recordingElapsed.inSeconds.clamp(1, 90)}秒，点击结束'
        : idleLabel;
    final Widget icon = processingVoice
        ? const Icon(
            Icons.hourglass_top_rounded,
            key: ValueKey('processing'),
            size: 17,
          )
        : recording
        ? const _DailyVoiceInputWave(key: ValueKey('voice_wave'))
        : const Icon(Icons.mic_rounded, key: ValueKey('idle'), size: 17);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: onPressed == null
            ? LinearGradient(
                colors: [
                  _expressionGreen.withValues(alpha: 0.45),
                  _expressionGreen.withValues(alpha: 0.38),
                ],
              )
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF426E3F), Color(0xFF275632)],
              ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x25315A3A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: icon,
        ),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

class _DailyVoiceInputWave extends StatefulWidget {
  const _DailyVoiceInputWave({super.key});

  @override
  State<_DailyVoiceInputWave> createState() => _DailyVoiceInputWaveState();
}

class _DailyVoiceInputWaveState extends State<_DailyVoiceInputWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double progress = _controller.value * math.pi * 2;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(5, (index) {
              final double phase = progress + index * 0.72;
              final double volume = (math.sin(phase) + 1) / 2;
              return Container(
                width: 3,
                height: 5 + volume * 11,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7 + volume * 0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _DailyExpressionScoreStrip extends StatelessWidget {
  const _DailyExpressionScoreStrip({
    required this.attemptScore,
    required this.bestScore,
    required this.onAttemptTap,
    required this.onBestTap,
  });

  final double? attemptScore;
  final double bestScore;
  final VoidCallback onAttemptTap;
  final VoidCallback onBestTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _DailyScoreMetric(
              key: const ValueKey<String>('daily_expression_attempt_score'),
              icon: Icons.trending_up_rounded,
              label: '本次',
              score: attemptScore,
              accent: true,
              onTap: onAttemptTap,
            ),
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: _expressionLine.withValues(alpha: 0.6),
          ),
          Expanded(
            child: _DailyScoreMetric(
              key: const ValueKey<String>('daily_expression_best_score'),
              icon: Icons.workspace_premium_rounded,
              label: '最佳',
              score: bestScore > 0 ? bestScore : null,
              accent: false,
              onTap: onBestTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyScoreMetric extends StatelessWidget {
  const _DailyScoreMetric({
    super.key,
    required this.icon,
    required this.label,
    required this.score,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final double? score;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String scoreText = score == null
        ? '--'
        : score!.clamp(0, 100).round().toString();
    final Color iconColor = accent ? _expressionGreen : _expressionGold;
    return Material(
      color: Colors.white.withValues(alpha: 0.38),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: iconColor),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: _expressionMuted,
                    fontSize: 11.2,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  scoreText,
                  style: const TextStyle(
                    color: _expressionText,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _DailyScoreDetailKind { attempt, best }

class _DailyScoreDetailData {
  const _DailyScoreDetailData({
    required this.kind,
    required this.title,
    required this.emptyText,
    required this.targetExpression,
    required this.score,
    required this.textMatch,
    required this.pronunciationScore,
    required this.passed,
    required this.transcript,
    required this.scoredAt,
    required this.attempts,
    required this.nextReviewAt,
  });

  final _DailyScoreDetailKind kind;
  final String title;
  final String emptyText;
  final String targetExpression;
  final double? score;
  final double? textMatch;
  final double? pronunciationScore;
  final bool? passed;
  final String transcript;
  final DateTime? scoredAt;
  final int attempts;
  final DateTime? nextReviewAt;

  bool get hasScore => score != null;

  factory _DailyScoreDetailData.fromProgress({
    required _DailyScoreDetailKind kind,
    required InterviewExpressionLearningProgress progress,
    required String targetExpression,
  }) {
    return switch (kind) {
      _DailyScoreDetailKind.attempt => _DailyScoreDetailData(
        kind: kind,
        title: '本次练习详情',
        emptyText: '完成一次练习后，这里会显示内容匹配、发音信号和识别文本。',
        targetExpression: targetExpression,
        score: progress.lastScore,
        textMatch: progress.lastTextMatch,
        pronunciationScore: progress.lastPronunciationScore,
        passed: progress.lastPassed,
        transcript: progress.lastTranscript,
        scoredAt: progress.lastScoredAt ?? progress.lastPracticedAt,
        attempts: progress.attempts,
        nextReviewAt: progress.nextReviewAt,
      ),
      _DailyScoreDetailKind.best => _DailyScoreDetailData(
        kind: kind,
        title: '历史最高详情',
        emptyText: '还没有历史最高记录。完成跟读后，会保留最高分和对应明细。',
        targetExpression: targetExpression,
        score: progress.bestScore > 0 ? progress.bestScore : null,
        textMatch: progress.bestTextMatch,
        pronunciationScore: progress.bestPronunciationScore,
        passed: null,
        transcript: progress.bestTranscript.isNotEmpty
            ? progress.bestTranscript
            : progress.lastTranscript,
        scoredAt: progress.bestScoredAt ?? progress.lastPracticedAt,
        attempts: progress.attempts,
        nextReviewAt: progress.nextReviewAt,
      ),
    };
  }
}

class _DailyScoreDetailSheet extends StatelessWidget {
  const _DailyScoreDetailSheet({required this.data});

  final _DailyScoreDetailData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        8,
        22,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: _expressionText,
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _expressionGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _dailyScoreDetailScoreText(data.score),
                  style: const TextStyle(
                    color: _expressionGreen,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!data.hasScore)
            Text(
              data.emptyText,
              style: const TextStyle(
                color: _expressionMuted,
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            )
          else ...[
            _DailyScoreDetailMetricList(data: data),
            const SizedBox(height: 18),
            _DailyScoreDetailTextBlock(
              title: '目标表达',
              text: data.targetExpression,
            ),
            if (data.transcript.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _DailyScoreDetailTextBlock(
                title: data.kind == _DailyScoreDetailKind.best
                    ? '最佳记录转写'
                    : '本次识别文本',
                text: data.transcript,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DailyScoreDetailChip(
                  label: '累计跟读 ${data.attempts.clamp(0, 100000)} 次',
                ),
                if (data.scoredAt != null)
                  _DailyScoreDetailChip(
                    label: '记录 ${_dailyScoreDetailTime(data.scoredAt)}',
                  ),
                if (data.nextReviewAt != null)
                  _DailyScoreDetailChip(
                    label: '复习 ${_dailyScoreDetailTime(data.nextReviewAt)}',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyScoreDetailMetricList extends StatelessWidget {
  const _DailyScoreDetailMetricList({required this.data});

  final _DailyScoreDetailData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DailyScoreDetailMetricRow(
          label: '内容匹配',
          value: data.textMatch == null
              ? '--'
              : '${(data.textMatch! * 100).round()}',
          progress: data.textMatch,
          helper: '目标句关键词和顺序的匹配程度',
        ),
        const SizedBox(height: 10),
        _DailyScoreDetailMetricRow(
          label: '发音信号',
          value: data.pronunciationScore == null
              ? '--'
              : '${data.pronunciationScore!.round()}',
          progress: data.pronunciationScore == null
              ? null
              : data.pronunciationScore! / 100,
          helper: data.pronunciationScore == null
              ? '本次未拿到发音评分，只按文本匹配估算'
              : '来自发音评分链路的综合信号',
        ),
        if (data.passed != null) ...[
          const SizedBox(height: 10),
          _DailyScoreDetailMetricRow(
            label: '通过状态',
            value: data.passed! ? '通过' : '未通过',
            progress: data.passed! ? 1 : 0.45,
            helper: data.passed! ? '已达到本轮跟读通过线' : '内容匹配或综合分还没达到通过线',
          ),
        ],
      ],
    );
  }
}

class _DailyScoreDetailMetricRow extends StatelessWidget {
  const _DailyScoreDetailMetricRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.helper,
  });

  final String label;
  final String value;
  final double? progress;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final double resolvedProgress = (progress ?? 0).clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _expressionText,
                  fontSize: 14,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: _expressionText,
                fontSize: 15,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress == null ? 0 : resolvedProgress,
            minHeight: 7,
            backgroundColor: _expressionLine.withValues(alpha: 0.72),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == null
                  ? _expressionMuted.withValues(alpha: 0.45)
                  : _expressionGreen,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          helper,
          style: const TextStyle(
            color: _expressionMuted,
            fontSize: 12,
            height: 1.28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DailyScoreDetailTextBlock extends StatelessWidget {
  const _DailyScoreDetailTextBlock({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _expressionLine.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _expressionGreen,
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: _expressionText,
              fontSize: 14,
              height: 1.38,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyScoreDetailChip extends StatelessWidget {
  const _DailyScoreDetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _expressionGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _expressionMuted,
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _dailyScoreDetailScoreText(double? score) {
  return score == null ? '--' : score.clamp(0, 100).round().toString();
}

String _dailyScoreDetailTime(DateTime? value) {
  if (value == null) {
    return '--';
  }
  String two(int number) => number.toString().padLeft(2, '0');
  final DateTime now = DateTime.now();
  final String date = value.year == now.year
      ? '${two(value.month)}/${two(value.day)}'
      : '${value.year}/${two(value.month)}/${two(value.day)}';
  return '$date ${two(value.hour)}:${two(value.minute)}';
}

String _dailyExpressionContextNote({
  required ExpressionDailyQueueItem queueItem,
  required InterviewExpressionNode node,
  required InterviewExpressionLearningMaterial material,
}) {
  final String assetContext = _dailyAssetContextNote(
    queueItem: queueItem,
    node: node,
  );
  if (assetContext.isNotEmpty) {
    return assetContext;
  }
  if (queueItem.kind == ExpressionDailyQueueItem.kindVariant &&
      queueItem.variantOfNodeId.trim().isNotEmpty) {
    return _dailyVariantContextNote(
      queueItem: queueItem,
      node: node,
      material: material,
    );
  }
  final String timing = _dailyContextTiming(node);
  final String intent = _dailyContextIntent(node, material);
  final String firstSentence = timing.isNotEmpty && intent.isNotEmpty
      ? '${_dailyTimingPrefix(timing)}用这句来$intent。'
      : _dailyReadableUsage(node, material);
  return _dailyJoinContextSentences(<String>[
    firstSentence,
    _dailyPracticeFocus(node: node, queueItem: queueItem, material: material),
  ]);
}

String _dailyAssetContextNote({
  required ExpressionDailyQueueItem queueItem,
  required InterviewExpressionNode node,
}) {
  if (queueItem.kind == ExpressionDailyQueueItem.kindVariant &&
      queueItem.variantOfNodeId.trim().isNotEmpty) {
    final InterviewPracticeVariant? variant = _practiceVariantForQueueItem(
      node,
      queueItem,
    );
    final String variantContext = _dailyJoinContextParts(<String?>[
      ?variant?.contextAnalysis['when'],
      ?variant?.contextAnalysis['difference'],
      ?variant?.contextAnalysis['practiceFocus'],
    ]);
    if (variantContext.isNotEmpty) {
      return variantContext;
    }
    return '';
  }
  return _dailyJoinContextParts(<String?>[
    node.expressionContextAnalysis['when'],
    node.expressionContextAnalysis['purpose'],
    node.expressionContextAnalysis['practiceFocus'],
  ]);
}

InterviewPracticeVariant? _practiceVariantForQueueItem(
  InterviewExpressionNode node,
  ExpressionDailyQueueItem queueItem,
) {
  final String practiceText = queueItem.practiceText.trim().toLowerCase();
  for (final InterviewPracticeVariant variant in node.practiceVariants) {
    if (variant.text.trim().toLowerCase() == practiceText) {
      return variant;
    }
  }
  return null;
}

String _dailyJoinContextParts(List<String?> values) {
  final List<String> sentences = values
      .map((String? value) => _cleanDailyContextSentence(value ?? ''))
      .where((String value) => value.isNotEmpty)
      .toList(growable: false);
  return _dailyJoinContextSentences(sentences, maxSentences: 3);
}

String _dailyVariantContextNote({
  required ExpressionDailyQueueItem queueItem,
  required InterviewExpressionNode node,
  required InterviewExpressionLearningMaterial material,
}) {
  final String timing = _dailyContextTiming(node);
  final String intent = _dailyContextIntent(node, material);
  final String firstSentence = timing.isNotEmpty
      ? '${_dailyTimingPrefix(timing)}这句是主句的另一种自然说法。'
      : '这句是主句的另一种自然说法，放在同一类场景里替换使用。';
  return _dailyJoinContextSentences(<String>[
    firstSentence,
    if (intent.isNotEmpty) '练它不是换意思，而是换一种方式来$intent。',
    _dailyVariantPracticeValue(
      variantText: queueItem.practiceText,
      primaryText: node.targetText,
    ),
  ], maxSentences: 3);
}

String _dailyContextTiming(InterviewExpressionNode node) {
  final List<String> candidates = <String>[
    node.naturalTiming,
    _firstUsefulChineseSentence(node.usage),
    for (final String value in node.contextVariants)
      _firstUsefulChineseSentence(value),
  ];
  for (final String candidate in candidates) {
    final String value = _cleanDailyContextFragment(candidate);
    if (value.isNotEmpty && !_looksLikeTargetExpression(value)) {
      return value;
    }
  }
  return '';
}

String _dailyContextIntent(
  InterviewExpressionNode node,
  InterviewExpressionLearningMaterial material,
) {
  final List<String> candidates = <String>[node.intent, material.intentCn];
  for (final String candidate in candidates) {
    final String value = _cleanDailyContextFragment(candidate);
    if (value.isEmpty || value == node.meaning.trim()) {
      continue;
    }
    return value;
  }
  return '';
}

String _dailyReadableUsage(
  InterviewExpressionNode node,
  InterviewExpressionLearningMaterial material,
) {
  for (final String candidate in <String>[node.usage, material.nativeNotes]) {
    final String value = _cleanDailyContextSentence(candidate);
    if (value.isNotEmpty && !_looksLikeTargetExpression(value)) {
      return value;
    }
  }
  return '';
}

String _dailyPracticeFocus({
  required InterviewExpressionNode node,
  required ExpressionDailyQueueItem queueItem,
  required InterviewExpressionLearningMaterial material,
}) {
  final String searchable = <String>[
    node.intent,
    node.stageLabel,
    node.tag,
    node.usage,
    material.nativeNotes,
  ].join(' ');
  if (node.isRescue || _containsAny(searchable, const <String>['救场', '不熟悉'])) {
    return '重点是诚实承认空白，再把态度拉回积极。';
  }
  if (_containsAny(searchable, const <String>['感谢', '开场'])) {
    return '先把感谢和积极状态说完整，语气真诚、平稳就够了。';
  }
  if (_containsAny(searchable, const <String>['欢迎', '加入团队'])) {
    return '像新同事自然回应，不需要太正式，也不要说得过满。';
  }
  if (_containsAny(searchable, const <String>['岗位', '职责', '负责'])) {
    return '重点是让对方快速听懂你的角色和负责方向。';
  }
  if (_containsAny(searchable, const <String>['经验', '背景', '年'])) {
    return '控制在一句话里，把年限、领域或经验价值说清楚。';
  }
  if (_containsAny(searchable, const <String>['项目', '经历', '解决', '问题'])) {
    return '按背景、动作、结果的顺序说，别铺垫太久。';
  }
  if (_containsAny(searchable, const <String>['优势', '能力', '擅长'])) {
    return '把能力说成工作中能带来的价值，而不是只背形容词。';
  }
  if (_containsAny(searchable, const <String>['压力', '抗压'])) {
    return '听起来要稳，像是在说明处理方式，而不是硬撑。';
  }
  if (_containsAny(searchable, const <String>['动机', '寻找', '成长'])) {
    return '把动机说成职业选择，不要像在抱怨上一份工作。';
  }
  if (_containsAny(searchable, const <String>['规划', '五年'])) {
    return '表达方向感即可，不需要承诺过满。';
  }
  if (_containsAny(searchable, const <String>['反问', '后续', '下一步'])) {
    return '用礼貌问题推动对话，显得你在认真了解机会。';
  }
  if (queueItem.kind == ExpressionDailyQueueItem.kindWeak) {
    return '先把意思说完整，再慢慢提高自然度。';
  }
  if (queueItem.kind == ExpressionDailyQueueItem.kindReview) {
    return '这次重点是唤回使用位置，确认需要时能马上说出来。';
  }
  return '先记住它适合出现的位置，再跟读到顺口。';
}

String _dailyVariantPracticeValue({
  required String variantText,
  required String primaryText,
}) {
  final String value = variantText.trim().toLowerCase();
  if (value.contains('appreciate') ||
      value.contains('opportunity') ||
      value.contains('would')) {
    return '它更偏正式，适合想把语气说得稳一点时使用。';
  }
  if (value.startsWith('thanks') ||
      value.contains('glad') ||
      value.contains('happy')) {
    return '它更口语，适合语气轻松但仍然礼貌的场合。';
  }
  if (primaryText.trim().isNotEmpty &&
      variantText.trim().length < primaryText.trim().length * 0.78) {
    return '它更短，适合你想把意思快速说清楚的时候。';
  }
  return '练它的价值是不用背同一句话，也能自然完成同一个表达任务。';
}

String _dailyTimingPrefix(String timing) {
  final String value = _cleanDailyContextFragment(timing);
  if (value.isEmpty) {
    return '';
  }
  if (value.startsWith('在')) {
    return '$value，';
  }
  return '在$value，';
}

String _firstUsefulChineseSentence(String value) {
  final List<String> parts = value
      .split(RegExp(r'[。！？.!?]'))
      .map(_cleanDailyContextFragment)
      .where((String item) => item.isNotEmpty)
      .toList(growable: false);
  for (final String part in parts) {
    if (_containsCjk(part) &&
        _containsAny(part, const <String>[
          '时',
          '后',
          '前',
          '阶段',
          '环节',
          '场景',
          '入职',
          '面试',
          '介绍',
          '欢迎',
          '提问',
        ])) {
      return part;
    }
  }
  return '';
}

String _cleanDailyContextSentence(String value) {
  return _dailyEnsureSentence(_cleanDailyContextFragment(value));
}

String _cleanDailyContextFragment(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[。！？.!?]+$'), '')
      .replaceAll(RegExp(r'^语境[:：]\s*'), '')
      .trim();
}

String _dailyEnsureSentence(String value) {
  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (RegExp(r'[。！？.!?]$').hasMatch(trimmed)) {
    return trimmed;
  }
  return '$trimmed。';
}

String _dailyJoinContextSentences(
  List<String> candidates, {
  int maxSentences = 2,
}) {
  final Set<String> seen = <String>{};
  final List<String> result = <String>[];
  for (final String candidate in candidates) {
    final String sentence = _dailyEnsureSentence(candidate);
    final String key = sentence.replaceAll(RegExp(r'\s|[。！？.!?]'), '');
    if (sentence.isEmpty || key.isEmpty || !seen.add(key)) {
      continue;
    }
    result.add(sentence);
    if (result.length >= maxSentences) {
      break;
    }
  }
  return result.join();
}

bool _containsAny(String value, List<String> needles) {
  return needles.any(value.contains);
}

bool _containsCjk(String value) {
  return RegExp(r'[\u4e00-\u9fff]').hasMatch(value);
}

bool _looksLikeTargetExpression(String value) {
  return !_containsCjk(value) && value.split(' ').length > 5;
}

String _dailyKindLabel(String kind) {
  return switch (kind) {
    ExpressionDailyQueueItem.kindReview => '复习',
    ExpressionDailyQueueItem.kindWeak => '补弱',
    ExpressionDailyQueueItem.kindProgress => '继续',
    ExpressionDailyQueueItem.kindNew => '新学',
    ExpressionDailyQueueItem.kindVariant => '拓展',
    _ => '表达',
  };
}

String _primaryLabel({
  required String activeTaskType,
  required bool recording,
  required String? recordingTaskType,
  required bool processingVoice,
  required Duration recordingElapsed,
}) {
  if (recording) {
    return '${recordingElapsed.inSeconds.clamp(1, 90)}秒，点击结束';
  }
  if (processingVoice) {
    return '正在识别...';
  }
  return switch (activeTaskType) {
    'listen' => '听一句',
    'shadow' => '跟说一次',
    'slot_replace' => '说出你的版本',
    _ => '去模拟里用',
  };
}

String _displayTaskTitle(String activeTaskType, String title) {
  if (activeTaskType == 'slot_replace') {
    return '换成自己的信息';
  }
  if (activeTaskType == 'scene_transfer') {
    return '去模拟里用';
  }
  return title;
}

String _displayTaskPrompt(String activeTaskType, String prompt) {
  return switch (activeTaskType) {
    'listen' => '先别看英文，听一遍自然说法。',
    'shadow' => prompt.trim().isEmpty ? '现在看英文，跟着说一遍，先保证完整和顺。' : prompt.trim(),
    'slot_replace' => '把句子换成你的真实信息说一次。',
    _ => '进入实时模拟，把刚刚热过的表达自然用出来。',
  };
}

IconData _primaryIcon(
  String activeTaskType,
  bool recording,
  bool processingVoice,
) {
  if (recording) {
    return Icons.stop_rounded;
  }
  if (processingVoice) {
    return Icons.hourglass_top_rounded;
  }
  return switch (activeTaskType) {
    'listen' => Icons.volume_up_rounded,
    'shadow' || 'slot_replace' => Icons.keyboard_voice_rounded,
    _ => Icons.play_arrow_rounded,
  };
}

class _ExpressionProgressStrip extends StatelessWidget {
  const _ExpressionProgressStrip({
    required this.hasListen,
    required this.hasShadow,
    required this.hasSlot,
    required this.activeTaskType,
    required this.onSelect,
  });

  final bool hasListen;
  final bool hasShadow;
  final bool hasSlot;
  final String activeTaskType;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final List<_StepMarkerData> steps = <_StepMarkerData>[
      _StepMarkerData(
        type: 'listen',
        label: '听',
        done: hasListen,
        enabled: true,
      ),
      _StepMarkerData(
        type: 'shadow',
        label: '跟说',
        done: hasShadow,
        enabled: hasListen,
      ),
      _StepMarkerData(
        type: 'slot_replace',
        label: '换成自己',
        done: hasSlot,
        enabled: hasShadow,
      ),
      _StepMarkerData(
        type: 'scene_transfer',
        label: '实战',
        done: false,
        enabled: hasSlot,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value:
                (steps.where((_StepMarkerData item) => item.done).length /
                        steps.length)
                    .clamp(0, 1),
            minHeight: 5,
            backgroundColor: const Color(0xFFF0EDE6),
            valueColor: const AlwaysStoppedAnimation<Color>(_expressionGreen),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: steps
              .map(
                (_StepMarkerData step) => Expanded(
                  child: _ExpressionStepMarker(
                    step: step,
                    active: activeTaskType == step.type,
                    onTap: step.enabled ? () => onSelect(step.type) : null,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _StepMarkerData {
  const _StepMarkerData({
    required this.type,
    required this.label,
    required this.done,
    required this.enabled,
  });

  final String type;
  final String label;
  final bool done;
  final bool enabled;
}

class _ExpressionStepMarker extends StatelessWidget {
  const _ExpressionStepMarker({
    required this.step,
    required this.active,
    required this.onTap,
  });

  final _StepMarkerData step;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active
        ? _expressionGreen
        : step.done
        ? const Color(0xFF6E8766)
        : _expressionMuted.withValues(alpha: step.enabled ? 0.8 : 0.38);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 10 : 7,
              height: active ? 10 : 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.done || active
                    ? _expressionGreen
                    : const Color(0xFFD9D5CB),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              step.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.activeTaskType,
    required this.material,
    required this.node,
    required this.progress,
    required this.personalHints,
    required this.playing,
    required this.onPlay,
  });

  final String activeTaskType;
  final InterviewExpressionLearningMaterial material;
  final InterviewExpressionNode node;
  final InterviewExpressionLearningProgress progress;
  final List<String> personalHints;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    if (activeTaskType == 'listen') {
      return _ListenStepContent(
        intent: material.intentCn,
        scenePrompt: material.scenePrompt,
        targetExpression: material.targetExpression,
        playing: playing,
        onPlay: onPlay,
      );
    }
    if (activeTaskType == 'slot_replace') {
      final InterviewExpressionSpeakingTask task = material.taskFor(
        'slot_replace',
      );
      return _SlotReplaceStepContent(
        expression: material.targetExpression,
        task: task,
        node: node,
        personalHints: personalHints,
      );
    }
    if (activeTaskType == 'scene_transfer') {
      return _SceneTransferStepContent(
        scenePrompt: material.scenePrompt,
        targetExpression: material.targetExpression,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '目标表达',
          style: TextStyle(
            color: _expressionMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          material.targetExpression,
          style: const TextStyle(
            color: _expressionText,
            fontSize: 22,
            height: 1.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (material.chunks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: material.chunks
                .map((String chunk) => _ExpressionChunk(text: chunk))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _ListenStepContent extends StatelessWidget {
  const _ListenStepContent({
    required this.intent,
    required this.scenePrompt,
    required this.targetExpression,
    required this.playing,
    required this.onPlay,
  });

  final String intent;
  final String scenePrompt;
  final String targetExpression;
  final bool playing;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final String intentText = intent.trim().isNotEmpty
        ? intent.trim()
        : '先听一遍自然说法，抓住这句话要表达的意思。';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _expressionLine),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onPlay,
            customBorder: const CircleBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: playing ? _expressionGreen : Colors.white,
                border: Border.all(
                  color: playing ? _expressionGreen : const Color(0xFFD7E4CE),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x102F2A1D),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                playing ? Icons.graphic_eq_rounded : Icons.headphones_rounded,
                size: 34,
                color: playing ? Colors.white : _expressionGreen,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            intentText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _expressionText,
              fontSize: 19,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (scenePrompt.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              scenePrompt.trim(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _expressionMuted,
                fontSize: 12.5,
                height: 1.38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _CollapsedEnglishPreview(text: targetExpression),
        ],
      ),
    );
  }
}

class _CollapsedEnglishPreview extends StatefulWidget {
  const _CollapsedEnglishPreview({required this.text});

  final String text;

  @override
  State<_CollapsedEnglishPreview> createState() =>
      _CollapsedEnglishPreviewState();
}

class _CollapsedEnglishPreviewState extends State<_CollapsedEnglishPreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E1D6)),
        ),
        child: Text(
          _expanded ? widget.text : '英文先收起，听完再看',
          textAlign: TextAlign.center,
          maxLines: _expanded ? 3 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _expanded
                ? _expressionText.withValues(alpha: 0.72)
                : _expressionMuted,
            fontSize: _expanded ? 13 : 12.5,
            height: 1.35,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SlotReplaceStepContent extends StatelessWidget {
  const _SlotReplaceStepContent({
    required this.expression,
    required this.task,
    required this.node,
    required this.personalHints,
  });

  final String expression;
  final InterviewExpressionSpeakingTask task;
  final InterviewExpressionNode node;
  final List<String> personalHints;

  @override
  Widget build(BuildContext context) {
    final String pattern = _slotPattern(expression, task, node);
    final List<String> suggestions = _slotSuggestions(
      task,
      node,
      personalHints,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _expressionLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '现在换成你的情况',
            style: TextStyle(
              color: _expressionText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pattern,
            style: const TextStyle(
              color: _expressionText,
              fontSize: 19,
              height: 1.28,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              '可以先借一个开口',
              style: TextStyle(
                color: _expressionMuted,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: suggestions
                  .map((String item) => _ExpressionChunk(text: item))
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _SceneTransferStepContent extends StatelessWidget {
  const _SceneTransferStepContent({
    required this.scenePrompt,
    required this.targetExpression,
  });

  final String scenePrompt;
  final String targetExpression;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCFE2C5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: _expressionGreen, size: 19),
              SizedBox(width: 6),
              Text(
                '准备进实战',
                style: TextStyle(
                  color: _expressionText,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            scenePrompt.trim().isEmpty
                ? '进入实时模拟，把刚刚热过的表达自然说出来。'
                : scenePrompt.trim(),
            style: const TextStyle(
              color: _expressionText,
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            targetExpression,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _expressionMuted,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpressionChunk extends StatelessWidget {
  const _ExpressionChunk({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4EC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _expressionGreen,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TranscriptBox extends StatelessWidget {
  const _TranscriptBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE9D3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _expressionText,
          fontSize: 13,
          height: 1.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExpressionTag extends StatelessWidget {
  const _ExpressionTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4E8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _expressionGreen,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SmallExpressionAction extends StatelessWidget {
  const _SmallExpressionAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4EC),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: _expressionGreen),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _expressionGreen,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryExpressionButton extends StatelessWidget {
  const _PrimaryExpressionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: _expressionGreen,
          disabledBackgroundColor: _expressionGreen.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _SecondaryExpressionButton extends StatelessWidget {
  const _SecondaryExpressionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _expressionGreen,
          side: const BorderSide(color: _expressionLine),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _ExpressionErrorState extends StatelessWidget {
  const _ExpressionErrorState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _expressionMuted),
        ),
      ),
    );
  }
}

class _ExpressionEmptyState extends StatelessWidget {
  const _ExpressionEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '当前等级没有可热身的目标表达。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _expressionMuted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DailyExpressionEmptyState extends StatelessWidget {
  const _DailyExpressionEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          '今日表达已经安排完了。完成更多场景后，会继续生成复习和补弱表达。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _expressionMuted,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
