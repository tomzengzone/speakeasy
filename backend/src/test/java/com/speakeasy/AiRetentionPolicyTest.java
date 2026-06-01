package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
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
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AiRetentionPolicyTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";

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
}
