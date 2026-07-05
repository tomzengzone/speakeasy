package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "saved_expressions")
public class SavedExpression {
  @Id
  private UUID savedExpressionId;
  private UUID userId;
  private UUID targetExpressionId;
  private String expressionText;
  private String meaningCn;
  private String example;
  private UUID sourceEvidenceId;
  private String status;
  private Instant createdAt;
  private Instant updatedAt;

  protected SavedExpression() {}

  public SavedExpression(UUID savedExpressionId, UUID userId, UUID targetExpressionId, String expressionText, String meaningCn, String example, UUID sourceEvidenceId, Instant now) {
    this.savedExpressionId = savedExpressionId;
    this.userId = userId;
    this.targetExpressionId = targetExpressionId;
    this.expressionText = expressionText;
    this.meaningCn = meaningCn;
    this.example = example;
    this.sourceEvidenceId = sourceEvidenceId;
    this.status = "active";
    this.createdAt = now;
    this.updatedAt = now;
  }

  public UUID getSavedExpressionId() {
    return savedExpressionId;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public String getExpressionText() {
    return expressionText;
  }

  public String getMeaningCn() {
    return meaningCn;
  }

  public String getExample() {
    return example;
  }

  public String getStatus() {
    return status;
  }
}
