package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ops.AccountDeletionJob;
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
class AdminDataDeletionControllerTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";

  @Test
  void tcCom025AdminDataDeletionRetryRequiresOpsBearerToken() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138420");
    UUID jobId = UUID.randomUUID();

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(jobId))
            .header("Idempotency-Key", "admin-retry-auth"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(jobId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "admin-retry-auth"))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
  }

  @Test
  void tcCom025FailedDeletionJobRetryCompletesAndAuditsOpsRecovery() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138421");
    UUID userId = UUID.fromString(tokens.userId());
    AccountDeletionJob failed = failedJob(userId, "learning_cleanup_failed");

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(failed.getDeletionJobId()))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "admin-retry-success")
            .header("X-Request-Id", "req-admin-retry-success"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.deletion_job_id").value(failed.getDeletionJobId().toString()))
        .andExpect(jsonPath("$.status").value("completed"))
        .andExpect(jsonPath("$.completed_at", not(blankOrNullString())))
        .andExpect(jsonPath("$.failure_reason", nullValue()))
        .andExpect(jsonPath("$.retry_count").value(1));

    AccountDeletionJob completed = deletionJobs.findById(failed.getDeletionJobId()).orElseThrow();
    assertThat(completed.getStatus()).isEqualTo("completed");
    assertThat(completed.getRetryCount()).isEqualTo(1);
    assertThat(deletionRetryIdempotency
        .findByDeletionJobIdAndIdempotencyKey(failed.getDeletionJobId(), "admin-retry-success"))
        .isPresent()
        .get()
        .extracting("status")
        .isEqualTo("completed");
    assertThat(auditLogs.countByEventType("account_deletion_retry_requested")).isEqualTo(1);
    assertThat(auditLogs.countByEventType("account_deletion_retry_completed")).isEqualTo(1);

    mvc.perform(get("/user/me").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  @Test
  void tcCom025DuplicateRetryKeyReplaysWithoutNewRetryAuditOrAiRetentionJob() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138422");
    UUID userId = UUID.fromString(tokens.userId());
    AccountDeletionJob failed = failedJob(userId, "learning_cleanup_failed");

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(failed.getDeletionJobId()))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "admin-retry-replay")
            .header("X-Request-Id", "req-admin-retry-replay-1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("completed"))
        .andExpect(jsonPath("$.retry_count").value(1));

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(failed.getDeletionJobId()))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "admin-retry-replay")
            .header("X-Request-Id", "req-admin-retry-replay-2"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("completed"))
        .andExpect(jsonPath("$.retry_count").value(1));

    assertThat(deletionRetryIdempotency.count()).isEqualTo(1);
    assertThat(auditLogs.countByEventType("account_deletion_retry_requested")).isEqualTo(1);
    assertThat(auditLogs.countByEventType("account_deletion_retry_completed")).isEqualTo(1);
    assertThat(aiRetentionJobs.count()).isEqualTo(1);
  }

  @Test
  void tcCom025CompletedDeletionJobRetryIsNoop() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138423");
    MvcResult deletion = mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-before-admin-retry")
            .header("X-Request-Id", "req-delete-before-admin-retry"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.status").value("completed"))
        .andReturn();
    String deletionJobId = JsonPath.read(deletion.getResponse().getContentAsString(), "$.deletion_job_id");

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(deletionJobId))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "admin-retry-completed-noop")
            .header("X-Request-Id", "req-admin-retry-completed-noop"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.deletion_job_id").value(deletionJobId))
        .andExpect(jsonPath("$.status").value("completed"))
        .andExpect(jsonPath("$.retry_count").value(0));

    assertThat(deletionRetryIdempotency.count()).isZero();
    assertThat(auditLogs.countByEventType("account_deletion_retry_requested")).isZero();
    assertThat(auditLogs.countByEventType("account_deletion_retry_completed")).isZero();
  }

  @Test
  void tcCom025InProgressDeletionJobRetryFailsClosed() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138424");
    UUID userId = UUID.fromString(tokens.userId());
    AccountDeletionJob requested = deletionJobs.save(new AccountDeletionJob(
        UUID.randomUUID(), userId, "delete-in-progress-source", Instant.now()));

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(requested.getDeletionJobId()))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "admin-retry-in-progress"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("DELETE_IN_PROGRESS"));

    assertThat(deletionRetryIdempotency.count()).isZero();
  }

  @Test
  void tcCom025RetryValidatesIdempotencyKeyAndJobId() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138425");
    UUID userId = UUID.fromString(tokens.userId());
    AccountDeletionJob failed = failedJob(userId, "learning_cleanup_failed");

    mvc.perform(post("/admin/data-deletion/%s/retry".formatted(failed.getDeletionJobId()))
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(post("/admin/data-deletion/not-a-uuid/retry")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER)
            .header("Idempotency-Key", "admin-retry-missing-job"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
  }

  private AccountDeletionJob failedJob(UUID userId, String failureReason) {
    AccountDeletionJob failed = new AccountDeletionJob(UUID.randomUUID(), userId, "delete-failed-source-" + UUID.randomUUID(), Instant.now());
    failed.fail(failureReason);
    return deletionJobs.save(failed);
  }
}
