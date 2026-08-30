package com.speakeasy;

import static org.hamcrest.Matchers.containsString;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.common.ApiException;
import com.speakeasy.identity.AuthIdentityRepository;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserProfile;
import com.speakeasy.ops.AuthAuditService;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.auth.account-recovery-enabled=true")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PhoneAccountRecoveryTest extends BackendIntegrationTestSupport {
  @Autowired AuthService authService;
  @SpyBean AuthAuditService audit;
  @SpyBean AuthIdentityRepository identityLookup;

  @Test
  void requestCodePrivacyUsesOneAccountBlindPathForBoundUnboundAndMissingPhones()
      throws Exception {
    String boundPhone = "+8613800138650";
    String unboundPhone = "+8613800138651";
    String missingPhone = "+8613800138652";
    loginPhone(boundPhone);
    UUID unboundUserId = UUID.randomUUID();
    Instant now = Instant.parse("2026-08-30T00:00:00Z");
    users.save(new UserAccount(unboundUserId, "Recovery Unbound User", now));
    profiles.save(new UserProfile(unboundUserId, "Recovery Unbound User", "A2", 20, now));
    long usersBefore = users.count();
    long identitiesBefore = identities.count();
    long sessionsBefore = sessions.count();
    long auditsBefore = auditLogs.count();
    clearInvocations(identityLookup);

    MvcResult bound = requestRecoveryCode(boundPhone, "req-recovery-privacy-bound")
        .andExpect(status().isAccepted())
        .andReturn();
    MvcResult unbound = requestRecoveryCode(unboundPhone, "req-recovery-privacy-unbound")
        .andExpect(status().isAccepted())
        .andReturn();
    MvcResult missing = requestRecoveryCode(missingPhone, "req-recovery-privacy-missing")
        .andExpect(status().isAccepted())
        .andReturn();

    assertAcceptedRecoveryCodeResponse(bound, "req-recovery-privacy-bound");
    assertAcceptedRecoveryCodeResponse(unbound, "req-recovery-privacy-unbound");
    assertAcceptedRecoveryCodeResponse(missing, "req-recovery-privacy-missing");
    assertThat(unbound.getResponse().getContentAsString())
        .isEqualTo(bound.getResponse().getContentAsString());
    assertThat(missing.getResponse().getContentAsString())
        .isEqualTo(bound.getResponse().getContentAsString());

    // Deterministic timing-path evidence: code issuance never branches through account lookup.
    verify(identityLookup, never()).findByProviderAndProviderSubject(anyString(), anyString());
    assertThat(users.count()).isEqualTo(usersBefore);
    assertThat(identities.count()).isEqualTo(identitiesBefore);
    assertThat(sessions.count()).isEqualTo(sessionsBefore);
    assertThat(auditLogs.count()).isEqualTo(auditsBefore);
  }

  @Test
  void recoveryPreservesTheAccountRevokesEverySessionAndIssuesNoSession() throws Exception {
    String phone = "+8613800138600";
    AuthTokens first = loginPhone(phone);
    AuthTokens second = loginPhone(phone);
    long usersBefore = users.count();

    requestRecoveryCode(phone)
        .andExpect(status().isAccepted())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, containsString("no-store")))
        .andExpect(header().string("X-Request-Id", "req-recovery-code"))
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.status").value("accepted"));

    mvc.perform(post("/auth/account-recovery/phone")
            .header("X-Request-Id", "req-recovery-complete")
            .contentType(MediaType.APPLICATION_JSON)
            .content(recoveryBody(phone, "654321")))
        .andExpect(status().isOk())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "no-store"))
        .andExpect(header().string("X-Request-Id", "req-recovery-complete"))
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.status").value("recovered"))
        .andExpect(jsonPath("$.next_action").value("login_phone"))
        .andExpect(jsonPath("$.user").doesNotExist())
        .andExpect(jsonPath("$.session_id").doesNotExist())
        .andExpect(jsonPath("$.access_token").doesNotExist())
        .andExpect(jsonPath("$.refresh_token").doesNotExist())
        .andExpect(jsonPath("$.revoked_session_count").doesNotExist());

    assertSessionRevoked(first);
    assertSessionRevoked(second);
    AuthTokens relogin = loginPhone(phone);
    org.assertj.core.api.Assertions.assertThat(relogin.userId()).isEqualTo(first.userId());
    org.assertj.core.api.Assertions.assertThat(users.count()).isEqualTo(usersBefore);
  }

  @Test
  void nonexistentAccountAndInvalidOrReplayedCodesHaveOnePrivacySafeFailureAndNoSideEffects() throws Exception {
    String missingPhone = "+8613800138601";
    long usersBefore = users.count();
    long sessionsBefore = sessions.count();
    requestRecoveryCode(missingPhone).andExpect(status().isAccepted());

    assertRecoveryFailed(missingPhone, "654321");
    org.assertj.core.api.Assertions.assertThat(users.count()).isEqualTo(usersBefore);
    org.assertj.core.api.Assertions.assertThat(sessions.count()).isEqualTo(sessionsBefore);

    String existingPhone = "+8613800138602";
    AuthTokens existing = loginPhone(existingPhone);
    requestRecoveryCode(existingPhone).andExpect(status().isAccepted());
    assertRecoveryFailed(existingPhone, "123456");
    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(existing.accessToken())))
        .andExpect(status().isOk());

    requestRecoveryCode(existingPhone).andExpect(status().isAccepted());
    mvc.perform(post("/auth/account-recovery/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content(recoveryBody(existingPhone, "654321")))
        .andExpect(status().isOk());
    assertRecoveryFailed(existingPhone, "654321");
    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "%s",
                  "verification_code": "654321",
                  "terms_accepted": true
                }
                """.formatted(existingPhone)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void differentIdempotencyKeysCannotReplayAConsumedRecoveryCode() throws Exception {
    String phone = "+8613800138653";
    AuthTokens existing = loginPhone(phone);
    requestRecoveryCode(phone).andExpect(status().isAccepted());

    mvc.perform(post("/auth/account-recovery/phone")
            .header("X-Request-Id", "req-recovery-idempotency-first")
            .header("Idempotency-Key", "recovery-key-a")
            .contentType(MediaType.APPLICATION_JSON)
            .content(recoveryBody(phone, "654321")))
        .andExpect(status().isOk());
    long epochAfterSuccess = users.findById(UUID.fromString(existing.userId()))
        .orElseThrow()
        .getSecurityEpoch();
    long auditsAfterSuccess = auditLogs.countByEventType(
        "auth_sessions_revoked_credential_change");

    assertRecoveryFailed(phone, "654321", "recovery-key-a");
    assertRecoveryFailed(phone, "654321", "recovery-key-b");

    assertThat(users.findById(UUID.fromString(existing.userId())).orElseThrow().getSecurityEpoch())
        .isEqualTo(epochAfterSuccess);
    assertThat(auditLogs.countByEventType("auth_sessions_revoked_credential_change"))
        .isEqualTo(auditsAfterSuccess)
        .isEqualTo(1);
  }

  @Test
  void recoveryAndLoginCodesCannotCrossPurposes() throws Exception {
    String phone = "+8613800138603";
    loginPhone(phone);
    requestRecoveryCode(phone).andExpect(status().isAccepted());

    assertRecoveryFailed(phone, "123456");
    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "%s",
                  "verification_code": "654321",
                  "terms_accepted": true
                }
                """.formatted(phone)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void malformedRecoveryRequestUsesTheContractedBadRequest() throws Exception {
    mvc.perform(post("/auth/account-recovery/phone")
            .header("X-Request-Id", "req-recovery-invalid")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "",
                  "verification_code": ""
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, containsString("no-store")))
        .andExpect(header().string("X-Request-Id", "req-recovery-invalid"))
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  @Test
  void databaseFailureRollsBackEpochAndSessionRevocationAfterCodeConsumption() {
    String phone = "+8613800138604";
    AuthService.AuthSessionResult login = authService.loginPhone(phone, "123456", true);
    long securityEpoch = users.findById(login.user().getUserId()).orElseThrow().getSecurityEpoch();
    authService.requestPhoneAccountRecoveryCode(phone);
    org.mockito.Mockito.doThrow(new IllegalStateException("audit store unavailable"))
        .when(audit)
        .recordSystemEvent(
            org.mockito.ArgumentMatchers.eq("auth_sessions_revoked_credential_change"),
            org.mockito.ArgumentMatchers.any(UUID.class),
            org.mockito.ArgumentMatchers.isNull(),
            org.mockito.ArgumentMatchers.eq("account_recovery"),
            org.mockito.ArgumentMatchers.anyInt(),
            org.mockito.ArgumentMatchers.eq("req-recovery-rollback"));

    org.assertj.core.api.Assertions.assertThatThrownBy(() -> authService.recoverPhoneAccount(
            phone, "654321", "req-recovery-rollback"))
        .isInstanceOf(IllegalStateException.class);

    org.assertj.core.api.Assertions.assertThat(
        users.findById(login.user().getUserId()).orElseThrow().getSecurityEpoch())
        .isEqualTo(securityEpoch);
    org.assertj.core.api.Assertions.assertThat(
        sessions.findById(login.sessionId()).orElseThrow().isActive()).isTrue();
    org.assertj.core.api.Assertions.assertThat(
        authService.inspectAccessToken(login.accessToken()).currentUser()).isNotNull();
    org.assertj.core.api.Assertions.assertThatThrownBy(() -> authService.recoverPhoneAccount(
            phone, "654321", "req-recovery-replay"))
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("ACCOUNT_RECOVERY_VERIFICATION_FAILED");

    org.mockito.Mockito.reset(audit);
    authService.requestPhoneAccountRecoveryCode(phone);
    authService.recoverPhoneAccount(phone, "654321", "req-recovery-retry");
    assertThat(users.findById(login.user().getUserId()).orElseThrow().getSecurityEpoch())
        .isEqualTo(securityEpoch + 1);
    assertThat(sessions.findById(login.sessionId()).orElseThrow().isActive()).isFalse();
  }

  private org.springframework.test.web.servlet.ResultActions requestRecoveryCode(String phone) throws Exception {
    return requestRecoveryCode(phone, "req-recovery-code");
  }

  private org.springframework.test.web.servlet.ResultActions requestRecoveryCode(
      String phone, String requestId) throws Exception {
    return mvc.perform(post("/auth/account-recovery/phone/verification-codes")
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "phone_number": "%s",
              "device_id": "install-recovery-test"
            }
            """.formatted(phone)));
  }

  private void assertRecoveryFailed(String phone, String code) throws Exception {
    assertRecoveryFailed(phone, code, null);
  }

  private void assertRecoveryFailed(String phone, String code, String idempotencyKey)
      throws Exception {
    var request = post("/auth/account-recovery/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content(recoveryBody(phone, code));
    if (idempotencyKey != null) request.header("Idempotency-Key", idempotencyKey);
    mvc.perform(request)
        .andExpect(status().isUnauthorized())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, containsString("no-store")))
        .andExpect(jsonPath("$.error.code").value("ACCOUNT_RECOVERY_VERIFICATION_FAILED"))
        .andExpect(jsonPath("$.error.message").value("Account recovery could not be verified."))
        .andExpect(jsonPath("$.error.details").isEmpty());
  }

  private void assertAcceptedRecoveryCodeResponse(MvcResult result, String requestId)
      throws Exception {
    assertThat(result.getResponse().getHeader(HttpHeaders.CACHE_CONTROL)).contains("no-store");
    assertThat(result.getResponse().getHeader("X-Request-Id")).isEqualTo(requestId);
    assertThat(JsonPath.<Integer>read(result.getResponse().getContentAsString(), "$.schema_version"))
        .isEqualTo(1);
    assertThat(JsonPath.<String>read(result.getResponse().getContentAsString(), "$.status"))
        .isEqualTo("accepted");
    assertThat(result.getResponse().getContentAsString())
        .doesNotContain("user", "identity", "session", "token", "phone");
  }

  private void assertSessionRevoked(AuthTokens tokens) throws Exception {
    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("SESSION_REVOKED"));
    mvc.perform(post("/auth/refresh")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "refresh_token": "%s"
                }
                """.formatted(tokens.refreshToken())))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("SESSION_REVOKED"));
  }

  private String recoveryBody(String phone, String code) {
    return """
        {
          "schema_version": 1,
          "phone_number": "%s",
          "verification_code": "%s",
          "device_id": "install-recovery-test"
        }
        """.formatted(phone, code);
  }
}
