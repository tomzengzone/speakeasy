package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "review_items")
public class ReviewItem {
  @Id
  private UUID reviewItemId;
  private UUID userId;
  private UUID targetExpressionId;
  private UUID sourceEvidenceId;
  private String promptType;
  private Instant dueAt;
  private int intervalDays;
  private String status;
  private Instant updatedAt;

  protected ReviewItem() {}

  public ReviewItem(UUID reviewItemId, UUID userId, UUID targetExpressionId, UUID sourceEvidenceId, String promptType, Instant dueAt, int intervalDays, Instant now) {
    this.reviewItemId = reviewItemId;
    this.userId = userId;
    this.targetExpressionId = targetExpressionId;
    this.sourceEvidenceId = sourceEvidenceId;
    this.promptType = promptType;
    this.dueAt = dueAt;
    this.intervalDays = intervalDays;
    this.status = "due";
    this.updatedAt = now;
  }

  public void submit(String result, Instant now) {
    this.status = "skipped".equals(result) ? "skipped" : "completed";
    this.updatedAt = now;
  }

  public UUID getReviewItemId() {
    return reviewItemId;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public String getPromptType() {
    return promptType;
  }

  public Instant getDueAt() {
    return dueAt;
  }

  public String getStatus() {
    return status;
  }
}
