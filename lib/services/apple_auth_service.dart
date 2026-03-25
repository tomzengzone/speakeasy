import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:speakeasy/services/api_client.dart';

class AppleAuthResult {
  const AppleAuthResult({required this.token, required this.userJson});

  final String token;
  final Map<String, dynamic> userJson;
}

class AppleAuthService {
  const AppleAuthService();

  Future<AppleAuthResult> signInWithApple() async {
    // 接入前需在 Apple Developer / Xcode 中开启
    // Signing & Capabilities > Sign in with Apple，
    // 并保证 App ID、Bundle ID、Team ID 与后端校验配置一致。
    if (Platform.isAndroid || Platform.isLinux || Platform.isWindows) {
      throw Exception(
        '当前版本仅配置了 iOS / macOS 的 Apple 登录；如需 Android，请补充 Service ID 和 redirect URI。',
      );
    }

    try {
      final bool isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw Exception('当前设备暂不支持 Apple 登录');
      }

      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: const <AppleIDAuthorizationScopes>[
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

      final String authorizationCode = credential.authorizationCode.trim();
      final String identityToken = (credential.identityToken ?? '').trim();
      if (authorizationCode.isEmpty || identityToken.isEmpty) {
        throw Exception('Apple 登录凭证无效，请重试');
      }

      final Map<String, dynamic> res = await ApiClient.signInWithApple(
        authorizationCode: authorizationCode,
        identityToken: identityToken,
        userIdentifier: credential.userIdentifier,
        email: credential.email,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
      if (res['code'] != 0) {
        throw Exception(res['message'] ?? 'Apple 登录失败');
      }

      final Map<String, dynamic> data = _asMap(res['data']);
      final String token = (data['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) {
        throw Exception('服务器未返回登录凭证');
      }

      return AppleAuthResult(token: token, userJson: _asMap(data['user']));
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw Exception('已取消 Apple 登录');
      }
      throw Exception(
        error.message.trim().isEmpty ? 'Apple 登录失败，请稍后重试' : error.message,
      );
    } on SignInWithAppleNotSupportedException {
      throw Exception('当前设备暂不支持 Apple 登录');
    } on SocketException {
      throw Exception('网络异常，请检查连接后重试');
    } on TimeoutException {
      throw Exception('网络请求超时，请稍后重试');
    } on http.ClientException {
      throw Exception('网络请求失败，请稍后重试');
    }
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
