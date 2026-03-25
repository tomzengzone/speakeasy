import 'package:speakeasy/services/api_client.dart';
import 'package:speakeasy/models/auth_models.dart';

typedef EmailSignIn = Future<AppUser> Function(LoginSubmission submission);

class AuthSession {
  const AuthSession({
    required this.user,
    this.token,
    this.userJson = const <String, dynamic>{},
  });

  final AppUser user;
  final String? token;
  final Map<String, dynamic> userJson;

  bool get hasToken => (token ?? '').isNotEmpty;
}

abstract class AuthApi {
  Future<Map<String, dynamic>> verifySmsCode(String phone, String code);

  Future<Map<String, dynamic>> getMe();
}

class ApiClientAuthApi implements AuthApi {
  const ApiClientAuthApi();

  @override
  Future<Map<String, dynamic>> verifySmsCode(String phone, String code) {
    return ApiClient.verifySmsCode(phone, code);
  }

  @override
  Future<Map<String, dynamic>> getMe() {
    return ApiClient.getMe();
  }
}

class AuthService {
  AuthService({
    required EmailSignIn signInWithEmail,
    AuthApi api = const ApiClientAuthApi(),
  }) : _signInWithEmail = signInWithEmail,
       _api = api;

  final EmailSignIn _signInWithEmail;
  final AuthApi _api;

  Future<AuthSession> signIn(LoginSubmission submission) async {
    switch (submission.provider) {
      case LoginProvider.phone:
        return _signInWithPhone(
          phone: submission.phone ?? '',
          code: submission.code ?? '',
        );
      case LoginProvider.email:
        final AppUser user = await _signInWithEmail(submission);
        return AuthSession(user: user);
      case LoginProvider.apple:
      case LoginProvider.wechat:
        throw UnsupportedError('不支持的登录方式: ${submission.provider.name}');
    }
  }

  Future<AuthSession> _signInWithPhone({
    required String phone,
    required String code,
  }) async {
    final Map<String, dynamic> res = await _api.verifySmsCode(
      phone.trim(),
      code.trim(),
    );
    if (res['code'] != 0) {
      throw Exception(res['message'] ?? '登录失败');
    }

    final Map<String, dynamic> data = _asMap(res['data']);
    final String token = (data['token'] as String?) ?? '';
    if (token.isEmpty) {
      throw Exception('登录凭证无效');
    }

    Map<String, dynamic> userJson = _asMap(data['user']);
    if (userJson.isEmpty) {
      final Map<String, dynamic> meRes = await _api.getMe();
      if (meRes['code'] != 0) {
        throw Exception(meRes['message'] ?? '获取用户信息失败');
      }
      userJson = _asMap(meRes['data']);
    }

    return AuthSession(
      user: AppUser.fromJson(userJson),
      token: token,
      userJson: userJson,
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
