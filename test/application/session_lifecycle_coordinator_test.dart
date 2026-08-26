import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/session/session_lifecycle_coordinator.dart';
import 'package:speakeasy/core/auth/auth_credentials.dart';
import 'package:speakeasy/domain/auth/auth_models.dart';
import 'package:speakeasy/models/storage_models.dart';
import 'package:speakeasy/services/apple_auth_service.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/wechat_auth_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockSessionRemoteApi extends Mock implements SessionRemoteApi {}

class MockSessionCredentialStore extends Mock
    implements SessionCredentialStore {}

class MockSessionLocalStore extends Mock implements SessionLocalStore {}

void main() {
  late MockAuthService authService;
  late MockSessionRemoteApi remoteApi;
  late MockSessionCredentialStore credentialStore;
  late MockSessionLocalStore localStore;
  late SessionLifecycleCoordinator coordinator;

  setUpAll(() {
    registerFallbackValue(
      AuthCredentials(
        accessToken: 'fallback-access-token',
        refreshToken: 'fallback-refresh-token',
        expiresAt: DateTime.utc(2026, 8, 27),
      ),
    );
  });

  setUp(() {
    authService = MockAuthService();
    remoteApi = MockSessionRemoteApi();
    credentialStore = MockSessionCredentialStore();
    localStore = MockSessionLocalStore();
    coordinator = SessionLifecycleCoordinator(
      authService: authService,
      remoteApi: remoteApi,
      credentialStore: credentialStore,
      localStore: localStore,
    );
    when(() => credentialStore.read()).thenAnswer((_) async => null);
  });

  test('loadStoredSession 使用安全凭证恢复本地用户和偏好', () async {
    when(() => credentialStore.read()).thenAnswer(
      (_) async => AuthCredentials(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime.parse('2026-08-27T00:00:00Z'),
      ),
    );
    when(() => localStore.getAuthSession()).thenReturn(null);
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

    final StoredSessionSnapshot snapshot = await coordinator
        .loadStoredSession();

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
        credentials: AuthCredentials(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresAt: DateTime.parse('2026-08-27T00:00:00Z'),
        ),
        userJson: const <String, dynamic>{'nickname': '测试用户'},
      ),
    );

    final SessionSignInResult result = await coordinator.signIn(submission);

    expect(result.hasAuthenticatedSession, isTrue);
    expect(result.authenticatedSession!.token, 'access-token');
    expect(
      result.authenticatedSession!.credentials.refreshToken,
      'refresh-token',
    );
    expect(result.authenticatedSession!.userJson['nickname'], '测试用户');
  });

  test('signInWithTestPhone 会去除手机号空白并返回 payload', () async {
    when(() => remoteApi.testPhoneLogin('13800138000')).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'token': 'test-token',
          'refreshToken': 'test-refresh-token',
          'expiresAt': '2026-08-27T00:00:00Z',
          'user': <String, dynamic>{'nickname': '测试手机号'},
        },
      },
    );

    final AuthenticatedSessionPayload payload = await coordinator
        .signInWithTestPhone(phone: ' 13800138000 ');

    expect(payload.token, 'test-token');
    expect(payload.credentials.refreshToken, 'test-refresh-token');
    expect(payload.userJson['nickname'], '测试手机号');
    verify(() => remoteApi.testPhoneLogin('13800138000')).called(1);
  });

  test('Apple 登录保留完整凭证', () async {
    final AuthCredentials credentials = AuthCredentials(
      accessToken: 'apple-access-token',
      refreshToken: 'apple-refresh-token',
      expiresAt: DateTime.parse('2026-08-27T00:00:00Z'),
    );

    final AuthenticatedSessionPayload payload = await coordinator
        .signInWithApple(
          signIn: () async => AppleAuthResult(
            credentials: credentials,
            userJson: const <String, dynamic>{'nickname': 'Apple 用户'},
          ),
        );

    expect(payload.credentials, same(credentials));
    expect(payload.userJson['nickname'], 'Apple 用户');
  });

  test('微信登录保留完整凭证', () async {
    final AuthCredentials credentials = AuthCredentials(
      accessToken: 'wechat-access-token',
      refreshToken: 'wechat-refresh-token',
      expiresAt: DateTime.parse('2026-08-27T00:00:00Z'),
    );

    final AuthenticatedSessionPayload payload = await coordinator
        .signInWithWeChat(
          signIn: () async => WeChatAuthResult(
            code: 'wechat-code',
            credentials: credentials,
            userJson: const <String, dynamic>{'nickname': '微信用户'},
          ),
        );

    expect(payload.credentials, same(credentials));
    expect(payload.userJson['nickname'], '微信用户');
  });

  test('resolveAuthenticatedSession 在缺少 userJson 时会补拉取 me', () async {
    final AuthCredentials credentials = AuthCredentials(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.parse('2026-08-27T00:00:00Z'),
    );
    when(() => credentialStore.replace(credentials)).thenAnswer((_) async {});
    when(() => remoteApi.getMe()).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{'nickname': '后端用户', 'plan': 'monthly'},
      },
    );

    final ResolvedAuthenticatedSession session = await coordinator
        .resolveAuthenticatedSession(
          AuthenticatedSessionPayload(credentials: credentials),
        );

    expect(session.token, 'access-token');
    expect(session.userJson['nickname'], '后端用户');
    verify(() => credentialStore.replace(credentials)).called(1);
    verify(() => remoteApi.getMe()).called(1);
  });

  test('hydrateExistingSession 在 refresh 成功时原子替换完整凭证', () async {
    final AuthCredentials oldCredentials = AuthCredentials(
      accessToken: 'old-token',
      refreshToken: 'old-refresh-token',
      expiresAt: DateTime.parse('2026-08-26T00:00:00Z'),
    );
    when(() => credentialStore.read()).thenAnswer((_) async => oldCredentials);
    when(() => remoteApi.refreshToken('old-refresh-token')).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'token': 'new-token',
          'refreshToken': 'new-refresh-token',
          'expiresAt': '2026-08-27T00:00:00Z',
          'user': <String, dynamic>{'nickname': '刷新后的用户'},
        },
      },
    );
    when(() => credentialStore.replace(any())).thenAnswer((_) async {});

    final ResolvedAuthenticatedSession? session = await coordinator
        .hydrateExistingSession();

    expect(session, isNotNull);
    expect(session!.token, 'new-token');
    expect(session.credentials!.refreshToken, 'new-refresh-token');
    expect(session.userJson['nickname'], '刷新后的用户');
    verify(
      () => credentialStore.replace(
        any(
          that: isA<AuthCredentials>()
              .having(
                (AuthCredentials value) => value.accessToken,
                'accessToken',
                'new-token',
              )
              .having(
                (AuthCredentials value) => value.refreshToken,
                'refreshToken',
                'new-refresh-token',
              ),
        ),
      ),
    ).called(1);
    verifyNever(() => remoteApi.getMe());
  });

  test('hydrateExistingSession 在 refresh 失败时回退到 getMe', () async {
    final AuthCredentials credentials = AuthCredentials(
      accessToken: 'old-token',
      refreshToken: 'old-refresh-token',
      expiresAt: DateTime.parse('2026-08-27T00:00:00Z'),
    );
    when(() => credentialStore.read()).thenAnswer((_) async => credentials);
    when(() => remoteApi.refreshToken('old-refresh-token')).thenAnswer(
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
    verifyNever(() => credentialStore.replace(any()));
  });
}
