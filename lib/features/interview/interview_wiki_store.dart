import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/services/storage_service.dart';

class InterviewWikiStore {
  const InterviewWikiStore({this.sceneId = defaultInterviewSceneId});

  final String sceneId;

  static const String _key = 'interview_personal_wiki_expressions';
  static const String _compiledWikiKey = 'interview_compiled_wiki';
  static const String _growthWikiKey = 'interview_user_growth_wiki';
  static const String _activeSessionKey = 'interview_active_session';
  static const String _dismissedWikiItemsKey = 'interview_dismissed_wiki_items';
  static const String _usefulWikiItemsKey = 'interview_useful_wiki_items';
  static const String _expressionLearningProgressKey =
      'interview_expression_learning_progress';
  static const String _levelPreferencesKey =
      'interview_scene_level_preferences';

  String get _resolvedSceneId =>
      sceneId.trim().isEmpty ? defaultInterviewSceneId : sceneId.trim();

  String get _activeSessionStorageKey =>
      _resolvedSceneId == defaultInterviewSceneId
      ? _activeSessionKey
      : '${_activeSessionKey}_$_resolvedSceneId';

  List<InterviewPersonalWikiExpression> loadMasteredExpressions({
    String? sourceSceneId,
  }) {
    final String resolvedSceneId = (sourceSceneId ?? _resolvedSceneId).trim();
    final String effectiveSceneId = resolvedSceneId.isEmpty
        ? defaultInterviewSceneId
        : resolvedSceneId;
    return loadAllMasteredExpressions()
        .where((InterviewPersonalWikiExpression item) {
          final String itemSceneId = item.sourceSceneId.trim();
          if (itemSceneId.isEmpty) {
            return effectiveSceneId == defaultInterviewSceneId;
          }
          return itemSceneId == effectiveSceneId;
        })
        .toList(growable: false);
  }

  List<InterviewPersonalWikiExpression> loadAllMasteredExpressions() {
    return StorageService.instance.getList<InterviewPersonalWikiExpression>(
      _key,
      InterviewPersonalWikiExpression.fromJson,
    );
  }

  List<InterviewExpressionLearningProgress> loadExpressionLearningProgress({
    String? sourceSceneId,
  }) {
    final String resolvedSceneId = (sourceSceneId ?? _resolvedSceneId).trim();
    final String effectiveSceneId = resolvedSceneId.isEmpty
        ? defaultInterviewSceneId
        : resolvedSceneId;
    return loadAllExpressionLearningProgress()
        .where(
          (InterviewExpressionLearningProgress item) =>
              item.sceneId == effectiveSceneId,
        )
        .toList(growable: false);
  }

  List<InterviewExpressionLearningProgress>
  loadAllExpressionLearningProgress() {
    return StorageService.instance.getList<InterviewExpressionLearningProgress>(
      _expressionLearningProgressKey,
      InterviewExpressionLearningProgress.fromJson,
    );
  }

  InterviewExpressionLearningProgress? loadExpressionLearningProgressFor({
    required String nodeId,
    required String targetLevel,
    String? sourceSceneId,
  }) {
    final String key = InterviewExpressionLearningProgress.storageKey(
      sceneId: sourceSceneId ?? _resolvedSceneId,
      nodeId: nodeId,
      targetLevel: targetLevel,
    );
    for (final InterviewExpressionLearningProgress item
        in loadAllExpressionLearningProgress()) {
      if (item.key == key) {
        return item;
      }
    }
    return null;
  }

  Future<void> saveExpressionLearningProgress(
    InterviewExpressionLearningProgress progress,
  ) async {
    final List<InterviewExpressionLearningProgress> current =
        loadAllExpressionLearningProgress();
    final String key = progress.key;
    final List<InterviewExpressionLearningProgress> updated =
        <InterviewExpressionLearningProgress>[];
    bool replaced = false;
    for (final InterviewExpressionLearningProgress item in current) {
      if (item.key == key) {
        updated.add(progress);
        replaced = true;
      } else {
        updated.add(item);
      }
    }
    if (!replaced) {
      updated.add(progress);
    }
    await StorageService.instance.saveList<InterviewExpressionLearningProgress>(
      _expressionLearningProgressKey,
      updated,
      (InterviewExpressionLearningProgress value) => value.toJson(),
    );
  }

  Future<void> markExpressionLearningMasteredLinked({
    required String nodeId,
    required String targetLevel,
    String? sourceSceneId,
  }) async {
    final String effectiveSceneId = (sourceSceneId ?? _resolvedSceneId).trim();
    final InterviewExpressionLearningProgress existing =
        loadExpressionLearningProgressFor(
          nodeId: nodeId,
          targetLevel: targetLevel,
          sourceSceneId: effectiveSceneId,
        ) ??
        InterviewExpressionLearningProgress(
          sceneId: effectiveSceneId.isEmpty
              ? defaultInterviewSceneId
              : effectiveSceneId,
          nodeId: nodeId,
          targetLevel: targetLevel,
        );
    await saveExpressionLearningProgress(
      existing.copyWith(
        status: InterviewExpressionLearningStatus.masteredLinked,
        currentStep: InterviewExpressionLearningStep.recall,
        lastPracticedAt: DateTime.now(),
        completedWarmupSteps: const <String>[
          'listen',
          'shadow',
          'slot_replace',
        ],
        clearNextReviewAt: true,
      ),
    );
  }

  InterviewCompiledWiki loadCompiledWiki() {
    return StorageService.instance.getObject<InterviewCompiledWiki>(
          _compiledWikiKey,
          InterviewCompiledWiki.fromJson,
        ) ??
        InterviewCompiledWiki.empty();
  }

  Future<void> saveCompiledWiki(InterviewCompiledWiki wiki) {
    return StorageService.instance.saveObject<InterviewCompiledWiki>(
      _compiledWikiKey,
      wiki,
      (InterviewCompiledWiki value) => value.toJson(),
    );
  }

  InterviewUserGrowthWiki loadUserGrowthWiki() {
    return StorageService.instance.getObject<InterviewUserGrowthWiki>(
          _growthWikiKey,
          InterviewUserGrowthWiki.fromJson,
        ) ??
        InterviewUserGrowthWiki.empty();
  }

  Future<void> saveUserGrowthWiki(InterviewUserGrowthWiki wiki) {
    return StorageService.instance.saveObject<InterviewUserGrowthWiki>(
      _growthWikiKey,
      wiki,
      (InterviewUserGrowthWiki value) => value.toJson(),
    );
  }

  InterviewWikiActionPlan buildActionPlan({
    required InterviewPracticeSession? session,
    DateTime? now,
  }) {
    final DateTime referenceTime = now ?? DateTime.now();
    final String sceneId = (session?.publicSceneId ?? _resolvedSceneId).trim();
    final String effectiveSceneId = sceneId.isEmpty
        ? defaultInterviewSceneId
        : sceneId;
    final Set<String> dismissed = _loadWikiItemFlags(
      _dismissedWikiItemsKey,
    ).keys.toSet();
    final Map<String, int> useful = _loadWikiItemFlags(_usefulWikiItemsKey);
    final InterviewCompiledWiki compiledWiki = loadCompiledWiki();
    final InterviewUserGrowthWiki growthWiki = loadUserGrowthWiki();
    final List<InterviewPersonalWikiExpression> masteredExpressions =
        loadMasteredExpressions(sourceSceneId: effectiveSceneId);
    final Set<String> activeTags = _activeTagsForSession(session);

    final List<InterviewWikiActionItem> reviewQueue =
        masteredExpressions
            .where(
              (InterviewPersonalWikiExpression item) =>
                  item.text.trim().isNotEmpty &&
                  !item.nextReviewAt.isAfter(referenceTime),
            )
            .map(
              (InterviewPersonalWikiExpression item) =>
                  _reviewActionItem(item, now: referenceTime),
            )
            .where(
              (InterviewWikiActionItem item) => !dismissed.contains(item.id),
            )
            .toList(growable: false)
          ..sort(
            (InterviewWikiActionItem a, InterviewWikiActionItem b) =>
                _actionPriority(
                  b,
                  activeTags: activeTags,
                  useful: useful,
                ).compareTo(
                  _actionPriority(a, activeTags: activeTags, useful: useful),
                ),
          );

    final Set<String> masteredNodeIds = masteredExpressions
        .map(
          (InterviewPersonalWikiExpression item) => item.sourceNodeId.isNotEmpty
              ? item.sourceNodeId
              : item.sourceExpressionId,
        )
        .where((String id) => id.trim().isNotEmpty)
        .toSet();
    final List<InterviewWikiActionItem> weaknessQueue =
        <InterviewWikiActionItem>[
              ...growthWiki.weakExpressions
                  .where(
                    (InterviewWeakExpressionState item) =>
                        item.sourceSceneId == effectiveSceneId &&
                        !masteredNodeIds.contains(item.sourceNodeId),
                  )
                  .map(_weakExpressionActionItem),
              ...growthWiki.errorPatterns
                  .where(
                    (InterviewUserErrorPattern item) =>
                        item.sourceSceneId == effectiveSceneId,
                  )
                  .map(_errorPatternActionItem),
              ...compiledWiki.weakPatterns.map(_weakPatternActionItem),
            ]
            .where(
              (InterviewWikiActionItem item) => !dismissed.contains(item.id),
            )
            .toList(growable: false)
          ..sort(
            (InterviewWikiActionItem a, InterviewWikiActionItem b) =>
                _actionPriority(
                  b,
                  activeTags: activeTags,
                  useful: useful,
                ).compareTo(
                  _actionPriority(a, activeTags: activeTags, useful: useful),
                ),
          );

    final List<InterviewWikiActionItem> personalMaterialHints =
        <InterviewWikiActionItem>[
              ...growthWiki.interviewStories.map(_storyActionItem),
              ...compiledWiki.nextTargets.map(_nextTargetActionItem),
              ...growthWiki.personalFacts.map(_factActionItem),
              ...compiledWiki.personalFacts.map(_factActionItem),
            ]
            .where(
              (InterviewWikiActionItem item) => !dismissed.contains(item.id),
            )
            .toList(growable: false)
          ..sort(
            (InterviewWikiActionItem a, InterviewWikiActionItem b) =>
                _actionPriority(
                  b,
                  activeTags: activeTags,
                  useful: useful,
                ).compareTo(
                  _actionPriority(a, activeTags: activeTags, useful: useful),
                ),
          );

    final List<InterviewWikiActionItem> ranked =
        <InterviewWikiActionItem>[
          ...reviewQueue,
          ...weaknessQueue,
          ...personalMaterialHints,
        ]..sort(
          (InterviewWikiActionItem a, InterviewWikiActionItem b) =>
              _actionPriority(
                b,
                activeTags: activeTags,
                useful: useful,
              ).compareTo(
                _actionPriority(a, activeTags: activeTags, useful: useful),
              ),
        );
    final InterviewWikiActionItem? primaryAction = ranked.isEmpty
        ? null
        : ranked.first;
    final List<InterviewWikiActionItem> promptContext =
        <InterviewWikiActionItem>[
          ?primaryAction,
          ...ranked.where(
            (InterviewWikiActionItem item) => item != primaryAction,
          ),
        ].take(3).toList(growable: false);

    return InterviewWikiActionPlan(
      generatedAt: referenceTime,
      primaryAction: primaryAction,
      reviewQueue: reviewQueue.take(8).toList(growable: false),
      weaknessQueue: weaknessQueue.take(8).toList(growable: false),
      personalMaterialHints: personalMaterialHints
          .take(8)
          .toList(growable: false),
      promptContext: promptContext,
    );
  }

  Future<void> dismissWikiItem(String id) async {
    final String normalized = id.trim();
    if (normalized.isEmpty) {
      return;
    }
    final Map<String, int> current = _loadWikiItemFlags(_dismissedWikiItemsKey);
    current[normalized] = DateTime.now().millisecondsSinceEpoch;
    await StorageService.instance.saveObject<Map<String, int>>(
      _dismissedWikiItemsKey,
      current,
      (Map<String, int> value) => <String, dynamic>{...value},
    );
  }

  Future<void> markWikiItemUseful(String id) async {
    final String normalized = id.trim();
    if (normalized.isEmpty) {
      return;
    }
    final Map<String, int> current = _loadWikiItemFlags(_usefulWikiItemsKey);
    current[normalized] = (current[normalized] ?? 0) + 1;
    await StorageService.instance.saveObject<Map<String, int>>(
      _usefulWikiItemsKey,
      current,
      (Map<String, int> value) => <String, dynamic>{...value},
    );
  }

  InterviewActiveSessionSnapshot? loadActiveSession({required String userId}) {
    final InterviewActiveSessionSnapshot? snapshot = StorageService.instance
        .getObject<InterviewActiveSessionSnapshot>(
          _activeSessionStorageKey,
          InterviewActiveSessionSnapshot.fromJson,
        );
    if (snapshot == null || snapshot.session.userId != userId) {
      return null;
    }
    if (snapshot.session.currentStage == 'wrap_up') {
      return null;
    }
    if (snapshot.session.publicSceneId != _resolvedSceneId) {
      return null;
    }
    return snapshot;
  }

  Future<void> saveActiveSession({
    required InterviewPracticeSession session,
    required List<InterviewChatMessage> messages,
  }) {
    return StorageService.instance.saveObject<InterviewActiveSessionSnapshot>(
      _activeSessionStorageKey,
      InterviewActiveSessionSnapshot(
        session: session,
        messages: messages,
        updatedAt: DateTime.now(),
      ),
      (InterviewActiveSessionSnapshot value) => value.toJson(),
    );
  }

  Future<void> clearActiveSession() {
    return StorageService.instance.remove(_activeSessionStorageKey);
  }

  String loadSelectedTargetLevel() {
    final Map<String, String> preferences =
        StorageService.instance.getObject<Map<String, String>>(
          _levelPreferencesKey,
          (Map<String, dynamic> json) => json.map(
            (String key, dynamic value) =>
                MapEntry<String, String>(key, (value as String? ?? '').trim()),
          ),
        ) ??
        const <String, String>{};
    return _normalizeTargetLevel(preferences[_resolvedSceneId]);
  }

  Future<void> saveSelectedTargetLevel(String targetLevel) async {
    final Map<String, String> current =
        StorageService.instance.getObject<Map<String, String>>(
          _levelPreferencesKey,
          (Map<String, dynamic> json) => json.map(
            (String key, dynamic value) =>
                MapEntry<String, String>(key, (value as String? ?? '').trim()),
          ),
        ) ??
        <String, String>{};
    final Map<String, String> next = Map<String, String>.from(current);
    next[_resolvedSceneId] = _normalizeTargetLevel(targetLevel);
    await StorageService.instance.saveObject<Map<String, String>>(
      _levelPreferencesKey,
      next,
      (Map<String, String> value) => value,
    );
  }

  Future<InterviewCompiledWiki> mergeCompiledWiki(
    InterviewCompiledWiki incoming,
  ) async {
    final InterviewCompiledWiki existing = loadCompiledWiki();
    final InterviewCompiledWiki merged = InterviewCompiledWiki(
      updatedAt: DateTime.now(),
      summary: incoming.summary.trim().isNotEmpty
          ? incoming.summary.trim()
          : existing.summary,
      personalFacts: _mergeWikiItems(
        existing.personalFacts,
        incoming.personalFacts,
        limit: 16,
      ),
      interviewStories: _mergeWikiItems(
        existing.interviewStories,
        incoming.interviewStories,
        limit: 10,
      ),
      weakPatterns: _mergeWikiItems(
        existing.weakPatterns,
        incoming.weakPatterns,
        limit: 10,
      ),
      nextTargets: _mergeWikiItems(
        existing.nextTargets,
        incoming.nextTargets,
        limit: 10,
      ),
      compileCount: existing.compileCount + 1,
    );
    await saveCompiledWiki(merged);
    return merged;
  }

  InterviewWikiMemoryPack buildMemoryPack({
    required Iterable<String> tags,
    String query = '',
    DateTime? now,
    InterviewPracticeSession? session,
  }) {
    final InterviewCompiledWiki wiki = loadCompiledWiki();
    final InterviewUserGrowthWiki growthWiki = loadUserGrowthWiki();
    final List<InterviewPersonalWikiExpression> masteredExpressions =
        loadMasteredExpressions();
    final DateTime referenceTime = now ?? DateTime.now();
    final Set<String> tagSet = tags
        .map((String tag) => tag.trim())
        .where((String tag) => tag.isNotEmpty)
        .toSet();
    final List<String> dueExpressions =
        _rankedDueExpressions(
              masteredExpressions,
              tagSet: tagSet,
              now: referenceTime,
            )
            .take(2)
            .map(
              (InterviewPersonalWikiExpression item) =>
                  '${item.text}${item.tag.isEmpty ? '' : ' [${item.tag}]'}',
            )
            .toList(growable: false);

    final InterviewWikiActionPlan actionPlan = buildActionPlan(
      session: session,
      now: referenceTime,
    );
    final List<InterviewWikiActionItem> actionContext = actionPlan.promptContext
        .where((InterviewWikiActionItem item) {
          final bool queryMatches =
              query.trim().isNotEmpty &&
              (item.body.contains(query) ||
                  item.title.contains(query) ||
                  item.reason.contains(query) ||
                  item.suggestedUse.contains(query) ||
                  item.sourceNodeId == query);
          final bool tagMatches =
              tagSet.isEmpty ||
              tagSet.any(
                (String tag) =>
                    item.title.contains(tag) ||
                    item.body.contains(tag) ||
                    item.reason.contains(tag),
              );
          return queryMatches || tagMatches;
        })
        .take(3)
        .toList(growable: false);

    return InterviewWikiMemoryPack(
      summary: _summaryForPack(wiki, query),
      primaryAction: actionPlan.primaryAction,
      actionItems: <InterviewWikiActionItem>[
        ...actionPlan.reviewQueue,
        ...actionPlan.weaknessQueue,
        ...actionPlan.personalMaterialHints,
      ],
      promptContext: actionContext.isEmpty
          ? actionPlan.promptContext
          : actionContext,
      dueExpressions: dueExpressions,
      relevantFacts: _rankWikiItems(
        wiki.personalFacts,
        tagSet: tagSet,
        query: query,
      ).take(2).map(_formatWikiItem).toList(growable: false),
      relevantStories: _rankWikiItems(
        wiki.interviewStories,
        tagSet: tagSet,
        query: query,
      ).take(1).map(_formatWikiItem).toList(growable: false),
      weakPatterns: _rankWikiItems(
        wiki.weakPatterns,
        tagSet: tagSet,
        query: query,
      ).take(2).map(_formatWikiItem).toList(growable: false),
      nextTargets: _rankWikiItems(
        wiki.nextTargets,
        tagSet: tagSet,
        query: query,
      ).take(2).map(_formatWikiItem).toList(growable: false),
      weakExpressions: _rankWeakExpressions(
        growthWiki.weakExpressions,
        tagSet: tagSet,
        query: query,
      ).take(2).map(_formatWeakExpression).toList(growable: false),
      commonErrors: _rankErrorPatterns(
        growthWiki.errorPatterns,
        tagSet: tagSet,
        query: query,
      ).take(2).map(_formatErrorPattern).toList(growable: false),
      pronunciationNotes: _pronunciationNotes(growthWiki.pronunciationProfile),
      grammarNotes: _grammarNotes(growthWiki.grammarProfile),
    );
  }

  Future<InterviewUserGrowthWiki> updateUserGrowthWikiFromReview({
    required InterviewPracticeSession session,
    required InterviewReview review,
    int? pronunciationOverall,
    int? pronunciationAccuracy,
    int? pronunciationFluency,
    int? pronunciationCompleteness,
  }) async {
    final DateTime now = DateTime.now();
    final InterviewUserGrowthWiki existing = loadUserGrowthWiki();
    final InterviewCompiledWiki compiledWiki = loadCompiledWiki();
    final List<InterviewPersonalWikiExpression> allMastered =
        loadAllMasteredExpressions();
    final String sceneId = session.publicSceneId.trim().isEmpty
        ? _resolvedSceneId
        : session.publicSceneId.trim();
    final Set<String> sceneMasteredIds = allMastered
        .where(
          (InterviewPersonalWikiExpression item) =>
              item.sourceSceneId == sceneId,
        )
        .map(
          (InterviewPersonalWikiExpression item) => item.sourceNodeId.isNotEmpty
              ? item.sourceNodeId
              : item.sourceExpressionId,
        )
        .where((String id) => id.isNotEmpty)
        .toSet();

    final List<InterviewWeakExpressionState> weakExpressions =
        _mergeWeakExpressions(
          existing.weakExpressions,
          _weakExpressionsFromSession(
            session,
            sceneId: sceneId,
            masteredNodeIds: sceneMasteredIds,
          ),
          sceneId: sceneId,
          masteredNodeIds: sceneMasteredIds,
        );
    final List<InterviewUserErrorPattern> errorPatterns = _mergeErrorPatterns(
      existing.errorPatterns,
      _errorPatternsFromReview(
        session: session,
        review: review,
        sceneId: sceneId,
        now: now,
        pronunciationOverall: pronunciationOverall,
      ),
    );
    final InterviewUserGrowthWiki next = InterviewUserGrowthWiki(
      updatedAt: now,
      profileSummary: compiledWiki.summary.trim().isNotEmpty
          ? compiledWiki.summary.trim()
          : existing.profileSummary,
      personalFacts: _mergeWikiItems(
        existing.personalFacts,
        compiledWiki.personalFacts,
        limit: 20,
      ),
      interviewStories: _mergeWikiItems(
        existing.interviewStories,
        compiledWiki.interviewStories,
        limit: 16,
      ),
      masteredExpressions: allMastered,
      weakExpressions: weakExpressions,
      errorPatterns: errorPatterns,
      pronunciationProfile: _updatedPronunciationProfile(
        existing.pronunciationProfile,
        now: now,
        overall: pronunciationOverall,
        accuracy: pronunciationAccuracy,
        fluency: pronunciationFluency,
        completeness: pronunciationCompleteness,
      ),
      grammarProfile: _updatedGrammarProfile(
        existing.grammarProfile,
        errorPatterns: errorPatterns,
        now: now,
      ),
      sceneProgress: _mergeSceneProgress(
        existing.sceneProgress,
        InterviewSceneProgressState(
          sourceSceneId: sceneId,
          masteredCount: review.totalMasteredCount,
          totalCount: review.totalExpressionCount,
          weakCount: weakExpressions
              .where(
                (InterviewWeakExpressionState item) =>
                    item.sourceSceneId == sceneId,
              )
              .length,
          lastNodeId: session.currentStage == 'wrap_up'
              ? ''
              : session.currentStage,
          nextRoundMode: review.nextRoundMode,
          lastPracticedAt: now,
        ),
      ),
      evidenceRefs: _mergeEvidenceRefs(
        existing.evidenceRefs,
        _evidenceRefsFromSession(session, sceneId: sceneId),
      ),
      compileCount: existing.compileCount + 1,
    );
    await saveUserGrowthWiki(next);
    return next;
  }

  Future<void> recordAnswerDiagnosis({
    required InterviewPracticeSession session,
    required InterviewExpression targetExpression,
    required InterviewAnswerDiagnosis diagnosis,
    required String userText,
  }) async {
    if (diagnosis.isComplete) {
      return;
    }
    final DateTime now = DateTime.now();
    final InterviewUserGrowthWiki existing = loadUserGrowthWiki();
    final String sceneId = session.publicSceneId.trim().isEmpty
        ? _resolvedSceneId
        : session.publicSceneId.trim();
    final String issueType = diagnosis.normalizedIssueType.isEmpty
        ? 'missing_intent'
        : diagnosis.normalizedIssueType;
    final String category = _answerDiagnosisCategory(issueType);
    final String title = diagnosis.mainIssue.trim().isEmpty
        ? _answerDiagnosisTitle(issueType)
        : diagnosis.mainIssue.trim();
    final String correction = diagnosis.microFix.trim().isNotEmpty
        ? diagnosis.microFix.trim()
        : diagnosis.coachMessage.trim();
    final InterviewUserErrorPattern incoming = InterviewUserErrorPattern(
      id: _errorPatternId(
        sceneId,
        category,
        '${targetExpression.id} $issueType',
      ),
      category: category,
      title: title,
      detail: diagnosis.didWell.trim().isEmpty
          ? title
          : '${diagnosis.didWell.trim()}；$title',
      correction: correction,
      sourceSceneId: sceneId,
      tag: targetExpression.tag,
      evidence: userText.trim(),
      count: 1,
      firstSeenAt: now,
      lastSeenAt: now,
    );
    final List<InterviewUserErrorPattern> errorPatterns = _mergeErrorPatterns(
      existing.errorPatterns,
      <InterviewUserErrorPattern>[incoming],
    );
    final InterviewUserGrowthWiki next = InterviewUserGrowthWiki(
      updatedAt: now,
      profileSummary: existing.profileSummary,
      personalFacts: existing.personalFacts,
      interviewStories: existing.interviewStories,
      masteredExpressions: existing.masteredExpressions,
      weakExpressions: existing.weakExpressions,
      errorPatterns: errorPatterns,
      pronunciationProfile: existing.pronunciationProfile,
      grammarProfile: _updatedGrammarProfile(
        existing.grammarProfile,
        errorPatterns: errorPatterns,
        now: now,
      ),
      sceneProgress: existing.sceneProgress,
      evidenceRefs: existing.evidenceRefs,
      compileCount: existing.compileCount,
    );
    await saveUserGrowthWiki(next);
  }

  Future<void> upsertMasteredExpression({
    required InterviewExpression expression,
    required String stage,
    required String userExample,
    double? performanceScore,
    double? textMatch,
    int attemptCount = 1,
  }) async {
    final List<InterviewPersonalWikiExpression> current =
        loadAllMasteredExpressions();
    final String resolvedSceneId = _resolvedSceneId;
    final int existingIndex = current.indexWhere(
      (InterviewPersonalWikiExpression item) =>
          item.sourceSceneId == resolvedSceneId &&
          item.sourceExpressionId == expression.id,
    );
    final InterviewPersonalWikiExpression? existing = existingIndex >= 0
        ? current[existingIndex]
        : null;
    final DateTime now = DateTime.now();
    final int reviewCount = (existing?.reviewCount ?? 0) + 1;
    final double easeFactor = _nextEaseFactor(
      existing?.easeFactor ?? 2.5,
      performanceScore: performanceScore,
      textMatch: textMatch,
      attemptCount: attemptCount,
    );
    final int intervalDays = _nextIntervalDays(
      existing: existing,
      reviewCount: reviewCount,
      easeFactor: easeFactor,
      performanceScore: performanceScore,
      textMatch: textMatch,
      attemptCount: attemptCount,
    );
    final InterviewPersonalWikiExpression next =
        InterviewPersonalWikiExpression(
          id: expression.id.isNotEmpty
              ? resolvedSceneId == defaultInterviewSceneId
                    ? expression.id
                    : '${resolvedSceneId}_${expression.id}'
              : 'interview_${expression.text.hashCode}',
          sourceSceneId: resolvedSceneId,
          sourceExpressionId: expression.id,
          sourceNodeId: expression.id,
          text: expression.text,
          tag: expression.tag,
          stage: stage,
          masteredAt: existing?.masteredAt ?? now,
          userExample: userExample,
          firstMasteredAt:
              existing?.firstMasteredAt ?? existing?.masteredAt ?? now,
          lastReviewedAt: now,
          nextReviewAt: now.add(Duration(days: intervalDays)),
          reviewCount: reviewCount,
          easeFactor: easeFactor,
          intervalDays: intervalDays,
        );
    final List<InterviewPersonalWikiExpression> updated =
        List<InterviewPersonalWikiExpression>.from(current);
    if (existingIndex >= 0) {
      updated[existingIndex] = next;
    } else {
      updated.add(next);
    }
    await StorageService.instance.saveList<InterviewPersonalWikiExpression>(
      _key,
      updated,
      (InterviewPersonalWikiExpression value) => value.toJson(),
    );
  }

  List<InterviewWeakExpressionState> _weakExpressionsFromSession(
    InterviewPracticeSession session, {
    required String sceneId,
    required Set<String> masteredNodeIds,
  }) {
    final List<InterviewWeakExpressionState> result =
        <InterviewWeakExpressionState>[];
    for (final MapEntry<String, InterviewExpression> entry
        in session.stageExpressionTargets.entries) {
      final String stage = entry.key;
      if (stage == 'wrap_up' || masteredNodeIds.contains(entry.value.id)) {
        continue;
      }
      final InterviewTurnRecord? lastTurn = _lastTurnForStage(session, stage);
      final String coverageStatus = lastTurn?.coverageStatus ?? '';
      final String hintLevel = session.stageHintLevels[stage] ?? '';
      final int attempts = session.stageAttempts[stage] ?? 0;
      if (attempts <= 0 && coverageStatus.isEmpty && hintLevel.isEmpty) {
        continue;
      }
      result.add(
        InterviewWeakExpressionState(
          sourceSceneId: sceneId,
          sourceNodeId: entry.value.id,
          sourceExpressionId: entry.value.id,
          targetText: entry.value.text,
          tag: entry.value.tag,
          reason: _weakExpressionReason(
            coverageStatus: coverageStatus,
            hintLevel: hintLevel,
          ),
          lastUserExample: lastTurn?.userText ?? '',
          lastHintLevel: hintLevel,
          attempts: attempts,
          lastSeenAt: lastTurn?.createdAt ?? DateTime.now(),
        ),
      );
    }
    return result;
  }

  String _weakExpressionReason({
    required String coverageStatus,
    required String hintLevel,
  }) {
    if (coverageStatus == 'stuck') {
      return '用户卡住，尚未自然复现目标表达。';
    }
    if (coverageStatus == 'partial_covered') {
      return '用户只部分复现，需要继续练完整回答。';
    }
    if (hintLevel == 'L3' || hintLevel == 'L4') {
      return '用户依赖高阶提示，需要在新语境中复用。';
    }
    return '本轮尚未确认掌握。';
  }

  InterviewTurnRecord? _lastTurnForStage(
    InterviewPracticeSession session,
    String stage,
  ) {
    for (int index = session.turns.length - 1; index >= 0; index -= 1) {
      final InterviewTurnRecord turn = session.turns[index];
      if (turn.stage == stage) {
        return turn;
      }
    }
    return null;
  }

  List<InterviewWeakExpressionState> _mergeWeakExpressions(
    List<InterviewWeakExpressionState> existing,
    List<InterviewWeakExpressionState> incoming, {
    required String sceneId,
    required Set<String> masteredNodeIds,
  }) {
    final Map<String, InterviewWeakExpressionState> byKey =
        <String, InterviewWeakExpressionState>{};
    for (final InterviewWeakExpressionState item in existing) {
      final bool masteredInCurrentScene =
          item.sourceSceneId == sceneId &&
          masteredNodeIds.contains(item.sourceNodeId);
      if (!masteredInCurrentScene && item.key.trim().isNotEmpty) {
        byKey[item.key] = item;
      }
    }
    for (final InterviewWeakExpressionState item in incoming) {
      if (item.key.trim().isNotEmpty) {
        byKey[item.key] = item;
      }
    }
    final List<InterviewWeakExpressionState> merged =
        byKey.values.toList(growable: false)..sort(
          (InterviewWeakExpressionState a, InterviewWeakExpressionState b) =>
              b.lastSeenAt.compareTo(a.lastSeenAt),
        );
    return merged.take(80).toList(growable: false);
  }

  List<InterviewUserErrorPattern> _errorPatternsFromReview({
    required InterviewPracticeSession session,
    required InterviewReview review,
    required String sceneId,
    required DateTime now,
    required int? pronunciationOverall,
  }) {
    final List<InterviewUserErrorPattern> result =
        <InterviewUserErrorPattern>[];
    for (final InterviewCorrection correction in review.corrections) {
      result.add(
        InterviewUserErrorPattern(
          id: _errorPatternId(sceneId, 'expression', correction.id),
          category: 'expression',
          title: correction.wrong,
          detail: correction.reason,
          correction: correction.better,
          sourceSceneId: sceneId,
          tag: correction.category,
          evidence: correction.wrong,
          count: 1,
          firstSeenAt: now,
          lastSeenAt: now,
        ),
      );
    }
    for (final String tag in review.weakTags.take(4)) {
      result.add(
        InterviewUserErrorPattern(
          id: _errorPatternId(sceneId, 'fluency', tag),
          category: 'fluency',
          title: '$tag 易卡顿',
          detail: '用户在这个标签下没有稳定复现目标表达。',
          correction: '下一轮优先创造语境，让用户复用相关目标表达。',
          sourceSceneId: sceneId,
          tag: tag,
          evidence: 'weak tag from review',
          count: 1,
          firstSeenAt: now,
          lastSeenAt: now,
        ),
      );
    }
    if (pronunciationOverall != null && pronunciationOverall < 80) {
      result.add(
        InterviewUserErrorPattern(
          id: _errorPatternId(sceneId, 'pronunciation', 'overall'),
          category: 'pronunciation',
          title: '发音稳定性需要巩固',
          detail: '最近一次语音评分低于 80。',
          correction: '下一轮提示可优先使用更短句，并鼓励慢速清晰复述。',
          sourceSceneId: sceneId,
          tag: '',
          evidence: 'pronunciation score $pronunciationOverall',
          count: 1,
          firstSeenAt: now,
          lastSeenAt: now,
        ),
      );
    }
    if (session.consecutiveStuckCount > 0) {
      result.add(
        InterviewUserErrorPattern(
          id: _errorPatternId(sceneId, 'stuck', 'consecutive'),
          category: 'fluency',
          title: '连续卡顿',
          detail: '用户连续多轮需要降低难度或更明确的语境引导。',
          correction: '下一轮减少新表达密度，先让用户复用已出现表达。',
          sourceSceneId: sceneId,
          tag: '',
          evidence: 'consecutive stuck count ${session.consecutiveStuckCount}',
          count: 1,
          firstSeenAt: now,
          lastSeenAt: now,
        ),
      );
    }
    return result;
  }

  String _answerDiagnosisCategory(String issueType) {
    return switch (issueType) {
      'pronunciation' => 'pronunciation',
      'fluency' => 'fluency',
      'grammar' => 'grammar',
      'tone' => 'pragmatics',
      'off_topic' || 'question_echo' => 'relevance',
      _ => 'expression',
    };
  }

  String _answerDiagnosisTitle(String issueType) {
    return switch (issueType) {
      'grammar' => '语法影响表达',
      'tone' => '语气不够自然',
      'too_short' => '回答信息不足',
      'pronunciation' => '发音影响理解',
      'fluency' => '表达流畅度不足',
      'off_topic' => '回答偏离问题',
      'question_echo' => '像是在重复问题',
      _ => '目标表达没有说完整',
    };
  }

  String _errorPatternId(String sceneId, String category, String raw) {
    final String slug = '$sceneId $category $raw'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return slug.isEmpty ? '${sceneId}_${category}_unknown' : slug;
  }

  List<InterviewUserErrorPattern> _mergeErrorPatterns(
    List<InterviewUserErrorPattern> existing,
    List<InterviewUserErrorPattern> incoming,
  ) {
    final Map<String, InterviewUserErrorPattern> byId =
        <String, InterviewUserErrorPattern>{
          for (final InterviewUserErrorPattern item in existing)
            if (item.id.trim().isNotEmpty) item.id: item,
        };
    for (final InterviewUserErrorPattern item in incoming) {
      final InterviewUserErrorPattern? old = byId[item.id];
      byId[item.id] = old == null
          ? item
          : InterviewUserErrorPattern(
              id: old.id,
              category: item.category.isNotEmpty ? item.category : old.category,
              title: item.title.isNotEmpty ? item.title : old.title,
              detail: item.detail.isNotEmpty ? item.detail : old.detail,
              correction: item.correction.isNotEmpty
                  ? item.correction
                  : old.correction,
              sourceSceneId: item.sourceSceneId,
              tag: item.tag.isNotEmpty ? item.tag : old.tag,
              evidence: item.evidence.isNotEmpty ? item.evidence : old.evidence,
              count: old.count + item.count,
              firstSeenAt: old.firstSeenAt.isBefore(item.firstSeenAt)
                  ? old.firstSeenAt
                  : item.firstSeenAt,
              lastSeenAt: item.lastSeenAt,
            );
    }
    final List<InterviewUserErrorPattern> merged =
        byId.values.toList(growable: false)
          ..sort((InterviewUserErrorPattern a, InterviewUserErrorPattern b) {
            final int countCompare = b.count.compareTo(a.count);
            if (countCompare != 0) {
              return countCompare;
            }
            return b.lastSeenAt.compareTo(a.lastSeenAt);
          });
    return merged.take(80).toList(growable: false);
  }

  InterviewPronunciationProfile? _updatedPronunciationProfile(
    InterviewPronunciationProfile? existing, {
    required DateTime now,
    required int? overall,
    required int? accuracy,
    required int? fluency,
    required int? completeness,
  }) {
    if (overall == null) {
      return existing;
    }
    final int sampleCount = (existing?.sampleCount ?? 0) + 1;
    final int previousCount = sampleCount - 1;
    final List<String> notes = <String>{
      ...?existing?.notes,
      ..._notesForPronunciationScore(
        overall: overall,
        accuracy: accuracy,
        fluency: fluency,
        completeness: completeness,
      ),
    }.take(6).toList(growable: false);
    return InterviewPronunciationProfile(
      updatedAt: now,
      sampleCount: sampleCount,
      averageOverall: _updatedAverage(
        existing?.averageOverall ?? 0,
        previousCount,
        overall.toDouble(),
      ),
      averageAccuracy: _updatedAverage(
        existing?.averageAccuracy ?? 0,
        previousCount,
        accuracy?.toDouble(),
      ),
      averageFluency: _updatedAverage(
        existing?.averageFluency ?? 0,
        previousCount,
        fluency?.toDouble(),
      ),
      averageCompleteness: _updatedAverage(
        existing?.averageCompleteness ?? 0,
        previousCount,
        completeness?.toDouble(),
      ),
      notes: notes,
    );
  }

  double _updatedAverage(double current, int previousCount, double? next) {
    if (next == null) {
      return current;
    }
    if (previousCount <= 0) {
      return double.parse(next.toStringAsFixed(2));
    }
    return double.parse(
      (((current * previousCount) + next) / (previousCount + 1))
          .toStringAsFixed(2),
    );
  }

  List<String> _notesForPronunciationScore({
    required int overall,
    required int? accuracy,
    required int? fluency,
    required int? completeness,
  }) {
    final List<String> notes = <String>[];
    if (overall < 75) {
      notes.add('发音整体稳定性偏弱，优先用短句慢速复述。');
    }
    if ((accuracy ?? 100) < 75) {
      notes.add('准确度偏低，注意关键词发音。');
    }
    if ((fluency ?? 100) < 75) {
      notes.add('流利度偏低，下一轮减少句子长度。');
    }
    if ((completeness ?? 100) < 75) {
      notes.add('完整度偏低，提示时给更清晰的开头。');
    }
    return notes;
  }

  InterviewGrammarProfile? _updatedGrammarProfile(
    InterviewGrammarProfile? existing, {
    required List<InterviewUserErrorPattern> errorPatterns,
    required DateTime now,
  }) {
    final List<InterviewUserErrorPattern> grammarLike = errorPatterns
        .where(
          (InterviewUserErrorPattern item) =>
              item.category == 'expression' || item.category == 'grammar',
        )
        .toList(growable: false);
    if (grammarLike.isEmpty) {
      return existing;
    }
    grammarLike.sort(
      (InterviewUserErrorPattern a, InterviewUserErrorPattern b) =>
          b.count.compareTo(a.count),
    );
    final List<String> issues = grammarLike
        .take(6)
        .map((InterviewUserErrorPattern item) => item.title)
        .where((String item) => item.trim().isNotEmpty)
        .toList(growable: false);
    return InterviewGrammarProfile(
      updatedAt: now,
      issueCount: grammarLike.fold<int>(
        0,
        (int total, InterviewUserErrorPattern item) => total + item.count,
      ),
      recurringIssues: issues,
      notes: <String>{
        ...?existing?.notes,
        if (issues.isNotEmpty) '高频表达/语法问题：${issues.take(3).join('；')}',
      }.take(6).toList(growable: false),
    );
  }

  List<InterviewSceneProgressState> _mergeSceneProgress(
    List<InterviewSceneProgressState> existing,
    InterviewSceneProgressState incoming,
  ) {
    final Map<String, InterviewSceneProgressState> byScene =
        <String, InterviewSceneProgressState>{
          for (final InterviewSceneProgressState item in existing)
            if (item.sourceSceneId.trim().isNotEmpty) item.sourceSceneId: item,
        };
    byScene[incoming.sourceSceneId] = incoming;
    final List<InterviewSceneProgressState> merged =
        byScene.values.toList(growable: false)..sort(
          (InterviewSceneProgressState a, InterviewSceneProgressState b) =>
              b.lastPracticedAt.compareTo(a.lastPracticedAt),
        );
    return merged.take(30).toList(growable: false);
  }

  List<InterviewLearningEvidenceRef> _evidenceRefsFromSession(
    InterviewPracticeSession session, {
    required String sceneId,
  }) {
    return session.turns
        .where((InterviewTurnRecord turn) => turn.userText.trim().isNotEmpty)
        .take(12)
        .map(
          (InterviewTurnRecord turn) => InterviewLearningEvidenceRef(
            id: '${sceneId}_${turn.stage}_${turn.createdAt.microsecondsSinceEpoch}',
            type: turn.voiceCompositeScore == null ? 'turn' : 'voice_score',
            sourceSceneId: sceneId,
            sourceNodeId:
                session.stageExpressionTargets[turn.stage]?.id ?? turn.stage,
            stage: turn.stage,
            text: turn.userText,
            score: (turn.voiceCompositeScore ?? 0).toDouble(),
            createdAt: turn.createdAt,
          ),
        )
        .toList(growable: false);
  }

  List<InterviewLearningEvidenceRef> _mergeEvidenceRefs(
    List<InterviewLearningEvidenceRef> existing,
    List<InterviewLearningEvidenceRef> incoming,
  ) {
    final Map<String, InterviewLearningEvidenceRef> byId =
        <String, InterviewLearningEvidenceRef>{
          for (final InterviewLearningEvidenceRef item in existing)
            if (item.id.trim().isNotEmpty) item.id: item,
        };
    for (final InterviewLearningEvidenceRef item in incoming) {
      if (item.id.trim().isNotEmpty) {
        byId[item.id] = item;
      }
    }
    final List<InterviewLearningEvidenceRef> merged =
        byId.values.toList(growable: false)..sort(
          (InterviewLearningEvidenceRef a, InterviewLearningEvidenceRef b) =>
              b.createdAt.compareTo(a.createdAt),
        );
    return merged.take(80).toList(growable: false);
  }

  double _nextEaseFactor(
    double current, {
    double? performanceScore,
    double? textMatch,
    int attemptCount = 1,
  }) {
    if (!_hasReviewQualitySignal(
      performanceScore: performanceScore,
      textMatch: textMatch,
      attemptCount: attemptCount,
    )) {
      return (current + 0.08).clamp(1.3, 3.0).toDouble();
    }
    final double quality = _reviewQuality(
      performanceScore: performanceScore,
      textMatch: textMatch,
      attemptCount: attemptCount,
    );
    final double delta = quality >= 0.92
        ? 0.12
        : quality >= 0.82
        ? 0.06
        : quality >= 0.72
        ? 0
        : quality >= 0.62
        ? -0.10
        : -0.20;
    return (current + delta).clamp(1.3, 3.0).toDouble();
  }

  int _nextIntervalDays({
    required InterviewPersonalWikiExpression? existing,
    required int reviewCount,
    required double easeFactor,
    double? performanceScore,
    double? textMatch,
    int attemptCount = 1,
  }) {
    final int baseInterval = _baseIntervalDays(
      existing: existing,
      reviewCount: reviewCount,
      easeFactor: easeFactor,
    );
    if (!_hasReviewQualitySignal(
      performanceScore: performanceScore,
      textMatch: textMatch,
      attemptCount: attemptCount,
    )) {
      return baseInterval;
    }
    final double quality = _reviewQuality(
      performanceScore: performanceScore,
      textMatch: textMatch,
      attemptCount: attemptCount,
    );
    final double multiplier = quality >= 0.92
        ? 1.20
        : quality >= 0.82
        ? 1.0
        : quality >= 0.72
        ? 0.75
        : 0.50;
    return (baseInterval * multiplier).round().clamp(1, 90).toInt();
  }

  int _baseIntervalDays({
    required InterviewPersonalWikiExpression? existing,
    required int reviewCount,
    required double easeFactor,
  }) {
    if (existing == null || reviewCount <= 1) {
      return 1;
    }
    if (reviewCount == 2) {
      return 3;
    }
    if (reviewCount == 3) {
      return 7;
    }
    final int previousInterval = existing.intervalDays <= 0
        ? 1
        : existing.intervalDays;
    return (previousInterval * easeFactor).round().clamp(7, 90).toInt();
  }

  bool _hasReviewQualitySignal({
    required double? performanceScore,
    required double? textMatch,
    required int attemptCount,
  }) {
    return performanceScore != null || textMatch != null || attemptCount > 1;
  }

  double _reviewQuality({
    required double? performanceScore,
    required double? textMatch,
    required int attemptCount,
  }) {
    final double scoreSignal = (performanceScore ?? ((textMatch ?? 0.78) * 100))
        .clamp(0, 100)
        .toDouble();
    final double textSignal = (textMatch ?? scoreSignal / 100)
        .clamp(0, 1)
        .toDouble();
    final double attemptPenalty = ((attemptCount - 1).clamp(0, 5) * 0.04)
        .clamp(0, 0.20)
        .toDouble();
    return (scoreSignal / 100 * 0.70 + textSignal * 0.30 - attemptPenalty)
        .clamp(0, 1)
        .toDouble();
  }

  List<InterviewCompiledWikiItem> _mergeWikiItems(
    List<InterviewCompiledWikiItem> existing,
    List<InterviewCompiledWikiItem> incoming, {
    required int limit,
  }) {
    final Map<String, InterviewCompiledWikiItem> byKey =
        <String, InterviewCompiledWikiItem>{};
    for (final InterviewCompiledWikiItem item in existing) {
      final String key = _wikiItemKey(item);
      if (key.isNotEmpty) {
        byKey[key] = item;
      }
    }
    for (final InterviewCompiledWikiItem item in incoming) {
      final String key = _wikiItemKey(item);
      if (key.isNotEmpty) {
        byKey[key] = item;
      }
    }
    final List<InterviewCompiledWikiItem> merged =
        byKey.values.toList(growable: false)..sort(
          (InterviewCompiledWikiItem a, InterviewCompiledWikiItem b) =>
              b.updatedAt.compareTo(a.updatedAt),
        );
    return merged.take(limit).toList(growable: false);
  }

  Map<String, int> _loadWikiItemFlags(String key) {
    return StorageService.instance.getObject<Map<String, int>>(
          key,
          (Map<String, dynamic> json) => json.map(
            (String key, dynamic value) => MapEntry<String, int>(
              key,
              ((value as num?)?.round() ?? 0).toInt(),
            ),
          ),
        ) ??
        <String, int>{};
  }

  Set<String> _activeTagsForSession(InterviewPracticeSession? session) {
    if (session == null) {
      return const <String>{};
    }
    return <String>{
      if (session.currentStage != 'wrap_up')
        stageToPrimaryTag[session.currentStage] ?? '',
      session.stagePrimaryTags[session.currentStage] ?? '',
      session.stageExpressionTargets[session.currentStage]?.tag ?? '',
    }.where((String item) => item.trim().isNotEmpty).toSet();
  }

  int _actionPriority(
    InterviewWikiActionItem item, {
    required Set<String> activeTags,
    required Map<String, int> useful,
  }) {
    int score = item.priority + ((useful[item.id] ?? 0).clamp(0, 5) * 3);
    if (activeTags.isNotEmpty &&
        activeTags.any(
          (String tag) =>
              item.title.contains(tag) ||
              item.body.contains(tag) ||
              item.reason.contains(tag),
        )) {
      score += 8;
    }
    return score;
  }

  InterviewWikiActionItem _reviewActionItem(
    InterviewPersonalWikiExpression item, {
    required DateTime now,
  }) {
    final int overdueDays = now
        .difference(item.nextReviewAt)
        .inDays
        .clamp(0, 30);
    return InterviewWikiActionItem(
      id: 'review:${item.sourceSceneId}:${item.sourceExpressionId}',
      type: 'review',
      title: item.text,
      body: item.tag.isEmpty ? '复习已掌握表达' : '复习 ${item.tag} 表达',
      sourceSceneId: item.sourceSceneId,
      sourceNodeId: item.sourceNodeId,
      priority: 100 + overdueDays,
      reason: overdueDays > 0
          ? '这句已经到期 $overdueDays 天，优先自然复现一次。'
          : '这句今天到期，适合放进下一轮回答里巩固。',
      evidence: item.userExample,
      suggestedUse: '下一问围绕相近语境，引导用户自然说出这句表达。',
    );
  }

  InterviewWikiActionItem _weakExpressionActionItem(
    InterviewWeakExpressionState item,
  ) {
    return InterviewWikiActionItem(
      id: 'weak:${item.sourceSceneId}:${item.sourceNodeId}',
      type: 'weak_expression',
      title: item.targetText,
      body: item.reason,
      sourceSceneId: item.sourceSceneId,
      sourceNodeId: item.sourceNodeId,
      priority: 88 + item.attempts.clamp(0, 8),
      reason: item.reason,
      evidence: item.lastUserExample,
      suggestedUse: '先降低问题难度，再让用户补完整目标表达。',
    );
  }

  InterviewWikiActionItem _errorPatternActionItem(
    InterviewUserErrorPattern item,
  ) {
    return InterviewWikiActionItem(
      id: 'error:${item.id}',
      type: 'error_pattern',
      title: item.title,
      body: item.correction.isEmpty ? item.detail : item.correction,
      sourceSceneId: item.sourceSceneId,
      sourceNodeId: '',
      priority: 78 + item.count.clamp(0, 10),
      reason: item.detail,
      evidence: item.evidence,
      suggestedUse: item.correction.isEmpty ? '下一轮避免重复这个表达问题。' : '下一轮优先使用建议改写。',
    );
  }

  InterviewWikiActionItem _weakPatternActionItem(
    InterviewCompiledWikiItem item,
  ) {
    return InterviewWikiActionItem(
      id: 'weak_pattern:${item.id}',
      type: 'weak_pattern',
      title: item.title,
      body: item.body,
      sourceSceneId: _resolvedSceneId,
      sourceNodeId: '',
      priority: 76,
      reason: item.body,
      evidence: item.evidence,
      suggestedUse: '把这个弱点转成下一轮追问或提示约束。',
    );
  }

  InterviewWikiActionItem _nextTargetActionItem(
    InterviewCompiledWikiItem item,
  ) {
    return InterviewWikiActionItem(
      id: 'next_target:${item.id}',
      type: 'next_target',
      title: item.title,
      body: item.body,
      sourceSceneId: _resolvedSceneId,
      sourceNodeId: '',
      priority: 66,
      reason: '复盘生成的下轮目标。',
      evidence: item.evidence,
      suggestedUse: item.body.isEmpty ? '下一轮练这个目标。' : item.body,
    );
  }

  InterviewWikiActionItem _storyActionItem(InterviewCompiledWikiItem item) {
    return InterviewWikiActionItem(
      id: 'story:${item.id}',
      type: 'personal_story',
      title: item.title,
      body: item.body,
      sourceSceneId: _resolvedSceneId,
      sourceNodeId: '',
      priority: 58,
      reason: '这是可复用的个人面试素材。',
      evidence: item.evidence,
      suggestedUse: '遇到经历、成果或问题解决类问题时复用这段素材。',
    );
  }

  InterviewWikiActionItem _factActionItem(InterviewCompiledWikiItem item) {
    return InterviewWikiActionItem(
      id: 'fact:${item.id}',
      type: 'personal_fact',
      title: item.title,
      body: item.body,
      sourceSceneId: _resolvedSceneId,
      sourceNodeId: '',
      priority: 48,
      reason: '这是长期个人背景信息。',
      evidence: item.evidence,
      suggestedUse: '在自我介绍或追问中作为真实背景补充。',
    );
  }

  String _wikiItemKey(InterviewCompiledWikiItem item) {
    if (item.id.trim().isNotEmpty) {
      return item.id.trim();
    }
    return '${item.tag}|${item.title}|${item.body}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _summaryForPack(InterviewCompiledWiki wiki, String query) {
    if (wiki.summary.trim().isEmpty) {
      return '';
    }
    final Set<String> queryTokens = _memoryTokens(query);
    if (queryTokens.isEmpty) {
      return wiki.summary.trim();
    }
    final Set<String> summaryTokens = _memoryTokens(wiki.summary);
    if (summaryTokens.intersection(queryTokens).isEmpty) {
      return '';
    }
    return wiki.summary.trim();
  }

  List<InterviewPersonalWikiExpression> _rankedDueExpressions(
    List<InterviewPersonalWikiExpression> expressions, {
    required Set<String> tagSet,
    required DateTime now,
  }) {
    final List<InterviewPersonalWikiExpression> candidates = expressions
        .where((InterviewPersonalWikiExpression item) {
          if (item.text.trim().isEmpty) {
            return false;
          }
          if (item.nextReviewAt.isAfter(now)) {
            return false;
          }
          return tagSet.isEmpty || tagSet.contains(item.tag);
        })
        .toList(growable: false);
    candidates.sort((
      InterviewPersonalWikiExpression a,
      InterviewPersonalWikiExpression b,
    ) {
      final int tagCompare = _tagScore(
        b.tag,
        tagSet,
      ).compareTo(_tagScore(a.tag, tagSet));
      if (tagCompare != 0) {
        return tagCompare;
      }
      return a.nextReviewAt.compareTo(b.nextReviewAt);
    });
    return candidates;
  }

  List<InterviewCompiledWikiItem> _rankWikiItems(
    List<InterviewCompiledWikiItem> items, {
    required Set<String> tagSet,
    required String query,
  }) {
    final Set<String> queryTokens = _memoryTokens(query);
    final List<InterviewCompiledWikiItem> candidates = items
        .where(
          (InterviewCompiledWikiItem item) =>
              item.title.trim().isNotEmpty || item.body.trim().isNotEmpty,
        )
        .toList(growable: false);
    candidates.sort((InterviewCompiledWikiItem a, InterviewCompiledWikiItem b) {
      final int scoreCompare = _wikiItemScore(
        b,
        tagSet: tagSet,
        queryTokens: queryTokens,
      ).compareTo(_wikiItemScore(a, tagSet: tagSet, queryTokens: queryTokens));
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return candidates;
  }

  List<InterviewWeakExpressionState> _rankWeakExpressions(
    List<InterviewWeakExpressionState> items, {
    required Set<String> tagSet,
    required String query,
  }) {
    final Set<String> queryTokens = _memoryTokens(query);
    final List<InterviewWeakExpressionState> candidates = items
        .where(
          (InterviewWeakExpressionState item) =>
              item.targetText.trim().isNotEmpty,
        )
        .toList(growable: false);
    candidates.sort((
      InterviewWeakExpressionState a,
      InterviewWeakExpressionState b,
    ) {
      final int scoreCompare =
          _weakExpressionScore(
            b,
            tagSet: tagSet,
            queryTokens: queryTokens,
          ).compareTo(
            _weakExpressionScore(a, tagSet: tagSet, queryTokens: queryTokens),
          );
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return b.lastSeenAt.compareTo(a.lastSeenAt);
    });
    return candidates;
  }

  int _weakExpressionScore(
    InterviewWeakExpressionState item, {
    required Set<String> tagSet,
    required Set<String> queryTokens,
  }) {
    int score = _tagScore(item.tag, tagSet) * 20;
    if (queryTokens.isNotEmpty) {
      final Set<String> itemTokens = _memoryTokens(
        '${item.targetText} ${item.reason} ${item.lastUserExample}',
      );
      score += itemTokens.intersection(queryTokens).length * 6;
    }
    if (item.lastHintLevel == 'L3' || item.lastHintLevel == 'L4') {
      score += 4;
    }
    score += item.attempts.clamp(0, 4);
    return score;
  }

  List<InterviewUserErrorPattern> _rankErrorPatterns(
    List<InterviewUserErrorPattern> items, {
    required Set<String> tagSet,
    required String query,
  }) {
    final Set<String> queryTokens = _memoryTokens(query);
    final List<InterviewUserErrorPattern> candidates = items
        .where(
          (InterviewUserErrorPattern item) =>
              item.title.trim().isNotEmpty || item.detail.trim().isNotEmpty,
        )
        .toList(growable: false);
    candidates.sort((InterviewUserErrorPattern a, InterviewUserErrorPattern b) {
      final int scoreCompare =
          _errorPatternScore(
            b,
            tagSet: tagSet,
            queryTokens: queryTokens,
          ).compareTo(
            _errorPatternScore(a, tagSet: tagSet, queryTokens: queryTokens),
          );
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return b.lastSeenAt.compareTo(a.lastSeenAt);
    });
    return candidates;
  }

  int _errorPatternScore(
    InterviewUserErrorPattern item, {
    required Set<String> tagSet,
    required Set<String> queryTokens,
  }) {
    int score = _tagScore(item.tag, tagSet) * 20;
    score += item.count.clamp(0, 10);
    if (queryTokens.isNotEmpty) {
      final Set<String> itemTokens = _memoryTokens(
        '${item.title} ${item.detail} ${item.correction} ${item.evidence}',
      );
      score += itemTokens.intersection(queryTokens).length * 6;
    }
    return score;
  }

  int _wikiItemScore(
    InterviewCompiledWikiItem item, {
    required Set<String> tagSet,
    required Set<String> queryTokens,
  }) {
    int score = _tagScore(item.tag, tagSet) * 20;
    if (queryTokens.isNotEmpty) {
      final Set<String> itemTokens = _memoryTokens(
        '${item.title} ${item.body} ${item.evidence}',
      );
      score += itemTokens.intersection(queryTokens).length * 6;
    }
    if (item.evidence.trim().isNotEmpty) {
      score += 2;
    }
    return score;
  }

  int _tagScore(String tag, Set<String> tagSet) {
    if (tagSet.isEmpty) {
      return 1;
    }
    return tagSet.contains(tag) ? 2 : 0;
  }

  String _formatWikiItem(InterviewCompiledWikiItem item) {
    final String body = item.body.trim().isNotEmpty
        ? item.body.trim()
        : item.title.trim();
    final String title = item.title.trim();
    final String prefix = title.isEmpty || title == body ? '' : '$title: ';
    final String suffix = item.tag.trim().isEmpty ? '' : ' [${item.tag}]';
    return '$prefix$body$suffix';
  }

  String _formatWeakExpression(InterviewWeakExpressionState item) {
    final String suffix = item.tag.trim().isEmpty ? '' : ' [${item.tag}]';
    final String hint = item.lastHintLevel.trim().isEmpty
        ? ''
        : ' hint=${item.lastHintLevel}';
    return '${item.targetText} | ${item.reason}$hint$suffix';
  }

  String _formatErrorPattern(InterviewUserErrorPattern item) {
    final String correction = item.correction.trim().isEmpty
        ? ''
        : ' -> ${item.correction}';
    final String suffix = item.tag.trim().isEmpty ? '' : ' [${item.tag}]';
    return '${item.title}$correction (x${item.count})$suffix';
  }

  List<String> _pronunciationNotes(InterviewPronunciationProfile? profile) {
    if (profile == null || profile.isEmpty) {
      return const <String>[];
    }
    return <String>[
      if (profile.averageOverall > 0)
        '平均发音 ${profile.averageOverall.toStringAsFixed(0)}',
      ...profile.notes,
    ].take(2).toList(growable: false);
  }

  List<String> _grammarNotes(InterviewGrammarProfile? profile) {
    if (profile == null || profile.isEmpty) {
      return const <String>[];
    }
    return <String>[
      ...profile.recurringIssues.map((String item) => '常见表达/语法问题：$item'),
      ...profile.notes,
    ].take(2).toList(growable: false);
  }

  Set<String> _memoryTokens(String value) {
    const Set<String> stopWords = <String>{
      'the',
      'and',
      'you',
      'your',
      'that',
      'this',
      'with',
      'about',
      'from',
      'have',
      'what',
      'where',
      'when',
      'which',
      'will',
      'would',
      'could',
      'should',
    };
    return RegExp(r"[a-zA-Z']+")
        .allMatches(value.toLowerCase())
        .map((RegExpMatch match) => match.group(0)!)
        .where((String token) => token.length > 3 && !stopWords.contains(token))
        .toSet();
  }
}

String _normalizeTargetLevel(String? raw) {
  final String value = raw?.trim() ?? '';
  return switch (value) {
    'L1' || 'beginner' => 'beginner',
    'L2' || 'intermediate' => 'intermediate',
    'L3' || 'advanced' => 'advanced',
    _ => 'beginner',
  };
}
