package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "target_expressions")
public class TargetExpression {
  @Id
  @Column(name = "target_expression_id", nullable = false)
  private UUID targetExpressionId;

  @Column(name = "scenario_version_id", nullable = false)
  private UUID scenarioVersionId;

  @Column(name = "level_code", nullable = false)
  private String levelCode;

  @Column(name = "text", nullable = false)
  private String text;

  @Column(name = "meaning_cn")
  private String meaningCn;

  @Column(name = "tags")
  private String tags;

  @Column(name = "usage_note")
  private String usageNote;

  protected TargetExpression() {}

  public TargetExpression(UUID targetExpressionId, UUID scenarioVersionId, String levelCode, String text) {
    this.targetExpressionId = targetExpressionId;
    this.scenarioVersionId = scenarioVersionId;
    this.levelCode = levelCode;
    this.text = text;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public UUID getScenarioVersionId() {
    return scenarioVersionId;
  }

  public String getLevelCode() {
    return levelCode;
  }

  public String getText() {
    return text;
  }

  public String getMeaningCn() {
    return meaningCn;
  }

  public String getTags() {
    return tags;
  }

  public String getUsageNote() {
    return usageNote;
  }
}
