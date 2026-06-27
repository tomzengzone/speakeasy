package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_autopilot_goal_idempotency")
public class GoalAutopilotGoalIdempotency {
  @Id
  @Column(name = "replay_id", nullable = false)
  private UUID replayId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "idempotency_key", nullable = false)
  private String idempotencyKey;

  @Column(name = "request_hash", nullable = false)
  private String requestHash;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "goal_revision", nullable = false)
  private int goalRevision;

  @Column(name = "response_json", nullable = false)
  private String responseJson;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalAutopilotGoalIdempotency() {}

  public GoalAutopilotGoalIdempotency(
      UUID replayId,
      UUID userId,
      String idempotencyKey,
      String requestHash,
      UUID goalProfileId,
      int goalRevision,
      String responseJson,
      Instant createdAt) {
    this.replayId = replayId;
    this.userId = userId;
    this.idempotencyKey = idempotencyKey;
    this.requestHash = requestHash;
    this.goalProfileId = goalProfileId;
    this.goalRevision = goalRevision;
    this.responseJson = responseJson;
    this.createdAt = createdAt;
  }

  public UUID getReplayId() {
    return replayId;
  }

  public String getRequestHash() {
    return requestHash;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public int getGoalRevision() {
    return goalRevision;
  }

  public String getResponseJson() {
    return responseJson;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
