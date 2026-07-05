import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/session/session_profile_coordinator.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/models/storage_models.dart';

class MockSessionProfileRemoteApi extends Mock
    implements SessionProfileRemoteApi {}

class MockSessionProfileLocalStore extends Mock
    implements SessionProfileLocalStore {}

void main() {
  late MockSessionProfileRemoteApi remoteApi;
  late MockSessionProfileLocalStore localStore;
  late SessionProfileCoordinator coordinator;

  setUpAll(() {
    registerFallbackValue(const UserPreferencesStorageModel());
    registerFallbackValue(
      const StoredUserProfileModel(
        nickname: 'fallback',
        avatarUrl: '',
        memberPlan: 'free',
      ),
    );
  });

  setUp(() {
    remoteApi = MockSessionProfileRemoteApi();
    localStore = MockSessionProfileLocalStore();
    coordinator = SessionProfileCoordinator(
      remoteApi: remoteApi,
      localStore: localStore,
    );
    when(
      () => localStore.getUserPreferences(),
    ).thenReturn(const UserPreferencesStorageModel());
    when(() => localStore.saveUserPreferences(any())).thenAnswer((_) async {});
    when(() => localStore.saveUserProfile(any())).thenAnswer((_) async {});
    when(() => localStore.clearUserProfile()).thenAnswer((_) async {});
    when(() => localStore.clearUserPreferences()).thenAnswer((_) async {});
    when(() => remoteApi.clearToken()).thenAnswer((_) async {});
  });

  test('persistUser 会保存用户资料并同步 onboarding 状态到偏好', () async {
    const AppUser user = AppUser(
      nickname: '测试用户',
      avatarUrl: 'https://example.com/a.png',
      memberPlan: 'monthly',
      onboardingDone: true,
    );

    await coordinator.persistUser(user);

    verify(() => localStore.saveUserProfile(any())).called(1);
    verify(
      () => localStore.saveUserPreferences(
        any(
          that: isA<UserPreferencesStorageModel>().having(
            (UserPreferencesStorageModel value) => value.onboardingDone,
            'onboardingDone',
            true,
          ),
        ),
      ),
    ).called(1);
  });

  test('persistOnboarding 会保存目标等级时长并回写用户状态', () async {
    const AppUser user = AppUser(
      nickname: '测试用户',
      avatarUrl: '',
      memberPlan: 'free',
      onboardingDone: true,
    );

    await coordinator.persistOnboarding(
      user: user,
      goals: const <String>['口语'],
      level: 2,
      dailyMinutes: 15,
    );

    verify(
      () => localStore.saveUserPreferences(
        any(
          that: isA<UserPreferencesStorageModel>()
              .having(
                (UserPreferencesStorageModel value) => value.goals,
                'goals',
                const <String>['口语'],
              )
              .having(
                (UserPreferencesStorageModel value) => value.level,
                'level',
                2,
              )
              .having(
                (UserPreferencesStorageModel value) => value.dailyGoalMinutes,
                'dailyGoalMinutes',
                15,
              ),
        ),
      ),
    ).called(1);
    verify(() => localStore.saveUserProfile(any())).called(1);
  });

  test('syncUserPatch 在存在 token 时返回后端用户数据', () async {
    when(() => remoteApi.getToken()).thenAnswer((_) async => 'jwt-token');
    when(
      () => remoteApi.updateMe(<String, dynamic>{
        'display_name': '新昵称',
        'avatar_ref': 'assets/images/avatars/default_avatar_2.png',
      }),
    ).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'nickname': '远端昵称',
          'avatarUrl': 'assets/images/avatars/default_avatar_2.png',
        },
      },
    );

    final Map<String, dynamic>? data = await coordinator
        .syncUserPatch(<String, dynamic>{
          'display_name': '新昵称',
          'avatar_ref': 'assets/images/avatars/default_avatar_2.png',
        });

    expect(data, isNotNull);
    expect(data!['nickname'], '远端昵称');
    expect(data['avatarUrl'], 'assets/images/avatars/default_avatar_2.png');
  });

  test('clearSessionData 会清理本地资料与 token', () async {
    await coordinator.clearSessionData();

    verify(() => localStore.clearUserProfile()).called(1);
    verify(() => localStore.clearUserPreferences()).called(1);
    verify(() => remoteApi.clearToken()).called(1);
  });

  test('deleteAccount 会先调用远端注销再清理本地会话', () async {
    when(() => remoteApi.getToken()).thenAnswer((_) async => 'jwt-token');
    when(
      () => remoteApi.deleteAccount(),
    ).thenAnswer((_) async => <String, dynamic>{'code': 0});

    await coordinator.deleteAccount();

    verify(() => remoteApi.deleteAccount()).called(1);
    verify(() => localStore.clearUserProfile()).called(1);
    verify(() => localStore.clearUserPreferences()).called(1);
    verify(() => remoteApi.clearToken()).called(1);
  });

  test('persistThemeMode 会更新偏好主题模式', () async {
    await coordinator.persistThemeMode(ThemeMode.dark);

    verify(
      () => localStore.saveUserPreferences(
        any(
          that: isA<UserPreferencesStorageModel>().having(
            (UserPreferencesStorageModel value) => value.themeMode,
            'themeMode',
            ThemeMode.dark,
          ),
        ),
      ),
    ).called(1);
  });
}
