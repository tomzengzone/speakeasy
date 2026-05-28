package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "mastery_records")
public class MasteryRecord {
  @Id
  private UUID masteryRecordId;
  private UUID userId;
  private UUID targetExpressionId;
  private String masteryStatus;
  private Double score;
  private UUID lastEvidenceId;
  private Instant updatedAt;

  protected MasteryRecord() {}

  public MasteryRecord(UUID masteryRecordId, UUID userId, UUID targetExpressionId, String masteryStatus, Double score, UUID lastEvidenceId, Instant updatedAt) {
    this.masteryRecordId = masteryRecordId;
    this.userId = userId;
    this.targetExpressionId = targetExpressionId;
    this.masteryStatus = masteryStatus;
    this.score = score;
    this.lastEvidenceId = lastEvidenceId;
    this.updatedAt = updatedAt;
  }

  public void update(String masteryStatus, Double score, UUID lastEvidenceId, Instant now) {
    this.masteryStatus = masteryStatus;
    this.score = score;
    this.lastEvidenceId = lastEvidenceId;
    this.updatedAt = now;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public String getMasteryStatus() {
    return masteryStatus;
  }

  public Double getScore() {
    return score;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
