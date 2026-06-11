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
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminAuditControllerTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";
  @Autowired JdbcTemplate jdbcTemplate;

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
    rawAudit("00000000-0000-0000-0000-000000000011", "system", "system", "sensitive_fixture", "audit:redaction",
        """
            {
              "schema_version": 1,
              "safe_status": "blocked",
              "token": "secret-token",
              "full_transcript": "raw words should not leak",
              "safe_note": "see https://media.test.local/audio.wav for detail",
              "nested": {
                "safe_reason": "quota",
                "signed_url": "https://media.test.local/audio.wav?signature=secret-token"
              },
              "items": ["safe", "https://media.test.local/audio.wav?token=secret-token"]
            }
            """,
        "req-sensitive-json",
        base.plusSeconds(60));
    rawAudit("00000000-0000-0000-0000-000000000012", "system", "system", "sensitive_fixture", "audit:redaction",
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
  void tcCom024AdminAuditEndpointRedactsSensitiveTargetRefs() throws Exception {
    rawAudit("00000000-0000-0000-0000-000000000013", "system", "system", "sensitive_target_fixture",
        "audio_ref:media://audio/raw-audio-1", "{\"schema_version\":1,\"safe_status\":\"recorded\"}",
        "req-sensitive-target",
        Instant.parse("2026-06-10T11:03:00Z"));

    MvcResult result = mvc.perform(get("/admin/audit")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .queryParam("event_type", "sensitive_target_fixture")
            .queryParam("limit", "1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.events", hasSize(1)))
        .andExpect(jsonPath("$.events[0].target_ref").value("redacted:target_ref"))
        .andReturn();

    assertThat(result.getResponse().getContentAsString()).doesNotContain("media://audio/raw-audio-1");
  }

  @Test
  void tcCom024AuditWritePathSanitizesSensitiveDetailsBeforePersistence() {
    Instant createdAt = Instant.parse("2026-06-10T12:00:00Z");
    auditLogs.save(new AuditLog(
        UUID.fromString("00000000-0000-0000-0000-000000000021"),
        "system",
        "system",
        "sensitive_write_fixture",
        "https://media.test.local/audio.wav?signature=secret-token",
        """
            {
              "schema_version": 1,
              "safe_status": "blocked",
              "token": "secret-token",
              "full_transcript": "raw words should not persist",
              "nested": {
                "safe_reason": "quota",
                "signed_url": "https://media.test.local/audio.wav?signature=secret-token"
              },
              "safe_note": "see https://media.test.local/audio.wav for detail",
              "items": ["safe", "https://media.test.local/audio.wav?token=secret-token"]
            }
            """,
        "https://request.test.local/audit?token=secret-token",
        createdAt));

    String details = jdbcTemplate.queryForObject(
        "SELECT redacted_details FROM audit_logs WHERE audit_log_id = ?",
        String.class,
        UUID.fromString("00000000-0000-0000-0000-000000000021"));
    String targetRef = jdbcTemplate.queryForObject(
        "SELECT target_ref FROM audit_logs WHERE audit_log_id = ?",
        String.class,
        UUID.fromString("00000000-0000-0000-0000-000000000021"));
    String requestId = jdbcTemplate.queryForObject(
        "SELECT request_id FROM audit_logs WHERE audit_log_id = ?",
        String.class,
        UUID.fromString("00000000-0000-0000-0000-000000000021"));

    assertThat(details)
        .contains("\"safe_status\":\"blocked\"")
        .contains("\"safe_reason\":\"quota\"")
        .doesNotContain("secret-token")
        .doesNotContain("signature=")
        .doesNotContain("full_transcript")
        .doesNotContain("signed_url")
        .doesNotContain("raw words should not persist")
        .doesNotContain("see https://")
        .doesNotContain("https://media.test.local");
    assertThat(targetRef).isEqualTo("redacted:target_ref");
    assertThat(requestId).isEqualTo("unknown");

    auditLogs.save(new AuditLog(
        UUID.fromString("00000000-0000-0000-0000-000000000022"),
        "system",
        "system",
        "sensitive_target_write_fixture",
        "transcript_ref:raw-transcript-1",
        "{\"schema_version\":1,\"safe_status\":\"blocked\"}",
        "req-sensitive-target-write",
        createdAt.plusSeconds(1)));

    String sensitiveTokenTargetRef = jdbcTemplate.queryForObject(
        "SELECT target_ref FROM audit_logs WHERE audit_log_id = ?",
        String.class,
        UUID.fromString("00000000-0000-0000-0000-000000000022"));
    assertThat(sensitiveTokenTargetRef).isEqualTo("redacted:target_ref");
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

  private void rawAudit(
      String auditLogId,
      String actorType,
      String actorId,
      String eventType,
      String targetRef,
      String redactedDetails,
      String requestId,
      Instant createdAt) {
    jdbcTemplate.update(
        """
            INSERT INTO audit_logs (
              audit_log_id, actor_type, actor_id, event_type, target_ref, redacted_details, request_id, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
        UUID.fromString(auditLogId),
        actorType,
        actorId,
        eventType,
        targetRef,
        redactedDetails,
        requestId,
        createdAt);
  }
}
