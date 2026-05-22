import 'package:speakeasy/services/api_client.dart';

typedef AppleLoginAction = Future<void> Function();
typedef WeChatLoginAction = Future<void> Function();
typedef PhoneCodeLoginAction =
    Future<void> Function({required String phone, required String code});
typedef TestPhoneLoginAction = Future<void> Function({required String phone});

abstract class LoginCodeRemoteApi {
  Future<Map<String, dynamic>> sendSmsCode(String phone);
}

class ApiClientLoginCodeRemoteApi implements LoginCodeRemoteApi {
  const ApiClientLoginCodeRemoteApi();

  @override
  Future<Map<String, dynamic>> sendSmsCode(String phone) {
    return ApiClient.sendSmsCode(phone);
  }
}

class LoginActionsCoordinator {
  const LoginActionsCoordinator({
    LoginCodeRemoteApi remoteApi = const ApiClientLoginCodeRemoteApi(),
  }) : _remoteApi = remoteApi;

  final LoginCodeRemoteApi _remoteApi;

  Future<void> sendCode({required String phone}) async {
    final Map<String, dynamic> res = await _remoteApi.sendSmsCode(phone.trim());
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '验证码发送失败');
    }
  }

  Future<void> signInWithApple({required AppleLoginAction signIn}) {
    return signIn();
  }

  Future<void> signInWithWeChat({required WeChatLoginAction signIn}) {
    return signIn();
  }

  Future<void> signInWithPhoneCode({
    required String phone,
    required String code,
    required PhoneCodeLoginAction signIn,
  }) {
    return signIn(phone: phone, code: code);
  }

  Future<void> signInWithTestPhone({
    required String phone,
    required TestPhoneLoginAction signIn,
  }) {
    return signIn(phone: phone.trim());
  }
}
