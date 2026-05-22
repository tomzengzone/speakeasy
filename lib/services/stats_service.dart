import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/models/learning_stats_model.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'storage_service.dart';

class StatsService {
  const StatsService();

  static const Duration cacheTtl = Duration(minutes: 30);

  Future<LearningStatsModel?> loadCachedStats({Duration? maxAge}) async {
    return StorageService.instance.getLearningStatsCache(maxAge: maxAge)?.stats;
  }

  Future<void> cacheStats(LearningStatsModel stats) async {
    await StorageService.instance.saveLearningStatsCache(
      LearningStatsCacheStorageModel(stats: stats, cachedAt: DateTime.now()),
    );
  }

  Future<LearningStatsModel> refreshStats() async {
    final LearningStatsModel stats = await ApiClient.getLearningStats();
    await cacheStats(stats);
    return stats;
  }

  Future<LearningStatsModel?> fetchStats({Duration maxAge = cacheTtl}) async {
    final LearningStatsModel? cached = await loadCachedStats(maxAge: maxAge);
    if (cached != null) {
      return cached;
    }
    return refreshStats();
  }

  Future<LearningStatsModel> recordSession({
    required int durationSeconds,
    required int score,
    String? title,
    String? emoji,
    List<String>? tags,
    Map<String, dynamic>? feedbackJson,
    String? promptText,
    Map<String, dynamic>? sceneDraftJson,
    String feedbackStatus = 'ready',
    Map<String, dynamic>? feedbackContextJson,
  }) async {
    final LearningStatsModel? stats = await ApiClient.recordPracticeSession(
      durationSeconds: durationSeconds,
      score: score,
      title: title,
      emoji: emoji,
      tags: tags,
      feedback: feedbackJson,
      promptText: promptText,
      sceneDraft: sceneDraftJson,
      feedbackStatus: feedbackStatus,
      feedbackContext: feedbackContextJson,
    );
    final LearningStatsModel resolved = stats ?? await refreshStats();
    await cacheStats(resolved);
    return resolved;
  }

  Future<void> clearCache() async {
    await StorageService.instance.clearLearningStatsCache();
  }

  Future<LearningStatsModel> upsertPracticeFeedback({
    required int durationSeconds,
    required int score,
    required String title,
    String? emoji,
    List<String>? tags,
    required Map<String, dynamic> feedbackJson,
    String? promptText,
    Map<String, dynamic>? sceneDraftJson,
    Map<String, dynamic>? feedbackContextJson,
  }) async {
    final LearningStatsModel? stats = await ApiClient.upsertPracticeFeedback(
      durationSeconds: durationSeconds,
      score: score,
      title: title,
      emoji: emoji,
      tags: tags,
      feedback: feedbackJson,
      promptText: promptText,
      sceneDraft: sceneDraftJson,
      feedbackContext: feedbackContextJson,
    );
    final LearningStatsModel resolved = stats ?? await refreshStats();
    await cacheStats(resolved);
    return resolved;
  }

  Future<LearningStatsModel> deletePracticeSceneGroup(String title) async {
    final LearningStatsModel? stats = await ApiClient.deletePracticeSceneGroup(title);
    final LearningStatsModel resolved = stats ?? await refreshStats();
    await cacheStats(resolved);
    return resolved;
  }
}
