package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "learning_evidences")
public class LearningEvidence {
  @Id
  private UUID evidenceId;
  private UUID userId;
  private String sourceType;
  private String sourceId;
  private String evidenceType;
  private UUID targetExpressionId;
  private Double confidence;
  private String acceptedStatus;
  private String rejectionReason;
  private Instant createdAt;

  protected LearningEvidence() {}

  public LearningEvidence(
      UUID evidenceId,
      UUID userId,
      String sourceType,
      String sourceId,
      String evidenceType,
      UUID targetExpressionId,
      Double confidence,
      String acceptedStatus,
      String rejectionReason,
      Instant createdAt) {
    this.evidenceId = evidenceId;
    this.userId = userId;
    this.sourceType = sourceType;
    this.sourceId = sourceId;
    this.evidenceType = evidenceType;
    this.targetExpressionId = targetExpressionId;
    this.confidence = confidence;
    this.acceptedStatus = acceptedStatus;
    this.rejectionReason = rejectionReason;
    this.createdAt = createdAt;
  }

  public UUID getEvidenceId() {
    return evidenceId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getEvidenceType() {
    return evidenceType;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public Double getConfidence() {
    return confidence;
  }

  public String getAcceptedStatus() {
    return acceptedStatus;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
