package com.speakeasy.api;

import com.speakeasy.ops.AccountDeletionService;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AdminDataDeletionController {
  private final AccountDeletionService accountDeletionService;

  public AdminDataDeletionController(AccountDeletionService accountDeletionService) {
    this.accountDeletionService = accountDeletionService;
  }

  @PostMapping("/admin/data-deletion/{jobId}/retry")
  public AccountDeletionJobResponse retryDeletionJob(
      @PathVariable String jobId,
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId) {
    return AccountDeletionJobResponse.from(
        1, accountDeletionService.retryDeletionJob(jobId, idempotencyKey, requestId));
  }
}
