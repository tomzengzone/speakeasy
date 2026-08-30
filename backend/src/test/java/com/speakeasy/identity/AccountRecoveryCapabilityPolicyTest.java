package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EmptySource;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;

class AccountRecoveryCapabilityPolicyTest {
  @ParameterizedTest
  @ValueSource(strings = {"true", " TRUE ", "TrUe"})
  void trimmedCaseInsensitiveExplicitTrueEnablesCapability(String configuredValue) {
    AccountRecoveryCapabilityPolicy policy =
        new AccountRecoveryCapabilityPolicy(configuredValue);

    assertThatCode(policy::requireEnabled).doesNotThrowAnyException();
  }

  @ParameterizedTest
  @NullSource
  @EmptySource
  @ValueSource(strings = {"false", "invalid", "1", "yes"})
  void everyNonTrueValueFailsClosed(String configuredValue) {
    AccountRecoveryCapabilityPolicy policy =
        new AccountRecoveryCapabilityPolicy(configuredValue);

    assertThatThrownBy(policy::requireEnabled)
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("AUTH_SERVICE_UNAVAILABLE");
  }
}
