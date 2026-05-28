package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "onboarding_assessments")
public class OnboardingAssessment {
  @Id
  @Column(name = "assessment_id", nullable = false)
  private UUID assessmentId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "goal_direction", nullable = false)
  private String goalDirection;

  @Column(name = "pain_points")
  private String painPoints;

  @Column(name = "output_level", nullable = false)
  private String outputLevel;

  @Column(name = "daily_minutes", nullable = false)
  private int dailyMinutes;

  @Column(name = "completed_at", nullable = false)
  private Instant completedAt;

  protected OnboardingAssessment() {}

  public OnboardingAssessment(UUID assessmentId, UUID userId, String goalDirection, String outputLevel, int dailyMinutes, Instant completedAt) {
    this(assessmentId, userId, goalDirection, null, outputLevel, dailyMinutes, completedAt);
  }

  public OnboardingAssessment(
      UUID assessmentId,
      UUID userId,
      String goalDirection,
      String painPoints,
      String outputLevel,
      int dailyMinutes,
      Instant completedAt) {
    this.assessmentId = assessmentId;
    this.userId = userId;
    this.goalDirection = goalDirection;
    this.painPoints = painPoints;
    this.outputLevel = outputLevel;
    this.dailyMinutes = dailyMinutes;
    this.completedAt = completedAt;
  }

  public UUID getAssessmentId() {
    return assessmentId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getGoalDirection() {
    return goalDirection;
  }

  public String getPainPoints() {
    return painPoints;
  }

  public String getOutputLevel() {
    return outputLevel;
  }

  public int getDailyMinutes() {
    return dailyMinutes;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }
}
