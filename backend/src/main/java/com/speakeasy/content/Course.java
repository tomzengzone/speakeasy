package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "content_course")
public class Course {
  @Id
  @Column(name = "course_id", nullable = false)
  private UUID courseId;

  @Column(name = "scenario_id", nullable = false)
  private String scenarioId;

  @Column(name = "slug", nullable = false)
  private String slug;

  @Column(name = "sort_order", nullable = false)
  private int sortOrder;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected Course() {}

  public UUID getCourseId() {
    return courseId;
  }

  public String getScenarioId() {
    return scenarioId;
  }

  public String getSlug() {
    return slug;
  }

  public int getSortOrder() {
    return sortOrder;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
