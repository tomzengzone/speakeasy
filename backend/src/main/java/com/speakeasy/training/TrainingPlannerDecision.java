package com.speakeasy.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "training_planner_decisions")
public class TrainingPlannerDecision {
  @Id
  @Column(name = "planner_decision_id", nullable = false)
  private UUID plannerDecisionId;

  @Column(name = "training_session_id", nullable = false)
  private UUID trainingSessionId;

  @Column(name = "source_turn_id")
  private UUID sourceTurnId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "decision_type", nullable = false)
  private String decisionType;

  @Column(name = "next_status", nullable = false)
  private String nextStatus;

  @Column(name = "next_step_key", nullable = false)
  private String nextStepKey;

  @Column(name = "next_micro_action", nullable = false)
  private String nextMicroAction;

  @Column(name = "next_hint_level", nullable = false)
  private String nextHintLevel;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "planner_version", nullable = false)
  private String plannerVersion;

  @Column(name = "input_snapshot", nullable = false)
  private String inputSnapshot;

  @Column(name = "output_snapshot", nullable = false)
  private String outputSnapshot;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected TrainingPlannerDecision() {}

  public TrainingPlannerDecision(
      UUID plannerDecisionId,
      UUID trainingSessionId,
      UUID sourceTurnId,
      UUID userId,
      String decisionType,
      String nextStatus,
      String nextStepKey,
      String nextMicroAction,
      String nextHintLevel,
      String reasonCode,
      String plannerVersion,
      String inputSnapshot,
      String outputSnapshot,
      Instant createdAt) {
    this.plannerDecisionId = plannerDecisionId;
    this.trainingSessionId = trainingSessionId;
    this.sourceTurnId = sourceTurnId;
    this.userId = userId;
    this.decisionType = decisionType;
    this.nextStatus = nextStatus;
    this.nextStepKey = nextStepKey;
    this.nextMicroAction = nextMicroAction;
    this.nextHintLevel = nextHintLevel;
    this.reasonCode = reasonCode;
    this.plannerVersion = plannerVersion;
    this.inputSnapshot = inputSnapshot;
    this.outputSnapshot = outputSnapshot;
    this.createdAt = createdAt;
  }

  public UUID getPlannerDecisionId() {
    return plannerDecisionId;
  }

  public UUID getTrainingSessionId() {
    return trainingSessionId;
  }

  public UUID getSourceTurnId() {
    return sourceTurnId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getDecisionType() {
    return decisionType;
  }

  public String getNextStatus() {
    return nextStatus;
  }

  public String getNextStepKey() {
    return nextStepKey;
  }

  public String getNextMicroAction() {
    return nextMicroAction;
  }

  public String getNextHintLevel() {
    return nextHintLevel;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public String getPlannerVersion() {
    return plannerVersion;
  }

  public String getInputSnapshot() {
    return inputSnapshot;
  }

  public String getOutputSnapshot() {
    return outputSnapshot;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
