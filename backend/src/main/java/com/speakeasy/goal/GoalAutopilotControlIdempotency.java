package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_autopilot_control_idempotency")
public class GoalAutopilotControlIdempotency {
  @Id
  @Column(name = "replay_id", nullable = false)
  private UUID replayId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "goal_revision", nullable = false)
  private int goalRevision;

  @Column(name = "operation", nullable = false)
  private String operation;

  @Column(name = "idempotency_key", nullable = false)
  private String idempotencyKey;

  @Column(name = "request_hash", nullable = false)
  private String requestHash;

  @Column(name = "response_json", nullable = false)
  private String responseJson;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalAutopilotControlIdempotency() {}

  public GoalAutopilotControlIdempotency(
      UUID replayId,
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      String operation,
      String idempotencyKey,
      String requestHash,
      String responseJson,
      Instant createdAt) {
    this.replayId = replayId;
    this.userId = userId;
    this.goalProfileId = goalProfileId;
    this.goalRevision = goalRevision;
    this.operation = operation;
    this.idempotencyKey = idempotencyKey;
    this.requestHash = requestHash;
    this.responseJson = responseJson;
    this.createdAt = createdAt;
  }

  public UUID getReplayId() {
    return replayId;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public int getGoalRevision() {
    return goalRevision;
  }

  public String getOperation() {
    return operation;
  }

  public String getRequestHash() {
    return requestHash;
  }

  public String getResponseJson() {
    return responseJson;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
