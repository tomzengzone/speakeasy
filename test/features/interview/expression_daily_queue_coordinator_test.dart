import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speakeasy/features/interview/expression_daily_queue_coordinator.dart';
import 'package:speakeasy/features/interview/interview_engine.dart';
import 'package:speakeasy/features/interview/interview_expression_learning_page.dart';
import 'package:speakeasy/features/interview/interview_models.dart';
import 'package:speakeasy/features/interview/interview_wiki_store.dart';
import 'package:speakeasy/services/app_session.dart';
import 'package:speakeasy/services/audio_service.dart';
import 'package:speakeasy/services/storage_service.dart';

class _QueuePlaybackAudioService extends AudioService {
  final List<String> playedTexts = <String>[];
  int stopCount = 0;
  final List<Completer<bool>> _playCompleters = <Completer<bool>>[];

  @override
  Future<bool> playCachedTts(
    String text, {
    String? voice,
    String? sceneId,
    String? targetLevel,
    String? nodeId,
  }) {
    playedTexts.add(text);
    final Completer<bool> completer = Completer<bool>();
    _playCompleters.add(completer);
    return completer.future;
  }

  @override
  Future<void> stopPlayback({bool clearRealtimeBuffer = true}) async {
    stopCount += 1;
    for (final Completer<bool> completer in _playCompleters) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    hiveDir = await Directory.systemTemp.createTemp(
      'speakeasy_expression_queue_test_',
    );
    await StorageService.instance.init(hivePath: hiveDir.path);
  });

  setUp(() async {
    await StorageService.instance.remove('interview_personal_wiki_expressions');
    await StorageService.instance.remove('interview_user_growth_wiki');
    await StorageService.instance.remove(
      'interview_expression_learning_progress',
    );
    await StorageService.instance.clearFavoriteExpressions();
  });

  tearDownAll(() async {
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  const ExpressionDailyQueueCoordinator coordinator =
      ExpressionDailyQueueCoordinator();

  const ExpressionDailyQueueScene jobScene = ExpressionDailyQueueScene(
    sceneId: defaultInterviewSceneId,
    targetLevel: 'beginner',
    title: '英语面试',
    order: 0,
  );

  const ExpressionDailyQueueScene variantScene = ExpressionDailyQueueScene(
    sceneId: 'practice_variant_scene',
    targetLevel: 'beginner',
    title: '变体场景',
    order: 0,
  );

  InterviewSceneGraph practiceVariantGraph() {
    return InterviewSceneGraph.fromJson(<String, dynamic>{
      'schemaVersion': 1,
      'meta': <String, dynamic>{
        'id': variantScene.sceneId,
        'titleCn': variantScene.title,
        'titleEn': 'Practice Variant Scene',
      },
      'flow': <String>['PV_01'],
      'nodes': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'PV_01',
          'targetLevel': 'beginner',
          'slot': 1,
          'targetText':
              "Thank you for having me. I'm excited to be here today.",
          'meaning': '感谢您邀请我来。我很高兴今天能来到这里。',
          'stageLabel': '开场感谢',
          'expectedVariants': <Map<String, dynamic>>[
            <String, dynamic>{
              'text': 'Thanks for the opportunity.',
              'kind': 'role_variant',
            },
          ],
          'practiceVariants': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'copy',
              'text': "Thank you for having me. I'm excited to be here today.",
              'meaning': '主句不应该作为变体练习。',
              'type': 'same',
              'priority': 0,
            },
            <String, dynamic>{
              'id': 'formal',
              'text': 'I appreciate the opportunity to speak with you today.',
              'meaning': '我很感谢今天有机会和您交流。',
              'type': 'formal',
              'priority': 1,
            },
            <String, dynamic>{
              'id': 'warm',
              'text': 'Thanks for taking the time to speak with me today.',
              'meaning': '谢谢您抽时间和我交流。',
              'type': 'warm',
              'priority': 2,
            },
          ],
        },
      ],
    });
  }

  InterviewPersonalWikiExpression masteredExpression({
    required DateTime now,
    required String sceneId,
    required String nodeId,
    required DateTime nextReviewAt,
  }) {
    return InterviewPersonalWikiExpression(
      id: '${sceneId}_$nodeId',
      sourceSceneId: sceneId,
      sourceExpressionId: nodeId,
      sourceNodeId: nodeId,
      text: "I'm good at explaining difficult things in a simple way.",
      tag: '优势说明',
      stage: nodeId,
      masteredAt: now.subtract(const Duration(days: 5)),
      userExample: "I'm good at explaining difficult things in a simple way.",
      firstMasteredAt: now.subtract(const Duration(days: 5)),
      lastReviewedAt: now.subtract(const Duration(days: 3)),
      nextReviewAt: nextReviewAt,
      reviewCount: 2,
      intervalDays: 3,
    );
  }

  test(
    'daily queue does not recommend anything without joined scenes',
    () async {
      final List<ExpressionDailyQueueItem> queue = await coordinator.buildQueue(
        scenes: const <ExpressionDailyQueueScene>[],
      );

      expect(queue, isEmpty);
    },
  );

  test('daily queue only uses explicitly joined scenes', () async {
    final DateTime now = DateTime(2026, 5, 16, 9);
    await StorageService.instance.saveList<InterviewPersonalWikiExpression>(
      'interview_personal_wiki_expressions',
      <InterviewPersonalWikiExpression>[
        masteredExpression(
          now: now,
          sceneId: 'onboarding_introduction',
          nodeId: 'ONB_L1_1',
          nextReviewAt: now.subtract(const Duration(hours: 1)),
        ),
      ],
      (InterviewPersonalWikiExpression value) => value.toJson(),
    );

    final List<ExpressionDailyQueueItem> queue = await coordinator.buildQueue(
      scenes: const <ExpressionDailyQueueScene>[jobScene],
      now: now,
    );

    expect(queue, isNotEmpty);
    expect(
      queue.every(
        (ExpressionDailyQueueItem item) =>
            item.sceneId == defaultInterviewSceneId,
      ),
      isTrue,
    );
    expect(
      queue.any(
        (ExpressionDailyQueueItem item) =>
            item.sceneId == 'onboarding_introduction',
      ),
      isFalse,
    );
  });

  test('daily queue prioritizes review before weak and variants', () async {
    final DateTime now = DateTime(2026, 5, 16, 9);
    await StorageService.instance.saveList<InterviewPersonalWikiExpression>(
      'interview_personal_wiki_expressions',
      <InterviewPersonalWikiExpression>[
        masteredExpression(
          now: now,
          sceneId: defaultInterviewSceneId,
          nodeId: 'L1_06',
          nextReviewAt: now.subtract(const Duration(hours: 2)),
        ),
      ],
      (InterviewPersonalWikiExpression value) => value.toJson(),
    );
    await const InterviewWikiStore(
      sceneId: defaultInterviewSceneId,
    ).saveUserGrowthWiki(
      InterviewUserGrowthWiki(
        updatedAt: now,
        weakExpressions: <InterviewWeakExpressionState>[
          InterviewWeakExpressionState(
            sourceSceneId: defaultInterviewSceneId,
            sourceNodeId: 'L1_01',
            sourceExpressionId: 'L1_01',
            targetText:
                "Thank you for having me. I'm excited to be here today.",
            tag: '自我介绍',
            reason: '开场感谢还不稳定',
            lastUserExample: 'Thanks.',
            lastHintLevel: 'L2',
            attempts: 2,
            lastSeenAt: now.subtract(const Duration(minutes: 20)),
          ),
        ],
      ),
    );

    final List<ExpressionDailyQueueItem> queue = await coordinator.buildQueue(
      scenes: const <ExpressionDailyQueueScene>[jobScene],
      now: now,
    );

    expect(queue[0].kind, ExpressionDailyQueueItem.kindReview);
    expect(queue[0].nodeId, 'L1_06');
    expect(queue[1].kind, ExpressionDailyQueueItem.kindWeak);
    expect(queue[1].nodeId, 'L1_01');
    expect(queue[2].kind, ExpressionDailyQueueItem.kindVariant);
    expect(
      queue[0].practiceMode,
      isIn(const <String>[
        ExpressionDailyQueueItem.practiceModeMeaningChoice,
        ExpressionDailyQueueItem.practiceModeIntentRecall,
        ExpressionDailyQueueItem.practiceModeChunkRecall,
        ExpressionDailyQueueItem.practiceModeFluencySprint,
      ]),
    );
    expect(
      queue[1].practiceMode,
      isIn(const <String>[
        ExpressionDailyQueueItem.practiceModeRepairChoice,
        ExpressionDailyQueueItem.practiceModeMistakeRepair,
        ExpressionDailyQueueItem.practiceModeClozeRecall,
      ]),
    );
    expect(
      queue[2].practiceMode,
      isIn(const <String>[
        ExpressionDailyQueueItem.practiceModeCueChoice,
        ExpressionDailyQueueItem.practiceModeCueResponse,
        ExpressionDailyQueueItem.practiceModeVariantParaphrase,
      ]),
    );
    expect(
      queue.any(
        (ExpressionDailyQueueItem item) =>
            item.kind == ExpressionDailyQueueItem.kindNew ||
            item.kind == ExpressionDailyQueueItem.kindProgress,
      ),
      isFalse,
    );
  });

  test('daily queue ranks weak expressions by learning evidence', () async {
    final DateTime now = DateTime(2026, 5, 16, 9);
    await const InterviewWikiStore(
      sceneId: defaultInterviewSceneId,
    ).saveUserGrowthWiki(
      InterviewUserGrowthWiki(
        updatedAt: now,
        weakExpressions: <InterviewWeakExpressionState>[
          InterviewWeakExpressionState(
            sourceSceneId: defaultInterviewSceneId,
            sourceNodeId: 'L1_01',
            sourceExpressionId: 'L1_01',
            targetText:
                "Thank you for having me. I'm excited to be here today.",
            tag: '自我介绍',
            reason: '本轮尚未确认掌握。',
            lastUserExample: 'Thanks.',
            lastHintLevel: 'L1',
            attempts: 1,
            lastSeenAt: now,
          ),
          InterviewWeakExpressionState(
            sourceSceneId: defaultInterviewSceneId,
            sourceNodeId: 'L1_02',
            sourceExpressionId: 'L1_02',
            targetText:
                'I currently work as a product manager on internal tools.',
            tag: '当前岗位',
            reason: '用户卡住，尚未自然复现目标表达。',
            lastUserExample: '',
            lastHintLevel: 'L4',
            attempts: 5,
            lastSeenAt: now.subtract(const Duration(days: 2)),
          ),
        ],
      ),
    );
    await StorageService.instance.saveList<InterviewExpressionLearningProgress>(
      'interview_expression_learning_progress',
      <InterviewExpressionLearningProgress>[
        InterviewExpressionLearningProgress(
          sceneId: defaultInterviewSceneId,
          nodeId: 'L1_02',
          targetLevel: 'beginner',
          status: InterviewExpressionLearningStatus.learning,
          currentStep: InterviewExpressionLearningStep.shadow,
          attempts: 3,
          bestScore: 52,
          lastPracticedAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      (InterviewExpressionLearningProgress value) => value.toJson(),
    );

    final List<ExpressionDailyQueueItem> queue = await coordinator.buildQueue(
      scenes: const <ExpressionDailyQueueScene>[jobScene],
      now: now,
    );
    final List<ExpressionDailyQueueItem> weakItems = queue
        .where(
          (ExpressionDailyQueueItem item) =>
              item.kind == ExpressionDailyQueueItem.kindWeak,
        )
        .toList(growable: false);

    expect(weakItems, hasLength(2));
    expect(weakItems.first.nodeId, 'L1_02');
  });

  test(
    'daily queue removes weak expression after successful practice',
    () async {
      final DateTime now = DateTime(2026, 5, 16, 9);
      await const InterviewWikiStore(
        sceneId: defaultInterviewSceneId,
      ).saveUserGrowthWiki(
        InterviewUserGrowthWiki(
          updatedAt: now,
          weakExpressions: <InterviewWeakExpressionState>[
            InterviewWeakExpressionState(
              sourceSceneId: defaultInterviewSceneId,
              sourceNodeId: 'L1_01',
              sourceExpressionId: 'L1_01',
              targetText:
                  "Thank you for having me. I'm excited to be here today.",
              tag: '自我介绍',
              reason: '用户只部分复现，需要继续练完整回答。',
              lastUserExample: 'Thanks.',
              lastHintLevel: 'L3',
              attempts: 2,
              lastSeenAt: now.subtract(const Duration(hours: 1)),
            ),
          ],
        ),
      );
      await StorageService.instance
          .saveList<InterviewExpressionLearningProgress>(
            'interview_expression_learning_progress',
            <InterviewExpressionLearningProgress>[
              InterviewExpressionLearningProgress(
                sceneId: defaultInterviewSceneId,
                nodeId: 'L1_01',
                targetLevel: 'beginner',
                status: InterviewExpressionLearningStatus.prepared,
                currentStep: InterviewExpressionLearningStep.recall,
                attempts: 1,
                bestScore: 60,
                lastPassed: true,
                lastPracticedAt: now,
                completedWarmupSteps: const <String>['listen', 'shadow'],
              ),
            ],
            (InterviewExpressionLearningProgress value) => value.toJson(),
          );

      final List<ExpressionDailyQueueItem> queue = await coordinator.buildQueue(
        scenes: const <ExpressionDailyQueueScene>[jobScene],
        now: now,
      );

      expect(
        queue.any(
          (ExpressionDailyQueueItem item) =>
              item.kind == ExpressionDailyQueueItem.kindWeak &&
              item.nodeId == 'L1_01',
        ),
        isFalse,
      );
    },
  );

  test('daily queue is not capped by daily goal minutes', () async {
    final ExpressionDailyQueueCoordinator customCoordinator =
        ExpressionDailyQueueCoordinator(
          graphLoader: ({String sceneId = ''}) async => practiceVariantGraph(),
        );
    final List<ExpressionDailyQueueScene> scenes = <ExpressionDailyQueueScene>[
      for (int index = 0; index < 10; index += 1)
        ExpressionDailyQueueScene(
          sceneId: 'variant_scene_$index',
          targetLevel: 'beginner',
          title: '变体场景 $index',
          order: index,
        ),
    ];

    final List<ExpressionDailyQueueItem> queue = await customCoordinator
        .buildQueue(scenes: scenes);

    expect(queue, hasLength(10));
    expect(
      queue.every(
        (ExpressionDailyQueueItem item) =>
            item.kind == ExpressionDailyQueueItem.kindVariant,
      ),
      isTrue,
    );
  });

  test(
    'daily queue prefers offline practice variants over expected variants',
    () async {
      final ExpressionDailyQueueCoordinator customCoordinator =
          ExpressionDailyQueueCoordinator(
            graphLoader: ({String sceneId = ''}) async =>
                practiceVariantGraph(),
          );

      final List<ExpressionDailyQueueItem> queue = await customCoordinator
          .buildQueue(scenes: const <ExpressionDailyQueueScene>[variantScene]);

      final ExpressionDailyQueueItem variant = queue.firstWhere(
        (ExpressionDailyQueueItem item) =>
            item.kind == ExpressionDailyQueueItem.kindVariant,
      );

      expect(
        variant.practiceText,
        'I appreciate the opportunity to speak with you today.',
      );
      expect(variant.translation, '我很感谢今天有机会和您交流。');
      expect(variant.nodeId, 'PV_01#variant_formal');
      expect(variant.variantOfNodeId, 'PV_01');
      expect(
        queue.any(
          (ExpressionDailyQueueItem item) =>
              item.practiceText == 'Thanks for the opportunity.',
        ),
        isFalse,
      );
    },
  );

  test(
    'daily queue returns variants for every selected scene without new items',
    () async {
      final ExpressionDailyQueueCoordinator customCoordinator =
          ExpressionDailyQueueCoordinator(
            graphLoader: ({String sceneId = ''}) async =>
                practiceVariantGraph(),
          );
      final List<ExpressionDailyQueueScene> scenes =
          <ExpressionDailyQueueScene>[
            for (int index = 0; index < 3; index += 1)
              ExpressionDailyQueueScene(
                sceneId: 'variant_scene_$index',
                targetLevel: 'beginner',
                title: '变体场景 $index',
                order: index,
              ),
          ];

      final List<ExpressionDailyQueueItem> queue = await customCoordinator
          .buildQueue(scenes: scenes);

      expect(queue, hasLength(3));
      expect(
        queue.where(
          (ExpressionDailyQueueItem item) =>
              item.kind == ExpressionDailyQueueItem.kindVariant,
        ),
        hasLength(3),
      );
      expect(
        queue.where(
          (ExpressionDailyQueueItem item) =>
              item.kind == ExpressionDailyQueueItem.kindNew,
        ),
        isEmpty,
      );
    },
  );

  test(
    'daily queue advances to the next unfinished practice variant',
    () async {
      await StorageService.instance
          .saveList<InterviewExpressionLearningProgress>(
            'interview_expression_learning_progress',
            <InterviewExpressionLearningProgress>[
              InterviewExpressionLearningProgress(
                sceneId: variantScene.sceneId,
                nodeId: 'PV_01#variant_formal',
                targetLevel: variantScene.targetLevel,
                status: InterviewExpressionLearningStatus.prepared,
                currentStep: InterviewExpressionLearningStep.recall,
                completedWarmupSteps: const <String>['listen', 'shadow'],
              ),
            ],
            (InterviewExpressionLearningProgress value) => value.toJson(),
          );
      final ExpressionDailyQueueCoordinator customCoordinator =
          ExpressionDailyQueueCoordinator(
            graphLoader: ({String sceneId = ''}) async =>
                practiceVariantGraph(),
          );

      final List<ExpressionDailyQueueItem> queue = await customCoordinator
          .buildQueue(scenes: const <ExpressionDailyQueueScene>[variantScene]);

      final ExpressionDailyQueueItem variant = queue.firstWhere(
        (ExpressionDailyQueueItem item) =>
            item.kind == ExpressionDailyQueueItem.kindVariant,
      );

      expect(
        variant.practiceText,
        'Thanks for taking the time to speak with me today.',
      );
      expect(variant.translation, '谢谢您抽时间和我交流。');
      expect(variant.nodeId, 'PV_01#variant_warm');
    },
  );

  test(
    'scene wiki assets include dedicated expression context analysis',
    () async {
      for (final String sceneId in const <String>[
        defaultInterviewSceneId,
        'onboarding_introduction',
      ]) {
        final InterviewSceneGraph graph = await loadInterviewSceneGraph(
          sceneId: sceneId,
        );
        expect(graph.nodes, isNotEmpty);
        final Map<String, int> focusCounts = <String, int>{};
        for (final InterviewExpressionNode node in graph.nodes) {
          expect(
            node.expressionContextAnalysis['when'],
            isNotEmpty,
            reason: '${graph.id}:${node.id} is missing context when',
          );
          expect(
            node.expressionContextAnalysis['purpose'],
            isNotEmpty,
            reason: '${graph.id}:${node.id} is missing context purpose',
          );
          expect(
            node.expressionContextAnalysis['practiceFocus'],
            isNotEmpty,
            reason: '${graph.id}:${node.id} is missing context practiceFocus',
          );
          for (final InterviewPracticeVariant variant
              in node.practiceVariants) {
            expect(
              variant.contextAnalysis['when'],
              isNotEmpty,
              reason:
                  '${graph.id}:${node.id}:${variant.id} missing variant when',
            );
            expect(
              variant.contextAnalysis['difference'],
              isNotEmpty,
              reason:
                  '${graph.id}:${node.id}:${variant.id} missing variant difference',
            );
            expect(
              variant.contextAnalysis['practiceFocus'],
              isNotEmpty,
              reason:
                  '${graph.id}:${node.id}:${variant.id} missing variant focus',
            );
            final String focus = variant.contextAnalysis['practiceFocus']!;
            focusCounts[focus] = (focusCounts[focus] ?? 0) + 1;
          }
        }
        final int maxDuplicateFocus = focusCounts.values.fold<int>(0, math.max);
        expect(
          maxDuplicateFocus,
          lessThanOrEqualTo(2),
          reason:
              '$sceneId variant practiceFocus should be expression-specific',
        );
      }
    },
  );

  test('expression progress persists shadow score detail fields', () {
    final InterviewExpressionLearningProgress progress =
        InterviewExpressionLearningProgress.fromJson(
          InterviewExpressionLearningProgress(
            sceneId: defaultInterviewSceneId,
            nodeId: 'L1_01',
            targetLevel: 'beginner',
            attempts: 4,
            bestScore: 91,
            lastTranscript:
                "Thank you for having me. I'm excited to be here today.",
            lastScore: 82,
            lastTextMatch: 0.74,
            lastPronunciationScore: 88,
            lastPassed: true,
            lastScoredAt: DateTime(2026, 5, 18, 20, 30),
            bestTranscript:
                "Thank you for having me. I'm excited to be here today.",
            bestTextMatch: 0.95,
            bestPronunciationScore: 92,
            bestScoredAt: DateTime(2026, 5, 18, 19, 45),
          ).toJson(),
        );

    expect(progress.lastScore, 82);
    expect(progress.lastTextMatch, 0.74);
    expect(progress.lastPronunciationScore, 88);
    expect(progress.lastPassed, isTrue);
    expect(progress.lastScoredAt, DateTime(2026, 5, 18, 20, 30));
    expect(progress.bestTranscript, contains('Thank you for having me'));
    expect(progress.bestTextMatch, 0.95);
    expect(progress.bestPronunciationScore, 92);
    expect(progress.bestScoredAt, DateTime(2026, 5, 18, 19, 45));
  });

  testWidgets(
    'daily expression deck shows target, translation, play and shadow',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioServiceScope(
            service: AudioService(),
            child: AppSessionScope(
              session: AppSession(),
              child: const Scaffold(
                body: InterviewExpressionWarmupDeckView(
                  sceneId: defaultInterviewSceneId,
                  targetLevel: 'beginner',
                  queueItems: <ExpressionDailyQueueItem>[
                    ExpressionDailyQueueItem(
                      sceneId: defaultInterviewSceneId,
                      targetLevel: 'beginner',
                      nodeId: 'L1_01',
                      kind: ExpressionDailyQueueItem.kindNew,
                      practiceText:
                          "Thank you for having me. I'm excited to be here today.",
                      translation: '感谢您邀请我来。我很高兴今天能来到这里。',
                      sourceLabel: '英语面试 · 开场感谢',
                      priorityDueAt: null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .byKey(const ValueKey<String>('daily_expression_card'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      expect(
        find.byKey(const ValueKey<String>('daily_expression_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('daily_expression_card_background')),
        findsOneWidget,
      );
      final Size cardSize = tester.getSize(
        find.byKey(const ValueKey<String>('daily_expression_card_background')),
      );
      expect(cardSize.height, greaterThan(480));
      expect(cardSize.height, lessThan(560));
      expect(
        find.byKey(const ValueKey<String>('daily_expression_plan_bar')),
        findsNothing,
      );
      expect(find.text('今日计划'), findsNothing);
      expect(find.text('1/1'), findsNothing);
      expect(find.textContaining('Thank you for having me'), findsOneWidget);
      expect(find.textContaining('感谢您邀请我来'), findsOneWidget);
      final Text targetText = tester.widget<Text>(
        find.textContaining('Thank you for having me'),
      );
      final Text translationText = tester.widget<Text>(
        find.textContaining('感谢您邀请我来'),
      );
      final Text sourceText = tester.widget<Text>(find.text('英语面试 · 开场感谢'));
      expect(targetText.overflow, TextOverflow.visible);
      expect(translationText.overflow, TextOverflow.ellipsis);
      expect(sourceText.overflow, TextOverflow.ellipsis);
      expect(find.text('语境'), findsNothing);
      expect(find.textContaining('练习提示'), findsNothing);
      expect(find.textContaining('用于面试开场'), findsNothing);
      expect(find.textContaining('积极语气放轻'), findsNothing);
      expect(find.text('本次'), findsOneWidget);
      expect(find.text('最佳'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('daily_expression_play_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('daily_expression_shadow_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('daily_expression_swipe_hint')),
        findsOneWidget,
      );
      expect(find.text('上滑下一条'), findsNothing);
      expect(
        tester
                .getTopLeft(
                  find.byKey(
                    const ValueKey<String>('daily_expression_swipe_hint'),
                  ),
                )
                .dy >
            tester
                .getBottomLeft(
                  find.byKey(
                    const ValueKey<String>('daily_expression_card_background'),
                  ),
                )
                .dy,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey<String>('daily_expression_favorite_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets('daily expression card renders the V1 voice practice modes', (
    WidgetTester tester,
  ) async {
    final List<(String, String, String)> scenarios = <(String, String, String)>[
      (ExpressionDailyQueueItem.practiceModeShadow, '跟读', '跟读'),
      (ExpressionDailyQueueItem.practiceModeMeaningChoice, '选自然表达', '点选答案'),
      (ExpressionDailyQueueItem.practiceModeCueChoice, '选择回应', '点选答案'),
      (ExpressionDailyQueueItem.practiceModeRepairChoice, '选正确版', '点选答案'),
      (ExpressionDailyQueueItem.practiceModeEchoRecall, '听后复述', '开始复述'),
      (ExpressionDailyQueueItem.practiceModeClozeRecall, '表达填空', '说完整句'),
      (ExpressionDailyQueueItem.practiceModeIntentRecall, '意图回忆', '说英文'),
      (ExpressionDailyQueueItem.practiceModeCueResponse, '接下句', '接一句'),
      (ExpressionDailyQueueItem.practiceModeChunkRecall, '短语背诵', '背出来'),
      (ExpressionDailyQueueItem.practiceModeSlotPersonalize, '替换槽位', '替换后说'),
      (ExpressionDailyQueueItem.practiceModeMistakeRepair, '纠错复现', '说正确版'),
      (ExpressionDailyQueueItem.practiceModeVariantParaphrase, '变体改写', '说变体'),
      (ExpressionDailyQueueItem.practiceModeFluencySprint, '流利挑战', '开始挑战'),
    ];

    for (final (String mode, String modeLabel, String primaryLabel)
        in scenarios) {
      await tester.pumpWidget(
        MaterialApp(
          home: AudioServiceScope(
            service: AudioService(),
            child: AppSessionScope(
              session: AppSession(),
              child: Scaffold(
                body: InterviewExpressionWarmupDeckView(
                  sceneId: defaultInterviewSceneId,
                  targetLevel: 'beginner',
                  queueItems: <ExpressionDailyQueueItem>[
                    ExpressionDailyQueueItem(
                      sceneId: defaultInterviewSceneId,
                      targetLevel: 'beginner',
                      nodeId: 'L1_01',
                      kind: ExpressionDailyQueueItem.kindNew,
                      practiceText:
                          "Thank you for having me. I'm excited to be here today.",
                      translation: '感谢您邀请我来。我很高兴今天能来到这里。',
                      sourceLabel: '英语面试 · 开场感谢',
                      priorityDueAt: null,
                      practiceMode: mode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .byKey(const ValueKey<String>('daily_expression_card'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      expect(
        find.byKey(const ValueKey<String>('daily_expression_card')),
        findsOneWidget,
      );
      expect(find.text(modeLabel), findsWidgets);
      expect(find.text(primaryLabel), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('daily_expression_target_text')),
        findsOneWidget,
      );
      if (mode == ExpressionDailyQueueItem.practiceModeClozeRecall) {
        expect(find.textContaining('______'), findsOneWidget);
      }
      if (<String>{
        ExpressionDailyQueueItem.practiceModeMeaningChoice,
        ExpressionDailyQueueItem.practiceModeCueChoice,
        ExpressionDailyQueueItem.practiceModeRepairChoice,
      }.contains(mode)) {
        expect(
          find.byKey(const ValueKey<String>('daily_expression_shadow_button')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey<String>('daily_expression_choice_correct')),
          findsOneWidget,
        );
      }
      if (mode != ExpressionDailyQueueItem.practiceModeShadow &&
          mode != ExpressionDailyQueueItem.practiceModeSlotPersonalize &&
          mode != ExpressionDailyQueueItem.practiceModeFluencySprint &&
          mode != ExpressionDailyQueueItem.practiceModeMeaningChoice &&
          mode != ExpressionDailyQueueItem.practiceModeCueChoice &&
          mode != ExpressionDailyQueueItem.practiceModeRepairChoice) {
        expect(
          find.byKey(const ValueKey<String>('daily_expression_answer_button')),
          findsOneWidget,
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('daily expression card swipes up as a continuous stream', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AudioServiceScope(
          service: AudioService(),
          child: AppSessionScope(
            session: AppSession(),
            child: const Scaffold(
              body: InterviewExpressionWarmupDeckView(
                sceneId: defaultInterviewSceneId,
                targetLevel: 'beginner',
                queueItems: <ExpressionDailyQueueItem>[
                  ExpressionDailyQueueItem(
                    sceneId: defaultInterviewSceneId,
                    targetLevel: 'beginner',
                    nodeId: 'L1_01',
                    kind: ExpressionDailyQueueItem.kindNew,
                    practiceText:
                        "Thank you for having me. I'm excited to be here today.",
                    translation: '感谢您邀请我来。我很高兴今天能来到这里。',
                    sourceLabel: '英语面试 · 开场感谢',
                    priorityDueAt: null,
                  ),
                  ExpressionDailyQueueItem(
                    sceneId: defaultInterviewSceneId,
                    targetLevel: 'beginner',
                    nodeId: 'L1_02#variant_natural',
                    kind: ExpressionDailyQueueItem.kindVariant,
                    practiceText:
                        "Right now, I'm a designer at a growing company.",
                    translation: '我目前在一家小公司做设计师。',
                    sourceLabel: '英语面试 · 当前职位',
                    priorityDueAt: null,
                    variantOfNodeId: 'L1_02',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('daily_expression_card'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Thank you for having me'), findsOneWidget);

    await tester.timedDrag(
      find.byKey(const ValueKey<String>('daily_expression_card')),
      const Offset(0, -520),
      const Duration(milliseconds: 120),
    );
    await tester.pump(const Duration(milliseconds: 720));

    expect(find.textContaining('Thank you for having me'), findsNothing);
    expect(find.textContaining('Right now, I'), findsOneWidget);
    expect(find.textContaining('和主句用在同一位置'), findsNothing);
    expect(find.textContaining('这个变体更短、更直接'), findsNothing);
    expect(find.textContaining('Right / now / designer'), findsNothing);
    expect(find.textContaining('当前角色和工作范围'), findsNothing);
    expect(find.text('英语面试 · 当前职位'), findsOneWidget);
    expect(find.text('2/2'), findsNothing);

    await tester.timedDrag(
      find.byKey(const ValueKey<String>('daily_expression_card')),
      const Offset(0, -520),
      const Duration(milliseconds: 120),
    );
    await tester.pump(const Duration(milliseconds: 720));

    expect(find.textContaining('Right now, I'), findsNothing);
    expect(find.textContaining('Thank you for having me'), findsOneWidget);
  });

  testWidgets(
    'daily expression autoplay continues after swipe and stops old card',
    (WidgetTester tester) async {
      final _QueuePlaybackAudioService audioService =
          _QueuePlaybackAudioService();
      await tester.pumpWidget(
        MaterialApp(
          home: AudioServiceScope(
            service: audioService,
            child: AppSessionScope(
              session: AppSession(),
              child: const Scaffold(
                body: InterviewExpressionWarmupDeckView(
                  sceneId: defaultInterviewSceneId,
                  targetLevel: 'beginner',
                  queueItems: <ExpressionDailyQueueItem>[
                    ExpressionDailyQueueItem(
                      sceneId: defaultInterviewSceneId,
                      targetLevel: 'beginner',
                      nodeId: 'L1_01',
                      kind: ExpressionDailyQueueItem.kindNew,
                      practiceText:
                          "Thank you for having me. I'm excited to be here today.",
                      translation: '感谢您邀请我来。我很高兴今天能来到这里。',
                      sourceLabel: '英语面试 · 开场感谢',
                      priorityDueAt: null,
                    ),
                    ExpressionDailyQueueItem(
                      sceneId: defaultInterviewSceneId,
                      targetLevel: 'beginner',
                      nodeId: 'L1_02#variant_natural',
                      kind: ExpressionDailyQueueItem.kindVariant,
                      practiceText:
                          "Right now, I'm a designer at a growing company.",
                      translation: '我目前在一家小公司做设计师。',
                      sourceLabel: '英语面试 · 当前职位',
                      priorityDueAt: null,
                      variantOfNodeId: 'L1_02',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      for (int i = 0; i < 20; i += 1) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find
            .byKey(const ValueKey<String>('daily_expression_card'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }

      await tester.tap(
        find.byKey(const ValueKey<String>('daily_expression_play_button')),
      );
      await tester.pump();

      expect(audioService.playedTexts, hasLength(1));
      expect(
        audioService.playedTexts.single,
        contains('Thank you for having me'),
      );
      expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);

      await tester.timedDrag(
        find.byKey(const ValueKey<String>('daily_expression_card')),
        const Offset(0, -520),
        const Duration(milliseconds: 120),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 360));

      expect(audioService.stopCount, greaterThanOrEqualTo(1));
      expect(audioService.playedTexts, hasLength(2));
      expect(audioService.playedTexts.last, contains('Right now, I'));
      expect(find.textContaining('Right now, I'), findsOneWidget);
    },
  );

  testWidgets('daily expression card swipes down to refresh priority', (
    WidgetTester tester,
  ) async {
    List<ExpressionDailyQueueItem>
    queueItems = const <ExpressionDailyQueueItem>[
      ExpressionDailyQueueItem(
        sceneId: defaultInterviewSceneId,
        targetLevel: 'beginner',
        nodeId: 'L1_01',
        kind: ExpressionDailyQueueItem.kindVariant,
        practiceText: "Thank you for having me. I'm excited to be here today.",
        translation: '感谢您邀请我来。我很高兴今天能来到这里。',
        sourceLabel: '英语面试 · 开场感谢',
        priorityDueAt: null,
      ),
      ExpressionDailyQueueItem(
        sceneId: defaultInterviewSceneId,
        targetLevel: 'beginner',
        nodeId: 'L1_06',
        kind: ExpressionDailyQueueItem.kindReview,
        practiceText:
            'One of my strengths is explaining complex ideas in a simple way.',
        translation: '我擅长用简单的方式解释难懂的事情。',
        sourceLabel: '英语面试 · 优势说明',
        priorityDueAt: null,
      ),
    ];
    int refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AudioServiceScope(
          service: AudioService(),
          child: AppSessionScope(
            session: AppSession(),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setHarnessState) {
                return Scaffold(
                  body: InterviewExpressionWarmupDeckView(
                    sceneId: defaultInterviewSceneId,
                    targetLevel: 'beginner',
                    queueItems: queueItems,
                    onRefreshQueue: () async {
                      refreshCount += 1;
                      setHarnessState(() {
                        queueItems = <ExpressionDailyQueueItem>[
                          queueItems[1],
                          queueItems[0],
                        ];
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('daily_expression_card'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.textContaining('Thank you for having me'), findsOneWidget);

    final double initialCardTop = tester
        .getTopLeft(
          find.byKey(
            const ValueKey<String>('daily_expression_card_background'),
          ),
        )
        .dy;
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey<String>('daily_expression_card')),
      ),
    );
    await gesture.moveBy(const Offset(0, 160));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('daily_expression_refresh_indicator')),
      findsOneWidget,
    );
    expect(refreshCount, 0);
    expect(
      tester
              .getTopLeft(
                find.byKey(
                  const ValueKey<String>('daily_expression_card_background'),
                ),
              )
              .dy >
          initialCardTop + 24,
      isTrue,
    );

    await gesture.up();
    for (int i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.textContaining('One of my strengths').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(refreshCount, 1);
    expect(find.textContaining('Thank you for having me'), findsNothing);
    expect(find.textContaining('One of my strengths'), findsOneWidget);
  });

  testWidgets('daily expression choice card handles wrong and correct taps', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AudioServiceScope(
          service: AudioService(),
          child: AppSessionScope(
            session: AppSession(),
            child: Scaffold(
              body: InterviewExpressionWarmupDeckView(
                sceneId: defaultInterviewSceneId,
                targetLevel: 'beginner',
                queueItems: <ExpressionDailyQueueItem>[
                  ExpressionDailyQueueItem(
                    sceneId: defaultInterviewSceneId,
                    targetLevel: 'beginner',
                    nodeId: 'L1_01',
                    kind: ExpressionDailyQueueItem.kindNew,
                    practiceText:
                        "Thank you for having me. I'm excited to be here today.",
                    translation: '感谢您邀请我来。我很高兴今天能来到这里。',
                    sourceLabel: '英语面试 · 开场感谢',
                    priorityDueAt: null,
                    practiceMode:
                        ExpressionDailyQueueItem.practiceModeMeaningChoice,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    for (int i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const ValueKey<String>('daily_expression_choice_wrong_0'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    expect(find.text('点选答案'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('daily_expression_shadow_button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('daily_expression_choice_correct')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('daily_expression_choice_wrong_0')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('daily_expression_choice_wrong_0')),
    );
    for (int i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('还不对').evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.text('再选一次'), findsOneWidget);
    expect(find.textContaining('还不对'), findsOneWidget);

    InterviewExpressionLearningProgress? wrongProgress;
    for (int i = 0; i < 40; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
      wrongProgress = InterviewWikiStore(sceneId: defaultInterviewSceneId)
          .loadExpressionLearningProgressFor(
            nodeId: 'L1_01',
            targetLevel: 'beginner',
            sourceSceneId: defaultInterviewSceneId,
          );
      if (wrongProgress?.lastPassed == false) {
        break;
      }
    }
    expect(wrongProgress?.lastPassed, isFalse);

    await tester.tap(
      find.byKey(const ValueKey<String>('daily_expression_choice_correct')),
    );
    for (int i = 0; i < 20; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.textContaining('还不对').evaluate().isEmpty) {
        break;
      }
    }

    expect(find.text('回答正确'), findsOneWidget);
    expect(find.textContaining('还不对'), findsNothing);

    InterviewExpressionLearningProgress? savedProgress;
    for (int i = 0; i < 40; i += 1) {
      await tester.pump(const Duration(milliseconds: 50));
      savedProgress = InterviewWikiStore(sceneId: defaultInterviewSceneId)
          .loadExpressionLearningProgressFor(
            nodeId: 'L1_01',
            targetLevel: 'beginner',
            sourceSceneId: defaultInterviewSceneId,
          );
      if (savedProgress?.lastPassed == true) {
        break;
      }
    }
    expect(savedProgress?.lastPassed, isTrue);
    expect(
      savedProgress?.completedWarmupSteps,
      contains(ExpressionDailyQueueItem.practiceModeMeaningChoice),
    );
  });
}
