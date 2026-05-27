package com.speakeasy.ops;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "account_deletion_jobs")
public class AccountDeletionJob {
  @Id
  @Column(name = "deletion_job_id", nullable = false)
  private UUID deletionJobId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "requested_at", nullable = false)
  private Instant requestedAt;

  @Column(name = "completed_at")
  private Instant completedAt;

  @Column(name = "failure_reason")
  private String failureReason;

  @Column(name = "retry_count", nullable = false)
  private int retryCount;

  protected AccountDeletionJob() {}

  public AccountDeletionJob(UUID deletionJobId, UUID userId, Instant requestedAt) {
    this.deletionJobId = deletionJobId;
    this.userId = userId;
    this.status = "requested";
    this.requestedAt = requestedAt;
  }

  public UUID getDeletionJobId() {
    return deletionJobId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getStatus() {
    return status;
  }

  public Instant getRequestedAt() {
    return requestedAt;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public int getRetryCount() {
    return retryCount;
  }
}
