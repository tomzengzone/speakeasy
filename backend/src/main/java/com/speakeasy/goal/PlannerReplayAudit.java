package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_planner_replay_audits")
public class PlannerReplayAudit {
  @Id
  @Column(name = "replay_audit_id", nullable = false)
  private UUID replayAuditId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "decision_family", nullable = false)
  private String decisionFamily;

  @Column(name = "source_entity_ref", nullable = false)
  private String sourceEntityRef;

  @Column(name = "input_snapshot_hash", nullable = false)
  private String inputSnapshotHash;

  @Column(name = "output_snapshot_hash", nullable = false)
  private String outputSnapshotHash;

  @Column(name = "expected_decision", nullable = false)
  private String expectedDecision;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "rule_version", nullable = false)
  private String ruleVersion;

  @Column(name = "replay_hash", nullable = false)
  private String replayHash;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected PlannerReplayAudit() {}

  public PlannerReplayAudit(
      UUID replayAuditId,
      UUID userId,
      String decisionFamily,
      String sourceEntityRef,
      String inputSnapshotHash,
      String outputSnapshotHash,
      String expectedDecision,
      String reasonCode,
      String ruleVersion,
      String replayHash,
      Instant createdAt) {
    this.replayAuditId = replayAuditId;
    this.userId = userId;
    this.decisionFamily = decisionFamily;
    this.sourceEntityRef = sourceEntityRef;
    this.inputSnapshotHash = inputSnapshotHash;
    this.outputSnapshotHash = outputSnapshotHash;
    this.expectedDecision = expectedDecision;
    this.reasonCode = reasonCode;
    this.ruleVersion = ruleVersion;
    this.replayHash = replayHash;
    this.createdAt = createdAt;
  }

  public UUID getReplayAuditId() {
    return replayAuditId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getDecisionFamily() {
    return decisionFamily;
  }

  public String getSourceEntityRef() {
    return sourceEntityRef;
  }

  public String getInputSnapshotHash() {
    return inputSnapshotHash;
  }

  public String getOutputSnapshotHash() {
    return outputSnapshotHash;
  }

  public String getExpectedDecision() {
    return expectedDecision;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public String getRuleVersion() {
    return ruleVersion;
  }

  public String getReplayHash() {
    return replayHash;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
