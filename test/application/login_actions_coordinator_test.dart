import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakeasy/application/login/login_actions_coordinator.dart';

class MockLoginCodeRemoteApi extends Mock implements LoginCodeRemoteApi {}

void main() {
  late MockLoginCodeRemoteApi remoteApi;
  late LoginActionsCoordinator coordinator;

  setUp(() {
    remoteApi = MockLoginCodeRemoteApi();
    coordinator = LoginActionsCoordinator(remoteApi: remoteApi);
  });

  test('sendCode 会 trim 手机号并调用远端接口', () async {
    when(
      () => remoteApi.sendSmsCode('13800138000'),
    ).thenAnswer((_) async => <String, dynamic>{'code': 0});

    await coordinator.sendCode(phone: ' 13800138000 ');

    verify(() => remoteApi.sendSmsCode('13800138000')).called(1);
  });

  test('sendCode 会透传服务端错误消息', () async {
    when(
      () => remoteApi.sendSmsCode('13800138000'),
    ).thenAnswer((_) async => <String, dynamic>{'code': 1, 'message': '发送失败'});

    expect(
      () => coordinator.sendCode(phone: '13800138000'),
      throwsA(
        isA<Exception>().having(
          (Exception error) => error.toString(),
          'message',
          contains('发送失败'),
        ),
      ),
    );
  });

  test('signInWithPhoneCode 会把参数委托给 session action', () async {
    String? capturedPhone;
    String? capturedCode;

    await coordinator.signInWithPhoneCode(
      phone: '13800138000',
      code: '1234',
      signIn: ({required String phone, required String code}) async {
        capturedPhone = phone;
        capturedCode = code;
      },
    );

    expect(capturedPhone, '13800138000');
    expect(capturedCode, '1234');
  });
}
