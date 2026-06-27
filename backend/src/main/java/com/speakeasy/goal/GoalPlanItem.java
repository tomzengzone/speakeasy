package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_plan_items")
public class GoalPlanItem {
  @Id
  @Column(name = "plan_item_id", nullable = false)
  private UUID planItemId;

  @Column(name = "daily_plan_id", nullable = false)
  private UUID dailyPlanId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "item_type", nullable = false)
  private String itemType;

  @Column(name = "title", nullable = false)
  private String title;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "duration_minutes", nullable = false)
  private int durationMinutes;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "memory_risk", nullable = false)
  private String memoryRisk;

  @Column(name = "pressure_level", nullable = false)
  private String pressureLevel;

  @Column(name = "order_index", nullable = false)
  private int orderIndex;

  @Column(name = "completed_at")
  private Instant completedAt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected GoalPlanItem() {}

  public GoalPlanItem(
      UUID planItemId,
      UUID dailyPlanId,
      UUID goalProfileId,
      UUID userId,
      String itemType,
      String title,
      String reasonCode,
      int durationMinutes,
      String status,
      String memoryRisk,
      String pressureLevel,
      int orderIndex,
      Instant now) {
    this.planItemId = planItemId;
    this.dailyPlanId = dailyPlanId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    this.itemType = itemType;
    this.title = title;
    this.reasonCode = reasonCode;
    this.durationMinutes = durationMinutes;
    this.status = status;
    this.memoryRisk = memoryRisk;
    this.pressureLevel = pressureLevel;
    this.orderIndex = orderIndex;
    this.createdAt = now;
    this.updatedAt = now;
  }

  public void markOutcome(String outcome, Instant now) {
    this.status = outcome;
    this.updatedAt = now;
    if ("completed".equals(outcome)) {
      this.completedAt = now;
    }
  }

  public void activate(Instant now) {
    this.status = "active";
    this.updatedAt = now;
  }

  public UUID getPlanItemId() {
    return planItemId;
  }

  public UUID getDailyPlanId() {
    return dailyPlanId;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public String getItemType() {
    return itemType;
  }

  public String getTitle() {
    return title;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public int getDurationMinutes() {
    return durationMinutes;
  }

  public String getStatus() {
    return status;
  }

  public String getMemoryRisk() {
    return memoryRisk;
  }

  public String getPressureLevel() {
    return pressureLevel;
  }

  public int getOrderIndex() {
    return orderIndex;
  }
}
