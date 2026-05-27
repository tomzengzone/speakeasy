package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "scenario_levels")
public class ScenarioLevel {
  @Id
  @Column(name = "scenario_level_id", nullable = false)
  private UUID scenarioLevelId;

  @Column(name = "scenario_id", nullable = false)
  private String scenarioId;

  @Column(name = "level_code", nullable = false)
  private String levelCode;

  @Column(name = "target_level", nullable = false)
  private String targetLevel;

  @Column(name = "expression_count", nullable = false)
  private int expressionCount;

  protected ScenarioLevel() {}

  public ScenarioLevel(UUID scenarioLevelId, String scenarioId, String levelCode, int expressionCount) {
    this.scenarioLevelId = scenarioLevelId;
    this.scenarioId = scenarioId;
    this.levelCode = levelCode;
    this.targetLevel = levelCode;
    this.expressionCount = expressionCount;
  }
}
