import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/services/auth_service.dart';
import 'package:speakeasy/services/app_session.dart';

class MockAuthApi extends Mock implements AuthApi {}

class MockAppRepository extends Mock implements AppRepository {}

void main() {
  late MockAuthApi api;
  late MockAppRepository repository;
  late AuthService service;

  setUp(() {
    api = MockAuthApi();
    repository = MockAppRepository();
    service = AuthService(signInWithEmail: repository.signIn, api: api);
  });

  test('手机号登录会去除空白并返回 token 与用户信息', () async {
    when(() => api.verifySmsCode('13800138000', '123456')).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'token': 'jwt-token',
          'user': <String, dynamic>{
            'nickname': '测试用户',
            'avatarUrl': 'https://example.com/avatar.png',
            'memberPlan': 'monthly',
          },
        },
      },
    );

    final AuthSession session = await service.signIn(
      const LoginSubmission(
        provider: LoginProvider.phone,
        phone: ' 13800138000 ',
        code: ' 123456 ',
      ),
    );

    expect(session.hasToken, isTrue);
    expect(session.token, 'jwt-token');
    expect(session.user.nickname, '测试用户');
    expect(session.user.memberPlan, 'monthly');
    verify(() => api.verifySmsCode('13800138000', '123456')).called(1);
    verifyNever(() => api.getMe());
  });

  test('手机号登录缺少用户信息时会补拉取当前用户', () async {
    when(() => api.verifySmsCode('13800138000', '654321')).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{'token': 'jwt-token'},
      },
    );
    when(() => api.getMe()).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'nickname': '后端用户',
          'avatar': 'https://example.com/fetched.png',
          'plan': 'free',
        },
      },
    );

    final AuthSession session = await service.signIn(
      const LoginSubmission(
        provider: LoginProvider.phone,
        phone: '13800138000',
        code: '654321',
      ),
    );

    expect(session.token, 'jwt-token');
    expect(session.user.nickname, '后端用户');
    expect(session.user.avatarUrl, 'https://example.com/fetched.png');
    verify(() => api.getMe()).called(1);
  });

  test('手机号登录遇到业务错误时抛出服务端消息', () async {
    when(() => api.verifySmsCode('13800138000', '000000')).thenAnswer(
      (_) async => <String, dynamic>{'code': 4001, 'message': '验证码错误'},
    );

    expect(
      () => service.signIn(
        const LoginSubmission(
          provider: LoginProvider.phone,
          phone: '13800138000',
          code: '000000',
        ),
      ),
      throwsA(
        isA<Exception>().having(
          (Exception error) => error.toString(),
          'message',
          'Exception: 验证码错误',
        ),
      ),
    );
  });

  test('手机号登录缺少 token 时抛出凭证无效错误', () async {
    when(() => api.verifySmsCode('13800138000', '123456')).thenAnswer(
      (_) async => <String, dynamic>{
        'code': 0,
        'data': <String, dynamic>{
          'user': <String, dynamic>{'nickname': '测试用户'},
        },
      },
    );

    expect(
      () => service.signIn(
        const LoginSubmission(
          provider: LoginProvider.phone,
          phone: '13800138000',
          code: '123456',
        ),
      ),
      throwsA(
        isA<Exception>().having(
          (Exception error) => error.toString(),
          'message',
          'Exception: 登录凭证无效',
        ),
      ),
    );
  });

  test('邮箱登录会委托仓储并返回无 token 的会话结果', () async {
    const LoginSubmission submission = LoginSubmission(
      provider: LoginProvider.email,
      email: 'user@example.com',
      password: 'secret',
      nickname: '邮箱用户',
    );
    when(() => repository.signIn(submission)).thenAnswer(
      (_) async => const AppUser(
        nickname: '邮箱用户',
        avatarUrl: 'https://example.com/mail.png',
        memberPlan: 'free',
      ),
    );

    final AuthSession session = await service.signIn(submission);

    expect(session.hasToken, isFalse);
    expect(session.token, isNull);
    expect(session.user.nickname, '邮箱用户');
    verify(() => repository.signIn(submission)).called(1);
    verifyNever(() => api.verifySmsCode(any(), any()));
  });
}
