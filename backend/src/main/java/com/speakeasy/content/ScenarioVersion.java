package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "scenario_versions")
public class ScenarioVersion {
  @Id
  @Column(name = "scenario_version_id", nullable = false)
  private UUID scenarioVersionId;

  @Column(name = "scenario_id", nullable = false)
  private String scenarioId;

  @Column(name = "version", nullable = false)
  private String version;

  @Column(name = "content_status", nullable = false)
  private String contentStatus;

  @Column(name = "published_at")
  private Instant publishedAt;

  protected ScenarioVersion() {}

  public ScenarioVersion(UUID scenarioVersionId, String scenarioId, String version, Instant publishedAt) {
    this.scenarioVersionId = scenarioVersionId;
    this.scenarioId = scenarioId;
    this.version = version;
    this.contentStatus = "published";
    this.publishedAt = publishedAt;
  }

  public UUID getScenarioVersionId() {
    return scenarioVersionId;
  }

  public String getScenarioId() {
    return scenarioId;
  }

  public String getVersion() {
    return version;
  }

  public String getContentStatus() {
    return contentStatus;
  }

  public Instant getPublishedAt() {
    return publishedAt;
  }
}
