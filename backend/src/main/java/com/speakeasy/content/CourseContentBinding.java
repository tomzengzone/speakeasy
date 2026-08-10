package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "content_course_content_binding")
public class CourseContentBinding {
  @Id
  @Column(name = "course_content_binding_id", nullable = false)
  private UUID courseContentBindingId;

  @Column(name = "course_version_id", nullable = false)
  private UUID courseVersionId;

  @Column(name = "scenario_version_id", nullable = false)
  private UUID scenarioVersionId;

  @Column(name = "scenario_level_id", nullable = false)
  private UUID scenarioLevelId;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected CourseContentBinding() {}

  public UUID getCourseContentBindingId() {
    return courseContentBindingId;
  }

  public UUID getCourseVersionId() {
    return courseVersionId;
  }

  public UUID getScenarioVersionId() {
    return scenarioVersionId;
  }

  public UUID getScenarioLevelId() {
    return scenarioLevelId;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
