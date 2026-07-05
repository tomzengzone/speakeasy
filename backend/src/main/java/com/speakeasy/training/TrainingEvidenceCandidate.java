package com.speakeasy.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "training_evidence_candidates")
public class TrainingEvidenceCandidate {
  @Id
  @Column(name = "candidate_id", nullable = false)
  private UUID candidateId;

  @Column(name = "training_session_id", nullable = false)
  private UUID trainingSessionId;

  @Column(name = "source_turn_id")
  private UUID sourceTurnId;

  @Column(name = "learning_evidence_id")
  private UUID learningEvidenceId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "evidence_type", nullable = false)
  private String evidenceType;

  @Column(name = "target_expression_id")
  private UUID targetExpressionId;

  @Column(name = "confidence", nullable = false)
  private double confidence;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "rule_name", nullable = false)
  private String ruleName;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "schema_version", nullable = false)
  private int schemaVersion;

  @Column(name = "rule_input", nullable = false)
  private String ruleInput;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected TrainingEvidenceCandidate() {}

  public TrainingEvidenceCandidate(
      UUID candidateId,
      UUID trainingSessionId,
      UUID sourceTurnId,
      UUID learningEvidenceId,
      UUID userId,
      String evidenceType,
      UUID targetExpressionId,
      double confidence,
      String status,
      String ruleName,
      String reasonCode,
      int schemaVersion,
      String ruleInput,
      Instant createdAt) {
    this.candidateId = candidateId;
    this.trainingSessionId = trainingSessionId;
    this.sourceTurnId = sourceTurnId;
    this.learningEvidenceId = learningEvidenceId;
    this.userId = userId;
    this.evidenceType = evidenceType;
    this.targetExpressionId = targetExpressionId;
    this.confidence = confidence;
    this.status = status;
    this.ruleName = ruleName;
    this.reasonCode = reasonCode;
    this.schemaVersion = schemaVersion;
    this.ruleInput = ruleInput;
    this.createdAt = createdAt;
  }

  public UUID getCandidateId() {
    return candidateId;
  }

  public UUID getTrainingSessionId() {
    return trainingSessionId;
  }

  public UUID getSourceTurnId() {
    return sourceTurnId;
  }

  public UUID getLearningEvidenceId() {
    return learningEvidenceId;
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

  public double getConfidence() {
    return confidence;
  }

  public String getStatus() {
    return status;
  }

  public String getRuleName() {
    return ruleName;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public int getSchemaVersion() {
    return schemaVersion;
  }

  public String getRuleInput() {
    return ruleInput;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
