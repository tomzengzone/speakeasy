package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public final class AccountRecoveryCapabilityPolicy {
  private final boolean enabled;

  public AccountRecoveryCapabilityPolicy(
      @Value("${speakeasy.auth.account-recovery-enabled:false}") String configuredValue) {
    this.enabled = configuredValue != null
        && "true".equalsIgnoreCase(configuredValue.trim());
  }

  public void requireEnabled() {
    if (!enabled) {
      throw new ApiException(
          HttpStatus.SERVICE_UNAVAILABLE,
          "AUTH_SERVICE_UNAVAILABLE",
          "Authentication service is temporarily unavailable.",
          Map.of("retryable", true));
    }
  }
}
