import 'package:speakeasy/application/contracts/app_repository.dart';
import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/stats_service.dart';

abstract class SessionStatsAuthApi {
  Future<String?> getToken();
}

class ApiClientSessionStatsAuthApi implements SessionStatsAuthApi {
  const ApiClientSessionStatsAuthApi();

  @override
  Future<String?> getToken() => ApiClient.getToken();
}

class SessionStatsCoordinator {
  SessionStatsCoordinator({
    StatsService statsService = const StatsService(),
    SessionStatsAuthApi authApi = const ApiClientSessionStatsAuthApi(),
  }) : _statsService = statsService,
       _authApi = authApi;

  final StatsService _statsService;
  final SessionStatsAuthApi _authApi;

  Future<LearningStatsModel?> loadCachedStats() {
    return _statsService.loadCachedStats();
  }

  Future<void> cacheStats(LearningStatsModel stats) {
    return _statsService.cacheStats(stats);
  }

  Future<void> clearCache() {
    return _statsService.clearCache();
  }

  LearningStatsModel recordLocalSession({
    required LearningStatsModel currentStats,
    required int durationSeconds,
    required int score,
    String? title,
    String? emoji,
    List<String>? tags,
    SceneFeedback? feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    String feedbackStatus = 'ready',
    Map<String, dynamic>? feedbackContext,
    DateTime? practicedAt,
  }) {
    final DateTime resolvedPracticedAt = practicedAt ?? DateTime.now();
    return currentStats.recordLocalSession(
      durationSeconds: durationSeconds,
      score: score,
      practicedAt: resolvedPracticedAt,
      recentPractice: (title == null || title.trim().isEmpty)
          ? null
          : PracticeHistoryModel(
              title: title.trim(),
              score: score,
              emoji: (emoji ?? '').trim().isEmpty ? '🎯' : emoji!.trim(),
              practicedAt: resolvedPracticedAt,
              feedbackStatus: feedbackStatus,
              feedbackData: feedback?.toJson(),
              promptText: promptText?.trim().isEmpty ?? true
                  ? null
                  : promptText!.trim(),
              sceneDraftData: sceneDraft?.toJson(),
              feedbackContextData: feedbackContext,
              tags: _normalizeTags(tags),
            ),
    );
  }

  LearningStatsModel upsertLocalPracticeFeedback({
    required LearningStatsModel currentStats,
    required String title,
    required int score,
    String? emoji,
    List<String>? tags,
    required SceneFeedback feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    Map<String, dynamic>? feedbackContext,
    DateTime? practicedAt,
  }) {
    final PracticeHistoryModel updated = _buildUpdatedPracticeForFeedback(
      currentStats: currentStats,
      title: title,
      score: score,
      emoji: emoji,
      practicedAt: practicedAt,
      tags: tags,
      feedback: feedback,
      promptText: promptText,
      sceneDraft: sceneDraft,
      feedbackContext: feedbackContext,
    );
    return currentStats.upsertRecentPractice(updated);
  }

  LearningStatsModel deleteLocalPracticeGroup({
    required LearningStatsModel currentStats,
    required String title,
  }) {
    return currentStats.removeRecentPracticeGroup(title.trim());
  }

  Future<LearningStatsModel> refreshStats({
    required LearningStatsModel currentStats,
  }) async {
    final LearningStatsModel refreshed = await _statsService.refreshStats();
    return _mergeStats(refreshed, currentStats);
  }

  Future<LearningStatsModel?> syncRecordedSession({
    required LearningStatsModel currentStats,
    required int durationSeconds,
    required int score,
    String? title,
    String? emoji,
    List<String>? tags,
    SceneFeedback? feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    String feedbackStatus = 'ready',
    Map<String, dynamic>? feedbackContext,
  }) async {
    if (!await _hasAuthenticatedSession()) {
      return null;
    }

    final LearningStatsModel remoteStats = await _statsService.recordSession(
      durationSeconds: durationSeconds,
      score: score,
      title: title,
      emoji: emoji,
      tags: tags,
      feedbackJson: feedback?.toJson(),
      promptText: promptText,
      sceneDraftJson: sceneDraft?.toJson(),
      feedbackStatus: feedbackStatus,
      feedbackContextJson: feedbackContext,
    );
    return _mergeStats(remoteStats, currentStats);
  }

  Future<LearningStatsModel?> syncPracticeFeedback({
    required LearningStatsModel currentStats,
    required int durationSeconds,
    required int score,
    required String title,
    String? emoji,
    List<String>? tags,
    required SceneFeedback feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    Map<String, dynamic>? feedbackContext,
  }) async {
    if (!await _hasAuthenticatedSession()) {
      return null;
    }

    final LearningStatsModel remoteStats = await _statsService
        .upsertPracticeFeedback(
          durationSeconds: durationSeconds,
          score: score,
          title: title,
          emoji: emoji,
          tags: tags,
          feedbackJson: feedback.toJson(),
          promptText: promptText,
          sceneDraftJson: sceneDraft?.toJson(),
          feedbackContextJson: feedbackContext,
        );
    return _mergeStats(remoteStats, currentStats);
  }

  Future<LearningStatsModel?> syncDeletePracticeGroup({
    required LearningStatsModel currentStats,
    required String title,
  }) async {
    if (!await _hasAuthenticatedSession()) {
      return null;
    }

    final LearningStatsModel remoteStats = await _statsService
        .deletePracticeSceneGroup(title);
    return _mergeStats(remoteStats, currentStats);
  }

  LearningStatsModel _mergeStats(
    LearningStatsModel primary,
    LearningStatsModel fallback,
  ) {
    return primary.copyWith(
      recentPractices: _mergeRecentPractices(
        primary.recentPractices,
        fallback.recentPractices,
      ),
    );
  }

  Future<bool> _hasAuthenticatedSession() async {
    final String? token = await _authApi.getToken();
    return token != null && token.isNotEmpty;
  }

  PracticeHistoryModel _buildUpdatedPracticeForFeedback({
    required LearningStatsModel currentStats,
    required String title,
    required int score,
    String? emoji,
    DateTime? practicedAt,
    List<String>? tags,
    required SceneFeedback feedback,
    String? promptText,
    SceneDraft? sceneDraft,
    Map<String, dynamic>? feedbackContext,
  }) {
    final String trimmedTitle = title.trim();
    final PracticeHistoryModel? existing = currentStats.recentPractices
        .cast<PracticeHistoryModel?>()
        .firstWhere(
          (PracticeHistoryModel? item) => item?.title.trim() == trimmedTitle,
          orElse: () => null,
        );
    return (existing ??
            PracticeHistoryModel(
              title: trimmedTitle,
              score: score,
              emoji: (emoji ?? '').trim().isEmpty ? '🎯' : emoji!.trim(),
              practicedAt: practicedAt ?? DateTime.now(),
              tags: tags ?? const <String>[],
            ))
        .copyWith(
          score: score,
          emoji: (emoji ?? '').trim().isEmpty ? '🎯' : emoji!.trim(),
          practicedAt: practicedAt ?? existing?.practicedAt ?? DateTime.now(),
          tags: _normalizeTags(tags, fallback: existing?.tags),
          feedbackStatus: 'ready',
          feedbackData: feedback.toJson(),
          promptText: promptText?.trim().isEmpty ?? true
              ? existing?.promptText
              : promptText!.trim(),
          sceneDraftData: sceneDraft?.toJson() ?? existing?.sceneDraftData,
          feedbackContextData: feedbackContext ?? existing?.feedbackContextData,
        );
  }

  List<PracticeHistoryModel> _mergeRecentPractices(
    List<PracticeHistoryModel> primary,
    List<PracticeHistoryModel> fallback,
  ) {
    final List<PracticeHistoryModel> merged = <PracticeHistoryModel>[];
    final Set<String> seen = <String>{};

    void appendAll(List<PracticeHistoryModel> items) {
      for (final PracticeHistoryModel item in items) {
        final String title = item.title.trim();
        if (title.isEmpty) {
          continue;
        }
        final String key = (item.id?.trim().isNotEmpty ?? false)
            ? 'id:${item.id!.trim()}'
            : '$title|${item.practicedAt?.toIso8601String() ?? item.timeLabel ?? ''}';
        if (!seen.add(key)) {
          continue;
        }
        merged.add(item);
      }
    }

    appendAll(primary);
    appendAll(fallback);
    merged.sort((PracticeHistoryModel a, PracticeHistoryModel b) {
      final DateTime aAt =
          a.practicedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bAt =
          b.practicedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
    return merged.take(12).toList(growable: false);
  }

  List<String> _normalizeTags(
    List<String>? tags, {
    List<String>? fallback,
  }) {
    if (tags == null) {
      return fallback ?? const <String>[];
    }
    return tags
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }
}
