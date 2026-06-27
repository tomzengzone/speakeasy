package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goal_daily_plans")
public class GoalDailyPlan {
  @Id
  @Column(name = "daily_plan_id", nullable = false)
  private UUID dailyPlanId;

  @Column(name = "weekly_backplan_id", nullable = false)
  private UUID weeklyBackplanId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "plan_date", nullable = false)
  private LocalDate planDate;

  @Column(name = "total_minutes", nullable = false)
  private int totalMinutes;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "limitation_message", nullable = false)
  private String limitationMessage;

  @Column(name = "memory_policy_version", nullable = false)
  private String memoryPolicyVersion;

  @Column(name = "forgetting_risk", nullable = false)
  private String forgettingRisk;

  @Column(name = "next_review_interval_days", nullable = false)
  private int nextReviewIntervalDays;

  @Column(name = "overlearning_cap", nullable = false)
  private int overlearningCap;

  @Column(name = "interleaving_rule", nullable = false)
  private String interleavingRule;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected GoalDailyPlan() {}

  public GoalDailyPlan(
      UUID dailyPlanId,
      UUID weeklyBackplanId,
      UUID goalProfileId,
      UUID userId,
      LocalDate planDate,
      int totalMinutes,
      String status,
      String limitationMessage,
      String forgettingRisk,
      int nextReviewIntervalDays,
      Instant now) {
    this.dailyPlanId = dailyPlanId;
    this.weeklyBackplanId = weeklyBackplanId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    this.planDate = planDate;
    this.totalMinutes = totalMinutes;
    this.status = status;
    this.limitationMessage = limitationMessage;
    this.memoryPolicyVersion = "memory-curve-v1";
    this.forgettingRisk = forgettingRisk;
    this.nextReviewIntervalDays = nextReviewIntervalDays;
    this.overlearningCap = 2;
    this.interleavingRule = "rotate_fluency_pronunciation_scenario_fit";
    this.createdAt = now;
    this.updatedAt = now;
  }

  public void markStale(Instant now) {
    this.status = "stale";
    this.updatedAt = now;
  }

  public void markRecoveryRequired(Instant now) {
    this.status = "recovery_required";
    this.updatedAt = now;
  }

  public UUID getDailyPlanId() {
    return dailyPlanId;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public LocalDate getPlanDate() {
    return planDate;
  }

  public int getTotalMinutes() {
    return totalMinutes;
  }

  public String getStatus() {
    return status;
  }

  public String getLimitationMessage() {
    return limitationMessage;
  }

  public String getMemoryPolicyVersion() {
    return memoryPolicyVersion;
  }

  public String getForgettingRisk() {
    return forgettingRisk;
  }

  public int getNextReviewIntervalDays() {
    return nextReviewIntervalDays;
  }

  public int getOverlearningCap() {
    return overlearningCap;
  }

  public String getInterleavingRule() {
    return interleavingRule;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
