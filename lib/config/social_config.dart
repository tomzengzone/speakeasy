class SocialConfig {
  SocialConfig._();

  static const String _wechatAppIdPlaceholder = 'wx0000000000000000';
  static const String _wechatUniversalLinkPlaceholder =
      'https://your-domain.com/app/';

  static const String wechatAppId = String.fromEnvironment(
    'WECHAT_APP_ID',
    defaultValue: _wechatAppIdPlaceholder,
  );

  // iOS 需要配置已在微信开放平台登记并完成 Associated Domains 的 Universal Link。
  static const String wechatUniversalLink = String.fromEnvironment(
    'WECHAT_UNIVERSAL_LINK',
    defaultValue: _wechatUniversalLinkPlaceholder,
  );

  static const String wechatAuthScope = 'snsapi_userinfo';

  static bool get hasWechatAppId =>
      wechatAppId.trim().isNotEmpty &&
      wechatAppId.trim() != _wechatAppIdPlaceholder;

  static bool get hasWechatUniversalLink =>
      wechatUniversalLink.trim().isNotEmpty &&
      wechatUniversalLink.trim() != _wechatUniversalLinkPlaceholder;
}
