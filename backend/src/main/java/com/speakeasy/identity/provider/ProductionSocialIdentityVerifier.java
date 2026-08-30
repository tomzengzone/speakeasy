package com.speakeasy.identity.provider;

import com.speakeasy.common.ApiException;
import org.springframework.http.HttpStatus;

final class ProductionSocialIdentityVerifier implements SocialIdentityVerifier {
  private final AppleIdentityVerifier apple;
  private final WechatIdentityVerifier wechat;

  ProductionSocialIdentityVerifier(AppleIdentityVerifier apple, WechatIdentityVerifier wechat) {
    this.apple = apple;
    this.wechat = wechat;
  }

  @Override
  public VerifiedIdentity verify(String provider, String credential, String nonce) {
    return switch (provider) {
      case "apple" -> apple.verify(credential, nonce);
      case "wechat" -> wechat.verify(credential);
      default -> throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Provider is unsupported.");
    };
  }
}
