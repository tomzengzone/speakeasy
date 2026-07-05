package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.ops.AccountDeletionJob;
import com.speakeasy.ops.AuditLog;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountDeletionFailureAuditTest extends BackendIntegrationTestSupport {
  @Test
  void failedDeletionStatusIsExplainableAndAuditEvidenceCanBeRetained() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138400");
    UUID userId = UUID.fromString(tokens.userId());
    Instant now = Instant.now();
    AccountDeletionJob failed = new AccountDeletionJob(UUID.randomUUID(), userId, now);
    failed.fail("learning_cleanup_failed");
    deletionJobs.save(failed);
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "system",
        userId.toString(),
        "account_deletion_failed",
        "user:" + userId,
        "{\"reason\":\"learning_cleanup_failed\"}",
        "req_delete_failed",
        now));

    mvc.perform(get("/user/deletion-status").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.status").value("failed"))
        .andExpect(jsonPath("$.failure_reason").value("learning_cleanup_failed"));
  }
}
