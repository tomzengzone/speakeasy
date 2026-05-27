package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_profiles")
public class UserProfile {
  @Id
  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "nickname")
  private String nickname;

  @Column(name = "target_level")
  private String targetLevel;

  @Column(name = "daily_minutes", nullable = false)
  private int dailyMinutes;

  @Column(name = "reminder_enabled", nullable = false)
  private boolean reminderEnabled;

  @Column(name = "reminder_time")
  private String reminderTime;

  @Column(name = "theme")
  private String theme;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected UserProfile() {}

  public UserProfile(UUID userId, String nickname, String targetLevel, int dailyMinutes, Instant updatedAt) {
    this.userId = userId;
    this.nickname = nickname;
    this.targetLevel = targetLevel;
    this.dailyMinutes = dailyMinutes;
    this.reminderEnabled = false;
    this.updatedAt = updatedAt;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getNickname() {
    return nickname;
  }

  public String getTargetLevel() {
    return targetLevel;
  }

  public int getDailyMinutes() {
    return dailyMinutes;
  }

  public boolean isReminderEnabled() {
    return reminderEnabled;
  }

  public String getReminderTime() {
    return reminderTime;
  }

  public String getTheme() {
    return theme;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void update(String targetLevel, Integer dailyMinutes, Boolean reminderEnabled, String reminderTime, Instant updatedAt) {
    if (targetLevel != null && !targetLevel.isBlank()) {
      this.targetLevel = targetLevel;
    }
    if (dailyMinutes != null) {
      this.dailyMinutes = dailyMinutes;
    }
    if (reminderEnabled != null) {
      this.reminderEnabled = reminderEnabled;
    }
    if (reminderTime != null) {
      this.reminderTime = reminderTime;
    }
    this.updatedAt = updatedAt;
  }
}
