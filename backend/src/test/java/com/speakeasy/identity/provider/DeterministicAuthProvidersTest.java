package com.speakeasy.identity.provider;

import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import org.junit.jupiter.api.Test;

class DeterministicAuthProvidersTest {
  @Test
  void recoveryCodeIsPurposeBoundAndConsumedAtMostOnce() {
    DeterministicAuthProviders provider = new DeterministicAuthProviders();
    String phone = "+8613800000002";

    provider.requestCode(phone, PhoneVerificationPurpose.ACCOUNT_RECOVERY);

    assertThatThrownBy(() -> provider.verify(
        phone, "123456", PhoneVerificationPurpose.ACCOUNT_RECOVERY))
        .isInstanceOf(ApiException.class);
    assertThatThrownBy(() -> provider.verify(
        phone, "654321", PhoneVerificationPurpose.LOGIN))
        .isInstanceOf(ApiException.class);

    provider.verify(phone, "654321", PhoneVerificationPurpose.ACCOUNT_RECOVERY);
    assertThatThrownBy(() -> provider.verify(
        phone, "654321", PhoneVerificationPurpose.ACCOUNT_RECOVERY))
        .isInstanceOf(ApiException.class);
    assertThatThrownBy(() -> provider.verify(
        phone, "654321", PhoneVerificationPurpose.LOGIN))
        .isInstanceOf(ApiException.class);
  }
}
