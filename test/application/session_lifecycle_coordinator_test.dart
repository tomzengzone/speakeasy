import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSessionRemoteApi extends Mock implements SessionRemoteApi {}

class MockSessionLocalStore extends Mock implements SessionLocalStore {}

void main() {
  late MockAuthService authService;
  late MockSessionRemoteApi remoteApi;
  late MockSessionLocalStore localStore;
  late SessionLifecycleCoordinator coordinator;

  setUp(() {
    authService = MockAuthService();
    remoteApi = MockSessionRemoteApi();
    localStore = MockSessionLocalStore();
    coordinator = SessionLifecycleCoordinator(
      authService: authService,
      remoteApi: remoteApi,
      localStore: localStore,
    );
  });

  test('loadStoredSession 仅在存在 token 时恢复本地用户和偏好', () async {
    when(() => localStore.getAuthSession()).thenReturn(
      const AuthSessionStorageModel(token: 'jwt-token'),
    );
    when(() => localStore.getUserProfile()).thenReturn(
      const StoredUserProfileModel(
        nickname: '缓存用户',
        avatarUrl: '',
        memberPlan: 'monthly',
        onboardingDone: true,
      ),
    );
    when(() => localStore.getUserPreferences()).thenReturn(
      const UserPreferencesStorageModel(
        onboardingDone: true,
        themeMode: ThemeMode.dark,
      ),
    );

    final StoredSessionSnapshot snapshot = await coordinator.loadStoredSession();

    expect(snapshot.user, isNotNull);
    expect(snapshot.user!.nickname, '缓存用户');
    expect(snapshot.user!.avatarUrl, isNotEmpty);
    expect(snapshot.onboardingDone, isTrue);
    expect(snapshot.themeMode, ThemeMode.dark);
  });

  test('signIn 会将带 token 的会话映射为 authenticated 结果', () async {
    const LoginSubmission submission = LoginSubmission(
      provider: LoginProvider.phone,
      phone: '13800138000',
      code: '123456',
    );
    when(() => authService.signIn(submission)).thenAnswer(
      (_) async => AuthSession(
        user: const AppUser(
          nickname: '测试用户',
          avatarUrl: 'https://example.com/avatar.png',
          memberPlan: 'free',
        ),
        token: 'jwt-token',
        userJson: const <String, dynamic>{'nickname': '测试用户'},
      ),
    );

    final SessionSignInResult result = await coordinator.signIn(submission);

    expect(result.hasAuthenticatedSession, isTrue);
    expect(result.authenticatedSession!.token, 'jwt-token');
    expect(result.authenticatedSession!.userJson['nickname'], '测试用户');
  });

  test('signInWithTestPhone 会去除手机号空白并返回 payload', () async {
    when(() => remoteApi.testPhoneLogin('13800138000')).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'token': 'test-token',
          'user': <String, dynamic>{'nickname': '测试手机号'},
        },
      },
    );

    final AuthenticatedSessionPayload payload = await coordinator
        .signInWithTestPhone(phone: ' 13800138000 ');

    expect(payload.token, 'test-token');
    expect(payload.userJson['nickname'], '测试手机号');
    verify(() => remoteApi.testPhoneLogin('13800138000')).called(1);
  });

  test('resolveAuthenticatedSession 在缺少 userJson 时会补拉取 me', () async {
    when(() => remoteApi.saveToken('jwt-token')).thenAnswer((_) async {});
    when(() => remoteApi.getMe()).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{'nickname': '后端用户', 'plan': 'monthly'},
      },
    );

    final ResolvedAuthenticatedSession session = await coordinator
        .resolveAuthenticatedSession(
          const AuthenticatedSessionPayload(token: 'jwt-token'),
        );

    expect(session.token, 'jwt-token');
    expect(session.userJson['nickname'], '后端用户');
    verify(() => remoteApi.saveToken('jwt-token')).called(1);
    verify(() => remoteApi.getMe()).called(1);
  });

  test('hydrateExistingSession 在 refresh 成功时更新 token 并返回用户', () async {
    when(() => remoteApi.getToken()).thenAnswer((_) async => 'old-token');
    when(() => remoteApi.refreshToken()).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'token': 'new-token',
          'user': <String, dynamic>{'nickname': '刷新后的用户'},
        },
      },
    );
    when(() => remoteApi.saveToken('new-token')).thenAnswer((_) async {});

    final ResolvedAuthenticatedSession? session = await coordinator
        .hydrateExistingSession();

    expect(session, isNotNull);
    expect(session!.token, 'new-token');
    expect(session.userJson['nickname'], '刷新后的用户');
    verify(() => remoteApi.saveToken('new-token')).called(1);
    verifyNever(() => remoteApi.getMe());
  });

  test('hydrateExistingSession 在 refresh 失败时回退到 getMe', () async {
    when(() => remoteApi.getToken()).thenAnswer((_) async => 'old-token');
    when(() => remoteApi.refreshToken()).thenAnswer(
      (_) async => <String, dynamic>{'code': 401, 'message': 'expired'},
    );
    when(() => remoteApi.getMe()).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{'nickname': '回退用户'},
      },
    );

    final ResolvedAuthenticatedSession? session = await coordinator
        .hydrateExistingSession();

    expect(session, isNotNull);
    expect(session!.token, 'old-token');
    expect(session.userJson['nickname'], '回退用户');
    verify(() => remoteApi.getMe()).called(1);
  });
}
