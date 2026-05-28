package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_scenario_states")
public class UserScenarioState {
  @Id
  @Column(name = "user_scenario_state_id", nullable = false)
  private UUID userScenarioStateId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "scenario_id", nullable = false)
  private String scenarioId;

  @Column(name = "state", nullable = false)
  private String state;

  @Column(name = "current_flag", nullable = false)
  private boolean current;

  @Column(name = "target_level", nullable = false)
  private String targetLevel;

  @Column(name = "joined_at")
  private Instant joinedAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected UserScenarioState() {}

  public UserScenarioState(UUID userScenarioStateId, UUID userId, String scenarioId, String targetLevel, Instant now) {
    this.userScenarioStateId = userScenarioStateId;
    this.userId = userId;
    this.scenarioId = scenarioId;
    this.state = "joined";
    this.current = false;
    this.targetLevel = targetLevel;
    this.joinedAt = now;
    this.updatedAt = now;
  }

  public UUID getUserScenarioStateId() {
    return userScenarioStateId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getScenarioId() {
    return scenarioId;
  }

  public String getState() {
    return state;
  }

  public boolean isCurrent() {
    return current;
  }

  public String getTargetLevel() {
    return targetLevel;
  }

  public Instant getJoinedAt() {
    return joinedAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void join(String targetLevel, Instant updatedAt) {
    this.state = "joined";
    this.targetLevel = targetLevel;
    if (this.joinedAt == null) {
      this.joinedAt = updatedAt;
    }
    this.updatedAt = updatedAt;
  }

  public void remove(Instant updatedAt) {
    this.state = "removed";
    this.current = false;
    this.updatedAt = updatedAt;
  }

  public void setCurrent(boolean current, Instant updatedAt) {
    this.current = current;
    this.updatedAt = updatedAt;
  }

  public void changeLevel(String targetLevel, Instant updatedAt) {
    this.targetLevel = targetLevel;
    this.updatedAt = updatedAt;
  }
}
