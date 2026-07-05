package com.speakeasy.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "training_turns")
public class TrainingTurn {
  @Id
  @Column(name = "training_turn_id", nullable = false)
  private UUID trainingTurnId;

  @Column(name = "training_session_id", nullable = false)
  private UUID trainingSessionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "turn_index", nullable = false)
  private int turnIndex;

  @Column(name = "step_key", nullable = false)
  private String stepKey;

  @Column(name = "micro_action", nullable = false)
  private String microAction;

  @Column(name = "transcript")
  private String transcript;

  @Column(name = "audio_ref")
  private String audioRef;

  @Column(name = "selected_option_id")
  private String selectedOptionId;

  @Column(name = "result", nullable = false)
  private String result;

  @Column(name = "idempotency_key", nullable = false)
  private String idempotencyKey;

  @Column(name = "input_hash", nullable = false)
  private String inputHash;

  @Column(name = "provider_status", nullable = false)
  private String providerStatus;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected TrainingTurn() {}

  public TrainingTurn(
      UUID trainingTurnId,
      UUID trainingSessionId,
      UUID userId,
      int turnIndex,
      String stepKey,
      String microAction,
      String transcript,
      String audioRef,
      String selectedOptionId,
      String result,
      String idempotencyKey,
      String inputHash,
      String providerStatus,
      Instant createdAt) {
    this.trainingTurnId = trainingTurnId;
    this.trainingSessionId = trainingSessionId;
    this.userId = userId;
    this.turnIndex = turnIndex;
    this.stepKey = stepKey;
    this.microAction = microAction;
    this.transcript = transcript;
    this.audioRef = audioRef;
    this.selectedOptionId = selectedOptionId;
    this.result = result;
    this.idempotencyKey = idempotencyKey;
    this.inputHash = inputHash;
    this.providerStatus = providerStatus;
    this.createdAt = createdAt;
  }

  public UUID getTrainingTurnId() {
    return trainingTurnId;
  }

  public UUID getTrainingSessionId() {
    return trainingSessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public int getTurnIndex() {
    return turnIndex;
  }

  public String getStepKey() {
    return stepKey;
  }

  public String getMicroAction() {
    return microAction;
  }

  public String getTranscript() {
    return transcript;
  }

  public String getAudioRef() {
    return audioRef;
  }

  public String getSelectedOptionId() {
    return selectedOptionId;
  }

  public String getResult() {
    return result;
  }

  public String getIdempotencyKey() {
    return idempotencyKey;
  }

  public String getInputHash() {
    return inputHash;
  }

  public String getProviderStatus() {
    return providerStatus;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public boolean samePayload(String candidateInputHash) {
    return inputHash.equals(candidateInputHash);
  }
}
