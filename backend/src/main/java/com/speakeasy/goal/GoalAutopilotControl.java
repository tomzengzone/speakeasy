package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_autopilot_controls")
public class GoalAutopilotControl {
  @Id
  @Column(name = "control_id", nullable = false)
  private UUID controlId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "control_status", nullable = false)
  private String controlStatus;

  @Column(name = "paused_at")
  private Instant pausedAt;

  @Column(name = "pause_reason")
  private String pauseReason;

  @Column(name = "resumed_at")
  private Instant resumedAt;

  @Column(name = "quiet_hours_start")
  private String quietHoursStart;

  @Column(name = "quiet_hours_end")
  private String quietHoursEnd;

  @Column(name = "timezone", nullable = false)
  private String timezone;

  @Column(name = "notification_consent", nullable = false)
  private boolean notificationConsent;

  @Column(name = "intensity_override")
  private String intensityOverride;

  @Column(name = "missed_day_policy", nullable = false)
  private String missedDayPolicy;

  @Column(name = "rule_version", nullable = false)
  private String ruleVersion;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected GoalAutopilotControl() {}

  public GoalAutopilotControl(
      UUID controlId,
      UUID userId,
      UUID goalProfileId,
      String controlStatus,
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      boolean notificationConsent,
      String intensityOverride,
      String missedDayPolicy,
      String ruleVersion,
      Instant now) {
    this.controlId = controlId;
    this.userId = userId;
    this.goalProfileId = goalProfileId;
    this.controlStatus = controlStatus;
    this.quietHoursStart = quietHoursStart;
    this.quietHoursEnd = quietHoursEnd;
    this.timezone = timezone;
    this.notificationConsent = notificationConsent;
    this.intensityOverride = intensityOverride;
    this.missedDayPolicy = missedDayPolicy;
    this.ruleVersion = ruleVersion;
    this.createdAt = now;
    this.updatedAt = now;
  }

  public void updateSettings(
      String controlStatus,
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      boolean notificationConsent,
      String intensityOverride,
      String missedDayPolicy,
      Instant now) {
    this.controlStatus = controlStatus;
    this.quietHoursStart = quietHoursStart;
    this.quietHoursEnd = quietHoursEnd;
    this.timezone = timezone;
    this.notificationConsent = notificationConsent;
    this.intensityOverride = intensityOverride;
    this.missedDayPolicy = missedDayPolicy;
    this.updatedAt = now;
  }

  public boolean pause(String pauseReason, Instant now) {
    if ("paused".equals(controlStatus)) {
      return false;
    }
    this.controlStatus = "paused";
    this.pausedAt = now;
    this.pauseReason = pauseReason;
    this.resumedAt = null;
    this.updatedAt = now;
    return true;
  }

  public boolean resume(String controlStatus, Instant now) {
    if (!"paused".equals(this.controlStatus) && this.pausedAt == null && this.pauseReason == null) {
      return false;
    }
    this.controlStatus = controlStatus;
    this.resumedAt = now;
    this.pausedAt = null;
    this.pauseReason = null;
    this.updatedAt = now;
    return true;
  }

  public void setPolicyStatus(String controlStatus, Instant now) {
    if (!"paused".equals(this.controlStatus) && !this.controlStatus.equals(controlStatus)) {
      this.controlStatus = controlStatus;
      this.updatedAt = now;
    }
  }

  public UUID getControlId() {
    return controlId;
  }

  public UUID getUserId() {
    return userId;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public String getControlStatus() {
    return controlStatus;
  }

  public Instant getPausedAt() {
    return pausedAt;
  }

  public String getPauseReason() {
    return pauseReason;
  }

  public Instant getResumedAt() {
    return resumedAt;
  }

  public String getQuietHoursStart() {
    return quietHoursStart;
  }

  public String getQuietHoursEnd() {
    return quietHoursEnd;
  }

  public String getTimezone() {
    return timezone;
  }

  public boolean isNotificationConsent() {
    return notificationConsent;
  }

  public String getIntensityOverride() {
    return intensityOverride;
  }

  public String getMissedDayPolicy() {
    return missedDayPolicy;
  }

  public String getRuleVersion() {
    return ruleVersion;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
