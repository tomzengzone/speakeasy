package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_outcome_checkpoints")
public class GoalOutcomeCheckpoint {
  @Id
  @Column(name = "checkpoint_id", nullable = false)
  private UUID checkpointId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "checkpoint_type", nullable = false)
  private String checkpointType;

  @Column(name = "cadence", nullable = false)
  private String cadence;

  @Column(name = "result_status", nullable = false)
  private String resultStatus;

  @Column(name = "confidence_band", nullable = false)
  private String confidenceBand;

  @Column(name = "summary", nullable = false)
  private String summary;

  @Column(name = "plan_update_signal", nullable = false)
  private String planUpdateSignal;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalOutcomeCheckpoint() {}

  public GoalOutcomeCheckpoint(
      UUID checkpointId,
      UUID goalProfileId,
      UUID userId,
      String checkpointType,
      String cadence,
      String resultStatus,
      String confidenceBand,
      String summary,
      String planUpdateSignal,
      String reasonCode,
      Instant createdAt) {
    this.checkpointId = checkpointId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    this.checkpointType = checkpointType;
    this.cadence = cadence;
    this.resultStatus = resultStatus;
    this.confidenceBand = confidenceBand;
    this.summary = summary;
    this.planUpdateSignal = planUpdateSignal;
    this.reasonCode = reasonCode;
    this.createdAt = createdAt;
  }

  public UUID getCheckpointId() {
    return checkpointId;
  }

  public String getCheckpointType() {
    return checkpointType;
  }

  public String getCadence() {
    return cadence;
  }

  public String getResultStatus() {
    return resultStatus;
  }

  public String getConfidenceBand() {
    return confidenceBand;
  }

  public String getSummary() {
    return summary;
  }

  public String getPlanUpdateSignal() {
    return planUpdateSignal;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
