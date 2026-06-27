package com.speakeasy.ops;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "account_deletion_retry_idempotency")
public class AccountDeletionRetryIdempotency {
  @Id
  @Column(name = "retry_id", nullable = false)
  private UUID retryId;

  @Column(name = "deletion_job_id", nullable = false)
  private UUID deletionJobId;

  @Column(name = "idempotency_key", nullable = false)
  private String idempotencyKey;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "completed_at")
  private Instant completedAt;

  @Column(name = "failure_reason")
  private String failureReason;

  protected AccountDeletionRetryIdempotency() {}

  public AccountDeletionRetryIdempotency(UUID retryId, UUID deletionJobId, String idempotencyKey, Instant createdAt) {
    this.retryId = retryId;
    this.deletionJobId = deletionJobId;
    this.idempotencyKey = idempotencyKey;
    this.status = "started";
    this.createdAt = createdAt;
  }

  public void complete(Instant completedAt) {
    this.status = "completed";
    this.completedAt = completedAt;
    this.failureReason = null;
  }

  public void fail(String failureReason, Instant completedAt) {
    this.status = "failed";
    this.failureReason = failureReason;
    this.completedAt = completedAt;
  }

  public UUID getRetryId() {
    return retryId;
  }

  public UUID getDeletionJobId() {
    return deletionJobId;
  }

  public String getIdempotencyKey() {
    return idempotencyKey;
  }

  public String getStatus() {
    return status;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public String getFailureReason() {
    return failureReason;
  }
}
