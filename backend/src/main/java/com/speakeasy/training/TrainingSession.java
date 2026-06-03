package com.speakeasy.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "training_sessions")
public class TrainingSession {
  @Id
  @Column(name = "training_session_id", nullable = false)
  private UUID trainingSessionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "scenario_id", nullable = false)
  private String scenarioId;

  @Column(name = "scenario_version_id", nullable = false)
  private UUID scenarioVersionId;

  @Column(name = "level_code", nullable = false)
  private String levelCode;

  @Column(name = "mapping_version", nullable = false)
  private String mappingVersion;

  @Column(name = "action_chain_version", nullable = false)
  private String actionChainVersion;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "current_turn_index", nullable = false)
  private int currentTurnIndex;

  @Column(name = "current_step_key", nullable = false)
  private String currentStepKey;

  @Column(name = "current_micro_action", nullable = false)
  private String currentMicroAction;

  @Column(name = "hint_level", nullable = false)
  private String hintLevel;

  @Column(name = "failure_count", nullable = false)
  private int failureCount;

  @Column(name = "success_count", nullable = false)
  private int successCount;

  @Column(name = "evidence_write_status", nullable = false)
  private String evidenceWriteStatus;

  @Column(name = "sync_status", nullable = false)
  private String syncStatus;

  @Column(name = "last_reason_code")
  private String lastReasonCode;

  @Column(name = "started_at", nullable = false)
  private Instant startedAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  @Column(name = "completed_at")
  private Instant completedAt;

  protected TrainingSession() {}

  public TrainingSession(
      UUID trainingSessionId,
      UUID userId,
      String scenarioId,
      UUID scenarioVersionId,
      String levelCode,
      String mappingVersion,
      String actionChainVersion,
      Instant startedAt) {
    this.trainingSessionId = trainingSessionId;
    this.userId = userId;
    this.scenarioId = scenarioId;
    this.scenarioVersionId = scenarioVersionId;
    this.levelCode = levelCode;
    this.mappingVersion = mappingVersion;
    this.actionChainVersion = actionChainVersion;
    this.status = "ready";
    this.currentTurnIndex = 0;
    this.currentStepKey = "opening";
    this.currentMicroAction = "SayOne";
    this.hintLevel = "none";
    this.failureCount = 0;
    this.successCount = 0;
    this.evidenceWriteStatus = "not_started";
    this.syncStatus = "server_synced";
    this.startedAt = startedAt;
    this.updatedAt = startedAt;
  }

  public UUID getTrainingSessionId() {
    return trainingSessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getScenarioId() {
    return scenarioId;
  }

  public UUID getScenarioVersionId() {
    return scenarioVersionId;
  }

  public String getLevelCode() {
    return levelCode;
  }

  public String getMappingVersion() {
    return mappingVersion;
  }

  public String getActionChainVersion() {
    return actionChainVersion;
  }

  public String getStatus() {
    return status;
  }

  public int getCurrentTurnIndex() {
    return currentTurnIndex;
  }

  public String getCurrentStepKey() {
    return currentStepKey;
  }

  public String getCurrentMicroAction() {
    return currentMicroAction;
  }

  public String getHintLevel() {
    return hintLevel;
  }

  public int getFailureCount() {
    return failureCount;
  }

  public int getSuccessCount() {
    return successCount;
  }

  public String getEvidenceWriteStatus() {
    return evidenceWriteStatus;
  }

  public String getSyncStatus() {
    return syncStatus;
  }

  public String getLastReasonCode() {
    return lastReasonCode;
  }

  public Instant getStartedAt() {
    return startedAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public boolean terminal() {
    return "completed".equals(status) || "abandoned".equals(status);
  }

  public void recordSuccess() {
    successCount += 1;
    failureCount = 0;
  }

  public void recordFailure() {
    failureCount += 1;
    successCount = 0;
  }

  public void applyPlannerDecision(TrainingPlannerDecision decision, int turnIndex, Instant now) {
    this.status = decision.getNextStatus();
    this.currentStepKey = decision.getNextStepKey();
    this.currentMicroAction = decision.getNextMicroAction();
    this.hintLevel = decision.getNextHintLevel();
    this.lastReasonCode = decision.getReasonCode();
    this.currentTurnIndex = Math.max(currentTurnIndex, turnIndex);
    this.updatedAt = now;
  }

  public void markEvidenceWritten(boolean accepted, Instant now) {
    this.evidenceWriteStatus = accepted ? "accepted_written" : "rejected_no_write";
    this.updatedAt = now;
  }

  public void setStatus(String status, String reasonCode, Instant now) {
    this.status = status;
    this.lastReasonCode = reasonCode;
    this.updatedAt = now;
  }

  public void complete(Instant now) {
    this.status = "completed";
    this.completedAt = now;
    this.updatedAt = now;
    this.syncStatus = "server_synced";
  }
}
