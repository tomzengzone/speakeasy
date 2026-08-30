package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.verifyNoInteractions;

import com.speakeasy.common.ApiException;
import com.speakeasy.identity.AccountSecurityService;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.provider.PhoneVerificationProvider;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.HttpStatus;

abstract class AbstractAccountRecoveryCapabilityServiceGateTest
    extends BackendIntegrationTestSupport {
  @Autowired AuthService authService;
  @MockBean(name = "phoneVerificationProvider") PhoneVerificationProvider phoneVerification;
  @SpyBean AccountSecurityService accountSecurity;

  @Test
  void serviceRejectsRecoveryCodeRequestBeforeAnySideEffect() {
    RecoveryState before = existingAccountState("+8613800138692");
    clearInvocations(phoneVerification, accountSecurity);

    assertCapabilityUnavailable(() ->
        authService.requestPhoneAccountRecoveryCode("+8613800138692"));

    assertStateUnchanged(before);
    verifyNoInteractions(phoneVerification, accountSecurity);
  }

  @Test
  void serviceRejectsRecoveryCompletionBeforeAnySideEffect() {
    RecoveryState before = existingAccountState("+8613800138693");
    clearInvocations(phoneVerification, accountSecurity);

    assertCapabilityUnavailable(() -> authService.recoverPhoneAccount(
        "+8613800138693", "654321", "req-service-recovery-disabled"));

    assertStateUnchanged(before);
    verifyNoInteractions(phoneVerification, accountSecurity);
  }

  private RecoveryState existingAccountState(String phoneNumber) {
    AuthService.AuthSessionResult login = authService.loginPhone(phoneNumber, "123456", true);
    UUID userId = login.user().getUserId();
    return new RecoveryState(
        userId,
        login.sessionId(),
        users.count(),
        identities.count(),
        sessions.count(),
        auditLogs.count(),
        users.findById(userId).orElseThrow().getSecurityEpoch());
  }

  private void assertStateUnchanged(RecoveryState before) {
    assertThat(users.count()).isEqualTo(before.userCount());
    assertThat(identities.count()).isEqualTo(before.identityCount());
    assertThat(sessions.count()).isEqualTo(before.sessionCount());
    assertThat(auditLogs.count()).isEqualTo(before.auditCount());
    assertThat(users.findById(before.userId()).orElseThrow().getSecurityEpoch())
        .isEqualTo(before.securityEpoch());
    assertThat(sessions.findById(before.sessionId()).orElseThrow().isActive()).isTrue();
  }

  private static void assertCapabilityUnavailable(Runnable operation) {
    assertThatThrownBy(operation::run)
        .isInstanceOfSatisfying(ApiException.class, exception -> {
          assertThat(exception.getStatus()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
          assertThat(exception.getCode()).isEqualTo("AUTH_SERVICE_UNAVAILABLE");
          assertThat(exception.getDetails()).containsEntry("retryable", true);
        });
  }

  private record RecoveryState(
      UUID userId,
      UUID sessionId,
      long userCount,
      long identityCount,
      long sessionCount,
      long auditCount,
      long securityEpoch) {}
}
