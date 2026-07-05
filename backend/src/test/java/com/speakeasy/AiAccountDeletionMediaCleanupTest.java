package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.ai.AiMediaAsset;
import com.speakeasy.ai.AiProviderInvocationMetric;
import com.speakeasy.ai.AiRetentionJob;
import com.speakeasy.ai.AiRetentionService;
import com.speakeasy.ai.AiTtsCacheEntry;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AiAccountDeletionMediaCleanupTest extends BackendIntegrationTestSupport {
  @Autowired AiRetentionService aiRetentionService;

  @Test
  void tcComAi007AccountDeletionRunsAiMediaCacheAndMetricCleanup() throws Exception {
    AuthTokens tokens = loginPhone("+15550002002");
    UUID userId = UUID.fromString(tokens.userId());
    String userHash = aiRetentionService.userHashFor(userId);
    Instant now = Instant.now();
    UUID mediaId = UUID.randomUUID();
    UUID cacheId = UUID.randomUUID();

    AiMediaAsset media = new AiMediaAsset(
        mediaId,
        userId,
        "delete-media-1",
        "asr_input",
        "media://audio/" + mediaId,
        "https://media.test.local/audio/delete.m4a",
        "media:audit-delete",
        "https://upload.test.local/audio/delete.m4a",
        "audio/m4a",
        2048,
        12,
        "checksum-delete",
        now.plusSeconds(3600),
        now.minusSeconds(60));
    media.markValidated("object://delete", "checksum-delete", now.minusSeconds(30));
    mediaAssets.save(media);

    AiTtsCacheEntry cache = new AiTtsCacheEntry(
        cacheId,
        "delete-cache-key",
        "delete-normalized-hash",
        "qwen3-tts-flash",
        "Cherry",
        "Auto",
        "https://media.test.local/tts/delete.mp3",
        now.plusSeconds(3600),
        now.minusSeconds(60));
    cache.attachOwner(userHash);
    ttsCacheEntries.save(cache);

    aiProviderMetrics.save(new AiProviderInvocationMetric(
        UUID.randomUUID(),
        userHash,
        "free",
        "dashscope",
        "qwen-plus",
        "llm",
        "available",
        false,
        50,
        null,
        new BigDecimal("0.001000"),
        "daily_user",
        "low",
        "",
        now));

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "ai-account-delete-1")
            .header("X-Request-Id", "req-ai-account-delete-1"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.status").value("completed"));

    assertThat(mediaAssets.findById(mediaId).orElseThrow().getStatus()).isEqualTo("deleted");
    assertThat(ttsCacheEntries.findById(cacheId).orElseThrow().getStatus()).isEqualTo("deleted");
    assertThat(aiProviderMetrics.count()).isZero();

    AiRetentionJob job = aiRetentionJobs.findAll().stream()
        .filter(candidate -> "account_deletion".equals(candidate.getScope()))
        .findFirst()
        .orElseThrow();
    assertThat(job.getStatus()).isEqualTo("completed");
    assertThat(job.getUserRef()).isEqualTo(userHash);
    assertThat(job.getMediaDeletedCount()).isEqualTo(1);
    assertThat(job.getTtsCacheDeletedCount()).isEqualTo(1);
    assertThat(job.getProviderPayloadRedactedCount()).isEqualTo(1);
    assertThat(job.getRedactedEvidenceRef()).startsWith("audit:ai_retention:");
  }

  @Test
  void tcComAi007SharedTtsCacheDeletesOnlyAfterLastOwnerIsRemoved() throws Exception {
    AuthTokens firstTokens = loginPhone("+15550002003");
    AuthTokens secondTokens = loginPhone("+15550002004");
    UUID firstUserId = UUID.fromString(firstTokens.userId());
    UUID secondUserId = UUID.fromString(secondTokens.userId());
    Instant now = Instant.now();
    UUID cacheId = UUID.randomUUID();

    AiTtsCacheEntry cache = new AiTtsCacheEntry(
        cacheId,
        "shared-cache-key",
        "shared-normalized-hash",
        "qwen3-tts-flash",
        "Cherry",
        "Auto",
        "https://media.test.local/tts/shared.mp3",
        now.plusSeconds(3600),
        now.minusSeconds(60));
    ttsCacheEntries.save(cache);
    aiRetentionService.attachTtsCacheOwner(cacheId.toString(), firstUserId);
    aiRetentionService.attachTtsCacheOwner(cacheId.toString(), secondUserId);

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(firstTokens.accessToken()))
            .header("Idempotency-Key", "ai-account-delete-shared-first")
            .header("X-Request-Id", "req-ai-account-delete-shared-first"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.status").value("completed"));

    AiTtsCacheEntry cacheAfterFirstDeletion = ttsCacheEntries.findById(cacheId).orElseThrow();
    assertThat(cacheAfterFirstDeletion.getStatus()).isEqualTo("active");
    assertThat(cacheAfterFirstDeletion.getOwnerHash()).isNull();
    assertThat(ttsCacheOwners.findByOwnerHash(aiRetentionService.userHashFor(firstUserId))).isEmpty();
    assertThat(ttsCacheOwners.findByOwnerHash(aiRetentionService.userHashFor(secondUserId))).hasSize(1);

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(secondTokens.accessToken()))
            .header("Idempotency-Key", "ai-account-delete-shared-second")
            .header("X-Request-Id", "req-ai-account-delete-shared-second"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.status").value("completed"));

    assertThat(ttsCacheEntries.findById(cacheId).orElseThrow().getStatus()).isEqualTo("deleted");
    assertThat(ttsCacheOwners.findByOwnerHash(aiRetentionService.userHashFor(secondUserId))).isEmpty();
  }
}
