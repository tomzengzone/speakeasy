package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "learning_history_entries")
public class LearningHistoryEntry {
  @Id
  private UUID historyEntryId;
  private UUID userId;
  private UUID sourceSessionId;
  private String title;
  private String status;
  private Instant createdAt;
  private Instant deletedAt;

  protected LearningHistoryEntry() {}

  public LearningHistoryEntry(UUID historyEntryId, UUID userId, UUID sourceSessionId, String title, Instant now) {
    this.historyEntryId = historyEntryId;
    this.userId = userId;
    this.sourceSessionId = sourceSessionId;
    this.title = title;
    this.status = "recorded";
    this.createdAt = now;
  }

  public void delete(Instant now) {
    this.status = "deleted";
    this.deletedAt = now;
  }

  public UUID getHistoryEntryId() {
    return historyEntryId;
  }

  public UUID getSourceSessionId() {
    return sourceSessionId;
  }

  public String getTitle() {
    return title;
  }

  public String getStatus() {
    return status;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
