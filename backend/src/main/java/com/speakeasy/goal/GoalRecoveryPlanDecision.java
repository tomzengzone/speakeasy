package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_recovery_plan_decisions")
public class GoalRecoveryPlanDecision {
  @Id
  @Column(name = "decision_id", nullable = false)
  private UUID decisionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "goal_revision", nullable = false)
  private int goalRevision;

  @Column(name = "daily_plan_id", nullable = false)
  private UUID dailyPlanId;

  @Column(name = "source_event", nullable = false)
  private String sourceEvent;

  @Column(name = "recovery_mode", nullable = false)
  private String recoveryMode;

  @Column(name = "affected_plan_item_refs_json", nullable = false)
  private String affectedPlanItemRefsJson;

  @Column(name = "input_snapshot_hash", nullable = false)
  private String inputSnapshotHash;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "rule_version", nullable = false)
  private String ruleVersion;

  @Column(name = "idempotency_key", nullable = false)
  private String idempotencyKey;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalRecoveryPlanDecision() {}

  public GoalRecoveryPlanDecision(
      UUID decisionId,
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      UUID dailyPlanId,
      String sourceEvent,
      String recoveryMode,
      String affectedPlanItemRefsJson,
      String inputSnapshotHash,
      String reasonCode,
      String ruleVersion,
      String idempotencyKey,
      Instant createdAt) {
    this.decisionId = decisionId;
    this.userId = userId;
    this.goalProfileId = goalProfileId;
    this.goalRevision = goalRevision;
    this.dailyPlanId = dailyPlanId;
    this.sourceEvent = sourceEvent;
    this.recoveryMode = recoveryMode;
    this.affectedPlanItemRefsJson = affectedPlanItemRefsJson;
    this.inputSnapshotHash = inputSnapshotHash;
    this.reasonCode = reasonCode;
    this.ruleVersion = ruleVersion;
    this.idempotencyKey = idempotencyKey;
    this.createdAt = createdAt;
  }

  public UUID getDecisionId() {
    return decisionId;
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

  public UUID getDailyPlanId() {
    return dailyPlanId;
  }

  public String getSourceEvent() {
    return sourceEvent;
  }

  public String getRecoveryMode() {
    return recoveryMode;
  }

  public String getAffectedPlanItemRefsJson() {
    return affectedPlanItemRefsJson;
  }

  public String getInputSnapshotHash() {
    return inputSnapshotHash;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public String getRuleVersion() {
    return ruleVersion;
  }

  public String getIdempotencyKey() {
    return idempotencyKey;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
