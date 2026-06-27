package com.speakeasy.practice;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "session_summaries")
public class SessionSummary {
  @Id
  private UUID summaryId;
  private UUID sessionId;
  private UUID userId;
  private String learnedItems;
  private String weakPoints;
  private String nextFocus;
  private String evidenceCandidatePayload;
  private Instant createdAt;

  protected SessionSummary() {}

  public SessionSummary(
      UUID summaryId,
      UUID sessionId,
      UUID userId,
      List<String> learnedItems,
      List<String> weakPoints,
      String nextFocus,
      String evidenceCandidatePayload,
      Instant createdAt) {
    this.summaryId = summaryId;
    this.sessionId = sessionId;
    this.userId = userId;
    this.learnedItems = join(learnedItems);
    this.weakPoints = join(weakPoints);
    this.nextFocus = nextFocus;
    this.evidenceCandidatePayload = evidenceCandidatePayload;
    this.createdAt = createdAt;
  }

  private static String join(List<String> values) {
    return String.join("|", values == null ? List.of() : values);
  }

  private static List<String> split(String value) {
    return value == null || value.isBlank() ? List.of() : Arrays.stream(value.split("\\|")).toList();
  }

  public UUID getSummaryId() {
    return summaryId;
  }

  public UUID getSessionId() {
    return sessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public List<String> getLearnedItems() {
    return split(learnedItems);
  }

  public List<String> getWeakPoints() {
    return split(weakPoints);
  }

  public String getNextFocus() {
    return nextFocus;
  }

  public String getEvidenceCandidatePayload() {
    return evidenceCandidatePayload;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
