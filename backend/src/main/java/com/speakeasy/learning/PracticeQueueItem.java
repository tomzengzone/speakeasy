package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "practice_queue_items")
public class PracticeQueueItem {
  @Id
  private UUID queueItemId;
  private UUID userId;
  private String sourceType;
  private UUID targetExpressionId;
  private String taskType;
  private int priority;
  private String status;
  private Instant dueAt;
  private Instant createdAt;
  private Instant updatedAt;

  protected PracticeQueueItem() {}

  public PracticeQueueItem(
      UUID queueItemId,
      UUID userId,
      String sourceType,
      UUID targetExpressionId,
      String taskType,
      int priority,
      Instant dueAt,
      Instant now) {
    this.queueItemId = queueItemId;
    this.userId = userId;
    this.sourceType = sourceType;
    this.targetExpressionId = targetExpressionId;
    this.taskType = taskType;
    this.priority = priority;
    this.status = "ready";
    this.dueAt = dueAt;
    this.createdAt = now;
    this.updatedAt = now;
  }

  public void complete(Instant now) {
    this.status = "completed";
    this.updatedAt = now;
  }

  public UUID getQueueItemId() {
    return queueItemId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getSourceType() {
    return sourceType;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public String getTaskType() {
    return taskType;
  }

  public int getPriority() {
    return priority;
  }

  public String getStatus() {
    return status;
  }

  public Instant getDueAt() {
    return dueAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
