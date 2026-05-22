import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/contracts/app_repository.dart';
import 'package:speakeasy/application/session/session_stats_coordinator.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/services/stats_service.dart';

class MockStatsService extends Mock implements StatsService {}

class MockSessionStatsAuthApi extends Mock implements SessionStatsAuthApi {}

void main() {
  late MockStatsService statsService;
  late MockSessionStatsAuthApi authApi;
  late SessionStatsCoordinator coordinator;

  setUpAll(() {
    registerFallbackValue(const LearningStatsModel());
  });

  setUp(() {
    statsService = MockStatsService();
    authApi = MockSessionStatsAuthApi();
    coordinator = SessionStatsCoordinator(
      statsService: statsService,
      authApi: authApi,
    );
    when(() => statsService.cacheStats(any())).thenAnswer((_) async {});
  });

  test('recordLocalSession 会追加本地练习记录并规范化 tags', () {
    final LearningStatsModel next = coordinator.recordLocalSession(
      currentStats: const LearningStatsModel(),
      durationSeconds: 600,
      score: 88,
      title: '面试复盘',
      emoji: '💼',
      tags: const <String>['  面试  ', '', '高压', '超出'],
      feedbackStatus: 'pending',
    );

    expect(next.totalSessions, 1);
    expect(next.recentPractices, hasLength(1));
    expect(next.recentPractices.first.tags, const <String>['面试', '高压', '超出']);
    expect(next.recentPractices.first.feedbackStatus, 'pending');
  });

  test('upsertLocalPracticeFeedback 会更新现有记录并写入反馈', () {
    const PracticeHistoryModel existing = PracticeHistoryModel(
      title: '咖啡点单',
      score: 70,
      feedbackStatus: 'pending',
      promptText: 'old prompt',
    );
    final LearningStatsModel current = const LearningStatsModel(
      recentPractices: <PracticeHistoryModel>[existing],
    );
    const SceneFeedback feedback = SceneFeedback(
      overallScore: 90,
      headline: '很好',
      summary: '总结',
      metrics: <SceneFeedbackMetric>[],
      coachTip: '继续',
      improvements: <(String, String, String)>[],
    );

    final LearningStatsModel next = coordinator.upsertLocalPracticeFeedback(
      currentStats: current,
      title: '咖啡点单',
      score: 92,
      feedback: feedback,
      tags: const <String>['服务'],
    );

    expect(next.recentPractices, hasLength(1));
    expect(next.recentPractices.first.score, 92);
    expect(next.recentPractices.first.feedbackStatus, 'ready');
    expect(next.recentPractices.first.feedbackData?['overallScore'], 90);
    expect(next.recentPractices.first.tags, const <String>['服务']);
  });

  test('refreshStats 会保留本地 recentPractices 并与远端结果合并', () async {
    const PracticeHistoryModel local = PracticeHistoryModel(
      title: '本地练习',
      practicedAt: null,
    );
    const PracticeHistoryModel remote = PracticeHistoryModel(
      title: '远端练习',
      practicedAt: null,
    );
    when(() => statsService.refreshStats()).thenAnswer(
      (_) async => const LearningStatsModel(
        totalSessions: 3,
        recentPractices: <PracticeHistoryModel>[remote],
      ),
    );

    final LearningStatsModel result = await coordinator.refreshStats(
      currentStats: const LearningStatsModel(
        recentPractices: <PracticeHistoryModel>[local],
      ),
    );

    expect(result.totalSessions, 3);
    expect(result.recentPractices.map((PracticeHistoryModel e) => e.title), containsAll(<String>['远端练习', '本地练习']));
  });

  test('syncRecordedSession 在未登录时跳过远端同步', () async {
    when(() => authApi.getToken()).thenAnswer((_) async => null);

    final LearningStatsModel? result = await coordinator.syncRecordedSession(
      currentStats: const LearningStatsModel(),
      durationSeconds: 120,
      score: 80,
      title: '未登录练习',
    );

    expect(result, isNull);
    verifyNever(() => statsService.recordSession(
      durationSeconds: any(named: 'durationSeconds'),
      score: any(named: 'score'),
      title: any(named: 'title'),
      emoji: any(named: 'emoji'),
      tags: any(named: 'tags'),
      feedbackJson: any(named: 'feedbackJson'),
      promptText: any(named: 'promptText'),
      sceneDraftJson: any(named: 'sceneDraftJson'),
      feedbackStatus: any(named: 'feedbackStatus'),
      feedbackContextJson: any(named: 'feedbackContextJson'),
    ));
  });

  test('syncPracticeFeedback 会返回合并后的远端统计', () async {
    when(() => authApi.getToken()).thenAnswer((_) async => 'jwt-token');
    const SceneFeedback feedback = SceneFeedback(
      overallScore: 85,
      headline: 'ok',
      summary: 'summary',
      metrics: <SceneFeedbackMetric>[
        SceneFeedbackMetric(
          label: '清晰度',
          score: 80,
          color: Color(0xFF4A7C6F),
        ),
      ],
      coachTip: 'tip',
      improvements: <(String, String, String)>[],
    );
    when(
      () => statsService.upsertPracticeFeedback(
        durationSeconds: 300,
        score: 85,
        title: '场景反馈',
        emoji: null,
        tags: null,
        feedbackJson: feedback.toJson(),
        promptText: null,
        sceneDraftJson: null,
        feedbackContextJson: null,
      ),
    ).thenAnswer(
      (_) async => const LearningStatsModel(
        totalSessions: 5,
        recentPractices: <PracticeHistoryModel>[
          PracticeHistoryModel(title: '远端反馈'),
        ],
      ),
    );

    final LearningStatsModel? result = await coordinator.syncPracticeFeedback(
      currentStats: const LearningStatsModel(
        recentPractices: <PracticeHistoryModel>[
          PracticeHistoryModel(title: '本地反馈'),
        ],
      ),
      durationSeconds: 300,
      score: 85,
      title: '场景反馈',
      feedback: feedback,
    );

    expect(result, isNotNull);
    expect(result!.totalSessions, 5);
    expect(result.recentPractices.map((PracticeHistoryModel e) => e.title), containsAll(<String>['远端反馈', '本地反馈']));
  });
}
