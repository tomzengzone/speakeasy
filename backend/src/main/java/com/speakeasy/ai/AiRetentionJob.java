package com.speakeasy.ai;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_retention_jobs")
public class AiRetentionJob {
  @Id
  @Column(name = "job_id", nullable = false)
  private UUID jobId;

  @Column(name = "idempotency_key", nullable = false)
  private String idempotencyKey;

  @Column(name = "scope", nullable = false)
  private String scope;

  @Column(name = "user_ref")
  private String userRef;

  @Column(name = "reason", nullable = false)
  private String reason;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "media_deleted_count", nullable = false)
  private int mediaDeletedCount;

  @Column(name = "transcript_deleted_count", nullable = false)
  private int transcriptDeletedCount;

  @Column(name = "tts_cache_deleted_count", nullable = false)
  private int ttsCacheDeletedCount;

  @Column(name = "provider_payload_redacted_count", nullable = false)
  private int providerPayloadRedactedCount;

  @Column(name = "redacted_evidence_ref", nullable = false)
  private String redactedEvidenceRef;

  @Column(name = "failure_reason")
  private String failureReason;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "completed_at")
  private Instant completedAt;

  protected AiRetentionJob() {}

  public AiRetentionJob(UUID jobId, String idempotencyKey, String scope, String userRef, String reason, Instant createdAt) {
    this.jobId = jobId;
    this.idempotencyKey = idempotencyKey;
    this.scope = scope;
    this.userRef = clean(userRef);
    this.reason = reason;
    this.status = "pending";
    this.redactedEvidenceRef = "audit:ai_retention:" + jobId;
    this.createdAt = createdAt;
  }

  public UUID getJobId() {
    return jobId;
  }

  public String getIdempotencyKey() {
    return idempotencyKey;
  }

  public String getScope() {
    return scope;
  }

  public String getUserRef() {
    return userRef;
  }

  public String getReason() {
    return reason;
  }

  public String getStatus() {
    return status;
  }

  public int getMediaDeletedCount() {
    return mediaDeletedCount;
  }

  public int getTranscriptDeletedCount() {
    return transcriptDeletedCount;
  }

  public int getTtsCacheDeletedCount() {
    return ttsCacheDeletedCount;
  }

  public int getProviderPayloadRedactedCount() {
    return providerPayloadRedactedCount;
  }

  public String getRedactedEvidenceRef() {
    return redactedEvidenceRef;
  }

  public String getFailureReason() {
    return failureReason;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public void start() {
    this.status = "running";
  }

  public void complete(
      int mediaDeletedCount,
      int transcriptDeletedCount,
      int ttsCacheDeletedCount,
      int providerPayloadRedactedCount,
      Instant completedAt) {
    this.mediaDeletedCount = mediaDeletedCount;
    this.transcriptDeletedCount = transcriptDeletedCount;
    this.ttsCacheDeletedCount = ttsCacheDeletedCount;
    this.providerPayloadRedactedCount = providerPayloadRedactedCount;
    this.status = "completed";
    this.completedAt = completedAt;
  }

  public void failRetryable(String reason, Instant completedAt) {
    this.status = "failed_retryable";
    this.failureReason = clean(reason);
    this.completedAt = completedAt;
  }

  private String clean(String value) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? null : cleaned;
  }
}
