package com.speakeasy.identity.provider;

import com.speakeasy.common.ApiException;
import org.springframework.http.HttpStatus;

final class DisabledAuthProviders implements PhoneVerificationProvider, SocialIdentityVerifier {
  @Override
  public void requestCode(String phoneNumber) { throw unavailable(); }

  @Override
  public void verify(String phoneNumber, String verificationCode) { throw unavailable(); }

  @Override
  public VerifiedIdentity verify(String provider, String credential, String nonce) { throw unavailable(); }

  private ApiException unavailable() {
    return new ApiException(
        HttpStatus.SERVICE_UNAVAILABLE,
        "PROVIDER_UNAVAILABLE",
        "Authentication provider is not configured.");
  }
}
