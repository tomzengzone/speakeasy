package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.ai.AiMediaAsset;
import com.speakeasy.ai.AiMediaStorageService;
import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AccountDeletionJob;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AdminDataDeletionRetryFailureTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";

  @Test
  void tcCom025RetryFailurePersistsFailedStatusAndSanitizedAuditWithRealRetentionService() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138426");
    UUID userId = UUID.fromString(tokens.userId());
    AccountDeletionJob failed = new AccountDeletionJob(UUID.randomUUID(), userId, "delete-failed-source", Instant.now());
    failed.fail("learning_cleanup_failed");
    deletionJobs.save(failed);
    createFailingMediaAsset(userId);

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(failed.getDeletionJobId()))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "admin-retry-fails-again")
            .header("X-Request-Id", "req-admin-retry-fails-again"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("failed"))
        .andExpect(jsonPath("$.failure_reason").value("provider_unavailable"))
        .andExpect(jsonPath("$.retry_count").value(1));

    AccountDeletionJob retried = deletionJobs.findById(failed.getDeletionJobId()).orElseThrow();
    assertThat(retried.getStatus()).isEqualTo("failed");
    assertThat(retried.getFailureReason()).isEqualTo("provider_unavailable");
    assertThat(retried.getRetryCount()).isEqualTo(1);
    assertThat(deletionRetryIdempotency
        .findByDeletionJobIdAndIdempotencyKey(failed.getDeletionJobId(), "admin-retry-fails-again"))
        .isPresent()
        .get()
        .extracting("status", "failureReason")
        .containsExactly("failed", "provider_unavailable");
    assertThat(auditLogs.countByEventType("account_deletion_retry_failed")).isEqualTo(1);
    assertThat(auditLogs.findAll().stream()
        .filter(audit -> "account_deletion_retry_failed".equals(audit.getEventType()))
        .findFirst()
        .orElseThrow()
        .getRedactedDetails())
        .doesNotContain("secret")
        .doesNotContain("token=");
  }

  private void createFailingMediaAsset(UUID userId) {
    Instant now = Instant.now();
    UUID mediaId = UUID.randomUUID();
    AiMediaAsset media = new AiMediaAsset(
        mediaId,
        userId,
        "retry-failure-media",
        "asr_input",
        "media://audio/" + mediaId,
        "https://media.test.local/audio/retry-failure.m4a",
        "media:audit-retry-failure",
        "https://upload.test.local/audio/retry-failure.m4a",
        "audio/m4a",
        2048,
        12,
        "checksum-retry-failure",
        now.plusSeconds(3600),
        now.minusSeconds(60));
    media.markValidated("object://retry-failure", "checksum-retry-failure", now.minusSeconds(30));
    mediaAssets.save(media);
  }

  @TestConfiguration
  static class FailingAiMediaStorageConfiguration {
    @Bean
    @Primary
    AiMediaStorageService failingAiMediaStorageService() {
      return new AiMediaStorageService() {
        @Override
        public PreparedUpload prepareUpload(UploadRequest request) {
          return new PreparedUpload(
              "https://media.test.local/audio/" + request.mediaId() + ".m4a",
              "object://retry-failure",
              "https://upload.test.local/audio/" + request.mediaId() + ".m4a",
              Map.of("Content-Type", request.contentType()));
        }

        @Override
        public void deleteObject(AiMediaAsset asset) {
          if ("object://retry-failure".equals(asset.getObjectRef())) {
            throw new ApiException(
                HttpStatus.SERVICE_UNAVAILABLE,
                "PROVIDER_UNAVAILABLE",
                "provider unavailable token=secret");
          }
        }
      };
    }
  }
}
