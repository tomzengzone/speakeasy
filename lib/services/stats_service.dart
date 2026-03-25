import '../api_client.dart';
import '../models/learning_stats_model.dart';
import '../models/storage_models.dart';
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
  }) async {
    final LearningStatsModel? stats = await ApiClient.recordPracticeSession(
      durationSeconds: durationSeconds,
      score: score,
    );
    final LearningStatsModel resolved = stats ?? await refreshStats();
    await cacheStats(resolved);
    return resolved;
  }

  Future<void> clearCache() async {
    await StorageService.instance.clearLearningStatsCache();
  }
}
