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

  @Column(name = "idempotency_key")
  private String idempotencyKey;

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
    this(deletionJobId, userId, null, requestedAt);
  }

  public AccountDeletionJob(UUID deletionJobId, UUID userId, String idempotencyKey, Instant requestedAt) {
    this.deletionJobId = deletionJobId;
    this.userId = userId;
    this.idempotencyKey = idempotencyKey;
    this.status = "requested";
    this.requestedAt = requestedAt;
  }

  public void complete(Instant completedAt) {
    this.status = "completed";
    this.completedAt = completedAt;
    this.failureReason = null;
  }

  public void fail(String failureReason) {
    this.status = "failed";
    this.failureReason = failureReason;
    this.completedAt = null;
  }

  public void markAccessRevoked() {
    this.status = "access_revoked";
    this.completedAt = null;
    this.failureReason = null;
  }

  public void markDeletingLearningData() {
    this.status = "deleting_learning_data";
    this.completedAt = null;
    this.failureReason = null;
  }

  public void markAnonymizingAuditRefs() {
    this.status = "anonymizing_audit_refs";
    this.completedAt = null;
    this.failureReason = null;
  }

  public void markRetryStarted() {
    this.status = "requested";
    this.completedAt = null;
    this.failureReason = null;
    this.retryCount += 1;
  }

  public UUID getDeletionJobId() {
    return deletionJobId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getIdempotencyKey() {
    return idempotencyKey;
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

  public String getFailureReason() {
    return failureReason;
  }

  public int getRetryCount() {
    return retryCount;
  }
}
