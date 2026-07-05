package com.speakeasy.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "training_content_mappings")
public class TrainingContentMapping {
  @Id
  @Column(name = "mapping_id", nullable = false)
  private UUID mappingId;

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

  @Column(name = "step_key", nullable = false)
  private String stepKey;

  @Column(name = "micro_action", nullable = false)
  private String microAction;

  @Column(name = "order_index", nullable = false)
  private int orderIndex;

  @Column(name = "target_expression_id", nullable = false)
  private UUID targetExpressionId;

  @Column(name = "prompt_text", nullable = false)
  private String promptText;

  @Column(name = "review_status", nullable = false)
  private String reviewStatus;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected TrainingContentMapping() {}

  public TrainingContentMapping(
      UUID mappingId,
      String scenarioId,
      UUID scenarioVersionId,
      String levelCode,
      String mappingVersion,
      String actionChainVersion,
      String stepKey,
      String microAction,
      int orderIndex,
      UUID targetExpressionId,
      String promptText,
      String reviewStatus,
      Instant createdAt) {
    this.mappingId = mappingId;
    this.scenarioId = scenarioId;
    this.scenarioVersionId = scenarioVersionId;
    this.levelCode = levelCode;
    this.mappingVersion = mappingVersion;
    this.actionChainVersion = actionChainVersion;
    this.stepKey = stepKey;
    this.microAction = microAction;
    this.orderIndex = orderIndex;
    this.targetExpressionId = targetExpressionId;
    this.promptText = promptText;
    this.reviewStatus = reviewStatus;
    this.createdAt = createdAt;
  }

  public UUID getMappingId() {
    return mappingId;
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

  public String getStepKey() {
    return stepKey;
  }

  public String getMicroAction() {
    return microAction;
  }

  public int getOrderIndex() {
    return orderIndex;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public String getPromptText() {
    return promptText;
  }

  public String getReviewStatus() {
    return reviewStatus;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
