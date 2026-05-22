import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/home/home_cards_coordinator.dart';
import 'package:speakeasy/models/storage_models.dart';

class MockHomeCardsRemoteApi extends Mock implements HomeCardsRemoteApi {}

class MockHomeCardsLocalStore extends Mock implements HomeCardsLocalStore {}

void main() {
  late MockHomeCardsRemoteApi remoteApi;
  late MockHomeCardsLocalStore localStore;
  late HomeCardsCoordinator coordinator;

  setUpAll(() {
    registerFallbackValue(
      const LearningProgressStorageModel(
        savedIds: <int>[],
        dismissedIds: <int>[],
        completedIds: <int>[],
      ),
    );
    registerFallbackValue(
      const CachedCourseDataStorageModel(cards: <StoredExpressionCardModel>[]),
    );
  });

  setUp(() {
    remoteApi = MockHomeCardsRemoteApi();
    localStore = MockHomeCardsLocalStore();
    coordinator = HomeCardsCoordinator(remoteApi: remoteApi, localStore: localStore);
    when(() => localStore.saveLearningProgress(any())).thenAnswer((_) async {});
    when(() => localStore.saveCachedCourseData(any())).thenAnswer((_) async {});
  });

  test('loadLearningProgress 会返回 set 形式的进度状态', () async {
    when(() => localStore.getLearningProgress()).thenReturn(
      const LearningProgressStorageModel(
        savedIds: <int>[1, 3],
        dismissedIds: <int>[2],
        completedIds: <int>[4],
      ),
    );

    final HomeLearningProgress progress = await coordinator.loadLearningProgress();

    expect(progress.savedIds, <int>{1, 3});
    expect(progress.dismissedIds, <int>{2});
    expect(progress.completedIds, <int>{4});
  });

  test('loadRemoteCards 会解析卡片并提取后端状态位', () async {
    when(() => remoteApi.getCards()).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'card-1',
            'category': '不会开口',
            'title': '开场',
            'pattern': 'Hello',
            'image': 'https://example.com/a.png',
            'learnerCount': 100,
            'difficultyLevel': 1,
            'progress': <String>['idle'],
            'thumbHeight': 200,
            'colorHex': '#4A7244',
            'saved': true,
          },
          <String, dynamic>{
            'id': 'card-2',
            'category': '不会开口',
            'title': '结尾',
            'pattern': 'Bye',
            'image': 'https://example.com/b.png',
            'learnerCount': 80,
            'difficultyLevel': 2,
            'progress': <String>['idle'],
            'thumbHeight': 210,
            'colorHex': '#4A7244',
            'dismissed': true,
            'completed': true,
          },
        ],
      },
    );

    final HomeCardsSnapshot? snapshot = await coordinator.loadRemoteCards();

    expect(snapshot, isNotNull);
    expect(snapshot!.cards, hasLength(2));
    expect(snapshot.savedIds, <int>{0});
    expect(snapshot.dismissedIds, <int>{1});
    expect(snapshot.completedIds, <int>{1});
    verify(() => localStore.saveCachedCourseData(any())).called(1);
  });

  test('persistLearningProgress 会排序后写入本地存储', () async {
    await coordinator.persistLearningProgress(
      savedIds: <int>{3, 1},
      dismissedIds: <int>{4, 2},
      completedIds: <int>{5},
    );

    verify(
      () => localStore.saveLearningProgress(
        any(
          that: isA<LearningProgressStorageModel>()
              .having((LearningProgressStorageModel value) => value.savedIds, 'savedIds', <int>[1, 3])
              .having((LearningProgressStorageModel value) => value.dismissedIds, 'dismissedIds', <int>[2, 4])
              .having((LearningProgressStorageModel value) => value.completedIds, 'completedIds', <int>[5]),
        ),
      ),
    ).called(1);
  });
}
