package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.ops.AccountDeletionJob;
import java.time.Instant;
import java.util.UUID;

public record AccountDeletionJobResponse(
    int schemaVersion,
    UUID deletionJobId,
    String status,
    Instant requestedAt,
    Instant completedAt,
    String failureReason,
    int retryCount) implements SchemaResponse {
  static AccountDeletionJobResponse from(int schemaVersion, AccountDeletionJob deletionJob) {
    return new AccountDeletionJobResponse(
        schemaVersion,
        deletionJob.getDeletionJobId(),
        deletionJob.getStatus(),
        deletionJob.getRequestedAt(),
        deletionJob.getCompletedAt(),
        deletionJob.getFailureReason(),
        deletionJob.getRetryCount());
  }
}
