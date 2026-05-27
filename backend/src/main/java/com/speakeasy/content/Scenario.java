package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "scenarios")
public class Scenario {
  @Id
  @Column(name = "scenario_id", nullable = false)
  private String scenarioId;

  @Column(name = "slug", nullable = false)
  private String slug;

  @Column(name = "title", nullable = false)
  private String title;

  @Column(name = "summary")
  private String summary;

  @Column(name = "category")
  private String category;

  @Column(name = "status", nullable = false)
  private String status;

  protected Scenario() {}

  public Scenario(String scenarioId, String title, String summary) {
    this.scenarioId = scenarioId;
    this.slug = scenarioId;
    this.title = title;
    this.summary = summary;
    this.category = "official";
    this.status = "available";
  }

  public String getScenarioId() {
    return scenarioId;
  }
}
