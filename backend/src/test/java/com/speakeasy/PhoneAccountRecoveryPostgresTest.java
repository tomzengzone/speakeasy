package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.reset;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.Subscription;
import com.speakeasy.commerce.SubscriptionPlan;
import com.speakeasy.common.ApiException;
import com.speakeasy.content.UserScenarioState;
import com.speakeasy.identity.AuthIdentityRepository;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.AuthSessionRepository;
import com.speakeasy.ops.AuthAuditService;
import com.speakeasy.security.TokenHasher;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@SpringBootTest(properties = "speakeasy.auth.account-recovery-enabled=true")
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class PhoneAccountRecoveryPostgresTest extends BackendIntegrationTestSupport {
  @Container
  static final PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:15")
      .withDatabaseName("speakeasy_recovery_test")
      .withUsername("speakeasy")
      .withPassword("speakeasy");

  @DynamicPropertySource
  static void postgresProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", postgres::getJdbcUrl);
    registry.add("spring.datasource.username", postgres::getUsername);
    registry.add("spring.datasource.password", postgres::getPassword);
    registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
  }

  @Autowired AuthService authService;
  @Autowired JdbcTemplate jdbc;
  @SpyBean AuthAuditService audit;
  @SpyBean AuthIdentityRepository identityLookup;
  @SpyBean AuthSessionRepository sessionPersistence;

  @Test
  void recoveryAtomicallyRevokesPersistentAuthRowsAndPreservesAccountFactsOnPostgres()
      throws Exception {
    String phone = "+8613800138695";
    AuthService.AuthSessionResult first = authService.loginPhone(phone, "123456", true);
    AuthService.AuthSessionResult second = authService.loginPhone(phone, "123456", true);
    UUID userId = first.user().getUserId();
    seedLearningAndSubscriptionFacts(userId);
    long epochBefore = users.findById(userId).orElseThrow().getSecurityEpoch();
    BusinessFacts factsBefore = businessFacts(userId);

    assertPersistentAuthState(userId, "active", "active", "active", "active", 2);
    authService.requestPhoneAccountRecoveryCode(phone);
    mvc.perform(post("/auth/account-recovery/phone")
            .header("X-Request-Id", "req-recovery-postgres")
            .contentType(MediaType.APPLICATION_JSON)
            .content(recoveryBody(phone)))
        .andExpect(status().isOk())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "no-store"))
        .andExpect(header().string("X-Request-Id", "req-recovery-postgres"))
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.status").value("recovered"))
        .andExpect(jsonPath("$.next_action").value("login_phone"))
        .andExpect(jsonPath("$.user").doesNotExist())
        .andExpect(jsonPath("$.session_id").doesNotExist())
        .andExpect(jsonPath("$.access_token").doesNotExist())
        .andExpect(jsonPath("$.refresh_token").doesNotExist())
        .andExpect(jsonPath("$.revoked_session_count").doesNotExist());

    assertThat(users.findById(userId).orElseThrow().getSecurityEpoch())
        .isEqualTo(epochBefore + 1);
    assertPersistentAuthState(userId, "revoked", "revoked", "revoked", "active", 2);
    assertThat(businessFacts(userId)).isEqualTo(factsBefore);
    assertThat(authService.inspectAccessToken(first.accessToken()).code()).isEqualTo("SESSION_REVOKED");
    assertThat(authService.inspectAccessToken(second.accessToken()).code()).isEqualTo("SESSION_REVOKED");
    assertRefreshRevoked(first.refreshToken());
    assertRefreshRevoked(second.refreshToken());

    List<com.speakeasy.ops.AuditLog> recoveryAudits = auditLogs.findAll().stream()
        .filter(log -> "auth_sessions_revoked_credential_change".equals(log.getEventType()))
        .toList();
    assertThat(recoveryAudits).hasSize(1);
    assertThat(recoveryAudits.get(0).getRedactedDetails())
        .doesNotContain(phone, "654321", first.accessToken(), first.refreshToken(),
            second.accessToken(), second.refreshToken());
  }

  @Test
  void auditFailureRollsBackEveryPersistentRowAndAnewCodeCanRetryOnPostgres() {
    String phone = "+8613800138696";
    AuthService.AuthSessionResult login = authService.loginPhone(phone, "123456", true);
    UUID userId = login.user().getUserId();
    seedLearningAndSubscriptionFacts(userId);
    RecoverySnapshot before = recoverySnapshot(userId);
    authService.requestPhoneAccountRecoveryCode(phone);
    doThrow(new IllegalStateException("audit store unavailable"))
        .when(audit)
        .recordSystemEvent(
            eq("auth_sessions_revoked_credential_change"),
            any(UUID.class),
            isNull(),
            eq("account_recovery"),
            anyInt(),
            eq("req-recovery-postgres-rollback"));

    assertThatThrownBy(() -> authService.recoverPhoneAccount(
            phone, "654321", "req-recovery-postgres-rollback"))
        .isInstanceOf(IllegalStateException.class);

    assertThat(recoverySnapshot(userId)).isEqualTo(before);
    assertConsumedCodeCannotReplay(phone);
    reset(audit);
    retryWithNewCode(phone, userId, before.securityEpoch());
  }

  @Test
  void identityResolutionFailureRollsBackAndAnewCodeCanRetryOnPostgres() {
    String phone = "+8613800138697";
    AuthService.AuthSessionResult login = authService.loginPhone(phone, "123456", true);
    UUID userId = login.user().getUserId();
    seedLearningAndSubscriptionFacts(userId);
    RecoverySnapshot before = recoverySnapshot(userId);
    authService.requestPhoneAccountRecoveryCode(phone);
    doThrow(new DataAccessResourceFailureException("identity lookup unavailable"))
        .when(identityLookup)
        .findByProviderAndProviderSubject("phone", TokenHasher.hash(phone));

    assertThatThrownBy(() -> authService.recoverPhoneAccount(
            phone, "654321", "req-recovery-identity-rollback"))
        .isInstanceOf(DataAccessResourceFailureException.class);

    assertThat(recoverySnapshot(userId)).isEqualTo(before);
    reset(identityLookup);
    assertConsumedCodeCannotReplay(phone);
    retryWithNewCode(phone, userId, before.securityEpoch());
  }

  @Test
  void sessionPersistenceFailureRollsBackAndAnewCodeCanRetryOnPostgres() {
    String phone = "+8613800138698";
    AuthService.AuthSessionResult login = authService.loginPhone(phone, "123456", true);
    UUID userId = login.user().getUserId();
    seedLearningAndSubscriptionFacts(userId);
    RecoverySnapshot before = recoverySnapshot(userId);
    authService.requestPhoneAccountRecoveryCode(phone);
    doThrow(new DataAccessResourceFailureException("session persistence unavailable"))
        .when(sessionPersistence)
        .findByUserIdForUpdate(userId);

    assertThatThrownBy(() -> authService.recoverPhoneAccount(
            phone, "654321", "req-recovery-session-rollback"))
        .isInstanceOf(DataAccessResourceFailureException.class);

    reset(sessionPersistence);
    assertThat(recoverySnapshot(userId)).isEqualTo(before);
    assertConsumedCodeCannotReplay(phone);
    retryWithNewCode(phone, userId, before.securityEpoch());
  }

  private void seedLearningAndSubscriptionFacts(UUID userId) {
    Instant now = Instant.parse("2026-08-30T00:00:00Z");
    userScenarioStates.save(new UserScenarioState(
        UUID.randomUUID(), userId, "job_interview", "A2", now));
    UUID planId = UUID.randomUUID();
    UUID subscriptionId = UUID.randomUUID();
    plans.save(new SubscriptionPlan(
        planId, "apple", "recovery-test-" + planId, "monthly"));
    subscriptions.save(new Subscription(subscriptionId, userId, planId, "apple"));
    entitlements.save(new EntitlementSnapshot(
        UUID.randomUUID(), userId, subscriptionId, "premium",
        "{\"tts\":true}", "{\"ai\":100}", "active", now.plusSeconds(86400), now));
  }

  private void assertPersistentAuthState(
      UUID userId,
      String sessionStatus,
      String familyStatus,
      String refreshStatus,
      String accessStatus,
      int expectedRows) {
    assertThat(statuses("auth_sessions", userId)).containsOnly(sessionStatus).hasSize(expectedRows);
    assertThat(statuses("auth_refresh_token_families", userId))
        .containsOnly(familyStatus)
        .hasSize(expectedRows);
    assertThat(statuses("auth_refresh_tokens", userId))
        .containsOnly(refreshStatus)
        .hasSize(expectedRows);
    // Access-token rows are intentionally retained; session + epoch checks invalidate them.
    assertThat(statuses("auth_access_tokens", userId))
        .containsOnly(accessStatus)
        .hasSize(expectedRows);
  }

  private List<String> statuses(String table, UUID userId) {
    return jdbc.queryForList(
        "SELECT status FROM " + table + " WHERE user_id = ? ORDER BY status",
        String.class,
        userId);
  }

  private BusinessFacts businessFacts(UUID userId) {
    return new BusinessFacts(
        rows("SELECT auth_identity_id, user_id, provider, provider_subject, linked_at, status "
            + "FROM auth_identities WHERE user_id = ? ORDER BY auth_identity_id", userId),
        rows("SELECT user_id, nickname, target_level, daily_minutes, reminder_enabled, "
            + "reminder_time, theme, updated_at FROM user_profiles WHERE user_id = ?", userId),
        rows("SELECT user_scenario_state_id, user_id, scenario_id, state, current_flag, "
            + "target_level, joined_at, updated_at FROM user_scenario_states WHERE user_id = ? "
            + "ORDER BY user_scenario_state_id", userId),
        rows("SELECT subscription_id, user_id, plan_id, platform, status, starts_at, expires_at, "
            + "grace_until, latest_purchase_id FROM subscriptions WHERE user_id = ? "
            + "ORDER BY subscription_id", userId),
        rows("SELECT entitlement_snapshot_id, user_id, source_subscription_id, plan, "
            + "feature_flags, quota_limits, status, valid_until, generated_at "
            + "FROM entitlement_snapshots WHERE user_id = ? ORDER BY entitlement_snapshot_id", userId));
  }

  private RecoverySnapshot recoverySnapshot(UUID userId) {
    return new RecoverySnapshot(
        users.findById(userId).orElseThrow().getSecurityEpoch(),
        businessFacts(userId),
        rows("SELECT session_id, user_id, refresh_token_family_id, status, security_epoch, "
            + "revoked_at, revoked_reason_code FROM auth_sessions WHERE user_id = ? ORDER BY session_id", userId),
        rows("SELECT family_id, session_id, user_id, status, revoked_at, revoked_reason_code "
            + "FROM auth_refresh_token_families WHERE user_id = ? ORDER BY family_id", userId),
        rows("SELECT token_id, family_id, session_id, user_id, status, used_at, revoked_at "
            + "FROM auth_refresh_tokens WHERE user_id = ? ORDER BY token_id", userId),
        rows("SELECT token_id, session_id, user_id, status, revoked_at "
            + "FROM auth_access_tokens WHERE user_id = ? ORDER BY token_id", userId),
        rows("SELECT audit_log_id, event_type, target_ref, redacted_details, request_id "
            + "FROM audit_logs ORDER BY audit_log_id", null));
  }

  private List<Map<String, Object>> rows(String sql, UUID userId) {
    return userId == null ? jdbc.queryForList(sql) : jdbc.queryForList(sql, userId);
  }

  private void assertConsumedCodeCannotReplay(String phone) {
    assertThatThrownBy(() -> authService.recoverPhoneAccount(
            phone, "654321", "req-recovery-consumed-replay"))
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("ACCOUNT_RECOVERY_VERIFICATION_FAILED");
  }

  private void retryWithNewCode(String phone, UUID userId, long epochBefore) {
    authService.requestPhoneAccountRecoveryCode(phone);
    authService.recoverPhoneAccount(phone, "654321", "req-recovery-new-code-retry");
    assertThat(users.findById(userId).orElseThrow().getSecurityEpoch()).isEqualTo(epochBefore + 1);
    assertPersistentAuthState(userId, "revoked", "revoked", "revoked", "active", 1);
    assertThat(auditLogs.countByEventType("auth_sessions_revoked_credential_change")).isEqualTo(1);
  }

  private void assertRefreshRevoked(String refreshToken) {
    assertThatThrownBy(() -> authService.refresh(refreshToken))
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("SESSION_REVOKED");
  }

  private String recoveryBody(String phone) {
    return """
        {
          "schema_version": 1,
          "phone_number": "%s",
          "verification_code": "654321",
          "device_id": "install-recovery-postgres"
        }
        """.formatted(phone);
  }

  private record BusinessFacts(
      List<Map<String, Object>> identities,
      List<Map<String, Object>> profiles,
      List<Map<String, Object>> learning,
      List<Map<String, Object>> subscriptions,
      List<Map<String, Object>> entitlements) {}

  private record RecoverySnapshot(
      long securityEpoch,
      BusinessFacts businessFacts,
      List<Map<String, Object>> sessions,
      List<Map<String, Object>> families,
      List<Map<String, Object>> refreshTokens,
      List<Map<String, Object>> accessTokens,
      List<Map<String, Object>> audits) {}
}
