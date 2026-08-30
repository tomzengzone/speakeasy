package com.speakeasy.identity.provider;

import com.speakeasy.common.ApiException;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.http.HttpStatus;

final class DeterministicAuthProviders implements PhoneVerificationProvider, SocialIdentityVerifier {
  private static final String RECOVERY_CODE = "654321";
  private final Set<String> issuedRecoveryPhones = ConcurrentHashMap.newKeySet();
  private final Set<String> recoveryCodePhonesEverIssued = ConcurrentHashMap.newKeySet();

  @Override
  public void requestCode(String phoneNumber, PhoneVerificationPurpose purpose) {
    require(phoneNumber, "Phone number is required.");
    if (purpose == PhoneVerificationPurpose.ACCOUNT_RECOVERY) {
      String normalizedPhone = phoneNumber.trim();
      issuedRecoveryPhones.add(normalizedPhone);
      recoveryCodePhonesEverIssued.add(normalizedPhone);
    }
  }

  @Override
  public void verify(
      String phoneNumber, String verificationCode, PhoneVerificationPurpose purpose) {
    require(phoneNumber, "Phone number is required.");
    if (verificationCode == null || !verificationCode.matches("[0-9]{6}")) {
      throw unauthenticated("Verification code is invalid.");
    }
    String normalizedPhone = phoneNumber.trim();
    if (purpose == PhoneVerificationPurpose.ACCOUNT_RECOVERY) {
      if (!RECOVERY_CODE.equals(verificationCode)
          || !issuedRecoveryPhones.remove(normalizedPhone)) {
        throw unauthenticated("Verification code is invalid.");
      }
      return;
    }
    if (RECOVERY_CODE.equals(verificationCode)
        && recoveryCodePhonesEverIssued.contains(normalizedPhone)) {
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
