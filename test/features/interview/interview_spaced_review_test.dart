import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_llm_scheduler.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Directory tempDir = await Directory.systemTemp.createTemp(
      'speakeasy_wiki_test_',
    );
    await StorageService.instance.init(hivePath: tempDir.path);
  });

  setUp(() async {
    await StorageService.instance.remove('interview_personal_wiki_expressions');
    await StorageService.instance.remove('interview_compiled_wiki');
    await StorageService.instance.remove('interview_user_growth_wiki');
    await StorageService.instance.remove('interview_dismissed_wiki_items');
    await StorageService.instance.remove('interview_useful_wiki_items');
    await StorageService.instance.remove(
      'interview_expression_learning_progress',
    );
  });

  InterviewLibrary library() {
    return const InterviewLibrary(
      expressions: <InterviewExpression>[
        InterviewExpression(
          id: 'intro_1',
          level: 'beginner',
          levelLabel: 'Beginner',
          section: 'Self intro',
          text: 'I have a background in operations.',
          tag: '自我介绍',
          useCase: 'Introduce relevant background.',
        ),
        InterviewExpression(
          id: 'strength_1',
          level: 'beginner',
          levelLabel: 'Beginner',
          section: 'Strength',
          text: 'I am good at breaking down complex problems.',
          tag: '优势说明',
          useCase: 'Talk about strengths.',
        ),
        InterviewExpression(
          id: 'pressure_1',
          level: 'beginner',
          levelLabel: 'Beginner',
          section: 'Pressure',
          text: 'I stayed calm and focused on the next concrete action.',
          tag: '压力回应',
          useCase: 'Answer pressure or pushback questions.',
        ),
      ],
      corrections: <InterviewCorrection>[],
    );
  }

  InterviewPersonalWikiExpression wikiExpression({
    required DateTime now,
    required DateTime nextReviewAt,
    String id = 'intro_1',
    String tag = '自我介绍',
    int reviewCount = 1,
    int intervalDays = 1,
  }) {
    return InterviewPersonalWikiExpression(
      id: id,
      sourceExpressionId: id,
      text: 'I have a background in operations.',
      tag: tag,
      stage: 'self_intro',
      masteredAt: now.subtract(const Duration(days: 1)),
      userExample: 'I have a background in operations.',
      firstMasteredAt: now.subtract(const Duration(days: 1)),
      lastReviewedAt: now.subtract(Duration(days: intervalDays)),
      nextReviewAt: nextReviewAt,
      reviewCount: reviewCount,
      intervalDays: intervalDays,
    );
  }

  test('personal wiki fromJson backfills spaced review fields', () {
    final InterviewPersonalWikiExpression item =
        InterviewPersonalWikiExpression.fromJson(<String, dynamic>{
          'id': 'intro_1',
          'sourceExpressionId': 'intro_1',
          'text': 'I have a background in operations.',
          'tag': '自我介绍',
          'stage': 'self_intro',
          'masteredAt': '2026-04-20T10:00:00.000',
          'userExample': 'I have a background in operations.',
        });

    expect(item.reviewCount, 1);
    expect(item.sourceSceneId, defaultInterviewSceneId);
    expect(item.intervalDays, 1);
    expect(item.firstMasteredAt, item.masteredAt);
    expect(item.lastReviewedAt, item.masteredAt);
    expect(item.nextReviewAt, item.masteredAt.add(const Duration(days: 1)));
  });

  test('mastered review interval reacts to shadow quality', () async {
    const InterviewWikiStore store = InterviewWikiStore(
      sceneId: defaultInterviewSceneId,
    );
    final DateTime now = DateTime(2026, 5, 16, 9);
    final InterviewExpression expression = library().expressions.first;

    Future<InterviewPersonalWikiExpression> completeReview({
      required double performanceScore,
      required double textMatch,
      required int attemptCount,
    }) async {
      await StorageService.instance.remove(
        'interview_personal_wiki_expressions',
      );
      await StorageService.instance.saveList<InterviewPersonalWikiExpression>(
        'interview_personal_wiki_expressions',
        <InterviewPersonalWikiExpression>[
          InterviewPersonalWikiExpression(
            id: expression.id,
            sourceSceneId: defaultInterviewSceneId,
            sourceExpressionId: expression.id,
            sourceNodeId: expression.id,
            text: expression.text,
            tag: expression.tag,
            stage: expression.id,
            masteredAt: now.subtract(const Duration(days: 20)),
            userExample: expression.text,
            firstMasteredAt: now.subtract(const Duration(days: 20)),
            lastReviewedAt: now.subtract(const Duration(days: 7)),
            nextReviewAt: now.subtract(const Duration(hours: 1)),
            reviewCount: 3,
            easeFactor: 2.5,
            intervalDays: 7,
          ),
        ],
        (InterviewPersonalWikiExpression value) => value.toJson(),
      );

      await store.upsertMasteredExpression(
        expression: expression,
        stage: expression.id,
        userExample: expression.text,
        performanceScore: performanceScore,
        textMatch: textMatch,
        attemptCount: attemptCount,
      );
      return store.loadMasteredExpressions().single;
    }

    final InterviewPersonalWikiExpression strongReview = await completeReview(
      performanceScore: 96,
      textMatch: 1,
      attemptCount: 1,
    );
    final InterviewPersonalWikiExpression shakyReview = await completeReview(
      performanceScore: 66,
      textMatch: 0.56,
      attemptCount: 3,
    );

    expect(strongReview.reviewCount, 4);
    expect(shakyReview.reviewCount, 4);
    expect(strongReview.easeFactor, greaterThan(2.5));
    expect(shakyReview.easeFactor, lessThan(2.5));
    expect(strongReview.intervalDays, greaterThan(shakyReview.intervalDays));
  });

  test('compiled wiki parses durable sections', () {
    final InterviewCompiledWiki wiki = InterviewCompiledWiki.fromJson(
      <String, dynamic>{
        'updatedAt': '2026-04-27T08:00:00.000',
        'summary': 'Operations candidate with project experience.',
        'personalFacts': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'fact_ops',
            'title': 'Operations background',
            'body': 'The learner has operations experience.',
            'tag': '自我介绍',
            'evidence': 'experience in operations',
            'updatedAt': '2026-04-27T08:00:00.000',
          },
        ],
        'interviewStories': <Map<String, dynamic>>[],
        'weakPatterns': <Map<String, dynamic>>[],
        'nextTargets': <Map<String, dynamic>>[],
        'compileCount': 2,
      },
    );

    expect(wiki.isEmpty, isFalse);
    expect(wiki.compileCount, 2);
    expect(wiki.personalFacts.single.id, 'fact_ops');
  });

  test('user growth wiki keeps learning state dimensions', () {
    final DateTime now = DateTime(2026, 4, 30, 10);
    final InterviewUserGrowthWiki wiki = InterviewUserGrowthWiki(
      updatedAt: now,
      profileSummary: 'Operations candidate practicing interview answers.',
      masteredExpressions: <InterviewPersonalWikiExpression>[
        wikiExpression(
          now: now,
          nextReviewAt: now.add(const Duration(days: 1)),
        ),
      ],
      weakExpressions: <InterviewWeakExpressionState>[
        InterviewWeakExpressionState(
          sourceSceneId: defaultInterviewSceneId,
          sourceNodeId: 'interview_07',
          sourceExpressionId: 'interview_07',
          targetText: 'One of my key strengths is clear communication.',
          tag: '优势说明',
          reason: '用户只部分复现，需要继续练完整回答。',
          lastUserExample: 'I communicate well.',
          lastHintLevel: 'L3',
          attempts: 2,
          lastSeenAt: now,
        ),
      ],
      errorPatterns: <InterviewUserErrorPattern>[
        InterviewUserErrorPattern(
          id: 'job_interview_expression_strength',
          category: 'expression',
          title: 'I am good in communicate',
          detail: 'preposition and verb form issue',
          correction: 'I am good at communicating.',
          sourceSceneId: defaultInterviewSceneId,
          tag: '优势说明',
          evidence: 'I am good in communicate',
          count: 2,
          firstSeenAt: now.subtract(const Duration(days: 1)),
          lastSeenAt: now,
        ),
      ],
      pronunciationProfile: InterviewPronunciationProfile(
        updatedAt: now,
        sampleCount: 1,
        averageOverall: 75,
        notes: const <String>['流利度偏低，下一轮减少句子长度。'],
      ),
      grammarProfile: InterviewGrammarProfile(
        updatedAt: now,
        issueCount: 2,
        recurringIssues: const <String>['I am good in communicate'],
      ),
      sceneProgress: <InterviewSceneProgressState>[
        InterviewSceneProgressState(
          sourceSceneId: defaultInterviewSceneId,
          masteredCount: 1,
          totalCount: 10,
          weakCount: 1,
          lastNodeId: 'interview_07',
          nextRoundMode: InterviewNextRoundMode.review,
          lastPracticedAt: now,
        ),
      ],
      evidenceRefs: <InterviewLearningEvidenceRef>[
        InterviewLearningEvidenceRef(
          id: 'e1',
          type: 'turn',
          sourceSceneId: defaultInterviewSceneId,
          sourceNodeId: 'interview_07',
          stage: 'interview_07',
          text: 'I communicate well.',
          score: 50,
          createdAt: now,
        ),
      ],
      compileCount: 1,
    );

    final InterviewUserGrowthWiki restored = InterviewUserGrowthWiki.fromJson(
      wiki.toJson(),
    );

    expect(
      restored.masteredExpressions.single.sourceSceneId,
      defaultInterviewSceneId,
    );
    expect(restored.weakExpressions.single.sourceNodeId, 'interview_07');
    expect(restored.errorPatterns.single.count, 2);
    expect(restored.pronunciationProfile?.averageOverall, 75);
    expect(
      restored.grammarProfile?.recurringIssues.single,
      contains('communicate'),
    );
    expect(
      restored.sceneProgress.single.nextRoundMode,
      InterviewNextRoundMode.review,
    );
    expect(restored.evidenceRefs.single.text, 'I communicate well.');
  });

  test(
    'expression learning progress stores prepared without mastery',
    () async {
      const InterviewWikiStore store = InterviewWikiStore(
        sceneId: defaultInterviewSceneId,
      );
      final DateTime now = DateTime(2026, 5, 10, 8);
      final InterviewExpressionLearningProgress progress =
          InterviewExpressionLearningProgress(
            sceneId: defaultInterviewSceneId,
            nodeId: 'L1_01',
            targetLevel: 'beginner',
            status: InterviewExpressionLearningStatus.prepared,
            currentStep: InterviewExpressionLearningStep.recall,
            attempts: 3,
            bestScore: 84,
            lastPracticedAt: now,
            nextReviewAt: now.add(const Duration(days: 1)),
            lastTranscript: 'Thank you for having me.',
          );

      await store.saveExpressionLearningProgress(progress);

      final InterviewExpressionLearningProgress? restored = store
          .loadExpressionLearningProgressFor(
            nodeId: 'L1_01',
            targetLevel: 'beginner',
          );
      expect(restored?.status, InterviewExpressionLearningStatus.prepared);
      expect(restored?.isPrepared, isTrue);
      expect(restored?.bestScore, 84);
      expect(store.loadMasteredExpressions(), isEmpty);
    },
  );

  test('expression learning material parses speaking tasks', () {
    final InterviewExpressionNode node = InterviewExpressionNode.fromJson(
      <String, dynamic>{
        'id': 'L1_01',
        'targetLevel': 'beginner',
        'targetText': 'Thank you for having me.',
        'learningMaterial': <String, dynamic>{
          'intentCn': '表达感谢',
          'scenePrompt': 'Could you introduce yourself?',
          'targetExpression': 'Thank you for having me.',
          'nativeNotes': 'Keep it calm.',
          'chunks': <String>['Thank you', 'for having me'],
          'speakingTasks': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'listen',
              'title': '听一句',
              'prompt': '先听自然说法。',
              'targetText': 'Thank you for having me.',
            },
            <String, dynamic>{
              'type': 'shadow',
              'title': '跟说一次',
              'prompt': '跟读一遍。',
              'targetText': 'Thank you for having me.',
            },
          ],
        },
      },
    );

    final InterviewExpressionLearningMaterial material =
        node.resolvedLearningMaterial;
    expect(material.intentCn, '表达感谢');
    expect(material.chunks, contains('Thank you'));
    expect(material.taskFor('shadow').title, '跟说一次');
  });

  test('expression learning material falls back for legacy nodes', () {
    final InterviewExpressionNode node = InterviewExpressionNode.fromJson(
      <String, dynamic>{
        'id': 'L1_02',
        'targetLevel': 'beginner',
        'targetText': 'I am currently working as a designer.',
        'meaning': '说明当前岗位。',
        'question': 'What do you currently do?',
        'slots': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'role', 'example': 'product manager'},
        ],
      },
    );

    final InterviewExpressionLearningMaterial material =
        node.resolvedLearningMaterial;
    expect(material.intentCn, '说明当前岗位。');
    expect(material.taskFor('listen').targetText, node.targetText);
    expect(material.taskFor('slot_replace').slotName, 'role');
  });

  test('prepared requires listen and shadow warmup steps', () {
    const InterviewExpressionLearningProgress listenOnly =
        InterviewExpressionLearningProgress(
          sceneId: defaultInterviewSceneId,
          nodeId: 'L1_01',
          targetLevel: 'beginner',
          currentStep: InterviewExpressionLearningStep.shadow,
          completedWarmupSteps: <String>['listen'],
        );

    final InterviewExpressionLearningProgress shadowDone = listenOnly
        .withCompletedWarmupStep('shadow')
        .copyWith(
          status: InterviewExpressionLearningStatus.prepared,
          currentStep: InterviewExpressionLearningStep.recall,
        );

    expect(listenOnly.hasCompletedWarmupStep('listen'), isTrue);
    expect(listenOnly.hasMinimumWarmup, isFalse);
    expect(shadowDone.hasMinimumWarmup, isTrue);
    expect(shadowDone.isPrepared, isTrue);
  });

  test('mastered simulation links prepared expression progress', () async {
    const InterviewWikiStore store = InterviewWikiStore(
      sceneId: defaultInterviewSceneId,
    );
    await store.saveExpressionLearningProgress(
      const InterviewExpressionLearningProgress(
        sceneId: defaultInterviewSceneId,
        nodeId: 'L1_01',
        targetLevel: 'beginner',
        status: InterviewExpressionLearningStatus.prepared,
        currentStep: InterviewExpressionLearningStep.recall,
      ),
    );

    await store.markExpressionLearningMasteredLinked(
      nodeId: 'L1_01',
      targetLevel: 'beginner',
    );

    final InterviewExpressionLearningProgress? restored = store
        .loadExpressionLearningProgressFor(
          nodeId: 'L1_01',
          targetLevel: 'beginner',
        );
    expect(restored?.status, InterviewExpressionLearningStatus.masteredLinked);
    expect(restored?.isMasteredLinked, isTrue);
  });

  test(
    'wiki action plan prioritizes due review before weak and facts',
    () async {
      final DateTime now = DateTime(2026, 5, 2, 10);
      final InterviewWikiStore store = const InterviewWikiStore();
      final InterviewExpression expression = library().expressions.first;
      await store.upsertMasteredExpression(
        expression: expression,
        stage: 'intro_1',
        userExample: 'I have a background in operations.',
      );
      final List<InterviewPersonalWikiExpression> current = store
          .loadMasteredExpressions();
      await StorageService.instance.saveList<InterviewPersonalWikiExpression>(
        'interview_personal_wiki_expressions',
        <InterviewPersonalWikiExpression>[
          InterviewPersonalWikiExpression(
            id: current.single.id,
            sourceSceneId: defaultInterviewSceneId,
            sourceExpressionId: current.single.sourceExpressionId,
            sourceNodeId: current.single.sourceNodeId,
            text: current.single.text,
            tag: current.single.tag,
            stage: current.single.stage,
            masteredAt: now.subtract(const Duration(days: 8)),
            userExample: current.single.userExample,
            firstMasteredAt: now.subtract(const Duration(days: 8)),
            lastReviewedAt: now.subtract(const Duration(days: 8)),
            nextReviewAt: now.subtract(const Duration(days: 1)),
            reviewCount: 2,
            easeFactor: 2.5,
            intervalDays: 3,
          ),
        ],
        (InterviewPersonalWikiExpression value) => value.toJson(),
      );
      await store.saveUserGrowthWiki(
        InterviewUserGrowthWiki(
          updatedAt: now,
          personalFacts: <InterviewCompiledWikiItem>[
            InterviewCompiledWikiItem(
              id: 'fact_ops',
              title: 'Operations background',
              body: 'The learner has operations experience.',
              tag: '自我介绍',
              evidence: 'operations',
              updatedAt: now,
            ),
          ],
          weakExpressions: <InterviewWeakExpressionState>[
            InterviewWeakExpressionState(
              sourceSceneId: defaultInterviewSceneId,
              sourceNodeId: 'strength_1',
              sourceExpressionId: 'strength_1',
              targetText: 'I am good at breaking down complex problems.',
              tag: '优势说明',
              reason: '用户只部分复现，需要继续练完整回答。',
              lastUserExample: 'I solve problems.',
              lastHintLevel: 'L3',
              attempts: 2,
              lastSeenAt: now,
            ),
          ],
        ),
      );

      final InterviewWikiActionPlan plan = store.buildActionPlan(
        session: null,
        now: now,
      );

      expect(plan.primaryAction?.type, 'review');
      expect(plan.reviewQueue.single.priority, greaterThan(100));
      expect(plan.weaknessQueue.single.type, 'weak_expression');
      expect(plan.personalMaterialHints.single.type, 'personal_fact');
    },
  );

  test('structured memory pack keeps legacy prompt lists', () async {
    final DateTime now = DateTime(2026, 5, 2, 10);
    final InterviewWikiStore store = const InterviewWikiStore();
    await StorageService.instance.saveList<InterviewPersonalWikiExpression>(
      'interview_personal_wiki_expressions',
      <InterviewPersonalWikiExpression>[
        wikiExpression(
          now: now,
          nextReviewAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      (InterviewPersonalWikiExpression value) => value.toJson(),
    );
    await store.saveCompiledWiki(
      InterviewCompiledWiki(
        updatedAt: now,
        summary: 'Operations candidate.',
        nextTargets: <InterviewCompiledWikiItem>[
          InterviewCompiledWikiItem(
            id: 'target_1',
            title: 'Use a concrete result',
            body: 'Add one measurable outcome.',
            tag: '经历阐述',
            evidence: 'review',
            updatedAt: now,
          ),
        ],
      ),
    );

    final InterviewWikiMemoryPack pack = store.buildMemoryPack(
      tags: const <String>['自我介绍'],
      now: now,
    );

    expect(pack.primaryAction?.type, 'review');
    expect(pack.promptContext, isNotEmpty);
    expect(pack.dueExpressions.single, contains('background in operations'));
    expect(pack.nextTargets.single, contains('Use a concrete result'));
  });

  test('scene catalog exposes default public wiki asset', () async {
    final InterviewSceneCatalog catalog = await loadInterviewSceneCatalog();

    expect(catalog.defaultSceneId, defaultInterviewSceneId);
    expect(
      catalog.entryById(defaultInterviewSceneId)?.assetPath,
      contains('job_interview.json'),
    );
  });

  test('scene wiki asset loads v2 level tracks', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph(
      sceneId: defaultInterviewSceneId,
    );

    expect(graph.schemaVersion, 2);
    expect(graph.nodes, hasLength(39));
    expect(graph.tracks, hasLength(3));
    expect(graph.flowNodeIds.first, 'L1_01');
    expect(graph.flowNodeIds.last, 'L1_13');
    expect(graph.flowNodeIdsForLevel('intermediate').first, 'L2_01');
    expect(graph.flowNodeIdsForLevel('advanced').last, 'L3_13');
    expect(graph.toLibrary().expressions, hasLength(39));
    expect(graph.nodeById('L1_06')?.tag, '优势说明');
    expect(graph.nodeById('L1_01')?.nearMissVariants, isNotEmpty);
    expect(graph.nodeById('L2_01')?.targetLevel, 'intermediate');
    expect(graph.nodeById('L1_06')?.hintTree.l4, contains('complex ideas'));
    expect(graph.nodeById('L1_01')?.coachRubric.mustCover, isNotEmpty);
    expect(graph.nodeById('L1_01')?.coachMoves.retryInstruction, isNotEmpty);
    expect(graph.nodeById('L1_01')?.speechFocus.tone, contains('Confident'));
    expect(
      graph.nodeById('L1_01')?.toExpression().coachContext,
      contains('rubric must cover'),
    );
  });

  test('onboarding introduction scene wiki loads level tracks', () async {
    final InterviewSceneCatalog catalog = await loadInterviewSceneCatalog();

    expect(catalog.entryById('onboarding_introduction')?.titleCn, '入职介绍');

    final InterviewSceneGraph graph = await loadInterviewSceneGraph(
      sceneId: 'onboarding_introduction',
    );

    expect(graph.schemaVersion, 2);
    expect(graph.id, 'onboarding_introduction');
    expect(graph.titleCn, '入职介绍');
    expect(graph.nodes, hasLength(39));
    expect(graph.tracks, hasLength(3));
    expect(graph.flowNodeIds.first, 'ONB_L1_1');
    expect(graph.flowNodeIds.last, 'ONB_L1_13');
    expect(graph.flowNodeIdsForLevel('intermediate').first, 'ONB_L2_1');
    expect(graph.flowNodeIdsForLevel('advanced').last, 'ONB_L3_13');
    expect(graph.nodeById('ONB_L1_7')?.targetText, contains('focus on first'));
    expect(
      graph.nodeById('ONB_L1_1')?.expectedVariants.first.text,
      graph.nodeById('ONB_L1_1')?.targetText,
    );
    expect(
      graph.nodeById('ONB_L1_1')?.coachMoves.ifStuck,
      contains('hint ladder'),
    );
    expect(
      graph.nodeById('ONB_L1_1')?.toExpression().coachContext,
      contains('Warm'),
    );
    expect(graph.toLibrary().expressions, hasLength(39));
  });

  test('scene wiki target nodes include offline practice variants', () async {
    final InterviewSceneCatalog catalog = await loadInterviewSceneCatalog();

    for (final InterviewSceneCatalogEntry entry in catalog.scenes) {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph(
        sceneId: entry.id,
      );

      for (final InterviewExpressionNode node in graph.nodes) {
        expect(
          node.practiceVariants,
          hasLength(greaterThanOrEqualTo(2)),
          reason: '${entry.id}/${node.id} should have learnable variants',
        );
        expect(
          node.practiceVariants.any(
            (InterviewPracticeVariant variant) =>
                variant.text.trim().toLowerCase() ==
                node.targetText.trim().toLowerCase(),
          ),
          isFalse,
          reason: '${entry.id}/${node.id} should not repeat the target text',
        );
        expect(
          node.practiceVariants.every(
            (InterviewPracticeVariant variant) =>
                variant.id.trim().isNotEmpty &&
                variant.meaning.trim().isNotEmpty &&
                variant.priority > 0,
          ),
          isTrue,
          reason: '${entry.id}/${node.id} variants need stable asset metadata',
        );
      }
    }
  });

  test('scene wiki has learning-useful recommended expression card copy', () async {
    final InterviewSceneCatalog catalog = await loadInterviewSceneCatalog();
    final RegExp genericCuePattern = RegExp(
      r'How would you respond at the start|tell me what you currently do',
      caseSensitive: false,
    );

    for (final InterviewSceneCatalogEntry entry in catalog.scenes) {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph(
        sceneId: entry.id,
      );

      for (final InterviewExpressionNode node in graph.nodes) {
        final InterviewExpressionLearningMaterial material =
            node.resolvedLearningMaterial;
        expect(
          material.intentCn,
          contains('：'),
          reason:
              '${entry.id}/${node.id} should teach scene intent, not only a literal translation',
        );
        expect(
          material.scenePrompt,
          isNot(matches(genericCuePattern)),
          reason:
              '${entry.id}/${node.id} should provide a realistic cue for response cards',
        );
        expect(
          material.commonMistakes.first,
          startsWith('常见误句：'),
          reason:
              '${entry.id}/${node.id} repair cards should show the learner-facing wrong sentence',
        );
        expect(material.taskFor('listen').prompt, material.intentCn);
        expect(material.taskFor('scene_transfer').prompt, material.scenePrompt);
        for (final InterviewPracticeVariant variant in node.practiceVariants) {
          expect(
            variant.meaning,
            material.intentCn,
            reason:
                '${entry.id}/${node.id}/${variant.id} should show the same learning intent on variant cards',
          );
        }
      }
    }
  });

  test('scene wiki graph is immutable at runtime', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewExpressionNode firstNode = graph.nodes.first;

    expect(() => graph.nodes[0] = firstNode, throwsA(isA<UnsupportedError>()));
    expect(
      () => firstNode.nextIds[0] = 'tampered_node',
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => firstNode.expectedVariants.clear(),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => firstNode.practiceVariants.clear(),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('scene graph session starts from first wiki node', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );

    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      masteredWikiExpressions: const <InterviewPersonalWikiExpression>[],
    );
    final InterviewQuestionPlan plan = engine.openingQuestionPlanForSession(
      session: session,
      masteredWikiExpressions: const <InterviewPersonalWikiExpression>[],
    );

    expect(session.currentStage, 'L1_01');
    expect(session.publicSceneId, defaultInterviewSceneId);
    expect(session.stageExpressionTargets['L1_01']?.id, 'L1_01');
    expect(plan.stage, 'L1_01');
    expect(plan.targetExpression?.id, 'L1_01');
    expect(plan.localFallbackQuestion, contains('Welcome'));
    expect(
      plan.localFallbackQuestion,
      isNot(contains('How would you respond')),
    );
  });

  test('scene graph session starts from selected difficulty level', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );

    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      targetLevel: 'advanced',
    );
    final InterviewQuestionPlan plan = engine.openingQuestionPlanForSession(
      session: session,
      masteredWikiExpressions: const <InterviewPersonalWikiExpression>[],
    );

    expect(session.targetLevel, 'advanced');
    expect(session.currentStage, 'L3_01');
    expect(
      session.plannedStages.where((String stage) => stage != 'wrap_up'),
      everyElement(startsWith('L3_')),
    );
    expect(plan.targetExpression?.id, 'L3_01');
  });

  test('scene graph expected variant counts as mastered', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );
    final InterviewPracticeSession session = engine.startSession(userId: 'u1');

    final InterviewCoachReply reply = engine.answer(
      session,
      userText: "Thanks for having me. I'm really glad to be here.",
    );

    expect(
      reply.masteredExpressions.map((InterviewExpression item) => item.id),
      contains('L1_01'),
    );
    expect(session.masteredExpressionIds, contains('L1_01'));
    expect(session.currentStage, 'L1_02');
  });

  test(
    'scene graph mastery judge accepts intent plus core structure',
    () async {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph();
      final InterviewPracticeEngine engine = InterviewPracticeEngine(
        library: graph.toLibrary(),
        sceneGraph: graph,
      );
      final InterviewExpression target = graph
          .nodeById('L1_01')!
          .toExpression();

      final InterviewExpressionMasteryResult result = engine
          .evaluateExpressionMastery(
            expression: target,
            userText: "Thank you for inviting me. I'm happy to be here.",
            question: graph.nodeById('L1_01')!.question,
          );

      expect(result.status, InterviewExpressionMasteryStatus.mastered);
    },
  );

  test(
    'scene graph mastery judge marks incomplete openings as near miss',
    () async {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph();
      final InterviewPracticeEngine engine = InterviewPracticeEngine(
        library: graph.toLibrary(),
        sceneGraph: graph,
      );
      final InterviewExpression target = graph
          .nodeById('L1_01')!
          .toExpression();

      final InterviewExpressionMasteryResult result = engine
          .evaluateExpressionMastery(
            expression: target,
            userText: 'Thanks, I am Alex.',
            question: graph.nodeById('L1_01')!.question,
          );

      expect(result.status, InterviewExpressionMasteryStatus.nearMiss);
    },
  );

  test(
    'scene graph near miss pauses for coach retry before advancing',
    () async {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph();
      final InterviewPracticeEngine engine = InterviewPracticeEngine(
        library: graph.toLibrary(),
        sceneGraph: graph,
      );
      final InterviewPracticeSession session = engine.startSession(
        userId: 'u1',
      );

      final InterviewCoachReply reply = engine.answer(
        session,
        userText: 'Thanks, I am Alex.',
      );

      expect(
        reply.masteredExpressions.map((InterviewExpression item) => item.id),
        isNot(contains('L1_01')),
      );
      expect(session.masteredExpressionIds, isNot(contains('L1_01')));
      expect(session.pendingReuseTarget, isNull);
      expect(session.delayedReuseTarget, isNull);
      expect(session.currentStage, 'L1_01');
      expect(reply.nextAction, 'coach_retry');
      expect(reply.assistantMessage, contains('方向是对的'));
      expect(reply.assistantMessage, contains("I'm excited to be here today"));
      expect(
        reply.assistantMessage,
        isNot(
          contains("Thank you for having me. I'm excited to be here today."),
        ),
      );

      final InterviewCoachReply scaffoldReply = engine.answer(
        session,
        userText: 'Thanks, I am Alex.',
      );

      expect(scaffoldReply.nextAction, 'coach_retry');
      expect(scaffoldReply.assistantMessage, contains('支架'));

      final InterviewCoachReply modelReply = engine.answer(
        session,
        userText: 'Thanks, I am Alex.',
      );

      expect(modelReply.nextAction, 'coach_retry');
      expect(
        modelReply.assistantMessage,
        contains("Thank you for having me. I'm excited to be here today."),
      );

      final InterviewCoachReply masteredReply = engine.answer(
        session,
        userText: "Thank you for having me. I'm excited to be here today.",
      );

      expect(masteredReply.nextAction, 'next_question');
      expect(session.currentStage, 'L1_02');
    },
  );

  test(
    'scene graph mastery judge rejects unrelated candidate questions',
    () async {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph();
      final InterviewPracticeEngine engine = InterviewPracticeEngine(
        library: graph.toLibrary(),
        sceneGraph: graph,
      );
      final InterviewExpression target = graph
          .nodeById('L1_01')!
          .toExpression();

      final InterviewExpressionMasteryResult result = engine
          .evaluateExpressionMastery(
            expression: target,
            userText: 'What are the next steps?',
            question: graph.nodeById('L1_01')!.question,
          );

      expect(result.status, InterviewExpressionMasteryStatus.missed);
    },
  );

  test(
    'scene graph accepts question-shaped learner target expressions',
    () async {
      final InterviewSceneGraph graph = await loadInterviewSceneGraph(
        sceneId: 'onboarding_introduction',
      );
      final InterviewPracticeEngine engine = InterviewPracticeEngine(
        library: graph.toLibrary(),
        sceneGraph: graph,
      );
      final InterviewExpressionNode targetNode = graph.nodeById('ONB_L1_8')!;
      final InterviewExpression target = targetNode.toExpression();

      final InterviewExpressionMasteryResult result = engine
          .evaluateExpressionMastery(
            expression: target,
            userText: targetNode.targetText,
            question: graph.nodeById('ONB_L1_7')!.question,
          );

      expect(result.status, InterviewExpressionMasteryStatus.mastered);
      expect(result.reason, contains('matched target expression'));
    },
  );

  test('expression mastery judge tolerates minor grammar errors', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );
    const InterviewExpression target = InterviewExpression(
      id: 'custom_based_in',
      level: 'beginner',
      levelLabel: 'test',
      section: 'self intro',
      text: "I'm [Name], and I'm based in [City].",
      tag: '自我介绍',
      useCase: 'say name and location',
    );

    final InterviewExpressionMasteryResult result = engine
        .evaluateExpressionMastery(
          expression: target,
          userText: "I'm am based in Shanghai.",
          question: 'Where are you based?',
        );

    expect(result.status, InterviewExpressionMasteryStatus.mastered);
  });

  test('scene graph hints progress through L1 to L4', () async {
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );
    final InterviewPracticeSession session = engine.startSession(userId: 'u1');

    final InterviewHint l1 = engine.requestHint(
      session,
      question: graph.nodeById('L1_01')!.question,
    );
    final InterviewHint l2 = engine.requestHint(session);
    final InterviewHint l3 = engine.requestHint(session);
    final InterviewHint l4 = engine.requestHint(session);

    expect(l1.level, 'L1');
    expect(l2.level, 'L2');
    expect(l3.level, 'L3');
    expect(l4.level, 'L4');
    expect(l4.text, contains('Thank you for having me'));
  });

  test('scene graph review mode starts from due node', () async {
    final DateTime now = DateTime.now();
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );
    final InterviewPersonalWikiExpression dueStrength =
        InterviewPersonalWikiExpression(
          id: 'L1_06',
          sourceExpressionId: 'L1_06',
          sourceNodeId: 'L1_06',
          text: "I'm good at explaining difficult things in a simple way.",
          tag: '优势说明',
          stage: 'L1_06',
          masteredAt: now.subtract(const Duration(days: 4)),
          userExample:
              "I'm good at explaining difficult things in a simple way.",
          firstMasteredAt: now.subtract(const Duration(days: 4)),
          lastReviewedAt: now.subtract(const Duration(days: 3)),
          nextReviewAt: now.subtract(const Duration(hours: 1)),
          reviewCount: 2,
          intervalDays: 3,
        );

    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      roundMode: InterviewNextRoundMode.review,
      masteredWikiExpressions: <InterviewPersonalWikiExpression>[dueStrength],
    );

    expect(session.currentStage, 'L1_06');
    expect(session.stageExpressionTargets['L1_06']?.id, 'L1_06');
  });

  test('scene graph new lesson starts from unresolved weak node', () async {
    final DateTime now = DateTime.now();
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );

    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      weakExpressions: <InterviewWeakExpressionState>[
        InterviewWeakExpressionState(
          sourceSceneId: defaultInterviewSceneId,
          sourceNodeId: 'L1_06',
          sourceExpressionId: 'L1_06',
          targetText:
              "One of my strengths is explaining complex ideas in a simple way.",
          tag: '优势说明',
          reason: '用户卡住，尚未自然复现目标表达。',
          lastUserExample: '',
          lastHintLevel: 'L4',
          attempts: 4,
          lastSeenAt: now.subtract(const Duration(minutes: 30)),
        ),
      ],
    );

    expect(session.currentStage, 'L1_06');
    expect(session.stageExpressionTargets['L1_06']?.id, 'L1_06');
  });

  test('scene graph skips weak node resolved by expression practice', () async {
    final DateTime now = DateTime.now();
    final InterviewSceneGraph graph = await loadInterviewSceneGraph();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: graph.toLibrary(),
      sceneGraph: graph,
    );

    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      preparedLearningProgress: <InterviewExpressionLearningProgress>[
        InterviewExpressionLearningProgress(
          sceneId: defaultInterviewSceneId,
          nodeId: 'L1_06',
          targetLevel: 'beginner',
          status: InterviewExpressionLearningStatus.prepared,
          currentStep: InterviewExpressionLearningStep.recall,
          attempts: 1,
          bestScore: 86,
          lastPracticedAt: now,
          completedWarmupSteps: const <String>['listen', 'shadow'],
        ),
      ],
      weakExpressions: <InterviewWeakExpressionState>[
        InterviewWeakExpressionState(
          sourceSceneId: defaultInterviewSceneId,
          sourceNodeId: 'L1_06',
          sourceExpressionId: 'L1_06',
          targetText:
              "One of my strengths is explaining complex ideas in a simple way.",
          tag: '优势说明',
          reason: '用户只部分复现，需要继续练完整回答。',
          lastUserExample: 'I explain things.',
          lastHintLevel: 'L3',
          attempts: 2,
          lastSeenAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
    );

    expect(session.currentStage, isNot('L1_06'));
  });

  test(
    'scene graph ignores mastered expressions from another public scene',
    () async {
      final DateTime now = DateTime.now();
      final InterviewSceneGraph graph = await loadInterviewSceneGraph();
      final InterviewPracticeEngine engine = InterviewPracticeEngine(
        library: graph.toLibrary(),
        sceneGraph: graph,
      );
      final InterviewPersonalWikiExpression otherSceneDue =
          InterviewPersonalWikiExpression(
            id: 'other_scene_L1_06',
            sourceSceneId: 'other_scene',
            sourceExpressionId: 'L1_06',
            sourceNodeId: 'L1_06',
            text: "I'm good at explaining difficult things in a simple way.",
            tag: '优势说明',
            stage: 'L1_06',
            masteredAt: now.subtract(const Duration(days: 4)),
            userExample:
                "I'm good at explaining difficult things in a simple way.",
            firstMasteredAt: now.subtract(const Duration(days: 4)),
            lastReviewedAt: now.subtract(const Duration(days: 3)),
            nextReviewAt: now.subtract(const Duration(hours: 1)),
            reviewCount: 2,
            intervalDays: 3,
          );

      final InterviewPracticeSession session = engine.startSession(
        userId: 'u1',
        roundMode: InterviewNextRoundMode.review,
        masteredWikiExpressions: <InterviewPersonalWikiExpression>[
          otherSceneDue,
        ],
      );

      expect(session.currentStage, 'L1_01');
    },
  );

  test('fresh mastered expression stays in new expression expansion', () {
    final DateTime now = DateTime.now();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: library(),
    );

    final InterviewNextRoundMode mode = engine.roundModeForMasteredExpressions(
      <InterviewPersonalWikiExpression>[
        wikiExpression(
          now: now,
          nextReviewAt: now.add(const Duration(days: 1)),
        ),
      ],
    );

    expect(mode, InterviewNextRoundMode.newLesson);
  });

  test('due mastered expression triggers spaced review', () {
    final DateTime now = DateTime.now();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: library(),
    );

    final InterviewNextRoundMode mode = engine
        .roundModeForMasteredExpressions(<InterviewPersonalWikiExpression>[
          wikiExpression(
            now: now,
            nextReviewAt: now.subtract(const Duration(hours: 1)),
            reviewCount: 2,
            intervalDays: 3,
          ),
        ]);

    expect(mode, InterviewNextRoundMode.review);
  });

  test('opening question plan cold-starts new learners', () {
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: library(),
    );
    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      masteredWikiExpressions: const <InterviewPersonalWikiExpression>[],
    );

    final InterviewQuestionPlan plan = engine.openingQuestionPlanForSession(
      session: session,
      masteredWikiExpressions: const <InterviewPersonalWikiExpression>[],
    );

    expect(plan.action, 'cold_start_opening');
    expect(plan.stage, 'open');
    expect(plan.mustAskAbout, isNotEmpty);
    expect(plan.localFallbackQuestion, isNotEmpty);
  });

  test('opening question plan prioritizes due review', () {
    final DateTime now = DateTime.now();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: library(),
    );
    final List<InterviewPersonalWikiExpression> wiki =
        <InterviewPersonalWikiExpression>[
          wikiExpression(
            now: now,
            nextReviewAt: now.subtract(const Duration(hours: 1)),
            reviewCount: 2,
            intervalDays: 3,
          ),
        ];
    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      roundMode: InterviewNextRoundMode.review,
      masteredWikiExpressions: wiki,
    );

    final InterviewQuestionPlan plan = engine.openingQuestionPlanForSession(
      session: session,
      masteredWikiExpressions: wiki,
    );

    expect(plan.action, 'warm_start_due_review');
    expect(plan.targetExpressionText, isNotEmpty);
  });

  test('followup question plan keeps strategy explicit', () {
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: library(),
    );
    final InterviewPracticeSession session = engine.startSession(userId: 'u1');
    final InterviewExpression target = library().expressions.first;
    final InterviewCoachReply reply = InterviewCoachReply(
      predictedTag: '自我介绍',
      secondaryTags: const <String>[],
      coverageStatus: 'covered',
      hintState: 'none',
      nextAction: 'next_question',
      assistantMessage: 'What was your main responsibility in that role?',
      confidence: 0.9,
      correctionHits: const <InterviewCorrectionHit>[],
      coverageCredit: 1,
      stage: 'background',
      alignmentExpression: target,
    );

    final InterviewQuestionPlan plan = engine.followupQuestionPlanForReply(
      session: session,
      localReply: reply,
      userText: 'I work in operations.',
      expressions: <InterviewExpression>[target],
      reuseTarget: target,
    );

    expect(plan.action, 'reuse_aligned_expression');
    expect(plan.stage, 'background');
    expect(plan.targetExpressionText, target.text);
  });

  test('reproduced mastered pending target is cleared in review mode', () {
    final DateTime now = DateTime.now();
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: library(),
    );
    final List<InterviewPersonalWikiExpression> wiki =
        <InterviewPersonalWikiExpression>[
          wikiExpression(
            now: now,
            nextReviewAt: now.subtract(const Duration(hours: 1)),
            reviewCount: 2,
            intervalDays: 3,
          ),
        ];
    final InterviewPracticeSession session = engine.startSession(
      userId: 'u1',
      roundMode: InterviewNextRoundMode.review,
      masteredWikiExpressions: wiki,
    );
    final InterviewExpression pending = library().expressions.first;
    session.pendingReuseTarget = pending;

    final InterviewCoachReply reply = engine.answer(
      session,
      userText: 'I have a background in operations.',
    );

    expect(session.pendingReuseTarget, isNull);
    expect(
      reply.masteredExpressions.map((InterviewExpression item) => item.id),
      contains('intro_1'),
    );
  });

  test('stale pending target does not override next stage target', () {
    final InterviewPracticeEngine engine = InterviewPracticeEngine(
      library: library(),
    );
    final InterviewExpression intro = library().expressions[0];
    final InterviewExpression pressure = library().expressions[2];
    final InterviewPracticeSession session = InterviewPracticeSession(
      sessionId: 'local_plan',
      userId: 'u1',
      jobFamily: 'general',
      mode: 'full_mock',
      userTier: 'newbie',
      targetLevel: 'beginner',
      plannedStages: const <String>['pressure', 'wrap_up'],
      roundMode: InterviewNextRoundMode.review,
    );
    session.pendingReuseTarget = intro;
    session.stageExpressionTargets['pressure'] = pressure;
    final InterviewCoachReply reply = InterviewCoachReply(
      predictedTag: '自我介绍',
      secondaryTags: const <String>[],
      coverageStatus: 'covered',
      hintState: 'none',
      nextAction: 'next_question',
      assistantMessage:
          'Tell me about a time you were under pressure. How did you handle it?',
      confidence: 0.9,
      correctionHits: const <InterviewCorrectionHit>[],
      coverageCredit: 1,
      stage: 'pressure',
    );

    final InterviewQuestionPlan plan = engine.followupQuestionPlanForReply(
      session: session,
      localReply: reply,
      userText: 'Hi, I am Alex.',
      expressions: <InterviewExpression>[pressure],
    );

    expect(plan.targetExpression?.id, 'pressure_1');
    expect(plan.predictedTag, '压力回应');
  });

  test('question scheduler rejects generic direct-answer prompts', () {
    final InterviewLlmScheduler scheduler = InterviewLlmScheduler();
    final InterviewQuestionPlan plan = InterviewQuestionPlan(
      action: 'expand_new_expression',
      stage: 'L1_06',
      questionIntent:
          'open a context where the learner can describe a strength',
      mustAskAbout: 'one key strength',
      localFallbackQuestion: 'What would you say is one of your key strengths?',
      practiceFocus: 'new expression expansion',
      predictedTag: '优势说明',
      targetExpression: library().expressions[1],
    );

    expect(
      scheduler.questionFitsPlanForTesting(
        'Give me your direct answer first.',
        plan,
      ),
      isFalse,
    );
  });

  test('question scheduler accepts same-node question rewrites', () {
    final InterviewLlmScheduler scheduler = InterviewLlmScheduler();
    final InterviewQuestionPlan plan = InterviewQuestionPlan(
      action: 'expand_new_expression',
      stage: 'L1_06',
      questionIntent:
          'open a context where the learner can describe a strength',
      mustAskAbout: 'one key strength',
      localFallbackQuestion: 'What would you say is one of your key strengths?',
      practiceFocus: 'new expression expansion',
      predictedTag: '优势说明',
      targetExpression: library().expressions[1],
    );

    expect(
      scheduler.questionFitsPlanForTesting(
        'Could you tell me about one key strength you bring to the team?',
        plan,
      ),
      isTrue,
    );
  });

  test(
    'contextual hint accepts useful reply despite expression metadata drift',
    () {
      final InterviewLlmScheduler scheduler = InterviewLlmScheduler();
      final InterviewExpression target = library().expressions[2];

      final String? hint = scheduler.validateHintReplyForTesting(
        '''
{
  "expression_id": "changed_by_llm",
  "expression_text": "I kept calm and focused on the next step.",
  "suggested_reply": "I stayed calm and focused on the next concrete action when priorities changed."
}
''',
        question:
            'Tell me about a time you were under pressure. How did you handle it?',
        targetExpression: target,
      );

      expect(hint, isNotNull);
      expect(hint, contains('可以用：${target.text}'));
      expect(
        hint,
        contains(
          'I stayed calm and focused on the next concrete action when priorities changed.',
        ),
      );
    },
  );

  test('contextual hint still rejects placeholder replies', () {
    final InterviewLlmScheduler scheduler = InterviewLlmScheduler();
    final InterviewExpression target = library().expressions[2];

    final String? hint = scheduler.validateHintReplyForTesting(
      '''
{
  "suggested_reply": "I stayed calm and focused on [real weakness + action]."
}
''',
      question:
          'Tell me about a time you were under pressure. How did you handle it?',
      targetExpression: target,
    );

    expect(hint, isNull);
  });

  test('contextual hint rejects interviewer prompts as suggested replies', () {
    final InterviewLlmScheduler scheduler = InterviewLlmScheduler();
    final InterviewExpression target = library().expressions[1];

    final String? hint = scheduler.validateHintReplyForTesting(
      '''
{
  "suggested_reply": "Give me your direct answer first."
}
''',
      question:
          'What would you say is one of your biggest strengths, and how has it helped you at work?',
      targetExpression: target,
    );

    expect(hint, isNull);
  });

  test('answer diagnosis decoder accepts targeted coach JSON', () {
    final InterviewLlmScheduler scheduler = InterviewLlmScheduler();

    final InterviewAnswerDiagnosis? diagnosis = scheduler
        .decodeAnswerDiagnosisForTesting('''
{
  "issue_type": "missing_intent",
  "did_well": "你回应了问题方向。",
  "main_issue": "还缺少具体成果。",
  "micro_fix": "补上 achieved + result。",
  "retry_mode": "add_one_phrase",
  "coach_message": "方向对了。\\n这次只补一个结果：achieved + result。\\n再说一遍。",
  "suggested_reply": "",
  "confidence": 0.82
}
''');

    expect(diagnosis, isNotNull);
    expect(diagnosis!.issueType, 'missing_intent');
    expect(diagnosis.coachMessage, contains('achieved + result'));
    expect(diagnosis.retryMode, 'add_one_phrase');
  });

  test('active session snapshot restores unfinished progress', () {
    final InterviewPracticeSession session = InterviewPracticeSession(
      sessionId: 'local_test',
      userId: 'u1',
      jobFamily: 'general',
      mode: 'full_mock',
      userTier: 'newbie',
      targetLevel: 'beginner',
      plannedStages: const <String>['open', 'background', 'wrap_up'],
      roundMode: InterviewNextRoundMode.newLesson,
    );
    final InterviewExpression target = library().expressions.first;
    session.stageIndex = 1;
    session.stageAttempts['open'] = 1;
    session.stageBestCoverage['open'] = 0.75;
    session.stagePrimaryTags['open'] = '自我介绍';
    session.stageExpressionTargets['background'] = target;
    session.pendingReuseTarget = target;
    session.masteredExpressionIds.add('strength_1');
    session.turns.add(
      InterviewTurnRecord(
        stage: 'open',
        question: 'Could you introduce yourself briefly?',
        userText: 'I have a background in operations.',
        predictedTags: const <String>['自我介绍'],
        correctionHitIds: const <String>[],
        coverageStatus: 'covered',
        coverageCredit: 0.75,
        confidence: 0.8,
        createdAt: DateTime(2026, 4, 27, 9),
      ),
    );
    final InterviewActiveSessionSnapshot snapshot =
        InterviewActiveSessionSnapshot(
          session: session,
          messages: <InterviewChatMessage>[
            InterviewChatMessage(
              role: 'assistant',
              text: 'Could you introduce yourself briefly?',
              createdAt: DateTime(2026, 4, 27, 9),
              stage: 'open',
              tag: '自我介绍',
              targetExpression: target,
              questionPlanAction: 'introduce_new_expression',
              mustAskAbout: 'the learner background and current role',
            ),
          ],
          updatedAt: DateTime(2026, 4, 27, 9, 1),
        );

    final InterviewActiveSessionSnapshot restored =
        InterviewActiveSessionSnapshot.fromJson(snapshot.toJson());

    expect(restored.session.currentStage, 'background');
    expect(restored.session.turns.single.userText, contains('operations'));
    expect(
      restored.session.stageExpressionTargets['background']?.id,
      'intro_1',
    );
    expect(restored.session.pendingReuseTarget?.id, 'intro_1');
    expect(restored.session.masteredExpressionIds, contains('strength_1'));
    expect(restored.messages.single.text, contains('introduce yourself'));
    expect(restored.messages.single.targetExpression?.id, 'intro_1');
    expect(
      restored.messages.single.questionPlanAction,
      'introduce_new_expression',
    );
    expect(restored.messages.single.mustAskAbout, contains('background'));
  });
}
