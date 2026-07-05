package com.speakeasy.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "training_recaps")
public class TrainingRecap {
  @Id
  @Column(name = "recap_id", nullable = false)
  private UUID recapId;

  @Column(name = "training_session_id", nullable = false)
  private UUID trainingSessionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "summary", nullable = false)
  private String summary;

  @Column(name = "learned_items", nullable = false)
  private String learnedItems;

  @Column(name = "weak_points", nullable = false)
  private String weakPoints;

  @Column(name = "next_focus", nullable = false)
  private String nextFocus;

  @Column(name = "accepted_evidence_ids", nullable = false)
  private String acceptedEvidenceIds;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected TrainingRecap() {}

  public TrainingRecap(
      UUID recapId,
      UUID trainingSessionId,
      UUID userId,
      String summary,
      String learnedItems,
      String weakPoints,
      String nextFocus,
      String acceptedEvidenceIds,
      Instant createdAt) {
    this.recapId = recapId;
    this.trainingSessionId = trainingSessionId;
    this.userId = userId;
    this.summary = summary;
    this.learnedItems = learnedItems;
    this.weakPoints = weakPoints;
    this.nextFocus = nextFocus;
    this.acceptedEvidenceIds = acceptedEvidenceIds;
    this.createdAt = createdAt;
  }

  public UUID getRecapId() {
    return recapId;
  }

  public UUID getTrainingSessionId() {
    return trainingSessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getSummary() {
    return summary;
  }

  public String getLearnedItems() {
    return learnedItems;
  }

  public String getWeakPoints() {
    return weakPoints;
  }

  public String getNextFocus() {
    return nextFocus;
  }

  public String getAcceptedEvidenceIds() {
    return acceptedEvidenceIds;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
