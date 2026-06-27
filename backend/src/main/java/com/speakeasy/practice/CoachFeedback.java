package com.speakeasy.practice;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "coach_feedbacks")
public class CoachFeedback {
  @Id
  private UUID feedbackId;
  private UUID sessionId;
  private UUID sourceTurnId;
  private String feedbackType;
  private String summary;
  private String mainIssueType;
  private String suggestedExpression;
  private String nextPrompt;
  private String scoreKind;
  private Double scoreValue;
  private Double scoreConfidence;
  private String scoreStatus;
  private String validationStatus;
  private String providerStatus;
  private String recoverableErrorCode;
  private Instant createdAt;

  protected CoachFeedback() {}

  public CoachFeedback(
      UUID feedbackId,
      UUID sessionId,
      UUID sourceTurnId,
      String feedbackType,
      String summary,
      String mainIssueType,
      String suggestedExpression,
      String nextPrompt,
      String scoreKind,
      Double scoreValue,
      Double scoreConfidence,
      String scoreStatus,
      String validationStatus,
      String providerStatus,
      String recoverableErrorCode,
      Instant createdAt) {
    this.feedbackId = feedbackId;
    this.sessionId = sessionId;
    this.sourceTurnId = sourceTurnId;
    this.feedbackType = feedbackType;
    this.summary = summary;
    this.mainIssueType = mainIssueType;
    this.suggestedExpression = suggestedExpression;
    this.nextPrompt = nextPrompt;
    this.scoreKind = scoreKind;
    this.scoreValue = scoreValue;
    this.scoreConfidence = scoreConfidence;
    this.scoreStatus = scoreStatus;
    this.validationStatus = validationStatus;
    this.providerStatus = providerStatus;
    this.recoverableErrorCode = recoverableErrorCode;
    this.createdAt = createdAt;
  }

  public boolean recoverable() {
    return recoverableErrorCode != null && !recoverableErrorCode.isBlank();
  }

  public UUID getFeedbackId() {
    return feedbackId;
  }

  public UUID getSessionId() {
    return sessionId;
  }

  public UUID getSourceTurnId() {
    return sourceTurnId;
  }

  public String getFeedbackType() {
    return feedbackType;
  }

  public String getSummary() {
    return summary;
  }

  public String getMainIssueType() {
    return mainIssueType;
  }

  public String getSuggestedExpression() {
    return suggestedExpression;
  }

  public String getNextPrompt() {
    return nextPrompt;
  }

  public String getScoreKind() {
    return scoreKind;
  }

  public Double getScoreValue() {
    return scoreValue;
  }

  public Double getScoreConfidence() {
    return scoreConfidence;
  }

  public String getScoreStatus() {
    return scoreStatus;
  }

  public String getValidationStatus() {
    return validationStatus;
  }

  public String getProviderStatus() {
    return providerStatus;
  }

  public String getRecoverableErrorCode() {
    return recoverableErrorCode;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
