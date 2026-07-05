package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_notification_outbox_records")
public class NotificationOutboxRecord {
  @Id
  @Column(name = "outbox_id", nullable = false)
  private UUID outboxId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "goal_revision", nullable = false)
  private int goalRevision;

  @Column(name = "plan_item_id", nullable = false)
  private UUID planItemId;

  @Column(name = "reminder_slot", nullable = false)
  private String reminderSlot;

  @Column(name = "lifecycle_status", nullable = false)
  private String lifecycleStatus;

  @Column(name = "dedupe_key", nullable = false)
  private String dedupeKey;

  @Column(name = "input_snapshot_hash", nullable = false)
  private String inputSnapshotHash;

  @Column(name = "payload_hash", nullable = false)
  private String payloadHash;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "processing_status", nullable = false)
  private String processingStatus;

  @Column(name = "next_attempt_at")
  private Instant nextAttemptAt;

  @Column(name = "failure_reason")
  private String failureReason;

  @Column(name = "retry_count", nullable = false)
  private int retryCount;

  @Column(name = "sent_at")
  private Instant sentAt;

  @Column(name = "rule_version", nullable = false)
  private String ruleVersion;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected NotificationOutboxRecord() {}

  public NotificationOutboxRecord(
      UUID outboxId,
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      UUID planItemId,
      String reminderSlot,
      String lifecycleStatus,
      String dedupeKey,
      String inputSnapshotHash,
      String payloadHash,
      String reasonCode,
      String processingStatus,
      Instant nextAttemptAt,
      String ruleVersion,
      Instant now) {
    this.outboxId = outboxId;
    this.userId = userId;
    this.goalProfileId = goalProfileId;
    this.goalRevision = goalRevision;
    this.planItemId = planItemId;
    this.reminderSlot = reminderSlot;
    this.lifecycleStatus = lifecycleStatus;
    this.dedupeKey = dedupeKey;
    this.inputSnapshotHash = inputSnapshotHash;
    this.payloadHash = payloadHash;
    this.reasonCode = reasonCode;
    this.processingStatus = processingStatus;
    this.nextAttemptAt = nextAttemptAt;
    this.ruleVersion = ruleVersion;
    this.createdAt = now;
    this.updatedAt = now;
  }

  public void transition(
      String lifecycleStatus,
      String processingStatus,
      String reasonCode,
      Instant nextAttemptAt,
      String failureReason,
      Instant now) {
    this.lifecycleStatus = lifecycleStatus;
    this.processingStatus = processingStatus;
    this.reasonCode = reasonCode;
    this.nextAttemptAt = nextAttemptAt;
    this.failureReason = failureReason;
    this.updatedAt = now;
  }

  public void markFailure(String failureReason, Instant nextAttemptAt, Instant now) {
    this.lifecycleStatus = "failed";
    this.processingStatus = "retry_waiting";
    this.reasonCode = failureReason;
    this.nextAttemptAt = nextAttemptAt;
    this.failureReason = failureReason;
    this.retryCount += 1;
    this.updatedAt = now;
  }

  public void markSent(String payloadHash, Instant sentAt) {
    this.lifecycleStatus = "sent";
    this.processingStatus = "complete";
    this.reasonCode = "sent";
    this.payloadHash = payloadHash;
    this.nextAttemptAt = null;
    this.failureReason = null;
    this.sentAt = sentAt;
    this.updatedAt = sentAt;
  }

  public UUID getOutboxId() {
    return outboxId;
  }

  public UUID getUserId() {
    return userId;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public int getGoalRevision() {
    return goalRevision;
  }

  public UUID getPlanItemId() {
    return planItemId;
  }

  public String getReminderSlot() {
    return reminderSlot;
  }

  public String getLifecycleStatus() {
    return lifecycleStatus;
  }

  public String getDedupeKey() {
    return dedupeKey;
  }

  public String getInputSnapshotHash() {
    return inputSnapshotHash;
  }

  public String getPayloadHash() {
    return payloadHash;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public String getProcessingStatus() {
    return processingStatus;
  }

  public Instant getNextAttemptAt() {
    return nextAttemptAt;
  }

  public String getFailureReason() {
    return failureReason;
  }

  public int getRetryCount() {
    return retryCount;
  }

  public Instant getSentAt() {
    return sentAt;
  }

  public String getRuleVersion() {
    return ruleVersion;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
