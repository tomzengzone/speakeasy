package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.AiMediaAsset;
import com.speakeasy.ai.AiTtsCacheEntry;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AiRetentionPolicyTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";
  @Autowired JdbcTemplate jdbcTemplate;

  @Test
  void tcComAi006RetentionJobDeletesExpiredMediaAndCacheWithEvidence() throws Exception {
    AuthTokens tokens = loginPhone("+15550002001");
    UUID userId = UUID.fromString(tokens.userId());
    Instant now = Instant.now();
    UUID mediaId = UUID.randomUUID();
    UUID cacheId = UUID.randomUUID();

    AiMediaAsset media = new AiMediaAsset(
        mediaId,
        userId,
        "expired-media-1",
        "asr_input",
        "media://audio/" + mediaId,
        "https://media.test.local/audio/expired.m4a",
        "media:audit-expired",
        "https://upload.test.local/audio/expired.m4a",
        "audio/m4a",
        1024,
        10,
        "checksum",
        now.minusSeconds(60),
        now.minusSeconds(3600));
    media.markValidated("object://expired", "checksum", now.minusSeconds(3500));
    mediaAssets.save(media);

    ttsCacheEntries.save(new AiTtsCacheEntry(
        cacheId,
        "expired-cache-key",
        "normalized-hash",
        "qwen3-tts-flash",
        "Cherry",
        "Auto",
        "https://media.test.local/tts/expired.mp3",
        now.minusSeconds(60),
        now.minusSeconds(3600)));

    MvcResult created = mvc.perform(post("/admin/ai/retention-jobs")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "ai-retention-expired-1")
            .header("X-Request-Id", "req-ai-retention-expired-1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scope": "expired_media",
                  "reason": "scheduled_retention_policy"
                }
                """))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.job.status").value("completed"))
        .andExpect(jsonPath("$.job.media_deleted_count").value(1))
        .andExpect(jsonPath("$.job.tts_cache_deleted_count").value(1))
        .andExpect(jsonPath("$.job.redacted_evidence_ref").exists())
        .andReturn();

    String body = created.getResponse().getContentAsString();
    String jobId = JsonPath.read(body, "$.job.job_id");
    assertThat(mediaAssets.findById(mediaId).orElseThrow().getStatus()).isEqualTo("deleted");
    assertThat(ttsCacheEntries.findById(cacheId).orElseThrow().getStatus()).isEqualTo("deleted");
    String auditDetails = jdbcTemplate.queryForObject(
        "SELECT redacted_details FROM audit_logs WHERE event_type = 'ai_retention_job_completed' AND target_ref = ?",
        String.class,
        "ai_retention:" + jobId);
    assertThat(JsonPath.<String>read(auditDetails, "$.scope")).isEqualTo("expired_media");
    assertThat(JsonPath.<Integer>read(auditDetails, "$.media_deleted_count")).isEqualTo(1);
    assertThat(JsonPath.<Integer>read(auditDetails, "$.tts_cache_deleted_count")).isEqualTo(1);
    assertThat(auditDetails)
        .contains("\"scope\":\"expired_media\"")
        .contains("\"media_deleted_count\":1")
        .contains("\"tts_cache_deleted_count\":1")
        .contains("\"provider_payload_redacted_count\":0")
        .contains("\"evidence_ref\":\"audit:ai_retention:");

    MvcResult auditPage = mvc.perform(get("/admin/audit")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .queryParam("event_type", "ai_retention_job_completed")
            .queryParam("target_ref", "ai_retention:" + jobId)
            .queryParam("limit", "1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.events", hasSize(1)))
        .andExpect(jsonPath("$.events[0].event_type").value("ai_retention_job_completed"))
        .andExpect(jsonPath("$.events[0].target_ref").value("ai_retention:" + jobId))
        .andExpect(jsonPath("$.events[0].redacted_details.scope").value("expired_media"))
        .andExpect(jsonPath("$.events[0].redacted_details.media_deleted_count").value(1))
        .andExpect(jsonPath("$.events[0].redacted_details.tts_cache_deleted_count").value(1))
        .andExpect(jsonPath("$.events[0].redacted_details.provider_payload_redacted_count").value(0))
        .andExpect(jsonPath("$.events[0].redacted_details.evidence_ref").exists())
        .andReturn();
    assertThat(auditPage.getResponse().getContentAsString())
        .doesNotContain("https://media.test.local")
        .doesNotContain("https://upload.test.local");

    mvc.perform(get("/admin/ai/retention-jobs/%s".formatted(jobId))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.job.job_id").value(jobId))
        .andExpect(jsonPath("$.job.status").value("completed"));

    mvc.perform(post("/admin/ai/retention-jobs")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "ai-retention-expired-1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scope": "expired_media",
                  "reason": "scheduled_retention_policy"
                }
                """))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.job.job_id").value(jobId));
  }

  @Test
  void tcComAi006RetentionJobAcceptsCanonicalUserShaRefAndWritesStructuredAuditJson() throws Exception {
    MvcResult created = mvc.perform(post("/admin/ai/retention-jobs")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "ai-retention-user-sha-ref-1")
            .header("X-Request-Id", "req-ai-retention-user-sha-ref-1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scope": "account_deletion",
                  "user_ref": "user_sha256:ABCDEF1234567890",
                  "reason": "account_deletion"
                }
                """))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.job.status").value("completed"))
        .andExpect(jsonPath("$.job.media_deleted_count").value(0))
        .andExpect(jsonPath("$.job.tts_cache_deleted_count").value(0))
        .andReturn();

    String jobId = JsonPath.read(created.getResponse().getContentAsString(), "$.job.job_id");
    String auditDetails = jdbcTemplate.queryForObject(
        "SELECT redacted_details FROM audit_logs WHERE event_type = 'ai_retention_job_completed' AND target_ref = ?",
        String.class,
        "ai_retention:" + jobId);

    assertThat(JsonPath.<String>read(auditDetails, "$.scope")).isEqualTo("account_deletion");
    assertThat(JsonPath.<String>read(auditDetails, "$.user_ref")).isEqualTo("user_sha256:abcdef1234567890");
    assertThat(JsonPath.<Integer>read(auditDetails, "$.media_deleted_count")).isZero();
    assertThat(JsonPath.<Integer>read(auditDetails, "$.provider_payload_redacted_count")).isZero();
  }

  @Test
  void tcComAi006RetentionJobRejectsMalformedPreservedUserShaRef() throws Exception {
    mvc.perform(post("/admin/ai/retention-jobs")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "ai-retention-bad-user-sha-ref-1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scope": "account_deletion",
                  "user_ref": "user_sha256:abc\\",\\"media_deleted_count\\":99",
                  "reason": "account_deletion"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    assertThat(aiRetentionJobs.findAll()).isEmpty();
    assertThat(auditLogs.findAll()).isEmpty();
  }

  @Test
  void tcComAi006RetentionJobRejectsMalformedPreservedUserShaRefBeforeIdempotencyReplay() throws Exception {
    mvc.perform(post("/admin/ai/retention-jobs")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "ai-retention-replay-user-sha-ref-1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scope": "account_deletion",
                  "user_ref": "user_sha256:abcdef1234567890",
                  "reason": "account_deletion"
                }
                """))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.job.status").value("completed"));

    assertThat(aiRetentionJobs.count()).isEqualTo(1);
    assertThat(auditLogs.count()).isEqualTo(1);

    mvc.perform(post("/admin/ai/retention-jobs")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "ai-retention-replay-user-sha-ref-1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scope": "account_deletion",
                  "user_ref": "user_sha256:abc\\",\\"media_deleted_count\\":99",
                  "reason": "account_deletion"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    assertThat(aiRetentionJobs.count()).isEqualTo(1);
    assertThat(auditLogs.count()).isEqualTo(1);
  }

  @Test
  void tcComAi006RetentionJobRejectsMalformedDeletionJobRef() throws Exception {
    mvc.perform(post("/admin/ai/retention-jobs")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "ai-retention-bad-deletion-job-ref-1")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scope": "account_deletion",
                  "user_ref": "deletion_job:not-a-uuid",
                  "reason": "account_deletion"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    assertThat(aiRetentionJobs.findAll()).isEmpty();
    assertThat(auditLogs.findAll()).isEmpty();
  }
}
