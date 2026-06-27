package com.speakeasy.practice;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "practice_turns")
public class PracticeTurn {
  @Id
  private UUID practiceTurnId;
  private UUID sessionId;
  private UUID userId;
  private int turnIndex;
  private String role;
  private String transcript;
  private String audioRef;
  private String status;
  private String idempotencyKey;
  private String providerStatus;
  private Instant createdAt;
  private Instant updatedAt;

  protected PracticeTurn() {}

  public PracticeTurn(
      UUID practiceTurnId,
      UUID sessionId,
      UUID userId,
      int turnIndex,
      String role,
      String transcript,
      String audioRef,
      String status,
      String idempotencyKey,
      String providerStatus,
      Instant now) {
    this.practiceTurnId = practiceTurnId;
    this.sessionId = sessionId;
    this.userId = userId;
    this.turnIndex = turnIndex;
    this.role = role;
    this.transcript = transcript;
    this.audioRef = audioRef;
    this.status = status;
    this.idempotencyKey = idempotencyKey;
    this.providerStatus = providerStatus;
    this.createdAt = now;
    this.updatedAt = now;
  }

  public boolean samePayload(String transcript, String audioRef) {
    return Objects.equals(normalize(this.transcript), normalize(transcript))
        && Objects.equals(normalize(this.audioRef), normalize(audioRef));
  }

  private String normalize(String value) {
    return value == null || value.isBlank() ? null : value;
  }

  public UUID getPracticeTurnId() {
    return practiceTurnId;
  }

  public UUID getSessionId() {
    return sessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public int getTurnIndex() {
    return turnIndex;
  }

  public String getRole() {
    return role;
  }

  public String getTranscript() {
    return transcript;
  }

  public String getAudioRef() {
    return audioRef;
  }

  public String getStatus() {
    return status;
  }

  public String getIdempotencyKey() {
    return idempotencyKey;
  }

  public String getProviderStatus() {
    return providerStatus;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
