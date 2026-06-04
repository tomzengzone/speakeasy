package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_mastery_initial_states")
public class GoalMasteryInitialState {
  @Id
  @Column(name = "state_id", nullable = false)
  private UUID stateId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "dimension_key", nullable = false)
  private String dimensionKey;

  @Column(name = "initial_level", nullable = false)
  private String initialLevel;

  @Column(name = "evidence_ref", nullable = false)
  private String evidenceRef;

  @Column(name = "source", nullable = false)
  private String source;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalMasteryInitialState() {}

  public GoalMasteryInitialState(
      UUID stateId,
      UUID goalProfileId,
      UUID userId,
      String dimensionKey,
      String initialLevel,
      String evidenceRef,
      Instant createdAt) {
    this.stateId = stateId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    this.dimensionKey = dimensionKey;
    this.initialLevel = initialLevel;
    this.evidenceRef = evidenceRef;
    this.source = "initial_from_diagnostic";
    this.createdAt = createdAt;
  }

  public String getDimensionKey() {
    return dimensionKey;
  }

  public String getInitialLevel() {
    return initialLevel;
  }

  public String getSource() {
    return source;
  }
}
