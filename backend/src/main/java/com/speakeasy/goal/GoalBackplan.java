package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goal_backplans")
public class GoalBackplan {
  @Id
  @Column(name = "weekly_backplan_id", nullable = false)
  private UUID weeklyBackplanId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "plan_version", nullable = false)
  private String planVersion;

  @Column(name = "start_date", nullable = false)
  private LocalDate startDate;

  @Column(name = "end_date", nullable = false)
  private LocalDate endDate;

  @Column(name = "milestone", nullable = false)
  private String milestone;

  @Column(name = "session_count", nullable = false)
  private int sessionCount;

  @Column(name = "review_windows", nullable = false)
  private String reviewWindows;

  @Column(name = "checkpoint_due_date", nullable = false)
  private LocalDate checkpointDueDate;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "stale_reason")
  private String staleReason;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected GoalBackplan() {}

  public GoalBackplan(
      UUID weeklyBackplanId,
      UUID goalProfileId,
      UUID userId,
      String planVersion,
      LocalDate startDate,
      LocalDate endDate,
      String milestone,
      int sessionCount,
      String reviewWindows,
      LocalDate checkpointDueDate,
      String status,
      Instant now) {
    this.weeklyBackplanId = weeklyBackplanId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    this.planVersion = planVersion;
    this.startDate = startDate;
    this.endDate = endDate;
    this.milestone = milestone;
    this.sessionCount = sessionCount;
    this.reviewWindows = reviewWindows;
    this.checkpointDueDate = checkpointDueDate;
    this.status = status;
    this.createdAt = now;
    this.updatedAt = now;
  }

  public void markStale(String reasonCode, Instant now) {
    this.status = "stale";
    this.staleReason = reasonCode;
    this.updatedAt = now;
  }

  public UUID getWeeklyBackplanId() {
    return weeklyBackplanId;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public String getPlanVersion() {
    return planVersion;
  }

  public LocalDate getStartDate() {
    return startDate;
  }

  public LocalDate getEndDate() {
    return endDate;
  }

  public String getMilestone() {
    return milestone;
  }

  public int getSessionCount() {
    return sessionCount;
  }

  public String getReviewWindows() {
    return reviewWindows;
  }

  public LocalDate getCheckpointDueDate() {
    return checkpointDueDate;
  }

  public String getStatus() {
    return status;
  }
}
