package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.reset;

import com.speakeasy.common.ApiException;
import com.speakeasy.identity.AccountSecurityService;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.AuthSessionRepository;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import io.micrometer.core.instrument.MeterRegistry;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountSecurityPhase3Test extends BackendIntegrationTestSupport {
  @Autowired AuthService authService;
  @Autowired AuthSessionRepository authSessions;
  @Autowired UserAccountRepository userAccounts;
  @Autowired AccountSecurityService accountSecurityService;
  @Autowired MeterRegistry meterRegistry;
  @Autowired JdbcTemplate jdbcTemplate;
  @SpyBean AuditLogRepository authAuditRepository;

  @Test
  void defaultTokenAndSessionLifetimesMatchTheApprovedPolicy() {
    AuthService.AuthSessionResult login = login("+8613800138098", "phone-a");
    var session = authSessions.findById(login.sessionId()).orElseThrow();

    assertThat(Duration.between(session.getCreatedAt(), session.getExpiresAt()))
        .isEqualTo(Duration.ofMinutes(15));
    assertThat(Duration.between(session.getCreatedAt(), session.getIdleExpiresAt()))
        .isEqualTo(Duration.ofDays(30));
    assertThat(Duration.between(session.getCreatedAt(), session.getAbsoluteExpiresAt()))
        .isEqualTo(Duration.ofDays(90));
  }

  @Test
  void expiredAccessAndRefreshTokensReturnStableCodes() {
    AuthService.AuthSessionResult accessLogin = login("+8613800138099", "phone-a");
    jdbcTemplate.update(
        "UPDATE auth_sessions SET expires_at = ? WHERE session_id = ?",
        Timestamp.from(Instant.EPOCH), accessLogin.sessionId());
    assertThat(authService.inspectAccessToken(accessLogin.accessToken()).code())
        .isEqualTo("ACCESS_TOKEN_EXPIRED");

    AuthService.AuthSessionResult refreshLogin = login("+8613800138199", "phone-b");
    jdbcTemplate.update(
        "UPDATE auth_refresh_tokens SET expires_at = ? WHERE session_id = ?",
        Timestamp.from(Instant.EPOCH), refreshLogin.sessionId());
    assertThatThrownBy(() -> authService.refresh(refreshLogin.refreshToken()))
        .isInstanceOfSatisfying(ApiException.class,
            exception -> assertThat(exception.getCode()).isEqualTo("REFRESH_TOKEN_EXPIRED"));
  }

  @Test
  void auditFailureRollsBackAccountDisableAndSessionRevocation() {
    AuthService.AuthSessionResult login = login("+8613800138198", "phone-a");
    doThrow(new DataIntegrityViolationException("simulated audit failure"))
        .when(authAuditRepository).saveAndFlush(any(AuditLog.class));

    try {
      assertThatThrownBy(() -> accountSecurityService.disableAccount(
              login.user().getUserId(), "ops:user-42", "suspected_compromise",
              "case-456", "request-audit-failure"))
          .isInstanceOf(DataIntegrityViolationException.class);
    } finally {
      reset(authAuditRepository);
    }

    assertThat(userAccounts.findById(login.user().getUserId()).orElseThrow().getAccountStatus())
        .isEqualTo("active");
    assertThat(authService.authenticateAccessToken(login.accessToken())).isPresent();
    assertThat(meterRegistry.find("speakeasy.auth.security.operation")
        .tag("operation", "audit_write").tag("outcome", "failure").counter().count())
        .isGreaterThanOrEqualTo(1);
    assertThat(meterRegistry.find("speakeasy.auth.security.operation")
        .tag("operation", "account_disable").tag("outcome", "failure").counter().count())
        .isGreaterThanOrEqualTo(1);
  }

  @Test
  void refreshRotationDetectsReuseAndRevokesTheWholeFamily() {
    AuthService.AuthSessionResult login = login("+8613800138100", "phone-a");
    AuthService.AuthSessionResult refreshed = authService.refresh(login.refreshToken());

    assertThatThrownBy(() -> authService.refresh(login.refreshToken()))
        .isInstanceOfSatisfying(ApiException.class,
            exception -> assertThat(exception.getCode()).isEqualTo("TOKEN_REUSE_DETECTED"));

    assertThat(authService.authenticateAccessToken(refreshed.accessToken())).isEmpty();
    assertThatThrownBy(() -> authService.refresh(refreshed.refreshToken()))
        .isInstanceOfSatisfying(ApiException.class,
            exception -> assertThat(exception.getCode()).isEqualTo("SESSION_REVOKED"));
    assertThat(meterRegistry.find("speakeasy.auth.refresh")
        .tag("outcome", "failure").tag("reason", "token_reuse").counter().count()).isGreaterThanOrEqualTo(1);
  }

  @Test
  void deviceSessionOperationsAreUserScopedAndPreserveCurrentSessionForLogoutOthers() {
    AuthService.AuthSessionResult first = login("+8613800138101", "phone-a");
    AuthService.AuthSessionResult second = login("+8613800138101", "tablet-b");
    AuthService.AuthSessionResult anotherUser = login("+8613800138102", "other-user");

    var listed = accountSecurityService.listSessions(first.user().getUserId(), first.sessionId());
    assertThat(listed).hasSize(2);
    assertThat(listed).filteredOn(AccountSecurityService.SessionView::current).hasSize(1);
    assertThat(listed).extracting(AccountSecurityService.SessionView::deviceName)
        .containsExactlyInAnyOrder("phone-a", "tablet-b");

    assertThatThrownBy(() -> accountSecurityService.revokeSession(
            first.user().getUserId(), first.sessionId(), anotherUser.sessionId(), "request-1"))
        .isInstanceOfSatisfying(ApiException.class,
            exception -> assertThat(exception.getCode()).isEqualTo("SESSION_NOT_FOUND"));

    assertThat(accountSecurityService.logoutOthers(
        first.user().getUserId(), first.sessionId(), "request-2")).isEqualTo(1);
    assertThat(authService.authenticateAccessToken(first.accessToken())).isPresent();
    assertThat(authService.authenticateAccessToken(second.accessToken())).isEmpty();
    assertThat(authService.authenticateAccessToken(anotherUser.accessToken())).isPresent();
  }

  @Test
  void logoutAllRevokesEverySessionAndIsIdempotent() {
    AuthService.AuthSessionResult first = login("+8613800138103", "phone-a");
    AuthService.AuthSessionResult second = login("+8613800138103", "tablet-b");

    assertThat(accountSecurityService.logoutAll(first.user().getUserId(), first.sessionId(), "request-3")).isEqualTo(2);
    assertThat(accountSecurityService.logoutAll(first.user().getUserId(), first.sessionId(), "request-4")).isZero();
    assertThat(authService.authenticateAccessToken(first.accessToken())).isEmpty();
    assertThat(authService.authenticateAccessToken(second.accessToken())).isEmpty();
  }

  @Test
  void disablingAccountAdvancesEpochAndOldSessionsNeverReturnAfterEnable() {
    AuthService.AuthSessionResult login = login("+8613800138104", "phone-a");
    UUID userId = login.user().getUserId();
    long initialEpoch = userAccounts.findById(userId).orElseThrow().getSecurityEpoch();

    AccountSecurityService.AccountStatusChange disabled = accountSecurityService.disableAccount(
        userId, "ops:user-42", "suspected_compromise", "case-123", "request-5");

    assertThat(disabled.accountStatus()).isEqualTo("disabled");
    assertThat(disabled.revokedSessionCount()).isEqualTo(1);
    assertThat(userAccounts.findById(userId).orElseThrow().getSecurityEpoch()).isEqualTo(initialEpoch + 1);
    assertThat(authService.inspectAccessToken(login.accessToken()).code()).isEqualTo("ACCOUNT_DISABLED");

    accountSecurityService.enableAccount(userId, "ops:user-42", "review_complete", "case-123", "request-6");

    assertThat(authService.inspectAccessToken(login.accessToken()).code()).isEqualTo("SESSION_REVOKED");
  }

  @Test
  void highRiskCredentialChangeAdvancesEpochAndRevokesAllSessions() {
    AuthService.AuthSessionResult login = login("+8613800138105", "phone-a");

    int revoked = accountSecurityService.revokeForHighRiskCredentialChange(
        login.user().getUserId(), "account_recovery", "request-7");

    assertThat(revoked).isEqualTo(1);
    assertThat(authService.inspectAccessToken(login.accessToken()).code()).isEqualTo("SESSION_REVOKED");
  }

  @Test
  void concurrentRefreshAndLogoutCannotReactivateARevokedSession() throws Exception {
    AuthService.AuthSessionResult login = login("+8613800138106", "phone-a");
    CountDownLatch start = new CountDownLatch(1);
    var executor = Executors.newFixedThreadPool(2);
    try {
      var refresh = executor.submit(() -> {
        start.await();
        try {
          return authService.refresh(login.refreshToken());
        } catch (ApiException expectedRaceOutcome) {
          return null;
        }
      });
      var logout = executor.submit(() -> {
        start.await();
        accountSecurityService.logoutCurrent(login.user().getUserId(), login.sessionId(), "concurrent-logout");
        return null;
      });
      start.countDown();
      AuthService.AuthSessionResult refreshed = refresh.get(10, TimeUnit.SECONDS);
      logout.get(10, TimeUnit.SECONDS);

      assertThat(authService.authenticateAccessToken(login.accessToken())).isEmpty();
      if (refreshed != null) assertThat(authService.authenticateAccessToken(refreshed.accessToken())).isEmpty();
    } finally {
      executor.shutdownNow();
    }
  }

  @Test
  void concurrentAccessInspectionAndLogoutCannotReactivateARevokedSession() throws Exception {
    AuthService.AuthSessionResult login = login("+8613800138197", "phone-a");
    CountDownLatch start = new CountDownLatch(1);
    var executor = Executors.newFixedThreadPool(2);
    try {
      var accessInspection = executor.submit(() -> {
        start.await();
        return authService.inspectAccessToken(login.accessToken()).code();
      });
      var logout = executor.submit(() -> {
        start.await();
        accountSecurityService.logoutCurrent(
            login.user().getUserId(), login.sessionId(), "concurrent-access-logout");
        return null;
      });
      start.countDown();
      accessInspection.get(10, TimeUnit.SECONDS);
      logout.get(10, TimeUnit.SECONDS);

      assertThat(authService.inspectAccessToken(login.accessToken()).code()).isEqualTo("SESSION_REVOKED");
      assertThat(authSessions.findById(login.sessionId()).orElseThrow().isActive()).isFalse();
    } finally {
      executor.shutdownNow();
    }
  }

  @Test
  void concurrentUseOfOneRefreshTokenDetectsReuseAndRevokesIssuedSuccessor() throws Exception {
    AuthService.AuthSessionResult login = login("+8613800138107", "phone-a");
    CountDownLatch start = new CountDownLatch(1);
    var executor = Executors.newFixedThreadPool(2);
    try {
      var first = executor.submit(() -> refreshAfter(start, login.refreshToken()));
      var second = executor.submit(() -> refreshAfter(start, login.refreshToken()));
      start.countDown();

      Object firstResult = first.get(10, TimeUnit.SECONDS);
      Object secondResult = second.get(10, TimeUnit.SECONDS);
      assertThat(java.util.List.of(firstResult, secondResult))
          .filteredOn(AuthService.AuthSessionResult.class::isInstance).hasSize(1);
      assertThat(java.util.List.of(firstResult, secondResult))
          .filteredOn(result -> "TOKEN_REUSE_DETECTED".equals(result)).hasSize(1);
      AuthService.AuthSessionResult issued = (AuthService.AuthSessionResult) java.util.List.of(firstResult, secondResult).stream()
          .filter(AuthService.AuthSessionResult.class::isInstance).findFirst().orElseThrow();
      assertThat(authService.authenticateAccessToken(issued.accessToken())).isEmpty();
    } finally {
      executor.shutdownNow();
    }
  }

  private Object refreshAfter(CountDownLatch start, String refreshToken) throws InterruptedException {
    start.await();
    try {
      return authService.refresh(refreshToken);
    } catch (ApiException exception) {
      return exception.getCode();
    }
  }

  private AuthService.AuthSessionResult login(String phoneNumber, String deviceName) {
    return authService.loginPhone(
        phoneNumber,
        "123456",
        true,
        new AuthService.DeviceMetadata(UUID.randomUUID().toString(), deviceName, "android", "3.0.0"));
  }
}
