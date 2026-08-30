package com.speakeasy;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ops.AuditLogRepository;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "management.prometheus.metrics.export.enabled=true")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountSecurityApiTest extends BackendIntegrationTestSupport {
  @Autowired AuditLogRepository authAuditLogs;

  @Test
  void listsDevicesAndLogsOutOtherSessions() throws Exception {
    ApiTokens first = loginWithDevice("+8613800138200", "Alice phone", "android");
    ApiTokens second = loginWithDevice("+8613800138200", "Alice tablet", "android");

    mvc.perform(get("/auth/sessions").header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.sessions", hasSize(2)))
        .andExpect(jsonPath("$.sessions[0].current").value(true));

    mvc.perform(post("/auth/logout-others")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header("X-Request-Id", "req-logout-others"))
        .andExpect(status().isNoContent());

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken())))
        .andExpect(status().isOk());
    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(second.accessToken())))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("SESSION_REVOKED"));
  }

  @Test
  void remoteRevokeIsPrivateAndIdempotent() throws Exception {
    ApiTokens owner = loginWithDevice("+8613800138201", "Owner phone", "ios");
    ApiTokens target = loginWithDevice("+8613800138201", "Owner tablet", "ios");
    ApiTokens other = loginWithDevice("+8613800138202", "Other phone", "ios");

    mvc.perform(delete("/auth/sessions/{sessionId}", other.sessionId())
            .header(HttpHeaders.AUTHORIZATION, bearer(owner.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("SESSION_NOT_FOUND"));

    mvc.perform(delete("/auth/sessions/{sessionId}", target.sessionId())
            .header(HttpHeaders.AUTHORIZATION, bearer(owner.accessToken())))
        .andExpect(status().isNoContent());
    mvc.perform(delete("/auth/sessions/{sessionId}", target.sessionId())
            .header(HttpHeaders.AUTHORIZATION, bearer(owner.accessToken())))
        .andExpect(status().isNoContent());
  }

  @Test
  void refreshReuseReturnsStableCodeAndRevokesRotatedSession() throws Exception {
    ApiTokens login = loginWithDevice("+8613800138203", "Replay phone", "android");
    MvcResult refreshed = mvc.perform(post("/auth/refresh")
            .contentType(MediaType.APPLICATION_JSON)
            .content(refreshBody(login.refreshToken())))
        .andExpect(status().isOk())
        .andReturn();
    String nextAccess = JsonPath.read(refreshed.getResponse().getContentAsString(), "$.access_token");

    mvc.perform(post("/auth/refresh")
            .contentType(MediaType.APPLICATION_JSON)
            .content(refreshBody(login.refreshToken())))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("TOKEN_REUSE_DETECTED"));

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(nextAccess)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("SESSION_REVOKED"));
  }

  @Test
  void invalidTokensReturnStableCodes() throws Exception {
    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, "Bearer invalid-access"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("ACCESS_TOKEN_INVALID"));

    mvc.perform(post("/auth/refresh")
            .contentType(MediaType.APPLICATION_JSON)
            .content(refreshBody("invalid-refresh")))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("REFRESH_TOKEN_INVALID"));
  }

  @Test
  void rejectsDeviceAndAdminMetadataOutsideThePublishedContract() throws Exception {
    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version":1,
                  "phone_number":"+8613800138299",
                  "verification_code":"123456",
                  "terms_accepted":true,
                  "platform":"windows"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(post("/admin/users/{userId}/disable", UUID.randomUUID())
            .header(HttpHeaders.AUTHORIZATION, "Bearer ops-test-token")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"schema_version":1,"reason_code":"UPPERCASE_REASON","case_reference":"case 123"}
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  @Test
  void opsCanDisableAndEnableAccountWithAttributedAudit() throws Exception {
    ApiTokens login = loginWithDevice("+8613800138204", "Security phone", "android");

    mvc.perform(post("/admin/users/{userId}/disable", login.userId())
            .header(HttpHeaders.AUTHORIZATION, "Bearer ops-test-token")
            .header("X-Request-Id", "req-disable")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"schema_version":1,"reason_code":"suspected_compromise","case_reference":"case-123"}
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.account_status").value("disabled"))
        .andExpect(jsonPath("$.revoked_session_count").value(1));

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(login.accessToken())))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("ACCOUNT_DISABLED"));

    mvc.perform(post("/admin/users/{userId}/enable", login.userId())
            .header(HttpHeaders.AUTHORIZATION, "Bearer ops-test-token")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {"schema_version":1,"reason_code":"review_complete","case_reference":"case-123"}
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.account_status").value("active"));

    org.assertj.core.api.Assertions.assertThat(authAuditLogs.findAll())
        .extracting(com.speakeasy.ops.AuditLog::getEventType)
        .contains("account_disabled", "account_enabled");
    org.assertj.core.api.Assertions.assertThat(authAuditLogs.findAll())
        .filteredOn(log -> "account_disabled".equals(log.getEventType()))
        .allSatisfy(log -> {
          org.assertj.core.api.Assertions.assertThat(log.getActorId()).doesNotContain("ops-test-token");
          org.assertj.core.api.Assertions.assertThat(log.getRequestId()).isEqualTo("req-disable");
        });
  }

  @Test
  void prometheusMetricsRequireOpsAndExposeAuthenticationCounters() throws Exception {
    ApiTokens user = loginWithDevice("+8613800138205", "Metrics phone", "android");
    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, "Bearer invalid-access"))
        .andExpect(status().isUnauthorized());

    mvc.perform(get("/actuator/prometheus").header(HttpHeaders.AUTHORIZATION, bearer(user.accessToken())))
        .andExpect(status().isForbidden());
    mvc.perform(get("/actuator/prometheus").header(HttpHeaders.AUTHORIZATION, "Bearer ops-test-token"))
        .andExpect(status().isOk())
        .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.content()
            .string(org.hamcrest.Matchers.containsString("speakeasy_auth_access_total")))
        .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.content()
            .string(org.hamcrest.Matchers.containsString("http_server_requests_seconds_bucket")));
  }

  private ApiTokens loginWithDevice(String phone, String deviceName, String platform) throws Exception {
    MvcResult result = mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version":1,
                  "phone_number":"%s",
                  "verification_code":"123456",
                  "terms_accepted":true,
                  "device_id":"%s",
                  "device_name":"%s",
                  "platform":"%s",
                  "app_version":"3.0.0"
                }
                """.formatted(phone, UUID.randomUUID(), deviceName, platform)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session_id").exists())
        .andExpect(jsonPath("$.refresh_expires_at").exists())
        .andReturn();
    String body = result.getResponse().getContentAsString();
    return new ApiTokens(
        JsonPath.read(body, "$.user.user_id"),
        JsonPath.read(body, "$.session_id"),
        JsonPath.read(body, "$.access_token"),
        JsonPath.read(body, "$.refresh_token"));
  }

  private String refreshBody(String token) {
    return "{\"schema_version\":1,\"refresh_token\":\"" + token + "\"}";
  }

  private record ApiTokens(String userId, String sessionId, String accessToken, String refreshToken) {}
}
