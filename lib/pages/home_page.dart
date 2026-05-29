import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:speakeasy/features/commercial/commercial_scenario_gate.dart';
import 'package:speakeasy/features/interview/expression_daily_queue_coordinator.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_expression_learning_page.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_practice_page.dart';
import 'package:speakeasy/features/interview/interview_scene_listening_page.dart';
import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/storage_service.dart';
import 'package:speakeasy/l10n/l10n.dart';
import 'package:speakeasy/pages/profile_page.dart';
import 'package:speakeasy/utils/app_cached_network_image.dart';

class SpeakEasyHomePage extends StatefulWidget {
  const SpeakEasyHomePage({super.key});

  @override
  State<SpeakEasyHomePage> createState() => _SpeakEasyHomePageState();
}

class _SpeakEasyHomePageState extends State<SpeakEasyHomePage> {
  int _activeBottomIndex = 0;

  List<_InterviewSceneHomeStatus> _interviewSceneStatuses =
      <_InterviewSceneHomeStatus>[];
  bool _interviewScenesLoading = true;
  List<String> _selectedLearningSceneIds = <String>[];
  String? _activeLearningSceneId;
  String _selectedHomeSceneCategory = _recommendedHomeSceneCategory;
  final PageController _learningScenePageController = PageController();

  bool _searchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final ExpressionDailyQueueCoordinator _dailyQueueCoordinator =
      const ExpressionDailyQueueCoordinator();
  String _dailyExpressionQueueSignature = '';
  Future<List<ExpressionDailyQueueItem>>? _dailyExpressionQueueFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInterviewSceneStatuses();
    });
  }

  @override
  void dispose() {
    _learningScenePageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInterviewSceneStatuses() async {
    final String userId = AppSessionScope.of(context).nickname;
    setState(() => _interviewScenesLoading = true);
    try {
      final InterviewSceneCatalog catalog = await loadInterviewSceneCatalog();
      final DateTime now = DateTime.now();
      final List<_InterviewSceneHomeStatus> statuses =
          <_InterviewSceneHomeStatus>[];
      for (final InterviewSceneCatalogEntry entry in catalog.scenes) {
        try {
          final InterviewSceneGraph graph = await loadInterviewSceneGraph(
            sceneId: entry.id,
          );
          final InterviewWikiStore store = InterviewWikiStore(
            sceneId: entry.id,
          );
          final String storedTargetLevel = _safeLoadSelectedTargetLevel(store);
          final String selectedTargetLevel = _availableTargetLevel(
            graph,
            storedTargetLevel,
          );
          final List<String> activeNodeIdsInOrder = graph.flowNodeIdsForLevel(
            selectedTargetLevel,
          );
          final Set<String> activeNodeIds = activeNodeIdsInOrder.toSet();
          final List<InterviewPersonalWikiExpression> masteredExpressions =
              _safeLoadMasteredExpressions(store, entry.id);
          final InterviewUserGrowthWiki growthWiki = _safeLoadUserGrowthWiki(
            store,
          );
          final Set<String> masteredNodeIds = masteredExpressions
              .map(_nodeIdForHomeExpression)
              .where((String id) => id.trim().isNotEmpty)
              .where(activeNodeIds.contains)
              .toSet();
          final int dueReviewCount = masteredExpressions
              .where(
                (InterviewPersonalWikiExpression item) =>
                    activeNodeIds.contains(_nodeIdForHomeExpression(item)) &&
                    !item.nextReviewAt.isAfter(now),
              )
              .length;
          final List<InterviewWeakExpressionState> activeWeakExpressions =
              growthWiki.weakExpressions
                  .where(
                    (InterviewWeakExpressionState item) =>
                        item.sourceSceneId == entry.id &&
                        activeNodeIds.contains(
                          item.sourceNodeId.isNotEmpty
                              ? item.sourceNodeId
                              : item.sourceExpressionId,
                        ),
                  )
                  .toList(growable: false)
                ..sort(
                  (
                    InterviewWeakExpressionState a,
                    InterviewWeakExpressionState b,
                  ) => b.lastSeenAt.compareTo(a.lastSeenAt),
                );
          final int weakCount = activeWeakExpressions.length;
          final InterviewActiveSessionSnapshot? activeSession =
              _safeLoadActiveSession(store, userId);
          final bool hasActiveSession =
              activeSession != null &&
              activeSession.session.targetLevel == selectedTargetLevel;
          final _InterviewSceneNextTarget nextTarget = _nextTargetForHome(
            graph: graph,
            activeNodeIdsInOrder: activeNodeIdsInOrder,
            masteredNodeIds: masteredNodeIds,
            weakExpressions: activeWeakExpressions,
            dueReviewCount: dueReviewCount,
            hasActiveSession: hasActiveSession,
          );
          final int personalMaterialCount =
              growthWiki.personalFacts.length +
              growthWiki.interviewStories.length +
              growthWiki.evidenceRefs.length;
          final InterviewSceneProgressState? progress = _sceneProgressFor(
            growthWiki.sceneProgress,
            entry.id,
          );
          statuses.add(
            _InterviewSceneHomeStatus(
              entry: entry,
              title: graph.titleCn.isNotEmpty ? graph.titleCn : entry.titleCn,
              description: graph.description.isNotEmpty
                  ? graph.description
                  : entry.description,
              tags: <String>{
                ...entry.tags,
                ...graph.tags,
              }.where((String value) => value.trim().isNotEmpty).toList(),
              trackLabels: graph.tracks
                  .map((InterviewSceneTrack track) => track.title)
                  .where((String value) => value.trim().isNotEmpty)
                  .toList(growable: false),
              levelOptions: graph.tracks
                  .map(
                    (InterviewSceneTrack track) => _InterviewSceneLevelOption(
                      title: track.title.isEmpty ? track.id : track.title,
                      targetLevel: track.targetLevel,
                      expressionCount: track.nodeIds.length,
                    ),
                  )
                  .toList(growable: false),
              selectedTargetLevel: selectedTargetLevel,
              publicTrackCount: graph.tracks.length,
              publicPhaseCount: graph.phases.length,
              totalExpressionCount: activeNodeIds.length,
              masteredExpressionCount: masteredNodeIds.length,
              dueReviewCount: dueReviewCount,
              weakExpressionCount: weakCount,
              personalMaterialCount: personalMaterialCount,
              nextTargetLabel: nextTarget.label,
              nextTargetDetail: nextTarget.detail,
              nextTargetMode: nextTarget.mode,
              hasActiveSession: hasActiveSession,
              lastPracticedAt: progress?.lastPracticedAt,
            ),
          );
        } catch (error, stackTrace) {
          debugPrint(
            '[Home] failed to load interview scene ${entry.id}: $error',
          );
          debugPrint('$stackTrace');
        }
      }
      if (!mounted) {
        return;
      }
      final InterviewHomeSceneSelectionStorageModel storedSelection =
          _safeLoadHomeSceneSelection();
      final List<String> selectedSceneIds = _sanitizeLearningSceneIds(
        storedSelection.selectedSceneIds,
        statuses,
      );
      final String? activeSceneId = _resolveStoredActiveSceneId(
        storedSelection.activeSceneId,
        selectedSceneIds,
      );
      setState(() {
        _interviewSceneStatuses = statuses;
        _interviewScenesLoading = false;
        _selectedLearningSceneIds = selectedSceneIds;
        _activeLearningSceneId = activeSceneId;
        _dailyExpressionQueueSignature = '';
        _dailyExpressionQueueFuture = null;
      });
      if (!_sameStringList(
            storedSelection.selectedSceneIds,
            selectedSceneIds,
          ) ||
          storedSelection.activeSceneId != activeSceneId) {
        unawaited(
          StorageService.instance.saveInterviewHomeSceneSelection(
            InterviewHomeSceneSelectionStorageModel(
              selectedSceneIds: selectedSceneIds,
              activeSceneId: activeSceneId,
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[Home] failed to load interview scene catalog: $error');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _interviewSceneStatuses = <_InterviewSceneHomeStatus>[];
        _interviewScenesLoading = false;
        _dailyExpressionQueueSignature = '';
        _dailyExpressionQueueFuture = null;
      });
    }
  }

  String _safeLoadSelectedTargetLevel(InterviewWikiStore store) {
    try {
      return store.loadSelectedTargetLevel();
    } catch (error) {
      debugPrint('[Home] ignored invalid scene target level storage: $error');
      return '';
    }
  }

  List<InterviewPersonalWikiExpression> _safeLoadMasteredExpressions(
    InterviewWikiStore store,
    String sceneId,
  ) {
    try {
      return store.loadMasteredExpressions(sourceSceneId: sceneId);
    } catch (error) {
      debugPrint('[Home] ignored invalid mastered expression storage: $error');
      return const <InterviewPersonalWikiExpression>[];
    }
  }

  InterviewUserGrowthWiki _safeLoadUserGrowthWiki(InterviewWikiStore store) {
    try {
      return store.loadUserGrowthWiki();
    } catch (error) {
      debugPrint('[Home] ignored invalid growth wiki storage: $error');
      return InterviewUserGrowthWiki.empty();
    }
  }

  InterviewActiveSessionSnapshot? _safeLoadActiveSession(
    InterviewWikiStore store,
    String userId,
  ) {
    try {
      return store.loadActiveSession(userId: userId);
    } catch (error) {
      debugPrint('[Home] ignored invalid active interview session: $error');
      return null;
    }
  }

  InterviewHomeSceneSelectionStorageModel _safeLoadHomeSceneSelection() {
    try {
      return StorageService.instance.getInterviewHomeSceneSelection();
    } catch (error) {
      debugPrint('[Home] ignored invalid home scene selection storage: $error');
      return const InterviewHomeSceneSelectionStorageModel();
    }
  }

  _InterviewSceneNextTarget _nextTargetForHome({
    required InterviewSceneGraph graph,
    required List<String> activeNodeIdsInOrder,
    required Set<String> masteredNodeIds,
    required List<InterviewWeakExpressionState> weakExpressions,
    required int dueReviewCount,
    required bool hasActiveSession,
  }) {
    if (hasActiveSession) {
      return const _InterviewSceneNextTarget(
        mode: '继续',
        label: '继续未完成对话',
        detail: '从上次中断处接着练，系统会保留上下文。',
      );
    }
    if (dueReviewCount > 0) {
      return const _InterviewSceneNextTarget(
        mode: '复习',
        label: '先复习到期表达',
        detail: '系统标记了需要巩固的表达，优先复现。',
      );
    }
    if (weakExpressions.isNotEmpty) {
      final InterviewWeakExpressionState weak = weakExpressions.first;
      return _InterviewSceneNextTarget(
        mode: '补弱',
        label: weak.tag.isNotEmpty ? weak.tag : '补齐薄弱表达',
        detail: weak.targetText.isNotEmpty
            ? weak.targetText
            : '系统会降低难度并给出更明确提示。',
      );
    }
    for (final String nodeId in activeNodeIdsInOrder) {
      if (masteredNodeIds.contains(nodeId)) {
        continue;
      }
      final InterviewExpressionNode? node = graph.nodeById(nodeId);
      if (node == null) {
        continue;
      }
      return _InterviewSceneNextTarget(
        mode: '新课',
        label: node.intent.isNotEmpty ? node.intent : node.tag,
        detail: node.targetText.isNotEmpty ? node.targetText : '表达路径会推进到下一个目标。',
      );
    }
    return const _InterviewSceneNextTarget(
      mode: '巩固',
      label: '巩固完整场景',
      detail: '所有目标表达已覆盖，可以进行整场复现。',
    );
  }

  InterviewSceneProgressState? _sceneProgressFor(
    List<InterviewSceneProgressState> progress,
    String sceneId,
  ) {
    for (final InterviewSceneProgressState item in progress) {
      if (item.sourceSceneId == sceneId) {
        return item;
      }
    }
    return null;
  }

  List<String> _sanitizeLearningSceneIds(
    List<String> sceneIds,
    List<_InterviewSceneHomeStatus> statuses,
  ) {
    final Set<String> availableIds = statuses
        .map((_InterviewSceneHomeStatus status) => status.entry.id)
        .toSet();
    final Set<String> seen = <String>{};
    return sceneIds
        .map((String sceneId) => sceneId.trim())
        .where((String sceneId) => sceneId.isNotEmpty)
        .where(availableIds.contains)
        .where(seen.add)
        .toList(growable: false);
  }

  String? _resolveStoredActiveSceneId(
    String? activeSceneId,
    List<String> selectedSceneIds,
  ) {
    final String trimmed = (activeSceneId ?? '').trim();
    if (trimmed.isNotEmpty && selectedSceneIds.contains(trimmed)) {
      return trimmed;
    }
    if (selectedSceneIds.isNotEmpty) {
      return selectedSceneIds.first;
    }
    return null;
  }

  bool _sameStringList(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  String _availableTargetLevel(
    InterviewSceneGraph graph,
    String preferredTargetLevel,
  ) {
    for (final InterviewSceneTrack track in graph.tracks) {
      if (track.targetLevel == preferredTargetLevel) {
        return track.targetLevel;
      }
    }
    if (graph.tracks.isNotEmpty) {
      return graph.tracks.first.targetLevel;
    }
    return preferredTargetLevel.trim().isEmpty
        ? 'beginner'
        : preferredTargetLevel.trim();
  }

  String _nodeIdForHomeExpression(InterviewPersonalWikiExpression item) {
    return item.sourceNodeId.isNotEmpty
        ? item.sourceNodeId
        : item.sourceExpressionId;
  }

  List<_InterviewSceneHomeStatus> get _searchSceneStatuses {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return const <_InterviewSceneHomeStatus>[];
    }
    return _interviewSceneStatuses.where((_InterviewSceneHomeStatus status) {
      return status.title.toLowerCase().contains(query) ||
          status.description.toLowerCase().contains(query) ||
          status.trackLabels.any(
            (String label) => label.toLowerCase().contains(query),
          );
    }).toList();
  }

  _InterviewSceneHomeStatus? get _recommendedInterviewSceneStatus {
    if (_interviewSceneStatuses.isEmpty) {
      return null;
    }
    final List<_InterviewSceneHomeStatus> statuses =
        List<_InterviewSceneHomeStatus>.from(_interviewSceneStatuses)
          ..sort(_compareSceneStatus);
    return statuses.first;
  }

  _InterviewSceneHomeStatus? get _recommendedActionableInterviewSceneStatus {
    final List<_InterviewSceneHomeStatus> statuses =
        _interviewSceneStatuses
            .where(_shouldShowSceneInHomeHero)
            .toList(growable: false)
          ..sort(_compareSceneStatus);
    return statuses.isEmpty ? null : statuses.first;
  }

  List<_InterviewSceneHomeStatus> get _selectedLearningSceneStatuses {
    final Map<String, _InterviewSceneHomeStatus> byId =
        <String, _InterviewSceneHomeStatus>{
          for (final _InterviewSceneHomeStatus status
              in _interviewSceneStatuses)
            status.entry.id: status,
        };
    return _selectedLearningSceneIds
        .map((String sceneId) => byId[sceneId])
        .whereType<_InterviewSceneHomeStatus>()
        .toList(growable: false);
  }

  List<_InterviewSceneHomeStatus> get _completedLearningSceneStatuses {
    final List<_InterviewSceneHomeStatus> statuses =
        _interviewSceneStatuses
            .where((_InterviewSceneHomeStatus status) => status.isCompleted)
            .toList(growable: false)
          ..sort(_compareSceneStatus);
    return statuses;
  }

  _InterviewSceneHomeStatus? get _activeLearningSceneStatus {
    if (_interviewSceneStatuses.isEmpty) {
      return null;
    }
    final List<_InterviewSceneHomeStatus> selectedStatuses =
        _selectedLearningSceneStatuses;
    if (selectedStatuses.isNotEmpty) {
      final String activeSceneId = (_activeLearningSceneId ?? '').trim();
      for (final _InterviewSceneHomeStatus status in selectedStatuses) {
        if (status.entry.id == activeSceneId) {
          return status;
        }
      }
      return selectedStatuses.first;
    }
    return _recommendedInterviewSceneStatus;
  }

  bool _shouldShowSceneInHomeHero(_InterviewSceneHomeStatus status) {
    return !status.isCompleted ||
        status.dueReviewCount > 0 ||
        status.hasActiveSession;
  }

  int get _totalMasteredExpressionCount {
    return _interviewSceneStatuses.fold<int>(
      0,
      (int total, _InterviewSceneHomeStatus status) =>
          total + status.masteredExpressionCount,
    );
  }

  int get _totalExpressionCount {
    return _interviewSceneStatuses.fold<int>(
      0,
      (int total, _InterviewSceneHomeStatus status) =>
          total + status.totalExpressionCount,
    );
  }

  int _compareSceneStatus(
    _InterviewSceneHomeStatus a,
    _InterviewSceneHomeStatus b,
  ) {
    final int active =
        (b.hasActiveSession ? 1 : 0) - (a.hasActiveSession ? 1 : 0);
    if (active != 0) {
      return active;
    }
    final int due = b.dueReviewCount.compareTo(a.dueReviewCount);
    if (due != 0) {
      return due;
    }
    final DateTime aTime =
        a.lastPracticedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime bTime =
        b.lastPracticedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  List<_InterviewSceneHomeStatus> _statusesForHomeSceneCategory(
    String category,
  ) {
    final List<_InterviewSceneHomeStatus> statuses =
        category == _recommendedHomeSceneCategory
        ? List<_InterviewSceneHomeStatus>.from(_interviewSceneStatuses)
        : _interviewSceneStatuses
              .where(
                (_InterviewSceneHomeStatus status) =>
                    _matchesHomeSceneCategory(status, category),
              )
              .toList(growable: false);
    statuses.sort(_compareHomeCategorySceneStatus);
    return statuses;
  }

  int _compareHomeCategorySceneStatus(
    _InterviewSceneHomeStatus a,
    _InterviewSceneHomeStatus b,
  ) {
    final int active =
        ((b.entry.id == _activeLearningSceneStatus?.entry.id) ? 1 : 0) -
        ((a.entry.id == _activeLearningSceneStatus?.entry.id) ? 1 : 0);
    if (active != 0) {
      return active;
    }
    final int selected =
        (_selectedLearningSceneIds.contains(b.entry.id) ? 1 : 0) -
        (_selectedLearningSceneIds.contains(a.entry.id) ? 1 : 0);
    if (selected != 0) {
      return selected;
    }
    return _compareSceneStatus(a, b);
  }

  Future<void> _openInterviewScene(
    _InterviewSceneHomeStatus status, {
    String? targetLevel,
    String? initialNodeId,
  }) async {
    final String resolvedTargetLevel =
        targetLevel ?? status.selectedTargetLevel;
    if (!_canAccessSceneTargetLevel(resolvedTargetLevel)) {
      _showCommercialScenarioGate();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => InterviewPracticePage(
          sceneId: status.entry.id,
          targetLevel: resolvedTargetLevel,
          initialNodeId: initialNodeId ?? '',
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    unawaited(_loadInterviewSceneStatuses());
  }

  Future<void> _openSceneListening(
    _InterviewSceneHomeStatus status, {
    String? targetLevel,
  }) async {
    final String resolvedTargetLevel =
        targetLevel ?? status.selectedTargetLevel;
    if (!_canAccessSceneTargetLevel(resolvedTargetLevel)) {
      _showCommercialScenarioGate();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => InterviewSceneListeningPage(
          sceneId: status.entry.id,
          targetLevel: resolvedTargetLevel,
          coverUrl: _sceneCoverUrl(status.entry.id),
        ),
      ),
    );
  }

  Future<void> _openExpressionWarmupDeck(
    _InterviewSceneHomeStatus status,
    String targetLevel, {
    String initialTaskType = '',
  }) async {
    if (!_canAccessSceneTargetLevel(targetLevel)) {
      _showCommercialScenarioGate();
      return;
    }
    final InterviewExpressionLearningResult? result =
        await Navigator.of(context).push(
          MaterialPageRoute<InterviewExpressionLearningResult>(
            builder: (BuildContext context) => InterviewExpressionLearningPage(
              sceneId: status.entry.id,
              targetLevel: targetLevel,
              nodeId: '',
              quickWarmup: true,
              maxCards: 3,
              initialTaskType: initialTaskType,
            ),
          ),
        );
    if (!mounted) {
      return;
    }
    unawaited(_loadInterviewSceneStatuses());
    if (result != null && result.practiceScene) {
      await _addLearningScene(status, setActive: true);
      await _openInterviewScene(
        status,
        targetLevel: result.targetLevel,
        initialNodeId: result.nodeId,
      );
    }
  }

  Future<void> _practiceExpressionInSceneById(
    _InterviewSceneHomeStatus status,
    String nodeId,
  ) async {
    if (!_canAccessSceneTargetLevel(status.selectedTargetLevel)) {
      _showCommercialScenarioGate();
      return;
    }
    await _addLearningScene(status, setActive: true);
    await _openInterviewScene(
      status,
      targetLevel: status.selectedTargetLevel,
      initialNodeId: nodeId,
    );
  }

  Future<void> _openHomeSceneIntro(_InterviewSceneHomeStatus status) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => _HomeSceneIntroPage(
          status: status,
          isJoined: _selectedLearningSceneIds.contains(status.entry.id),
          hasProEntitlement: AppSessionScope.of(context).isPro,
          onSelectLevel: (String targetLevel) async {
            await _selectInterviewSceneLevel(status, targetLevel);
          },
          onJoinLearning: (String targetLevel) async {
            await InterviewWikiStore(
              sceneId: status.entry.id,
            ).saveSelectedTargetLevel(targetLevel);
            await _addLearningScene(status, setActive: true);
          },
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    unawaited(_loadInterviewSceneStatuses());
  }

  Future<void> _openCompletedSceneArchive() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => _CompletedHomeScenesPage(
          statuses: _completedLearningSceneStatuses,
          onOpenIntro: _openHomeSceneIntro,
        ),
      ),
    );
  }

  Future<void> _selectInterviewSceneLevel(
    _InterviewSceneHomeStatus status,
    String targetLevel,
  ) async {
    if (!_canAccessSceneTargetLevel(targetLevel)) {
      _showCommercialScenarioGate();
      return;
    }
    await InterviewWikiStore(
      sceneId: status.entry.id,
    ).saveSelectedTargetLevel(targetLevel);
    if (!mounted) {
      return;
    }
    await _loadInterviewSceneStatuses();
  }

  bool _canAccessSceneTargetLevel(String targetLevel) {
    return CommercialScenarioGate.canAccess(
      targetLevel: targetLevel,
      isPro: AppSessionScope.of(context).isPro,
    );
  }

  void _showCommercialScenarioGate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(CommercialScenarioGate.lockedMessage)),
    );
  }

  Future<void> _persistLearningSceneSelection({
    required List<String> selectedSceneIds,
    required String? activeSceneId,
  }) async {
    final List<String> normalizedIds = _sanitizeLearningSceneIds(
      selectedSceneIds,
      _interviewSceneStatuses,
    );
    final String? normalizedActiveSceneId = _resolveStoredActiveSceneId(
      activeSceneId,
      normalizedIds,
    );
    if (mounted) {
      setState(() {
        _selectedLearningSceneIds = normalizedIds;
        _activeLearningSceneId = normalizedActiveSceneId;
        _dailyExpressionQueueSignature = '';
        _dailyExpressionQueueFuture = null;
      });
    }
    await StorageService.instance.saveInterviewHomeSceneSelection(
      InterviewHomeSceneSelectionStorageModel(
        selectedSceneIds: normalizedIds,
        activeSceneId: normalizedActiveSceneId,
      ),
    );
  }

  Future<void> _addLearningScene(
    _InterviewSceneHomeStatus status, {
    bool setActive = false,
  }) {
    final List<String> nextIds = List<String>.from(_selectedLearningSceneIds);
    if (!nextIds.contains(status.entry.id)) {
      nextIds.add(status.entry.id);
    }
    final String? nextActiveId =
        setActive || (_activeLearningSceneId == null && nextIds.length == 1)
        ? status.entry.id
        : _activeLearningSceneId;
    return _persistLearningSceneSelection(
      selectedSceneIds: nextIds,
      activeSceneId: nextActiveId,
    );
  }

  Future<void> _setActiveLearningScene(_InterviewSceneHomeStatus status) {
    return _addLearningScene(status, setActive: true);
  }

  Future<void> _removeLearningScene(_InterviewSceneHomeStatus status) {
    final List<String> nextIds = _selectedLearningSceneIds
        .where((String sceneId) => sceneId != status.entry.id)
        .toList(growable: false);
    final String? nextActiveId = _activeLearningSceneId == status.entry.id
        ? (nextIds.isNotEmpty ? nextIds.first : null)
        : _activeLearningSceneId;
    return _persistLearningSceneSelection(
      selectedSceneIds: nextIds,
      activeSceneId: nextActiveId,
    );
  }

  Future<void> _showLearningScenePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: appBackground,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return _LearningScenePickerSheet(
          statuses: _interviewSceneStatuses,
          selectedSceneIds: _selectedLearningSceneIds,
          activeSceneId: _activeLearningSceneStatus?.entry.id,
          onToggleScene: (_InterviewSceneHomeStatus status, bool selected) {
            if (selected) {
              unawaited(_addLearningScene(status));
            } else {
              unawaited(_removeLearningScene(status));
            }
          },
          onSetActiveScene: (_InterviewSceneHomeStatus status) {
            unawaited(_setActiveLearningScene(status));
          },
          onSelectLevel:
              (_InterviewSceneHomeStatus status, String targetLevel) {
                unawaited(_selectInterviewSceneLevel(status, targetLevel));
              },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double learnTopChromeHeight = MediaQuery.paddingOf(context).top + 76;
    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle.dark
        .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: appBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: appBackground,
        body: Stack(
          children: [
            if (_activeBottomIndex == 0) ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: learnTopChromeHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: appBackground,
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFE8E3DC),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: learnTopChromeHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0.8, -0.92),
                        radius: 0.9,
                        colors: [Color(0x22BEE6A0), Color(0x00BEE6A0)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            SafeArea(
              bottom: false,
              child: switch (_activeBottomIndex) {
                0 => _buildLearnTab(),
                1 => _buildExpressionTrainingTab(),
                2 => ProfilePage(
                  completedSceneCount: _completedLearningSceneStatuses.length,
                  onOpenCompletedScenes: () =>
                      unawaited(_openCompletedSceneArchive()),
                ),
                _ => _buildLearnTab(),
              },
            ),
            if (_searchExpanded) Positioned.fill(child: _buildSearchOverlay()),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          currentIndex: _activeBottomIndex,
          onChanged: (int index) {
            setState(() {
              _activeBottomIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildLearnTab() {
    final _InterviewSceneHomeStatus? activeStatus = _activeLearningSceneStatus;
    final List<_InterviewSceneHomeStatus> categoryStatuses =
        _statusesForHomeSceneCategory(_selectedHomeSceneCategory);
    final List<_InterviewSceneHomeStatus> selectedStatuses =
        _selectedLearningSceneStatuses;
    final List<_InterviewSceneHomeStatus> selectedHeroStatuses =
        selectedStatuses
            .where(_shouldShowSceneInHomeHero)
            .toList(growable: false);
    final _InterviewSceneHomeStatus? fallbackHeroStatus =
        activeStatus != null && _shouldShowSceneInHomeHero(activeStatus)
        ? activeStatus
        : _recommendedActionableInterviewSceneStatus;
    final List<_InterviewSceneHomeStatus> heroStatuses =
        selectedHeroStatuses.isNotEmpty
        ? selectedHeroStatuses
        : <_InterviewSceneHomeStatus>[?fallbackHeroStatus];
    final String? heroActiveSceneId =
        heroStatuses.any(
          (_InterviewSceneHomeStatus status) =>
              status.entry.id == activeStatus?.entry.id,
        )
        ? activeStatus?.entry.id
        : (heroStatuses.isEmpty ? null : heroStatuses.first.entry.id);
    return Column(
      children: [
        _HomeHeader(
          masteredExpressionCount: _totalMasteredExpressionCount,
          totalExpressionCount: _totalExpressionCount,
          onSearchTap: () {
            setState(() {
              _searchExpanded = true;
              _searchController.clear();
            });
          },
        ),
        Expanded(
          child: ListView(
            key: const ValueKey<String>('home_learn_scroll'),
            padding: const EdgeInsets.fromLTRB(14, 34, 14, 100),
            children: [
              const _ActiveLearningSceneSectionHeader(),
              const SizedBox(height: 10),
              _ActiveLearningSceneCarousel(
                loading: _interviewScenesLoading,
                controller: _learningScenePageController,
                statuses: heroStatuses,
                activeSceneId: heroActiveSceneId,
                selectedSceneIds: _selectedLearningSceneIds,
                onListenScene: (status) => unawaited(
                  _openSceneListening(
                    status,
                    targetLevel: status.selectedTargetLevel,
                  ),
                ),
                onOpenScene: (status) => unawaited(_openInterviewScene(status)),
                onWarmupExpressions: (status) => unawaited(
                  _openExpressionWarmupDeck(
                    status,
                    status.selectedTargetLevel,
                    initialTaskType: 'shadow',
                  ),
                ),
                onRemoveScene: (status) =>
                    unawaited(_removeLearningScene(status)),
                onPageChanged: (status) =>
                    unawaited(_setActiveLearningScene(status)),
              ),
              const SizedBox(height: 16),
              _HomeSceneCategoryModule(
                loading: _interviewScenesLoading,
                categories: _homeSceneCategories,
                selectedCategory: _selectedHomeSceneCategory,
                statuses: categoryStatuses,
                totalSceneCount: _interviewSceneStatuses.length,
                selectedSceneIds: _selectedLearningSceneIds,
                activeSceneId: activeStatus?.entry.id,
                onCategoryChanged: (String category) {
                  setState(() => _selectedHomeSceneCategory = category);
                },
                onOpenIntro: (status) => unawaited(_openHomeSceneIntro(status)),
                onJoinScene: (status) =>
                    unawaited(_addLearningScene(status, setActive: true)),
                onOpenPicker: () => unawaited(_showLearningScenePicker()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpressionTrainingTab() {
    final List<_InterviewSceneHomeStatus> selectedStatuses =
        _selectedLearningSceneStatuses;
    final _InterviewSceneHomeStatus? activeStatus = _activeLearningSceneStatus;
    final List<_InterviewSceneHomeStatus> trainingStatuses =
        selectedStatuses.isNotEmpty
        ? <_InterviewSceneHomeStatus>[
            ?activeStatus,
            ...selectedStatuses.where(
              (_InterviewSceneHomeStatus status) =>
                  status.entry.id != activeStatus?.entry.id,
            ),
          ]
        : const <_InterviewSceneHomeStatus>[];
    if (_interviewScenesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (trainingStatuses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: _HomeExpressionTrainingEmpty(),
      );
    }
    return FutureBuilder<List<ExpressionDailyQueueItem>>(
      future: _dailyQueueFutureFor(trainingStatuses),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<ExpressionDailyQueueItem>> snapshot,
          ) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: _HomeExpressionTrainingEmpty(message: '今日表达加载失败，请稍后再试。'),
              );
            }
            final List<ExpressionDailyQueueItem> queueItems =
                snapshot.data ?? const <ExpressionDailyQueueItem>[];
            if (queueItems.isEmpty) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: _HomeExpressionTrainingEmpty(
                  message: '当前没有需要复习、补弱或拓展的表达。完成更多情景学习后会继续推荐。',
                ),
              );
            }
            return InterviewExpressionWarmupDeckView(
              sceneId: queueItems.first.sceneId,
              targetLevel: queueItems.first.targetLevel,
              quickWarmup: false,
              maxCards: 24,
              showHeader: false,
              queueItems: queueItems,
              onRefreshQueue: () =>
                  _refreshDailyExpressionQueue(trainingStatuses),
              onPracticeQueueItem: (ExpressionDailyQueueItem item) {
                final _InterviewSceneHomeStatus? status = _statusBySceneId(
                  item.sceneId,
                );
                if (status == null) {
                  return;
                }
                unawaited(
                  _practiceExpressionInSceneById(
                    status,
                    item.variantOfNodeId.isNotEmpty
                        ? item.variantOfNodeId
                        : item.nodeId,
                  ),
                );
              },
            );
          },
    );
  }

  Future<List<ExpressionDailyQueueItem>> _buildDailyExpressionQueueFuture(
    List<_InterviewSceneHomeStatus> statuses,
  ) {
    return _dailyQueueCoordinator.buildQueue(
      scenes: <ExpressionDailyQueueScene>[
        for (int index = 0; index < statuses.length; index += 1)
          ExpressionDailyQueueScene(
            sceneId: statuses[index].entry.id,
            targetLevel: statuses[index].selectedTargetLevel,
            title: statuses[index].title,
            order: index,
          ),
      ],
    );
  }

  String _dailyQueueSignatureFor(List<_InterviewSceneHomeStatus> statuses) {
    return <String>[
      ...statuses.map(
        (_InterviewSceneHomeStatus status) =>
            '${status.entry.id}:${status.selectedTargetLevel}:'
            '${status.dueReviewCount}:${status.weakExpressionCount}:'
            '${status.masteredExpressionCount}:${status.lastPracticedAt?.millisecondsSinceEpoch ?? 0}',
      ),
    ].join('|');
  }

  Future<List<ExpressionDailyQueueItem>> _dailyQueueFutureFor(
    List<_InterviewSceneHomeStatus> statuses,
  ) {
    final String signature = _dailyQueueSignatureFor(statuses);
    if (_dailyExpressionQueueSignature != signature ||
        _dailyExpressionQueueFuture == null) {
      _dailyExpressionQueueSignature = signature;
      _dailyExpressionQueueFuture = _buildDailyExpressionQueueFuture(statuses);
    }
    return _dailyExpressionQueueFuture!;
  }

  Future<void> _refreshDailyExpressionQueue(
    List<_InterviewSceneHomeStatus> statuses,
  ) async {
    final String signature = _dailyQueueSignatureFor(statuses);
    final Future<List<ExpressionDailyQueueItem>> nextFuture =
        _buildDailyExpressionQueueFuture(statuses);
    if (mounted) {
      setState(() {
        _dailyExpressionQueueSignature = signature;
        _dailyExpressionQueueFuture = nextFuture;
      });
    }
    await nextFuture;
  }

  _InterviewSceneHomeStatus? _statusBySceneId(String sceneId) {
    final String normalized = sceneId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final _InterviewSceneHomeStatus status in _interviewSceneStatuses) {
      if (status.entry.id == normalized) {
        return status;
      }
    }
    return null;
  }

  Widget _buildSearchOverlay() {
    final AppLocalizations l10n = context.l10n;
    return Container(
      color: appBackground,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.68, -1),
                end: Alignment(0.92, 1),
                colors: [
                  Color(0xFF2E4A2C),
                  Color(0xFF4A7244),
                  Color(0xFF87B076),
                  appBackground,
                ],
                stops: [0, 0.38, 0.72, 1],
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchExpanded = false;
                      _searchController.clear();
                    });
                  },
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xF2FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          size: 14,
                          color: Color(0xFF8EAA80),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              isCollapsed: true,
                              hintText: '搜索场景',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFB8C0B0),
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _searchController.clear()),
                            child: const Text(
                              '✕',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFB8C0B0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
              children: [
                if (_searchController.text.trim().isEmpty)
                  _SearchPlaceholder(
                    icon: Icons.search_rounded,
                    title: '输入关键词搜索场景',
                  )
                else if (_searchSceneStatuses.isEmpty)
                  _SearchPlaceholder(emoji: '🔍', title: l10n.noResultsFound)
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      l10n.foundResults(_searchSceneStatuses.length),
                      style: const TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  ..._searchSceneStatuses.map(
                    (_InterviewSceneHomeStatus status) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _WikiSceneTile(
                        status: status,
                        imageHeight: 150,
                        onSelectLevel: (String targetLevel) => unawaited(
                          _selectInterviewSceneLevel(status, targetLevel),
                        ),
                        onTap: () {
                          setState(() {
                            _searchExpanded = false;
                            _searchController.clear();
                          });
                          unawaited(_openHomeSceneIntro(status));
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewSceneHomeStatus {
  const _InterviewSceneHomeStatus({
    required this.entry,
    required this.title,
    required this.description,
    required this.tags,
    required this.trackLabels,
    required this.levelOptions,
    required this.selectedTargetLevel,
    required this.publicTrackCount,
    required this.publicPhaseCount,
    required this.totalExpressionCount,
    required this.masteredExpressionCount,
    required this.dueReviewCount,
    required this.weakExpressionCount,
    required this.personalMaterialCount,
    required this.nextTargetLabel,
    required this.nextTargetDetail,
    required this.nextTargetMode,
    required this.hasActiveSession,
    required this.lastPracticedAt,
  });

  final InterviewSceneCatalogEntry entry;
  final String title;
  final String description;
  final List<String> tags;
  final List<String> trackLabels;
  final List<_InterviewSceneLevelOption> levelOptions;
  final String selectedTargetLevel;
  final int publicTrackCount;
  final int publicPhaseCount;
  final int totalExpressionCount;
  final int masteredExpressionCount;
  final int dueReviewCount;
  final int weakExpressionCount;
  final int personalMaterialCount;
  final String nextTargetLabel;
  final String nextTargetDetail;
  final String nextTargetMode;
  final bool hasActiveSession;
  final DateTime? lastPracticedAt;

  double get masteryRatio {
    if (totalExpressionCount <= 0) {
      return 0;
    }
    return masteredExpressionCount / totalExpressionCount;
  }

  bool get isCompleted =>
      totalExpressionCount > 0 &&
      masteredExpressionCount >= totalExpressionCount;

  String get ctaLabel {
    if (hasActiveSession) {
      return '继续练习';
    }
    if (dueReviewCount > 0) {
      return '开始练习';
    }
    if (masteredExpressionCount < totalExpressionCount) {
      return '学习新表达';
    }
    return '巩固复习';
  }

  IconData get ctaIcon {
    if (hasActiveSession) {
      return Icons.play_arrow_rounded;
    }
    if (dueReviewCount > 0) {
      return Icons.replay_rounded;
    }
    return Icons.auto_awesome_rounded;
  }
}

class _InterviewSceneNextTarget {
  const _InterviewSceneNextTarget({
    required this.mode,
    required this.label,
    required this.detail,
  });

  final String mode;
  final String label;
  final String detail;
}

const String _allSceneTagLabel = '全部';
const String _recommendedHomeSceneCategory = '推荐';
const List<String> _homeSceneCategories = <String>[
  _recommendedHomeSceneCategory,
  '日常寒暄',
  '餐饮点单',
  '购物消费',
  '出行交通',
  '酒店旅行',
  '医疗药店',
  '居住生活',
  '校园学习',
  '职场基础',
  '会议沟通',
  '项目协作',
  '客户商务',
];

const Map<String, List<String>> _homeSceneCategoryKeywords =
    <String, List<String>>{
      '日常寒暄': <String>['寒暄', '问候', '聊天', '社交', 'small talk', 'daily'],
      '餐饮点单': <String>['餐饮', '点单', '餐厅', '咖啡', '菜单', 'restaurant', 'order'],
      '购物消费': <String>['购物', '消费', '付款', '退换', '价格', 'shop', 'purchase'],
      '出行交通': <String>['出行', '交通', '打车', '地铁', '机场', 'taxi', 'transport'],
      '酒店旅行': <String>['酒店', '旅行', '入住', '预订', '旅途', 'hotel', 'travel'],
      '医疗药店': <String>['医疗', '药店', '看病', '症状', '处方', 'clinic', 'pharmacy'],
      '居住生活': <String>['居住', '租房', '邻居', '维修', '生活', 'home', 'housing'],
      '校园学习': <String>['校园', '学习', '课程', '考试', '老师', 'school', 'study'],
      '职场基础': <String>['职场', '工作', '求职', '面试', '简历', '同事', '入职', 'work'],
      '会议沟通': <String>['会议', '沟通', '汇报', '讨论', '纪要', 'meeting'],
      '项目协作': <String>['项目', '协作', '进度', '任务', '交付', 'project'],
      '客户商务': <String>['客户', '商务', '销售', '谈判', '合作', '报价', 'business'],
    };
const String _allDifficultyTargetLevel = 'all';
const List<({String label, String targetLevel})> _wikiDifficultyFilters =
    <({String label, String targetLevel})>[
      (label: '全部', targetLevel: _allDifficultyTargetLevel),
      (label: 'L1 入门', targetLevel: 'beginner'),
      (label: 'L2 进阶', targetLevel: 'intermediate'),
      (label: 'L3 精通', targetLevel: 'advanced'),
    ];

class _InterviewSceneLevelOption {
  const _InterviewSceneLevelOption({
    required this.title,
    required this.targetLevel,
    required this.expressionCount,
  });

  final String title;
  final String targetLevel;
  final int expressionCount;
}

class _ActiveLearningSceneCarousel extends StatelessWidget {
  const _ActiveLearningSceneCarousel({
    required this.loading,
    required this.controller,
    required this.statuses,
    required this.activeSceneId,
    required this.selectedSceneIds,
    required this.onListenScene,
    required this.onOpenScene,
    required this.onWarmupExpressions,
    required this.onRemoveScene,
    required this.onPageChanged,
  });

  final bool loading;
  final PageController controller;
  final List<_InterviewSceneHomeStatus> statuses;
  final String? activeSceneId;
  final List<String> selectedSceneIds;
  final ValueChanged<_InterviewSceneHomeStatus> onListenScene;
  final ValueChanged<_InterviewSceneHomeStatus> onOpenScene;
  final ValueChanged<_InterviewSceneHomeStatus> onWarmupExpressions;
  final ValueChanged<_InterviewSceneHomeStatus> onRemoveScene;
  final ValueChanged<_InterviewSceneHomeStatus> onPageChanged;

  Future<void> _confirmRemoveScene(
    BuildContext context,
    _InterviewSceneHomeStatus status,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            '移除学习场景？',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          content: Text(
            '将「${status.title}」从我的学习中移除，已完成的练习记录不会删除。',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE45757),
                foregroundColor: Colors.white,
              ),
              child: const Text('移除'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    onRemoveScene(status);
  }

  @override
  Widget build(BuildContext context) {
    if (loading && statuses.isEmpty) {
      return const _OrchestrationSkeletonCard();
    }
    if (statuses.isEmpty) {
      return const _OrchestrationEmptyCard();
    }
    final int activeIndex = statuses.indexWhere(
      (_InterviewSceneHomeStatus status) => status.entry.id == activeSceneId,
    );
    final int safeActiveIndex = activeIndex < 0 ? 0 : activeIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.hasClients) {
        return;
      }
      final int? currentPage = controller.page?.round();
      if (currentPage != safeActiveIndex) {
        controller.jumpToPage(safeActiveIndex);
      }
    });
    return Column(
      children: [
        SizedBox(
          height: 376,
          child: PageView.builder(
            controller: controller,
            itemCount: statuses.length,
            onPageChanged: (int index) => onPageChanged(statuses[index]),
            itemBuilder: (BuildContext context, int index) {
              final _InterviewSceneHomeStatus status = statuses[index];
              final bool isUserSelected = selectedSceneIds.contains(
                status.entry.id,
              );
              return _ActiveLearningSceneHero(
                status: status,
                onListenScene: onListenScene,
                onOpenScene: onOpenScene,
                onWarmupExpressions: onWarmupExpressions,
                onRemoveScene: isUserSelected
                    ? () => unawaited(_confirmRemoveScene(context, status))
                    : null,
              );
            },
          ),
        ),
        if (statuses.length > 1) ...[
          const SizedBox(height: 10),
          _CarouselDots(count: statuses.length, activeIndex: safeActiveIndex),
        ],
      ],
    );
  }
}

class _ActiveLearningSceneHero extends StatelessWidget {
  const _ActiveLearningSceneHero({
    required this.status,
    required this.onListenScene,
    required this.onOpenScene,
    required this.onWarmupExpressions,
    required this.onRemoveScene,
  });

  final _InterviewSceneHomeStatus? status;
  final ValueChanged<_InterviewSceneHomeStatus> onListenScene;
  final ValueChanged<_InterviewSceneHomeStatus> onOpenScene;
  final ValueChanged<_InterviewSceneHomeStatus> onWarmupExpressions;
  final VoidCallback? onRemoveScene;

  @override
  Widget build(BuildContext context) {
    final _InterviewSceneHomeStatus? current = status;
    if (current == null) {
      return const _OrchestrationEmptyCard();
    }

    final Color accent = _sceneAccentColor(current);
    return Container(
      height: 376,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFBF3), Color(0xFFF3E4CC)],
          stops: [0, 0.56, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE7D3B4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24896634),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Color(0x0CFFFFFF),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 156,
            child: Stack(
              children: [
                Positioned.fill(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          return AppCachedNetworkImage(
                            imageUrl: _sceneCoverUrl(current.entry.id),
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            fit: BoxFit.cover,
                            placeholder: AppImagePlaceholder(
                              color: accent.withValues(alpha: 0.22),
                              icon: _sceneTagIcon(_firstSceneTag(current)),
                              iconColor: accent,
                            ),
                            errorWidget: AppImagePlaceholder(
                              color: accent.withValues(alpha: 0.22),
                              icon: _sceneTagIcon(_firstSceneTag(current)),
                              iconColor: accent,
                            ),
                          );
                        },
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFEAD3AA).withValues(alpha: 0.48),
                          const Color(0xFF8F6A43).withValues(alpha: 0.50),
                          const Color(0xFF2D2720).withValues(alpha: 0.86),
                        ],
                        stops: const [0, 0.52, 1],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.15, -0.18),
                        radius: 0.55,
                        colors: [
                          Colors.white.withValues(alpha: 0.16),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                if (onRemoveScene != null)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _HeroRemoveButton(onPressed: onRemoveScene!),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Text(
                        current.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0,
                          shadows: [
                            Shadow(
                              color: Color(0xB3000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Text(
                          _activeLevelLabel(current),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _HeroNextStepPanel(
              status: current,
              onListenScene: () => onListenScene(current),
              onOpenScene: () => onOpenScene(current),
              onWarmupExpressions: () => onWarmupExpressions(current),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (int index) {
        final bool active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? 18 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF24476F) : const Color(0xFFD8DDE5),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _HeroRemoveButton extends StatelessWidget {
  const _HeroRemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '移除学习场景',
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(999),
            elevation: 4,
            shadowColor: const Color(0x22000000),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                child: const Icon(
                  Icons.remove_rounded,
                  size: 23,
                  color: Color(0xFF24476F),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroNextStepPanel extends StatelessWidget {
  const _HeroNextStepPanel({
    required this.status,
    required this.onListenScene,
    required this.onOpenScene,
    required this.onWarmupExpressions,
  });

  final _InterviewSceneHomeStatus status;
  final VoidCallback onListenScene;
  final VoidCallback onOpenScene;
  final VoidCallback onWarmupExpressions;

  List<String> get _coachChips {
    if (status.weakExpressionCount > 0) {
      return const <String>['薄弱补强', '语法纠错', '发音评分'];
    }
    if (status.dueReviewCount > 0) {
      return const <String>['间隔复习', '发音评分', '表达纠偏'];
    }
    return const <String>['发音评分', '语法纠错', '追问陪练'];
  }

  @override
  Widget build(BuildContext context) {
    final int remainingCount =
        status.totalExpressionCount - status.masteredExpressionCount;
    final int waitingCount = remainingCount > 0 ? remainingCount : 0;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFA), Color(0xFFFBF3E6), Color(0xFFF2E1C6)],
          stops: [0, 0.54, 1],
        ),
        border: Border(top: BorderSide(color: Color(0xFFE9D8BB))),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本次目标 · ${status.nextTargetMode}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status.nextTargetLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.18,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _coachChips
                        .map((String label) => _HeroCoachChip(label: label))
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  _HeroCompactProgressSummary(
                    reviewCount: status.dueReviewCount,
                    waitingCount: waitingCount,
                    masteredCount: status.masteredExpressionCount,
                    totalCount: status.totalExpressionCount,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: status.masteryRatio.clamp(0, 1),
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE9DCC8),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFB77935),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 66,
            padding: const EdgeInsets.fromLTRB(12, 3, 12, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x18A8783A))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroBottomAction(
                    key: const ValueKey<String>('home_hero_listen_button'),
                    icon: Icons.local_fire_department_rounded,
                    label: '开始热身',
                    onPressed: onListenScene,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _HeroBottomAction(
                    key: const ValueKey<String>('home_hero_practice_button'),
                    icon: Icons.play_arrow_rounded,
                    label: '开始模拟',
                    onPressed: onOpenScene,
                    primary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBottomAction extends StatelessWidget {
  const _HeroBottomAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(18);
    final List<Color> gradientColors = primary
        ? const <Color>[Color(0xFFE6BF7B), Color(0xFFC78943), Color(0xFF9E642B)]
        : const <Color>[
            Color(0xFFFFFBF2),
            Color(0xFFF2E5CF),
            Color(0xFFE7D2AE),
          ];
    final Color foreground = primary ? Colors.white : const Color(0xFF6E4E1F);
    final Color iconSurface = primary
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.70);
    final Color iconBorder = primary
        ? Colors.white.withValues(alpha: 0.20)
        : const Color(0xFFE1C79C);
    final Color topHighlight = Colors.white.withValues(
      alpha: primary ? 0.28 : 0.78,
    );
    final Color bottomShade = primary
        ? const Color(0x40734518)
        : const Color(0x24856828);
    final Color borderColor = primary
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFE3CDA8);
    final Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: iconBorder),
          ),
          child: Icon(icon, size: 15),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: foreground,
              shadows: primary
                  ? const <Shadow>[
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: primary ? const Color(0x33915F29) : const Color(0x228E6627),
            blurRadius: 14,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
              stops: const <double>[0, 0.52, 1],
            ),
            borderRadius: borderRadius,
            border: Border.all(color: borderColor),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: borderRadius,
            splashColor: Colors.white.withValues(alpha: primary ? 0.16 : 0.30),
            highlightColor: Colors.white.withValues(
              alpha: primary ? 0.08 : 0.22,
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: topHighlight),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.transparent, bottomShade],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconTheme(
                      data: IconThemeData(color: foreground),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: foreground),
                        child: content,
                      ),
                    ),
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

class _HeroCoachChip extends StatelessWidget {
  const _HeroCoachChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8D7BA)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          height: 1,
          fontWeight: FontWeight.w900,
          color: Color(0xFF7B5727),
        ),
      ),
    );
  }
}

class _HeroCompactProgressSummary extends StatelessWidget {
  const _HeroCompactProgressSummary({
    required this.reviewCount,
    required this.waitingCount,
    required this.masteredCount,
    required this.totalCount,
  });

  final int reviewCount;
  final int waitingCount;
  final int masteredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '复习 $reviewCount · 待学 $waitingCount · 掌握 $masteredCount/$totalCount',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 11.5,
        height: 1,
        fontWeight: FontWeight.w900,
        color: textSecondary,
      ),
    );
  }
}

class _OrchestrationSkeletonCard extends StatelessWidget {
  const _OrchestrationSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 264,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _OrchestrationEmptyCard extends StatelessWidget {
  const _OrchestrationEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: const Text(
        '还没有学习中的场景',
        style: TextStyle(fontSize: 13, color: textSecondary),
      ),
    );
  }
}

class _ActiveLearningSceneSectionHeader extends StatelessWidget {
  const _ActiveLearningSceneSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '我的学习中',
      style: TextStyle(
        fontSize: 17,
        height: 1,
        fontWeight: FontWeight.w900,
        color: textPrimary,
      ),
    );
  }
}

class _HomeSceneModuleHeader extends StatelessWidget {
  const _HomeSceneModuleHeader();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '学习场景',
      style: TextStyle(
        fontSize: 17,
        height: 1,
        fontWeight: FontWeight.w900,
        color: textPrimary,
      ),
    );
  }
}

class _HomeExpressionTrainingEmpty extends StatelessWidget {
  const _HomeExpressionTrainingEmpty({this.message = '加入场景后，这里会推荐今天要热身的目标表达。'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 12.5,
          color: textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomeSceneCategoryModule extends StatelessWidget {
  const _HomeSceneCategoryModule({
    required this.loading,
    required this.categories,
    required this.selectedCategory,
    required this.statuses,
    required this.totalSceneCount,
    required this.selectedSceneIds,
    required this.activeSceneId,
    required this.onCategoryChanged,
    required this.onOpenIntro,
    required this.onJoinScene,
    required this.onOpenPicker,
  });

  final bool loading;
  final List<String> categories;
  final String selectedCategory;
  final List<_InterviewSceneHomeStatus> statuses;
  final int totalSceneCount;
  final List<String> selectedSceneIds;
  final String? activeSceneId;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<_InterviewSceneHomeStatus> onOpenIntro;
  final ValueChanged<_InterviewSceneHomeStatus> onJoinScene;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HomeSceneModuleHeader(),
        const SizedBox(height: 9),
        _HomeSceneCategoryRail(
          categories: categories,
          selectedCategory: selectedCategory,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 10),
        if (loading && totalSceneCount == 0)
          const _HomeSceneGridSkeleton()
        else if (totalSceneCount == 0)
          const _InterviewSceneEmptyCard()
        else if (statuses.isEmpty)
          const _HomeSceneCategoryEmptyCard(message: '当前分类暂无场景')
        else
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: statuses.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 198,
            ),
            itemBuilder: (BuildContext context, int index) {
              final _InterviewSceneHomeStatus status = statuses[index];
              final bool selected = selectedSceneIds.contains(status.entry.id);
              final bool active = activeSceneId == status.entry.id;
              return _HomeSceneGridCard(
                key: ValueKey<String>(
                  'home_scene_grid_card_${status.entry.id}',
                ),
                status: status,
                selected: selected,
                active: active,
                onTap: () => onOpenIntro(status),
                onJoin: status.isCompleted
                    ? () => onOpenIntro(status)
                    : () => onJoinScene(status),
              );
            },
          ),
      ],
    );
  }
}

class _HomeSceneCategoryRail extends StatelessWidget {
  const _HomeSceneCategoryRail({
    required this.categories,
    required this.selectedCategory,
    required this.onChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) {
          final String category = categories[index];
          final bool selected = category == selectedCategory;
          return GestureDetector(
            onTap: () => onChanged(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: selected ? darkGreen : const Color(0xFFF8F6F2),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? darkGreen : const Color(0xFFEDE8DF),
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeSceneGridCard extends StatelessWidget {
  const _HomeSceneGridCard({
    super.key,
    required this.status,
    required this.selected,
    required this.active,
    required this.onTap,
    required this.onJoin,
  });

  final _InterviewSceneHomeStatus status;
  final bool selected;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final Color accent = _sceneAccentColor(status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? accent.withValues(alpha: 0.34) : borderColor,
            width: active ? 1.2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 112,
              child: AppCachedNetworkImage(
                imageUrl: _sceneCoverUrl(status.entry.id),
                fit: BoxFit.cover,
                placeholder: AppImagePlaceholder(
                  color: accent.withValues(alpha: 0.18),
                  icon: _sceneTagIcon(_firstSceneTag(status)),
                  iconColor: accent,
                ),
                errorWidget: AppImagePlaceholder(
                  color: accent.withValues(alpha: 0.18),
                  icon: _sceneTagIcon(_firstSceneTag(status)),
                  iconColor: accent,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.16,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '${status.totalExpressionCount} 个表达',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _HomeSceneJoinButton(
                          key: ValueKey<String>(
                            'home_scene_join_${status.entry.id}',
                          ),
                          selected: selected,
                          completed: status.isCompleted,
                          onPressed: onJoin,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSceneJoinButton extends StatelessWidget {
  const _HomeSceneJoinButton({
    super.key,
    required this.selected,
    required this.completed,
    required this.onPressed,
  });

  final bool selected;
  final bool completed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String label = completed
        ? '已完成'
        : selected
        ? '已加入'
        : '加入学习';
    final bool passive = completed || selected;
    final Color foreground = passive ? darkGreen : Colors.white;
    final Color background = passive
        ? Colors.white.withValues(alpha: 0.94)
        : darkGreen.withValues(alpha: 0.94);
    final IconData icon = passive ? Icons.check_rounded : Icons.add_rounded;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSceneIntroPage extends StatefulWidget {
  const _HomeSceneIntroPage({
    required this.status,
    required this.isJoined,
    required this.hasProEntitlement,
    required this.onSelectLevel,
    required this.onJoinLearning,
  });

  final _InterviewSceneHomeStatus status;
  final bool isJoined;
  final bool hasProEntitlement;
  final Future<void> Function(String targetLevel) onSelectLevel;
  final Future<void> Function(String targetLevel) onJoinLearning;

  @override
  State<_HomeSceneIntroPage> createState() => _HomeSceneIntroPageState();
}

class _HomeSceneIntroPageState extends State<_HomeSceneIntroPage> {
  bool _joiningLearning = false;
  late bool _joined;
  late String _selectedTargetLevel;
  late Future<InterviewSceneGraph> _sceneGraphFuture;

  @override
  void initState() {
    super.initState();
    _joined = widget.isJoined;
    _selectedTargetLevel = widget.status.selectedTargetLevel;
    _sceneGraphFuture = loadInterviewSceneGraph(
      sceneId: widget.status.entry.id,
    );
  }

  @override
  void didUpdateWidget(_HomeSceneIntroPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status.entry.id != widget.status.entry.id) {
      _joined = widget.isJoined;
      _selectedTargetLevel = widget.status.selectedTargetLevel;
      _sceneGraphFuture = loadInterviewSceneGraph(
        sceneId: widget.status.entry.id,
      );
    }
  }

  int get _selectedExpressionCount {
    for (final _InterviewSceneLevelOption option
        in widget.status.levelOptions) {
      if (option.targetLevel == _selectedTargetLevel) {
        return option.expressionCount;
      }
    }
    return widget.status.totalExpressionCount;
  }

  void _selectTargetLevel(String targetLevel) {
    if (targetLevel == _selectedTargetLevel) {
      return;
    }
    if (!CommercialScenarioGate.canAccess(
      targetLevel: targetLevel,
      isPro: widget.hasProEntitlement,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(CommercialScenarioGate.lockedMessage)),
      );
      return;
    }
    setState(() => _selectedTargetLevel = targetLevel);
    unawaited(widget.onSelectLevel(targetLevel));
  }

  Future<void> _joinLearning() async {
    if (_joiningLearning || _joined) {
      return;
    }
    if (!CommercialScenarioGate.canAccess(
      targetLevel: _selectedTargetLevel,
      isPro: widget.hasProEntitlement,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(CommercialScenarioGate.lockedMessage)),
      );
      return;
    }
    setState(() => _joiningLearning = true);
    try {
      await widget.onJoinLearning(_selectedTargetLevel);
      if (!mounted) {
        return;
      }
      setState(() => _joined = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已加入我的学习中')));
    } finally {
      if (mounted) {
        setState(() => _joiningLearning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _InterviewSceneHomeStatus status = widget.status;
    final Color accent = _sceneAccentColor(status);
    final String selectedLevelLabel = _levelLabelForStatus(
      status,
      _selectedTargetLevel,
    );
    final List<String> tags = status.tags
        .where((String tag) => tag.trim().isNotEmpty && !_isLevelTagValue(tag))
        .take(4)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 14, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                    ),
                    label: const Text('返回'),
                    style: TextButton.styleFrom(
                      foregroundColor: textPrimary,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _HomeSceneIntroLevelMenu(
                    options: status.levelOptions,
                    selectedTargetLevel: _selectedTargetLevel,
                    selectedLabel: selectedLevelLabel,
                    hasProEntitlement: widget.hasProEntitlement,
                    onChanged: _selectTargetLevel,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 18),
                children: [
                  Container(
                    height: 190,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: accent.withValues(alpha: 0.16),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppCachedNetworkImage(
                          imageUrl: _sceneCoverUrl(status.entry.id),
                          fit: BoxFit.cover,
                          placeholder: AppImagePlaceholder(
                            color: accent.withValues(alpha: 0.18),
                            icon: _sceneTagIcon(_firstSceneTag(status)),
                            iconColor: accent,
                          ),
                          errorWidget: AppImagePlaceholder(
                            color: accent.withValues(alpha: 0.18),
                            icon: _sceneTagIcon(_firstSceneTag(status)),
                            iconColor: accent,
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x10000000), Color(0xB0000000)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 25,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                status.entry.titleEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xE6FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HomeSceneIntroMetric(
                          label: '表达',
                          value: '$_selectedExpressionCount',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HomeSceneIntroMetric(
                          label: '已掌握',
                          value:
                              '${status.masteredExpressionCount}/${status.totalExpressionCount}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HomeSceneIntroMetric(
                          label: '到期复习',
                          value: '${status.dueReviewCount}',
                        ),
                      ),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags
                          .map((String tag) => _HomeSceneIntroTag(label: tag))
                          .toList(growable: false),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    '下一步',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.nextTargetLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status.nextTargetDetail,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _HomeSceneTargetExpressionSection(
                    graphFuture: _sceneGraphFuture,
                    selectedTargetLevel: _selectedTargetLevel,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: appBackground,
                border: Border(top: BorderSide(color: Color(0xFFEDE8DF))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      key: const ValueKey<String>(
                        'home_scene_intro_join_button',
                      ),
                      onPressed: (_joiningLearning || _joined)
                          ? null
                          : _joinLearning,
                      style: FilledButton.styleFrom(
                        backgroundColor: darkGreen,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: darkGreen.withValues(
                          alpha: 0.46,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        _joined
                            ? Icons.check_rounded
                            : _joiningLearning
                            ? Icons.hourglass_top_rounded
                            : Icons.add_rounded,
                        size: 19,
                      ),
                      label: Text(
                        _joined
                            ? '已加入学习'
                            : _joiningLearning
                            ? '加入中'
                            : '加入学习',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
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

class _HomeSceneIntroMetric extends StatelessWidget {
  const _HomeSceneIntroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSceneIntroTag extends StatelessWidget {
  const _HomeSceneIntroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFEDE8DF)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: textSecondary,
        ),
      ),
    );
  }
}

class _HomeSceneIntroLevelMenu extends StatelessWidget {
  const _HomeSceneIntroLevelMenu({
    required this.options,
    required this.selectedTargetLevel,
    required this.selectedLabel,
    required this.hasProEntitlement,
    required this.onChanged,
  });

  final List<_InterviewSceneLevelOption> options;
  final String selectedTargetLevel;
  final String selectedLabel;
  final bool hasProEntitlement;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Text(
        selectedLabel,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: textSecondary,
        ),
      );
    }
    return PopupMenuButton<String>(
      initialValue: selectedTargetLevel,
      tooltip: '选择等级',
      onSelected: onChanged,
      itemBuilder: (BuildContext context) => options
          .map((_InterviewSceneLevelOption option) {
            final bool locked = !CommercialScenarioGate.canAccess(
              targetLevel: option.targetLevel,
              isPro: hasProEntitlement,
            );
            return PopupMenuItem<String>(
              value: option.targetLevel,
              enabled: !locked,
              child: Row(
                children: [
                  Icon(
                    locked
                        ? Icons.lock_outline_rounded
                        : option.targetLevel == selectedTargetLevel
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 17,
                    color: locked
                        ? const Color(0xFFA0622A)
                        : option.targetLevel == selectedTargetLevel
                        ? darkGreen
                        : textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      option.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: locked
                            ? textTertiary
                            : option.targetLevel == selectedTargetLevel
                            ? darkGreen
                            : textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (locked)
                    const _SceneLibraryBadge(
                      label: CommercialScenarioGate.lockedBadge,
                    )
                  else
                    Text(
                      '${option.expressionCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                      ),
                    ),
                ],
              ),
            );
          })
          .toList(growable: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF5EA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: darkGreen.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: darkGreen,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: darkGreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSceneTargetExpressionSection extends StatelessWidget {
  const _HomeSceneTargetExpressionSection({
    required this.graphFuture,
    required this.selectedTargetLevel,
  });

  final Future<InterviewSceneGraph> graphFuture;
  final String selectedTargetLevel;

  List<InterviewExpressionNode> _targetNodes(InterviewSceneGraph graph) {
    return graph
        .flowNodeIdsForLevel(selectedTargetLevel)
        .map(graph.nodeById)
        .whereType<InterviewExpressionNode>()
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InterviewSceneGraph>(
      future: graphFuture,
      builder:
          (BuildContext context, AsyncSnapshot<InterviewSceneGraph> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _HomeSceneTargetExpressionSkeleton();
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const _HomeSceneCategoryEmptyCard(message: '目标表达加载失败');
            }
            final InterviewSceneGraph graph = snapshot.data!;
            final List<InterviewExpressionNode> nodes = _targetNodes(graph);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '目标表达',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${nodes.length} 个',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (nodes.isEmpty)
                  const _HomeSceneCategoryEmptyCard(message: '当前等级暂无目标表达')
                else
                  ...List<Widget>.generate(
                    nodes.length,
                    (int index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HomeSceneTargetExpressionTile(
                        node: nodes[index],
                        index: index,
                        sceneId: graph.id,
                        targetLevel: selectedTargetLevel,
                      ),
                    ),
                  ),
              ],
            );
          },
    );
  }
}

class _HomeSceneTargetExpressionSkeleton extends StatelessWidget {
  const _HomeSceneTargetExpressionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '目标表达',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...List<Widget>.generate(
          3,
          (int index) => Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeSceneTargetExpressionTile extends StatefulWidget {
  const _HomeSceneTargetExpressionTile({
    required this.node,
    required this.index,
    required this.sceneId,
    required this.targetLevel,
  });

  final InterviewExpressionNode node;
  final int index;
  final String sceneId;
  final String targetLevel;

  @override
  State<_HomeSceneTargetExpressionTile> createState() =>
      _HomeSceneTargetExpressionTileState();
}

class _HomeSceneTargetExpressionTileState
    extends State<_HomeSceneTargetExpressionTile> {
  bool _playing = false;

  String get _title {
    if (widget.node.targetText.isNotEmpty) {
      return widget.node.targetText;
    }
    if (widget.node.intent.isNotEmpty) {
      return widget.node.intent;
    }
    return widget.node.tag.isNotEmpty ? widget.node.tag : '目标表达';
  }

  String get _subtitle {
    if (widget.node.meaning.isNotEmpty) {
      return widget.node.meaning;
    }
    if (widget.node.usage.isNotEmpty) {
      return widget.node.usage;
    }
    if (widget.node.question.isNotEmpty) {
      return widget.node.question;
    }
    return widget.node.stageLabel;
  }

  String get _label {
    if (widget.node.tag.isNotEmpty) {
      return widget.node.tag;
    }
    if (widget.node.stageLabel.isNotEmpty) {
      return widget.node.stageLabel;
    }
    return widget.node.level;
  }

  Future<void> _togglePlayback() async {
    final AudioService audioService = AudioServiceScope.of(context);
    unawaited(HapticFeedback.selectionClick());
    if (_playing) {
      await audioService.stopPlayback(clearRealtimeBuffer: false);
      if (mounted) {
        setState(() => _playing = false);
      }
      return;
    }
    setState(() => _playing = true);
    try {
      final bool played = await audioService.playCachedTts(
        _title,
        sceneId: widget.sceneId,
        targetLevel: widget.targetLevel,
        nodeId: widget.node.id,
      );
      if (!played && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('目标表达播放失败，请稍后再试')));
      }
    } finally {
      if (mounted) {
        setState(() => _playing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: darkGreen,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_label.isNotEmpty) ...[
                  Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.28,
                    fontWeight: FontWeight.w900,
                    color: textPrimary,
                  ),
                ),
                if (_subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.42,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HomeSceneExpressionPlayButton(
            playing: _playing,
            onPressed: _togglePlayback,
          ),
        ],
      ),
    );
  }
}

class _HomeSceneExpressionPlayButton extends StatelessWidget {
  const _HomeSceneExpressionPlayButton({
    required this.playing,
    required this.onPressed,
  });

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: playing ? '停止播放' : '播放目标表达',
      child: Material(
        color: const Color(0xFFEEF5EA),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: playing
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
                      ),
                    )
                  : const Icon(
                      Icons.volume_up_rounded,
                      size: 19,
                      color: darkGreen,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletedHomeScenesPage extends StatelessWidget {
  const _CompletedHomeScenesPage({
    required this.statuses,
    required this.onOpenIntro,
  });

  final List<_InterviewSceneHomeStatus> statuses;
  final ValueChanged<_InterviewSceneHomeStatus> onOpenIntro;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 14, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                    ),
                    label: const Text('返回'),
                    style: TextButton.styleFrom(
                      foregroundColor: textPrimary,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${statuses.length} 个已完成',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
                children: [
                  const Text(
                    '已完成场景',
                    style: TextStyle(
                      fontSize: 24,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '完成后的课程会归档在这里，随时可以进入简介页巩固复习。',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (statuses.isEmpty)
                    const _HomeSceneCategoryEmptyCard(message: '还没有已完成的场景')
                  else
                    ...statuses.map(
                      (_InterviewSceneHomeStatus status) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CompletedHomeSceneTile(
                          status: status,
                          onTap: () => onOpenIntro(status),
                        ),
                      ),
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

class _CompletedHomeSceneTile extends StatelessWidget {
  const _CompletedHomeSceneTile({required this.status, required this.onTap});

  final _InterviewSceneHomeStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = _sceneAccentColor(status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 64,
                  child: AppCachedNetworkImage(
                    imageUrl: _sceneCoverUrl(status.entry.id),
                    fit: BoxFit.cover,
                    placeholder: AppImagePlaceholder(
                      color: accent.withValues(alpha: 0.18),
                      icon: _sceneTagIcon(_firstSceneTag(status)),
                      iconColor: accent,
                    ),
                    errorWidget: AppImagePlaceholder(
                      color: accent.withValues(alpha: 0.18),
                      icon: _sceneTagIcon(_firstSceneTag(status)),
                      iconColor: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${status.totalExpressionCount} 个表达 · ${_activeLevelLabel(status)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        value: 1,
                        minHeight: 4,
                        backgroundColor: Color(0xFFEDEFF2),
                        valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeSceneGridSkeleton extends StatelessWidget {
  const _HomeSceneGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 156,
      ),
      itemBuilder: (BuildContext context, int index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class _HomeSceneCategoryEmptyCard extends StatelessWidget {
  const _HomeSceneCategoryEmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 12, color: textSecondary),
      ),
    );
  }
}

class _LearningScenePickerSheet extends StatefulWidget {
  const _LearningScenePickerSheet({
    required this.statuses,
    required this.selectedSceneIds,
    required this.activeSceneId,
    required this.onToggleScene,
    required this.onSetActiveScene,
    required this.onSelectLevel,
  });

  final List<_InterviewSceneHomeStatus> statuses;
  final List<String> selectedSceneIds;
  final String? activeSceneId;
  final void Function(_InterviewSceneHomeStatus status, bool selected)
  onToggleScene;
  final ValueChanged<_InterviewSceneHomeStatus> onSetActiveScene;
  final void Function(_InterviewSceneHomeStatus status, String targetLevel)
  onSelectLevel;

  @override
  State<_LearningScenePickerSheet> createState() =>
      _LearningScenePickerSheetState();
}

class _LearningScenePickerSheetState extends State<_LearningScenePickerSheet> {
  final TextEditingController _queryController = TextEditingController();
  late Set<String> _selectedSceneIds;
  String? _activeSceneId;
  String _selectedTag = _allSceneTagLabel;
  String _selectedDifficultyTargetLevel = _allDifficultyTargetLevel;

  @override
  void initState() {
    super.initState();
    _selectedSceneIds = widget.selectedSceneIds.toSet();
    _activeSceneId = widget.activeSceneId;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<String> get _tagOptions {
    final List<String> tags =
        widget.statuses
            .expand((_InterviewSceneHomeStatus status) => status.tags)
            .where((String tag) => !_isLevelTagValue(tag))
            .toSet()
            .toList()
          ..sort((String a, String b) => a.length.compareTo(b.length));
    return <String>[_allSceneTagLabel, ...tags.take(8)];
  }

  List<_InterviewSceneHomeStatus> get _filteredStatuses {
    final String query = _queryController.text.trim().toLowerCase();
    final List<_InterviewSceneHomeStatus> filtered = widget.statuses.where((
      _InterviewSceneHomeStatus status,
    ) {
      final bool matchesQuery =
          query.isEmpty ||
          status.title.toLowerCase().contains(query) ||
          status.description.toLowerCase().contains(query) ||
          status.tags.any((String tag) => tag.toLowerCase().contains(query)) ||
          status.trackLabels.any(
            (String label) => label.toLowerCase().contains(query),
          );
      final bool matchesTag =
          _selectedTag == _allSceneTagLabel ||
          status.tags.contains(_selectedTag);
      final bool matchesDifficulty =
          _selectedDifficultyTargetLevel == _allDifficultyTargetLevel ||
          status.levelOptions.any(
            (_InterviewSceneLevelOption option) =>
                option.targetLevel == _selectedDifficultyTargetLevel,
          );
      return matchesQuery && matchesTag && matchesDifficulty;
    }).toList();
    filtered.sort((a, b) {
      final int selected =
          (_selectedSceneIds.contains(b.entry.id) ? 1 : 0) -
          (_selectedSceneIds.contains(a.entry.id) ? 1 : 0);
      if (selected != 0) {
        return selected;
      }
      return b.dueReviewCount.compareTo(a.dueReviewCount);
    });
    return filtered;
  }

  void _toggleScene(_InterviewSceneHomeStatus status) {
    final bool nextSelected = !_selectedSceneIds.contains(status.entry.id);
    setState(() {
      if (nextSelected) {
        _selectedSceneIds.add(status.entry.id);
        _activeSceneId ??= status.entry.id;
      } else {
        _selectedSceneIds.remove(status.entry.id);
        if (_activeSceneId == status.entry.id) {
          _activeSceneId = _selectedSceneIds.isEmpty
              ? null
              : _selectedSceneIds.first;
        }
      }
    });
    widget.onToggleScene(status, nextSelected);
  }

  void _setActive(_InterviewSceneHomeStatus status) {
    setState(() {
      _selectedSceneIds.add(status.entry.id);
      _activeSceneId = status.entry.id;
    });
    widget.onSetActiveScene(status);
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.86;
    final List<_InterviewSceneHomeStatus> statuses = _filteredStatuses;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            14 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '添加学习场景',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PickerSearchField(
                controller: _queryController,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _PickerFilterRail(
                values: _tagOptions,
                selectedValue: _selectedTag,
                labelForValue: (String value) => value,
                onChanged: (String value) {
                  setState(() => _selectedTag = value);
                },
              ),
              const SizedBox(height: 10),
              _PickerFilterRail(
                values: _wikiDifficultyFilters
                    .map((filter) => filter.targetLevel)
                    .toList(growable: false),
                selectedValue: _selectedDifficultyTargetLevel,
                labelForValue: _difficultyFilterLabel,
                onChanged: (String value) {
                  setState(() => _selectedDifficultyTargetLevel = value);
                },
              ),
              const SizedBox(height: 12),
              Text(
                '显示 ${statuses.length} / ${widget.statuses.length} 个场景',
                style: const TextStyle(fontSize: 11, color: textSecondary),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: statuses.isEmpty
                    ? const _PickerEmptyState()
                    : ListView.separated(
                        itemCount: statuses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final _InterviewSceneHomeStatus status =
                              statuses[index];
                          return _LearningScenePickerRow(
                            status: status,
                            selected: _selectedSceneIds.contains(
                              status.entry.id,
                            ),
                            active: _activeSceneId == status.entry.id,
                            onToggle: () => _toggleScene(status),
                            onSetActive: () => _setActive(status),
                            onSelectLevel: (String targetLevel) =>
                                widget.onSelectLevel(status, targetLevel),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSearchField extends StatelessWidget {
  const _PickerSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 16, color: textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '搜索场景、表达路径、关键词',
                hintStyle: TextStyle(fontSize: 13, color: textTertiary),
              ),
              style: const TextStyle(fontSize: 13, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerFilterRail extends StatelessWidget {
  const _PickerFilterRail({
    required this.values,
    required this.selectedValue,
    required this.labelForValue,
    required this.onChanged,
  });

  final List<String> values;
  final String selectedValue;
  final String Function(String value) labelForValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final String value = values[index];
          final bool selected = value == selectedValue;
          return GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? darkGreen : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: selected ? darkGreen : borderColor),
              ),
              child: Text(
                labelForValue(value),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LearningScenePickerRow extends StatelessWidget {
  const _LearningScenePickerRow({
    required this.status,
    required this.selected,
    required this.active,
    required this.onToggle,
    required this.onSetActive,
    required this.onSelectLevel,
  });

  final _InterviewSceneHomeStatus status;
  final bool selected;
  final bool active;
  final VoidCallback onToggle;
  final VoidCallback onSetActive;
  final ValueChanged<String> onSelectLevel;

  @override
  Widget build(BuildContext context) {
    final Color accent = _sceneAccentColor(status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? accent : borderColor),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AppCachedNetworkImage(
                  imageUrl: _sceneCoverUrl(status.entry.id),
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  placeholder: AppImagePlaceholder(
                    color: accent.withValues(alpha: 0.18),
                    icon: _sceneTagIcon(_firstSceneTag(status)),
                    iconColor: accent,
                  ),
                  errorWidget: AppImagePlaceholder(
                    color: accent.withValues(alpha: 0.18),
                    icon: _sceneTagIcon(_firstSceneTag(status)),
                    iconColor: accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (active) const _SceneTileBadge(label: '当前'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      status.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '下一步 · ${status.nextTargetMode} · ${status.nextTargetLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SceneLevelSelector(
                  options: status.levelOptions,
                  selectedTargetLevel: status.selectedTargetLevel,
                  onChanged: onSelectLevel,
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onSetActive,
                style: OutlinedButton.styleFrom(
                  foregroundColor: darkGreen,
                  side: const BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('设为当前'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onToggle,
                style: FilledButton.styleFrom(
                  backgroundColor: selected
                      ? const Color(0xFFF1EFEB)
                      : darkGreen,
                  foregroundColor: selected ? textSecondary : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(selected ? '移除' : '加入'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerEmptyState extends StatelessWidget {
  const _PickerEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '当前筛选下没有场景',
        style: TextStyle(fontSize: 13, color: textSecondary),
      ),
    );
  }
}

class _WikiSceneTile extends StatelessWidget {
  const _WikiSceneTile({
    required this.status,
    required this.imageHeight,
    required this.onTap,
    required this.onSelectLevel,
  });

  final _InterviewSceneHomeStatus status;
  final double imageHeight;
  final VoidCallback onTap;
  final ValueChanged<String> onSelectLevel;

  @override
  Widget build(BuildContext context) {
    final int masteryPercent = (status.masteryRatio * 100).round();
    final String activeLevelLabel = _activeLevelLabel(status);
    final Color accent = _sceneAccentColor(status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedNetworkImage(
                    imageUrl: _sceneCoverUrl(status.entry.id),
                    fit: BoxFit.cover,
                    placeholder: AppImagePlaceholder(
                      color: accent.withValues(alpha: 0.18),
                      icon: _sceneTagIcon(_firstSceneTag(status)),
                      iconColor: accent,
                    ),
                    errorWidget: AppImagePlaceholder(
                      color: accent.withValues(alpha: 0.18),
                      icon: _sceneTagIcon(_firstSceneTag(status)),
                      iconColor: accent,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.46),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _SceneDots(count: status.levelOptions.length),
                  ),
                  if (status.hasActiveSession || status.dueReviewCount > 0)
                    Positioned(
                      top: 9,
                      left: 9,
                      child: _SceneTileBadge(
                        label: status.hasActiveSession ? '未完成' : '复习',
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    status.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _SceneWikiLine(
                    label: '表达路径',
                    value:
                        '${status.totalExpressionCount} 个目标表达 · ${status.publicTrackCount} 条路径',
                  ),
                  const SizedBox(height: 5),
                  _SceneWikiLine(
                    label: '我的进度',
                    value:
                        '已掌握 ${status.masteredExpressionCount} · 薄弱 ${status.weakExpressionCount} · 素材 ${status.personalMaterialCount}',
                  ),
                  const SizedBox(height: 9),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '下一步 · ${status.nextTargetMode}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          status.nextTargetLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SegmentedProgress(value: status.masteryRatio),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: status.levelOptions
                        .take(3)
                        .map((_InterviewSceneLevelOption option) {
                          final bool selected =
                              option.targetLevel == status.selectedTargetLevel;
                          return GestureDetector(
                            onTap: () {
                              if (!selected) {
                                onSelectLevel(option.targetLevel);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? accent.withValues(alpha: 0.12)
                                    : const Color(0xFFF5F2ED),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: selected
                                      ? accent.withValues(alpha: 0.4)
                                      : borderColor,
                                ),
                              ),
                              child: Text(
                                option.title.replaceAll(' ', ''),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: selected ? accent : textSecondary,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: Color(0xFFFF7A1A),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '$activeLevelLabel · ${status.totalExpressionCount} 个表达',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '$masteryPercent%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: accent,
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

class _SceneDots extends StatelessWidget {
  const _SceneDots({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final int safeCount = count.clamp(1, 4);
    return Row(
      children: List<Widget>.generate(
        safeCount,
        (_) => Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 3),
          decoration: const BoxDecoration(
            color: Color(0xD9FFFFFF),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SceneWikiLine extends StatelessWidget {
  const _SceneWikiLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 10.5, color: textSecondary),
        children: [
          TextSpan(
            text: '$label：',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _SceneTileBadge extends StatelessWidget {
  const _SceneTileBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: darkGreen,
        ),
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(4, (int index) {
        final double threshold = (index + 1) / 4;
        final bool active = value >= threshold || (index == 0 && value > 0);
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 5),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFDCE9D5) : const Color(0xFFEAE6DF),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

IconData _sceneTagIcon(String tag) {
  if (tag == _allSceneTagLabel) {
    return Icons.apps_rounded;
  }
  if (tag.contains('面试') || tag.contains('求职')) {
    return Icons.work_outline_rounded;
  }
  if (tag.contains('商务') || tag.contains('工作')) {
    return Icons.business_center_outlined;
  }
  if (tag.contains('旅行')) {
    return Icons.flight_takeoff_rounded;
  }
  if (tag.contains('社交') || tag.contains('聊天')) {
    return Icons.forum_outlined;
  }
  if (tag.contains('考试') || tag.contains('雅思')) {
    return Icons.school_outlined;
  }
  if (tag.contains('口语')) {
    return Icons.mic_none_rounded;
  }
  return Icons.auto_awesome_rounded;
}

String _difficultyFilterLabel(String targetLevel) {
  for (final filter in _wikiDifficultyFilters) {
    if (filter.targetLevel == targetLevel) {
      return filter.label;
    }
  }
  return '全部';
}

bool _matchesHomeSceneCategory(
  _InterviewSceneHomeStatus status,
  String category,
) {
  if (category == _recommendedHomeSceneCategory) {
    return true;
  }
  final List<String> keywords =
      _homeSceneCategoryKeywords[category] ?? const <String>[];
  if (keywords.isEmpty) {
    return false;
  }
  final String searchable = <String>[
    status.title,
    status.description,
    ...status.tags,
    ...status.trackLabels,
    status.entry.titleCn,
    status.entry.titleEn,
    status.entry.description,
  ].join(' ').toLowerCase();
  return keywords.any((String keyword) {
    final String normalized = keyword.trim().toLowerCase();
    return normalized.isNotEmpty && searchable.contains(normalized);
  });
}

bool _isLevelTagValue(String tag) {
  return RegExp(r'^L\d$', caseSensitive: false).hasMatch(tag.trim());
}

String _activeLevelLabel(_InterviewSceneHomeStatus status) {
  return _levelLabelForStatus(status, status.selectedTargetLevel);
}

String _levelLabelForStatus(
  _InterviewSceneHomeStatus status,
  String targetLevel,
) {
  for (final _InterviewSceneLevelOption option in status.levelOptions) {
    if (option.targetLevel == targetLevel) {
      return option.title;
    }
  }
  return _difficultyFilterLabel(targetLevel);
}

String _firstSceneTag(_InterviewSceneHomeStatus status) {
  for (final String tag in status.tags) {
    if (tag.trim().isNotEmpty && !RegExp(r'^L\d$').hasMatch(tag.trim())) {
      return tag;
    }
  }
  return status.title;
}

Color _sceneAccentColor(_InterviewSceneHomeStatus status) {
  final String tag = _firstSceneTag(status);
  if (tag.contains('面试') || tag.contains('求职')) {
    return const Color(0xFF4A7C6F);
  }
  if (tag.contains('商务') || tag.contains('工作')) {
    return const Color(0xFF5A6FA8);
  }
  if (tag.contains('旅行')) {
    return const Color(0xFF3D7FA8);
  }
  if (tag.contains('社交') || tag.contains('聊天')) {
    return const Color(0xFFA0622A);
  }
  return darkGreen;
}

String _sceneCoverUrl(String sceneId) {
  return switch (sceneId) {
    'job_interview' => 'assets/images/scene_covers/job_interview.png',
    'onboarding_introduction' =>
      'assets/images/scene_covers/onboarding_introduction.png',
    _ => 'assets/images/scene_covers/default_scene.png',
  };
}

// Kept for fallback experiments with the compact Wiki list layout.
// ignore: unused_element
class _InterviewSceneLibrarySection extends StatelessWidget {
  const _InterviewSceneLibrarySection({
    required this.loading,
    required this.statuses,
    required this.onOpenScene,
    required this.onSelectLevel,
  });

  final bool loading;
  final List<_InterviewSceneHomeStatus> statuses;
  final ValueChanged<_InterviewSceneHomeStatus> onOpenScene;
  final void Function(_InterviewSceneHomeStatus status, String targetLevel)
  onSelectLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                size: 17,
                color: darkGreen,
              ),
              const SizedBox(width: 7),
              const Text(
                '场景表达库',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 8),
              const _SceneLibraryBadge(label: '官方场景'),
              const Spacer(),
              Text(
                loading ? '同步中' : '${statuses.length} 个场景',
                style: const TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (loading && statuses.isEmpty)
          const _InterviewSceneLoadingCard()
        else if (statuses.isEmpty)
          const _InterviewSceneEmptyCard()
        else
          ...statuses.map(
            (_InterviewSceneHomeStatus status) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InterviewSceneHomeCard(
                status: status,
                onTap: () => onOpenScene(status),
                onSelectLevel: (String targetLevel) =>
                    onSelectLevel(status, targetLevel),
              ),
            ),
          ),
      ],
    );
  }
}

class _InterviewSceneHomeCard extends StatelessWidget {
  const _InterviewSceneHomeCard({
    required this.status,
    required this.onTap,
    required this.onSelectLevel,
  });

  final _InterviewSceneHomeStatus status;
  final VoidCallback onTap;
  final ValueChanged<String> onSelectLevel;

  @override
  Widget build(BuildContext context) {
    final int masteryPercent = (status.masteryRatio * 100).round();
    final Color actionColor = status.dueReviewCount > 0
        ? const Color(0xFFA0622A)
        : darkGreen;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF5EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work_outline_rounded, color: darkGreen),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '表达路径 · ${status.totalExpressionCount} 个目标表达',
                      style: const TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.hasActiveSession)
                const _SceneLibraryBadge(label: '未完成')
              else if (status.dueReviewCount > 0)
                const _SceneLibraryBadge(label: '到期复习'),
            ],
          ),
          if (status.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              status.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: textSecondary,
              ),
            ),
          ],
          if (status.trackLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            _SceneLevelSelector(
              options: status.levelOptions,
              selectedTargetLevel: status.selectedTargetLevel,
              onChanged: onSelectLevel,
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: status.masteryRatio.clamp(0, 1),
              minHeight: 7,
              backgroundColor: const Color(0xFFECE7DF),
              valueColor: AlwaysStoppedAnimation<Color>(actionColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SceneMetric(
                label: '已掌握',
                value:
                    '${status.masteredExpressionCount}/${status.totalExpressionCount}',
              ),
              const SizedBox(width: 10),
              _SceneMetric(label: '到期', value: '${status.dueReviewCount}'),
              const SizedBox(width: 10),
              _SceneMetric(label: '薄弱', value: '${status.weakExpressionCount}'),
              const Spacer(),
              Text(
                '$masteryPercent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(status.ctaIcon, size: 18),
              label: Text(status.ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneMetric extends StatelessWidget {
  const _SceneMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 11, color: textSecondary),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneLevelSelector extends StatelessWidget {
  const _SceneLevelSelector({
    required this.options,
    required this.selectedTargetLevel,
    required this.onChanged,
    this.compact = false,
  });

  final List<_InterviewSceneLevelOption> options;
  final String selectedTargetLevel;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          const Text(
            '选择难度后，本轮只推送该等级表达',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 7),
        ],
        Wrap(
          spacing: compact ? 5 : 7,
          runSpacing: compact ? 5 : 7,
          children: options
              .map((_InterviewSceneLevelOption option) {
                final bool selected = option.targetLevel == selectedTargetLevel;
                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    compact
                        ? option.title
                        : '${option.title} · ${option.expressionCount}',
                  ),
                  onSelected: (_) {
                    if (!selected) {
                      onChanged(option.targetLevel);
                    }
                  },
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  selectedColor: const Color(0xFFEEF5EA),
                  backgroundColor: const Color(0xFFF7F3EE),
                  side: BorderSide(
                    color: selected ? darkGreen : const Color(0xFFE2DDD4),
                  ),
                  labelStyle: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w900,
                    color: selected ? darkGreen : textSecondary,
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _SceneLibraryBadge extends StatelessWidget {
  const _SceneLibraryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: darkGreen,
        ),
      ),
    );
  }
}

class _InterviewSceneLoadingCard extends StatelessWidget {
  const _InterviewSceneLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            '正在读取场景和个人进度',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }
}

class _InterviewSceneEmptyCard extends StatelessWidget {
  const _InterviewSceneEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: const Text(
        '暂无可用的公共场景',
        style: TextStyle(fontSize: 12, color: textSecondary),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.masteredExpressionCount,
    required this.totalExpressionCount,
    required this.onSearchTap,
  });

  final int masteredExpressionCount;
  final int totalExpressionCount;
  final VoidCallback onSearchTap;

  static const List<Color> _abilityPalette = <Color>[
    Color(0xFF24476F),
    darkGreen,
    Color(0xFFC8955A),
  ];

  Future<void> _showAssessmentSheet(BuildContext context) async {
    final AppSession session = AppSessionScope.of(context);
    final LearningStatsModel stats = session.stats;
    final int expressionProgressPercent = _expressionProgressPercent();
    final int speakingScore = _calculateSpeakingScore(
      stats,
      expressionProgressPercent,
    );
    final bool hasAnyData =
        stats.hasOverviewData ||
        totalExpressionCount > 0 ||
        masteredExpressionCount > 0;
    final String abilityLevel = _abilityLevelLabel(speakingScore, hasAnyData);
    final List<_AbilityBarData> abilityBars = _buildAbilityBars(
      stats,
      expressionProgressPercent,
      speakingScore,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: appBackground,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: _HomeAssessmentSheet(
            avatarUrl: session.avatarUrl,
            nickname: session.nickname,
            score: speakingScore,
            levelLabel: abilityLevel,
            hasAnyData: hasAnyData,
            abilityBars: abilityBars,
            stats: stats,
            masteredExpressionCount: masteredExpressionCount,
            totalExpressionCount: totalExpressionCount,
          ),
        );
      },
    );
  }

  Future<void> _showLearningCalendarSheet(BuildContext context) async {
    final LearningStatsModel stats = AppSessionScope.of(context).stats;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: appBackground,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: _HomeLearningCalendarSheet(stats: stats),
        );
      },
    );
  }

  int _expressionProgressPercent() {
    if (totalExpressionCount <= 0) {
      return 0;
    }
    return ((masteredExpressionCount / totalExpressionCount) * 100)
        .round()
        .clamp(0, 100)
        .toInt();
  }

  int _calculateSpeakingScore(
    LearningStatsModel stats,
    int expressionProgressPercent,
  ) {
    double weightedScore = 0;
    double totalWeight = 0;

    void addScore(num? value, double weight) {
      if (value == null || value <= 0) {
        return;
      }
      weightedScore += value.clamp(0, 100).toDouble() * weight;
      totalWeight += weight;
    }

    addScore(stats.accuracyRate, 0.35);
    if (stats.skillLevels.isNotEmpty) {
      final int skillAverage =
          (stats.skillLevels.fold<int>(
                    0,
                    (int total, SkillLevelModel item) => total + item.level,
                  ) /
                  stats.skillLevels.length)
              .round()
              .clamp(0, 100)
              .toInt();
      addScore(skillAverage, 0.3);
    }
    addScore(stats.bestScore, 0.2);
    addScore(expressionProgressPercent, 0.25);
    if (stats.totalSessions > 0 || stats.currentStreak > 0) {
      addScore(stats.totalSessions * 8 + stats.currentStreak * 3, 0.1);
    }

    if (totalWeight == 0) {
      return 0;
    }
    return (weightedScore / totalWeight).round().clamp(0, 100).toInt();
  }

  String _abilityLevelLabel(int score, bool hasAnyData) {
    if (!hasAnyData) {
      return '待生成';
    }
    if (score >= 85) {
      return '流利表达';
    }
    if (score >= 65) {
      return '熟练中';
    }
    if (score >= 35) {
      return '进阶中';
    }
    return '起步中';
  }

  List<_AbilityBarData> _buildAbilityBars(
    LearningStatsModel stats,
    int expressionProgressPercent,
    int speakingScore,
  ) {
    final List<_AbilityBarData> bars = <_AbilityBarData>[];
    final List<SkillLevelModel> providedSkillLevels = stats.skillLevels
        .where((SkillLevelModel item) => item.hasContent)
        .take(3)
        .toList(growable: false);

    for (int i = 0; i < providedSkillLevels.length; i++) {
      final SkillLevelModel item = providedSkillLevels[i];
      bars.add(
        _AbilityBarData(
          label: item.label,
          value: item.level.clamp(0, 100).toInt(),
          color: item.color ?? _abilityPalette[i % _abilityPalette.length],
        ),
      );
    }

    final List<_AbilityBarData> fallbackBars = _fallbackAbilityBars(
      stats,
      expressionProgressPercent,
      speakingScore,
    );
    for (final _AbilityBarData item in fallbackBars) {
      if (bars.length >= 3) {
        break;
      }
      if (bars.any((_AbilityBarData bar) => bar.label == item.label)) {
        continue;
      }
      bars.add(item);
    }

    return bars.take(3).toList(growable: false);
  }

  List<_AbilityBarData> _fallbackAbilityBars(
    LearningStatsModel stats,
    int expressionProgressPercent,
    int speakingScore,
  ) {
    final int pronunciationScore =
        stats.accuracyRate ??
        (stats.bestScore > 0 ? stats.bestScore : speakingScore);
    final int rawFluencyScore =
        stats.totalSessions * 9 +
        stats.totalMinutes * 2 +
        stats.currentStreak * 5;
    final int fluencyScore = rawFluencyScore > 0
        ? rawFluencyScore.clamp(0, 100).toInt()
        : speakingScore;
    final int scenarioScore = expressionProgressPercent > 0
        ? expressionProgressPercent
        : speakingScore;

    return <_AbilityBarData>[
      _AbilityBarData(
        label: '发音清晰',
        value: pronunciationScore.clamp(0, 100).toInt(),
        color: _abilityPalette[0],
      ),
      _AbilityBarData(
        label: '表达流利',
        value: fluencyScore.clamp(0, 100).toInt(),
        color: _abilityPalette[1],
      ),
      _AbilityBarData(
        label: '场景应对',
        value: scenarioScore.clamp(0, 100).toInt(),
        color: _abilityPalette[2],
      ),
    ];
  }

  String _calendarSummary(LearningStatsModel stats) {
    final int learningDays = stats.displayLearningDays;
    if (learningDays > 0) {
      return '$learningDays天';
    }
    return '--';
  }

  @override
  Widget build(BuildContext context) {
    final AppSession session = AppSessionScope.of(context);
    final LearningStatsModel stats = session.stats;
    final int expressionProgressPercent = _expressionProgressPercent();
    final int speakingScore = _calculateSpeakingScore(
      stats,
      expressionProgressPercent,
    );
    final bool hasAnyData =
        stats.hasOverviewData ||
        totalExpressionCount > 0 ||
        masteredExpressionCount > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        children: [
          _HomeTopAvatarButton(
            avatarUrl: session.avatarUrl,
            score: speakingScore,
            hasAnyData: hasAnyData,
            onTap: () => _showAssessmentSheet(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFE7E3DA)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x0F1F2937),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF7B8A72),
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '搜索场景、表达路径、关键词',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E9787),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _HomeCalendarButton(
            label: _calendarSummary(stats),
            onTap: () => _showLearningCalendarSheet(context),
          ),
        ],
      ),
    );
  }
}

class _HomeTopAvatarButton extends StatelessWidget {
  const _HomeTopAvatarButton({
    required this.avatarUrl,
    required this.score,
    required this.hasAnyData,
    required this.onTap,
  });

  final String avatarUrl;
  final int score;
  final bool hasAnyData;
  final VoidCallback onTap;

  Color get _accentColor {
    if (!hasAnyData) {
      return const Color(0xFF9CA3AF);
    }
    if (score >= 65) {
      return darkGreen;
    }
    if (score >= 35) {
      return const Color(0xFF24476F);
    }
    return const Color(0xFFC8955A);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: _accentColor, width: 2),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x121F2937),
                      blurRadius: 14,
                      offset: Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: AppCachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: const AppImagePlaceholder(
                      color: Color(0xFF213F63),
                      icon: Icons.person_rounded,
                      iconColor: Colors.white,
                      iconSize: 20,
                    ),
                    errorWidget: const AppImagePlaceholder(
                      color: Color(0xFF213F63),
                      icon: Icons.person_rounded,
                      iconColor: Colors.white,
                      iconSize: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -1,
                child: Container(
                  height: 18,
                  constraints: const BoxConstraints(minWidth: 24),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: _accentColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: appBackground, width: 2),
                  ),
                  child: Text(
                    hasAnyData ? '$score' : '--',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCalendarButton extends StatelessWidget {
  const _HomeCalendarButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7E3DA)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F1F2937),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 19,
                color: darkGreen,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeAssessmentSheet extends StatelessWidget {
  const _HomeAssessmentSheet({
    required this.avatarUrl,
    required this.nickname,
    required this.score,
    required this.levelLabel,
    required this.hasAnyData,
    required this.abilityBars,
    required this.stats,
    required this.masteredExpressionCount,
    required this.totalExpressionCount,
  });

  final String avatarUrl;
  final String nickname;
  final int score;
  final String levelLabel;
  final bool hasAnyData;
  final List<_AbilityBarData> abilityBars;
  final LearningStatsModel stats;
  final int masteredExpressionCount;
  final int totalExpressionCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: AppCachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: const AppImagePlaceholder(
                    color: Color(0xFF213F63),
                    icon: Icons.person_rounded,
                    iconColor: Colors.white,
                  ),
                  errorWidget: const AppImagePlaceholder(
                    color: Color(0xFF213F63),
                    icon: Icons.person_rounded,
                    iconColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAnyData ? levelLabel : '完成一次情景学习后生成评测',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                hasAnyData ? '$score' : '--',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: darkGreen,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                for (int index = 0; index < abilityBars.length; index += 1)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == abilityBars.length - 1 ? 0 : 10,
                    ),
                    child: _HomeAbilityMicroBar(item: abilityBars[index]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HomeSheetMetric(
                  label: '练习次数',
                  value: '${stats.totalSessions}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeSheetMetric(
                  label: '最高分',
                  value: stats.bestScore > 0 ? '${stats.bestScore}' : '--',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeSheetMetric(
                  label: '表达掌握',
                  value: totalExpressionCount > 0
                      ? '$masteredExpressionCount/$totalExpressionCount'
                      : '--',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeLearningCalendarSheet extends StatelessWidget {
  const _HomeLearningCalendarSheet({required this.stats});

  final LearningStatsModel stats;

  List<bool> get _weekActivity {
    if (stats.weekActivity.length == 7) {
      return stats.weekActivity;
    }
    final List<bool> normalized = List<bool>.filled(7, false);
    for (int i = 0; i < stats.weekActivity.length && i < 7; i += 1) {
      normalized[i] = stats.weekActivity[i];
    }
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> labels = const <String>[
      '一',
      '二',
      '三',
      '四',
      '五',
      '六',
      '日',
    ];
    final List<bool> activity = _weekActivity;
    final int todayIndex = DateTime.now().weekday - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '学习日历',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HomeSheetMetric(
                  label: '累计学习',
                  value: stats.displayLearningDays > 0
                      ? '${stats.displayLearningDays}天'
                      : '--',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeSheetMetric(
                  label: '连续天数',
                  value: stats.currentStreak > 0
                      ? '${stats.currentStreak}天'
                      : '--',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomeSheetMetric(
                  label: '学习时长',
                  value: stats.totalMinutes > 0
                      ? '${stats.totalMinutes}分'
                      : '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int index = 0; index < labels.length; index += 1)
                  _CalendarDayChip(
                    label: labels[index],
                    active: activity[index],
                    today: index == todayIndex,
                  ),
              ],
            ),
          ),
          if (stats.recentPractices.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              '最近练习',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            for (final PracticeHistoryModel item in stats.recentPractices.take(
              3,
            ))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: darkGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HomeSheetMetric extends StatelessWidget {
  const _HomeSheetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarDayChip extends StatelessWidget {
  const _CalendarDayChip({
    required this.label,
    required this.active,
    required this.today,
  });

  final String label;
  final bool active;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final Color fill = active
        ? darkGreen
        : today
        ? const Color(0xFFEAF4E4)
        : const Color(0xFFF2EFEA);
    final Color foreground = active
        ? Colors.white
        : today
        ? darkGreen
        : textTertiary;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(
              color: today ? darkGreen : Colors.transparent,
              width: today ? 1.2 : 0,
            ),
          ),
          child: Icon(
            active ? Icons.check_rounded : Icons.remove_rounded,
            size: 15,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

class _AbilityBarData {
  const _AbilityBarData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

class _HomeAbilityMicroBar extends StatelessWidget {
  const _HomeAbilityMicroBar({required this.item});

  final _AbilityBarData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.value / 100,
              minHeight: 5,
              backgroundColor: const Color(0xFFEDEFF2),
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 24,
          child: Text(
            '${item.value}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: item.color,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder({this.icon, this.emoji, required this.title});

  final IconData? icon;
  final String? emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            if (icon != null)
              Icon(icon, size: 48, color: const Color(0xFFB8C0B0)),
            if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 82 + bottomInset,
          padding: EdgeInsets.fromLTRB(
            8,
            10,
            8,
            bottomInset > 0 ? bottomInset : 10,
          ),
          decoration: const BoxDecoration(
            color: Color(0xECFDFCF9),
            border: Border(
              top: BorderSide(color: Color(0xFFDDD9D0), width: 0.5),
            ),
          ),
          child: Row(
            children: List<Widget>.generate(bottomTabs.length, (int index) {
              final ({String label, IconData icon}) item = bottomTabs[index];
              final bool active = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  key: ValueKey<String>('home_bottom_tab_$index'),
                  onTap: () => onChanged(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 28,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0x143D5C3A)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          size: 21,
                          color: active ? darkGreen : const Color(0xFFB8B0A6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.bottomTabLabel(item.label),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.3,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active ? darkGreen : const Color(0xFFB8B0A6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
