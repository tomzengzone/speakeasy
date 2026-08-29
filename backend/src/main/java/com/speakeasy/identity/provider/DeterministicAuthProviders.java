package com.speakeasy.identity.provider;

import com.speakeasy.common.ApiException;
import org.springframework.http.HttpStatus;

final class DeterministicAuthProviders implements PhoneVerificationProvider, SocialIdentityVerifier {
  @Override
  public void requestCode(String phoneNumber) {
    require(phoneNumber, "Phone number is required.");
  }

  @Override
  public void verify(String phoneNumber, String verificationCode) {
    require(phoneNumber, "Phone number is required.");
    if (verificationCode == null || !verificationCode.matches("[0-9]{6}")) {
      throw unauthenticated("Verification code is invalid.");
    }
  }

  @Override
  public VerifiedIdentity verify(String provider, String credential, String nonce) {
    require(provider, "Provider is required.");
    require(credential, "Provider credential is required.");
    return new VerifiedIdentity(credential.trim());
  }

  private void require(String value, String message) {
    if (value == null || value.isBlank()) throw unauthenticated(message);
  }

  private ApiException unauthenticated(String message) {
    return new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", message);
  }
}
