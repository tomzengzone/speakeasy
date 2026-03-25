import 'dart:async';
import 'dart:io';

import 'package:fluwx/fluwx.dart';
import 'package:http/http.dart' as http;

import '../api_client.dart';
import '../config/social_config.dart';

class WeChatAuthResult {
  const WeChatAuthResult({
    required this.code,
    required this.token,
    required this.userJson,
  });

  final String code;
  final String token;
  final Map<String, dynamic> userJson;
}

class WeChatAuthService {
  WeChatAuthService._();

  static final WeChatAuthService instance = WeChatAuthService._();

  final Fluwx _fluwx = Fluwx();

  FluwxCancelable? _subscriber;
  Completer<WeChatAuthResponse>? _pendingAuthCompleter;
  Future<void>? _initFuture;
  bool _isInitialized = false;

  Future<void> ensureInitialized() async {
    if (_isInitialized) {
      return;
    }
    if (_initFuture != null) {
      return _initFuture;
    }

    final Completer<void> completer = Completer<void>();
    _initFuture = completer.future;

    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        throw Exception('当前平台暂不支持微信登录');
      }
      if (!SocialConfig.hasWechatAppId) {
        throw Exception('请先在 lib/config/social_config.dart 配置真实微信 AppID');
      }
      if (Platform.isIOS && !SocialConfig.hasWechatUniversalLink) {
        throw Exception(
          'iOS 微信登录还需要配置 Universal Link，并在 Xcode 中开启 Associated Domains',
        );
      }

      _bindSubscriberIfNeeded();
      final bool registered = await _fluwx.registerApi(
        appId: SocialConfig.wechatAppId,
        doOnAndroid: Platform.isAndroid,
        doOnIOS: Platform.isIOS,
        universalLink: Platform.isIOS ? SocialConfig.wechatUniversalLink : null,
      );
      if (!registered) {
        throw Exception('微信 SDK 初始化失败，请检查 AppID、签名和 Universal Link 配置');
      }

      _isInitialized = true;
      completer.complete();
    } catch (error, stackTrace) {
      _initFuture = null;
      completer.completeError(error, stackTrace);
      rethrow;
    }
  }

  Future<WeChatAuthResult> sendWeChatAuth() async {
    await ensureInitialized();

    try {
      final bool isInstalled = await _fluwx.isWeChatInstalled;
      if (!isInstalled) {
        throw Exception('请先安装微信后再试');
      }

      if (_pendingAuthCompleter != null &&
          !(_pendingAuthCompleter?.isCompleted ?? true)) {
        throw Exception('微信登录请求正在处理中，请稍候');
      }

      final Completer<WeChatAuthResponse> completer =
          Completer<WeChatAuthResponse>();
      _pendingAuthCompleter = completer;

      final bool launched = await _fluwx.authBy(
        which: NormalAuth(
          scope: SocialConfig.wechatAuthScope,
          state: _buildState(),
        ),
      );
      if (!launched) {
        _pendingAuthCompleter = null;
        throw Exception('未能拉起微信，请稍后重试');
      }

      final WeChatAuthResponse response = await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('微信登录超时，请返回应用后重试');
        },
      );

      final String code = response.code?.trim() ?? '';
      if (code.isEmpty) {
        throw Exception('微信授权成功，但未拿到登录 code');
      }

      final Map<String, dynamic> res = await ApiClient.signInWithWeChat(
        code: code,
        state: response.state?.trim(),
      );
      if (res['code'] != 0) {
        throw Exception(res['message'] ?? '微信登录失败');
      }

      final Map<String, dynamic> data = _asMap(res['data']);
      final String token = (data['token'] as String?)?.trim() ?? '';
      if (token.isEmpty) {
        throw Exception('服务器未返回登录凭证');
      }

      return WeChatAuthResult(
        code: code,
        token: token,
        userJson: _asMap(data['user']),
      );
    } on SocketException {
      throw Exception('网络异常，请检查连接后重试');
    } on TimeoutException {
      throw Exception('网络请求超时，请稍后重试');
    } on http.ClientException {
      throw Exception('网络请求失败，请稍后重试');
    } finally {
      _pendingAuthCompleter = null;
    }
  }

  void _bindSubscriberIfNeeded() {
    if (_subscriber != null) {
      return;
    }

    _subscriber = _fluwx.addSubscriber((WeChatResponse response) {
      if (response is! WeChatAuthResponse) {
        return;
      }

      final Completer<WeChatAuthResponse>? completer = _pendingAuthCompleter;
      if (completer == null || completer.isCompleted) {
        return;
      }

      if (!response.isSuccessful) {
        completer.completeError(Exception(_messageFromAuthResponse(response)));
        return;
      }

      completer.complete(response);
    });
  }

  String _buildState() {
    return 'speakeasy_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _messageFromAuthResponse(WeChatAuthResponse response) {
    return switch (response.errCode) {
      -2 => '已取消微信登录',
      -4 => '微信授权被拒绝，请重试',
      _ =>
        (response.errStr?.trim().isNotEmpty ?? false)
            ? response.errStr!.trim()
            : '微信授权失败，请稍后重试',
    };
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
