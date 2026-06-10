package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ops.AuditLog;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminAuditControllerTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";

  @Test
  void tcCom024AdminAuditEndpointRequiresOpsBearerToken() throws Exception {
    AuthTokens tokens = loginPhone("+15550004001");

    mvc.perform(get("/admin/audit"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));

    mvc.perform(get("/admin/audit").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
  }

  @Test
  void tcCom024AdminAuditEndpointFiltersPaginatesAndSelfAuditsAccess() throws Exception {
    Instant base = Instant.parse("2026-06-10T10:00:00Z");
    audit("00000000-0000-0000-0000-000000000001", "user", "user-a", "usage_reserved", "usage:asr", "{\"schema_version\":1}", "req-1", base);
    audit("00000000-0000-0000-0000-000000000002", "user", "user-a", "usage_reserved", "usage:asr", "{\"schema_version\":1}", "req-2", base.plusSeconds(120));
    audit("00000000-0000-0000-0000-000000000003", "user", "user-a", "usage_reserved", "usage:asr", "{\"schema_version\":1}", "req-3", base.plusSeconds(180));
    audit("00000000-0000-0000-0000-000000000004", "system", "system", "usage_reserved", "usage:asr", "{\"schema_version\":1}", "req-4", base.plusSeconds(240));
    audit("00000000-0000-0000-0000-000000000005", "user", "user-a", "usage_reserved", "usage:tts", "{\"schema_version\":1}", "req-5", base.plusSeconds(300));

    MvcResult firstPage = mvc.perform(get("/admin/audit")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("X-Request-Id", "req-admin-audit-001")
            .queryParam("limit", "2")
            .queryParam("event_type", "usage_reserved")
            .queryParam("actor_type", "user")
            .queryParam("target_ref", "usage:asr")
            .queryParam("created_after", "2026-06-10T10:00:00Z")
            .queryParam("created_before", "2026-06-10T10:05:00Z"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.limit").value(2))
        .andExpect(jsonPath("$.next_cursor", not(blankOrNullString())))
        .andExpect(jsonPath("$.events", hasSize(2)))
        .andExpect(jsonPath("$.events[0].audit_log_id").value("00000000-0000-0000-0000-000000000003"))
        .andExpect(jsonPath("$.events[0].actor_type").value("user"))
        .andExpect(jsonPath("$.events[0].event_type").value("usage_reserved"))
        .andExpect(jsonPath("$.events[0].target_ref").value("usage:asr"))
        .andExpect(jsonPath("$.events[0].request_id").value("req-3"))
        .andExpect(jsonPath("$.events[1].audit_log_id").value("00000000-0000-0000-0000-000000000002"))
        .andReturn();

    assertThat(auditLogs.countByEventType("admin_audit_events_listed")).isEqualTo(1);

    String cursor = JsonPath.read(firstPage.getResponse().getContentAsString(), "$.next_cursor");
    mvc.perform(get("/admin/audit")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .queryParam("limit", "2")
            .queryParam("cursor", cursor)
            .queryParam("event_type", "usage_reserved")
            .queryParam("actor_type", "user")
            .queryParam("target_ref", "usage:asr"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.events", hasSize(1)))
        .andExpect(jsonPath("$.events[0].audit_log_id").value("00000000-0000-0000-0000-000000000001"))
        .andExpect(jsonPath("$.next_cursor", nullValue()));
  }

  @Test
  void tcCom024AdminAuditEndpointRedactsSensitiveDetailsAndLegacyText() throws Exception {
    Instant base = Instant.parse("2026-06-10T11:00:00Z");
    audit("00000000-0000-0000-0000-000000000011", "system", "system", "sensitive_fixture", "audit:redaction",
        """
            {
              "schema_version": 1,
              "safe_status": "blocked",
              "token": "secret-token",
              "full_transcript": "raw words should not leak",
              "nested": {
                "safe_reason": "quota",
                "signed_url": "https://media.test.local/audio.wav?signature=secret-token"
              },
              "items": ["safe", "https://media.test.local/audio.wav?token=secret-token"]
            }
            """,
        "req-sensitive-json",
        base.plusSeconds(60));
    audit("00000000-0000-0000-0000-000000000012", "system", "system", "sensitive_fixture", "audit:redaction",
        "{token=secret-token, signed_url=https://media.test.local/audio.wav?signature=secret-token}",
        "req-sensitive-legacy",
        base);

    MvcResult result = mvc.perform(get("/admin/audit")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .queryParam("event_type", "sensitive_fixture")
            .queryParam("target_ref", "audit:redaction")
            .queryParam("limit", "2"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.events", hasSize(2)))
        .andExpect(jsonPath("$.events[0].redacted_details.safe_status").value("blocked"))
        .andExpect(jsonPath("$.events[0].redacted_details.nested.safe_reason").value("quota"))
        .andExpect(jsonPath("$.events[1].redacted_details.format").value("legacy_text"))
        .andExpect(jsonPath("$.events[1].redacted_details.summary").value("redacted"))
        .andReturn();

    String body = result.getResponse().getContentAsString();
    assertThat(body).doesNotContain("secret-token");
    assertThat(body).doesNotContain("signature=");
    assertThat(body).doesNotContain("full_transcript");
    assertThat(body).doesNotContain("signed_url");
    assertThat(body).doesNotContain("raw words should not leak");
    assertThat(body).doesNotContain("https://media.test.local");
  }

  @Test
  void tcCom024AdminAuditEndpointValidatesQueryBoundsAndCursor() throws Exception {
    mvc.perform(get("/admin/audit")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .queryParam("limit", "101"))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(get("/admin/audit")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .queryParam("cursor", "not-a-valid-cursor"))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  private void audit(
      String auditLogId,
      String actorType,
      String actorId,
      String eventType,
      String targetRef,
      String redactedDetails,
      String requestId,
      Instant createdAt) {
    auditLogs.save(new AuditLog(
        UUID.fromString(auditLogId),
        actorType,
        actorId,
        eventType,
        targetRef,
        redactedDetails,
        requestId,
        createdAt));
  }
}
