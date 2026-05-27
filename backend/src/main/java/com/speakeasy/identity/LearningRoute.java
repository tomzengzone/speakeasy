package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "learning_routes")
public class LearningRoute {
  @Id
  @Column(name = "route_id", nullable = false)
  private UUID routeId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "current_scenario_id", nullable = false)
  private String currentScenarioId;

  @Column(name = "target_level", nullable = false)
  private String targetLevel;

  @Column(name = "source_assessment_id")
  private UUID sourceAssessmentId;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected LearningRoute() {}

  public LearningRoute(UUID routeId, UUID userId, String currentScenarioId, String targetLevel, Instant now) {
    this.routeId = routeId;
    this.userId = userId;
    this.currentScenarioId = currentScenarioId;
    this.targetLevel = targetLevel;
    this.createdAt = now;
    this.updatedAt = now;
  }
}
