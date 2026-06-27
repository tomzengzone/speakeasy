package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goal_profiles")
public class GoalProfile {
  @Id
  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "goal_type", nullable = false)
  private String goalType;

  @Column(name = "target_score")
  private Double targetScore;

  @Column(name = "target_ability")
  private String targetAbility;

  @Column(name = "deadline", nullable = false)
  private LocalDate deadline;

  @Column(name = "daily_minutes", nullable = false)
  private int dailyMinutes;

  @Column(name = "intensity_preference", nullable = false)
  private String intensityPreference;

  @Column(name = "support_status", nullable = false)
  private String supportStatus;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "revision", nullable = false)
  private int revision;

  @Column(name = "limitation_message", nullable = false)
  private String limitationMessage;

  @Column(name = "quiet_hours_start")
  private String quietHoursStart;

  @Column(name = "quiet_hours_end")
  private String quietHoursEnd;

  @Column(name = "notification_consent", nullable = false)
  private boolean notificationConsent;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected GoalProfile() {}

  public GoalProfile(
      UUID goalProfileId,
      UUID userId,
      String goalType,
      Double targetScore,
      String targetAbility,
      LocalDate deadline,
      int dailyMinutes,
      String intensityPreference,
      String supportStatus,
      String status,
      String limitationMessage,
      String quietHoursStart,
      String quietHoursEnd,
      boolean notificationConsent,
      Instant now) {
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    revise(
        goalType,
        targetScore,
        targetAbility,
        deadline,
        dailyMinutes,
        intensityPreference,
        supportStatus,
        status,
        limitationMessage,
        quietHoursStart,
        quietHoursEnd,
        notificationConsent,
        now);
    this.revision = 1;
    this.createdAt = now;
  }

  public void revise(
      String goalType,
      Double targetScore,
      String targetAbility,
      LocalDate deadline,
      int dailyMinutes,
      String intensityPreference,
      String supportStatus,
      String status,
      String limitationMessage,
      String quietHoursStart,
      String quietHoursEnd,
      boolean notificationConsent,
      Instant now) {
    this.goalType = goalType;
    this.targetScore = targetScore;
    this.targetAbility = targetAbility;
    this.deadline = deadline;
    this.dailyMinutes = dailyMinutes;
    this.intensityPreference = intensityPreference;
    this.supportStatus = supportStatus;
    this.status = status;
    this.limitationMessage = limitationMessage;
    this.quietHoursStart = quietHoursStart;
    this.quietHoursEnd = quietHoursEnd;
    this.notificationConsent = notificationConsent;
    this.updatedAt = now;
    if (createdAt != null) {
      this.revision += 1;
    }
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getGoalType() {
    return goalType;
  }

  public Double getTargetScore() {
    return targetScore;
  }

  public String getTargetAbility() {
    return targetAbility;
  }

  public LocalDate getDeadline() {
    return deadline;
  }

  public int getDailyMinutes() {
    return dailyMinutes;
  }

  public String getIntensityPreference() {
    return intensityPreference;
  }

  public String getSupportStatus() {
    return supportStatus;
  }

  public String getStatus() {
    return status;
  }

  public int getRevision() {
    return revision;
  }

  public String getLimitationMessage() {
    return limitationMessage;
  }

  public String getQuietHoursStart() {
    return quietHoursStart;
  }

  public String getQuietHoursEnd() {
    return quietHoursEnd;
  }

  public boolean isNotificationConsent() {
    return notificationConsent;
  }
}
