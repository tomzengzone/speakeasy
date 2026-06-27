package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "expression_practice_attempts")
public class ExpressionPracticeAttempt {
  @Id
  private UUID attemptId;
  private UUID queueItemId;
  private UUID userId;
  private String taskType;
  private String answerText;
  private String transcriptRef;
  private String result;
  private Double bestScore;
  private Instant completedAt;

  protected ExpressionPracticeAttempt() {}

  public ExpressionPracticeAttempt(
      UUID attemptId,
      UUID queueItemId,
      UUID userId,
      String taskType,
      String answerText,
      String transcriptRef,
      String result,
      Double bestScore,
      Instant completedAt) {
    this.attemptId = attemptId;
    this.queueItemId = queueItemId;
    this.userId = userId;
    this.taskType = taskType;
    this.answerText = answerText;
    this.transcriptRef = transcriptRef;
    this.result = result;
    this.bestScore = bestScore;
    this.completedAt = completedAt;
  }

  public UUID getAttemptId() {
    return attemptId;
  }

  public UUID getQueueItemId() {
    return queueItemId;
  }

  public Double getBestScore() {
    return bestScore;
  }
}
