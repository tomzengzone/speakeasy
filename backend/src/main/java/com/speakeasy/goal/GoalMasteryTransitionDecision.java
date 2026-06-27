package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_mastery_transition_decisions")
public class GoalMasteryTransitionDecision {
  @Id
  @Column(name = "transition_id", nullable = false)
  private UUID transitionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "goal_revision", nullable = false)
  private int goalRevision;

  @Column(name = "memory_item_state_id", nullable = false)
  private String memoryItemStateId;

  @Column(name = "item_type", nullable = false)
  private String itemType;

  @Column(name = "item_ref", nullable = false)
  private String itemRef;

  @Column(name = "previous_level", nullable = false)
  private String previousLevel;

  @Column(name = "proposed_level", nullable = false)
  private String proposedLevel;

  @Column(name = "accepted_level", nullable = false)
  private String acceptedLevel;

  @Column(name = "direction", nullable = false)
  private String direction;

  @Column(name = "evidence_refs_json", nullable = false)
  private String evidenceRefsJson;

  @Column(name = "confidence", nullable = false)
  private double confidence;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "rule_version", nullable = false)
  private String ruleVersion;

  @Column(name = "input_snapshot_hash", nullable = false)
  private String inputSnapshotHash;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalMasteryTransitionDecision() {}

  public GoalMasteryTransitionDecision(
      UUID transitionId,
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      String memoryItemStateId,
      String itemType,
      String itemRef,
      String previousLevel,
      String proposedLevel,
      String acceptedLevel,
      String direction,
      String evidenceRefsJson,
      double confidence,
      String reasonCode,
      String ruleVersion,
      String inputSnapshotHash,
      Instant createdAt) {
    this.transitionId = transitionId;
    this.userId = userId;
    this.goalProfileId = goalProfileId;
    this.goalRevision = goalRevision;
    this.memoryItemStateId = memoryItemStateId;
    this.itemType = itemType;
    this.itemRef = itemRef;
    this.previousLevel = previousLevel;
    this.proposedLevel = proposedLevel;
    this.acceptedLevel = acceptedLevel;
    this.direction = direction;
    this.evidenceRefsJson = evidenceRefsJson;
    this.confidence = confidence;
    this.reasonCode = reasonCode;
    this.ruleVersion = ruleVersion;
    this.inputSnapshotHash = inputSnapshotHash;
    this.createdAt = createdAt;
  }

  public UUID getTransitionId() {
    return transitionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public UUID getGoalProfileId() {
    return goalProfileId;
  }

  public int getGoalRevision() {
    return goalRevision;
  }

  public String getMemoryItemStateId() {
    return memoryItemStateId;
  }

  public String getItemType() {
    return itemType;
  }

  public String getItemRef() {
    return itemRef;
  }

  public String getPreviousLevel() {
    return previousLevel;
  }

  public String getProposedLevel() {
    return proposedLevel;
  }

  public String getAcceptedLevel() {
    return acceptedLevel;
  }

  public String getDirection() {
    return direction;
  }

  public String getEvidenceRefsJson() {
    return evidenceRefsJson;
  }

  public double getConfidence() {
    return confidence;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public String getRuleVersion() {
    return ruleVersion;
  }

  public String getInputSnapshotHash() {
    return inputSnapshotHash;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
