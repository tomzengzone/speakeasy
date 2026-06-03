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
  private String ruleName;
  private String reasonCode;
  private Integer schemaVersion;
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
    this(
        evidenceId,
        userId,
        sourceType,
        sourceId,
        evidenceType,
        targetExpressionId,
        confidence,
        acceptedStatus,
        rejectionReason,
        null,
        null,
        null,
        createdAt);
  }

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
      String ruleName,
      String reasonCode,
      Integer schemaVersion,
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
    this.ruleName = ruleName;
    this.reasonCode = reasonCode;
    this.schemaVersion = schemaVersion;
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

  public String getRuleName() {
    return ruleName;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public Integer getSchemaVersion() {
    return schemaVersion;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
