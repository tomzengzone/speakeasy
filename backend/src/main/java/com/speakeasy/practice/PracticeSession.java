package com.speakeasy.practice;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "practice_sessions")
public class PracticeSession {
  @Id
  private UUID practiceSessionId;
  private UUID userId;
  private String scenarioId;
  private String levelCode;
  private String status;
  private int currentTurnIndex;
  private Instant startedAt;
  private Instant updatedAt;
  private Instant completedAt;

  protected PracticeSession() {}

  public PracticeSession(UUID practiceSessionId, UUID userId, String scenarioId, String levelCode, Instant now) {
    this.practiceSessionId = practiceSessionId;
    this.userId = userId;
    this.scenarioId = scenarioId;
    this.levelCode = levelCode;
    this.status = "active";
    this.currentTurnIndex = 0;
    this.startedAt = now;
    this.updatedAt = now;
  }

  public void markFeedbackReady(int turnIndex, Instant now) {
    this.status = "feedback";
    this.currentTurnIndex = turnIndex;
    this.updatedAt = now;
  }

  public void markRecoverableError(int turnIndex, Instant now) {
    this.status = "recoverable_error";
    this.currentTurnIndex = turnIndex;
    this.updatedAt = now;
  }

  public void complete(Instant now) {
    this.status = "completed";
    this.completedAt = now;
    this.updatedAt = now;
  }

  public UUID getPracticeSessionId() {
    return practiceSessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getScenarioId() {
    return scenarioId;
  }

  public String getLevelCode() {
    return levelCode;
  }

  public String getStatus() {
    return status;
  }

  public int getCurrentTurnIndex() {
    return currentTurnIndex;
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
}
