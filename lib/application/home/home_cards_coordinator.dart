import 'package:speakeasy/models/app_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/services/storage_service.dart';

class HomeLearningProgress {
  const HomeLearningProgress({
    required this.savedIds,
    required this.dismissedIds,
    required this.completedIds,
  });

  final Set<int> savedIds;
  final Set<int> dismissedIds;
  final Set<int> completedIds;
}

class HomeCardsSnapshot {
  const HomeCardsSnapshot({
    required this.cards,
    required this.savedIds,
    required this.dismissedIds,
    required this.completedIds,
  });

  final List<ExpressionCardData> cards;
  final Set<int> savedIds;
  final Set<int> dismissedIds;
  final Set<int> completedIds;
}

abstract class HomeCardsRemoteApi {
  Future<Map<String, dynamic>> getCards();

  Future<void> updateCardState(
    String cardId, {
    bool? saved,
    bool? dismissed,
    bool? completed,
  });
}

class ApiClientHomeCardsRemoteApi implements HomeCardsRemoteApi {
  const ApiClientHomeCardsRemoteApi();

  @override
  Future<Map<String, dynamic>> getCards() => ApiClient.getCards();

  @override
  Future<void> updateCardState(
    String cardId, {
    bool? saved,
    bool? dismissed,
    bool? completed,
  }) {
    return ApiClient.updateCardState(
      cardId,
      saved: saved,
      dismissed: dismissed,
      completed: completed,
    );
  }
}

abstract class HomeCardsLocalStore {
  LearningProgressStorageModel getLearningProgress();

  Future<void> saveLearningProgress(LearningProgressStorageModel progress);

  CachedCourseDataStorageModel? getCachedCourseData();

  Future<void> saveCachedCourseData(CachedCourseDataStorageModel cache);
}

class StorageServiceHomeCardsLocalStore implements HomeCardsLocalStore {
  const StorageServiceHomeCardsLocalStore();

  @override
  CachedCourseDataStorageModel? getCachedCourseData() {
    return StorageService.instance.getCachedCourseData();
  }

  @override
  LearningProgressStorageModel getLearningProgress() {
    return StorageService.instance.getLearningProgress();
  }

  @override
  Future<void> saveCachedCourseData(CachedCourseDataStorageModel cache) {
    return StorageService.instance.saveCachedCourseData(cache);
  }

  @override
  Future<void> saveLearningProgress(LearningProgressStorageModel progress) {
    return StorageService.instance.saveLearningProgress(progress);
  }
}

class HomeCardsCoordinator {
  HomeCardsCoordinator({
    HomeCardsRemoteApi remoteApi = const ApiClientHomeCardsRemoteApi(),
    HomeCardsLocalStore localStore = const StorageServiceHomeCardsLocalStore(),
  }) : _remoteApi = remoteApi,
       _localStore = localStore;

  final HomeCardsRemoteApi _remoteApi;
  final HomeCardsLocalStore _localStore;

  Future<HomeLearningProgress> loadLearningProgress() async {
    final LearningProgressStorageModel progress = _localStore
        .getLearningProgress();
    return HomeLearningProgress(
      savedIds: progress.savedIds.toSet(),
      dismissedIds: progress.dismissedIds.toSet(),
      completedIds: progress.completedIds.toSet(),
    );
  }

  Future<List<ExpressionCardData>?> loadCachedCards() async {
    final CachedCourseDataStorageModel? cache = _localStore.getCachedCourseData();
    return cache?.toCards();
  }

  Future<HomeCardsSnapshot?> loadRemoteCards() async {
    final Map<String, dynamic> res = await _remoteApi.getCards();
    if (res['code'] != 0) {
      return null;
    }

    final List<dynamic> list = res['data'] as List<dynamic>;
    final List<ExpressionCardData> cards = list
        .map(
          (dynamic e) => ExpressionCardData.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
    final Set<int> savedIds = <int>{};
    final Set<int> dismissedIds = <int>{};
    final Set<int> completedIds = <int>{};
    for (int i = 0; i < cards.length; i++) {
      final Map<String, dynamic> cardJson = list[i] as Map<String, dynamic>;
      if (cardJson['saved'] == true) {
        savedIds.add(i);
      }
      if (cardJson['dismissed'] == true) {
        dismissedIds.add(i);
      }
      if (cardJson['completed'] == true) {
        completedIds.add(i);
      }
    }
    await _localStore.saveCachedCourseData(
      CachedCourseDataStorageModel.fromCards(cards, cachedAt: DateTime.now()),
    );
    return HomeCardsSnapshot(
      cards: cards,
      savedIds: savedIds,
      dismissedIds: dismissedIds,
      completedIds: completedIds,
    );
  }

  Future<void> persistLearningProgress({
    required Set<int> savedIds,
    required Set<int> dismissedIds,
    required Set<int> completedIds,
  }) {
    return _localStore.saveLearningProgress(
      LearningProgressStorageModel(
        savedIds: (savedIds.toList()..sort()),
        dismissedIds: (dismissedIds.toList()..sort()),
        completedIds: (completedIds.toList()..sort()),
      ),
    );
  }

  Future<void> updateCardState(
    ExpressionCardData card,
    int index, {
    bool? saved,
    bool? dismissed,
    bool? completed,
  }) {
    return _remoteApi.updateCardState(
      _cardIdFor(card, index),
      saved: saved,
      dismissed: dismissed,
      completed: completed,
    );
  }

  String _cardIdFor(ExpressionCardData card, int index) {
    final String? remoteId = card.id;
    if (remoteId != null && remoteId.isNotEmpty) {
      return remoteId;
    }
    return 'card_${(index + 1).toString().padLeft(3, '0')}';
  }
}
