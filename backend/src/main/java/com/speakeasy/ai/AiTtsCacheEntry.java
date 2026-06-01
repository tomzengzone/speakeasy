package com.speakeasy.ai;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_tts_cache_entries")
public class AiTtsCacheEntry {
  @Id
  @Column(name = "cache_id", nullable = false)
  private UUID cacheId;

  @Column(name = "cache_key", nullable = false)
  private String cacheKey;

  @Column(name = "normalized_text_hash", nullable = false)
  private String normalizedTextHash;

  @Column(name = "model", nullable = false)
  private String model;

  @Column(name = "voice", nullable = false)
  private String voice;

  @Column(name = "language", nullable = false)
  private String language;

  @Column(name = "audio_ref", nullable = false)
  private String audioRef;

  @Column(name = "owner_hash")
  private String ownerHash;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "hit_count", nullable = false)
  private int hitCount;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "last_hit_at")
  private Instant lastHitAt;

  @Column(name = "deleted_at")
  private Instant deletedAt;

  protected AiTtsCacheEntry() {}

  public AiTtsCacheEntry(
      UUID cacheId,
      String cacheKey,
      String normalizedTextHash,
      String model,
      String voice,
      String language,
      String audioRef,
      Instant expiresAt,
      Instant createdAt) {
    this.cacheId = cacheId;
    this.cacheKey = cacheKey;
    this.normalizedTextHash = normalizedTextHash;
    this.model = model;
    this.voice = voice;
    this.language = language;
    this.audioRef = audioRef;
    this.status = "active";
    this.expiresAt = expiresAt;
    this.createdAt = createdAt;
  }

  public UUID getCacheId() {
    return cacheId;
  }

  public String getCacheKey() {
    return cacheKey;
  }

  public String getNormalizedTextHash() {
    return normalizedTextHash;
  }

  public String getModel() {
    return model;
  }

  public String getVoice() {
    return voice;
  }

  public String getLanguage() {
    return language;
  }

  public String getAudioRef() {
    return audioRef;
  }

  public String getOwnerHash() {
    return ownerHash;
  }

  public String getStatus() {
    return status;
  }

  public int getHitCount() {
    return hitCount;
  }

  public Instant getExpiresAt() {
    return expiresAt;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getLastHitAt() {
    return lastHitAt;
  }

  public Instant getDeletedAt() {
    return deletedAt;
  }

  public boolean activeAt(Instant now) {
    return "active".equals(status) && deletedAt == null && expiresAt.isAfter(now);
  }

  public void markHit(Instant now) {
    this.hitCount += 1;
    this.lastHitAt = now;
  }

  public void markStale(Instant now) {
    this.status = "stale";
    this.lastHitAt = now;
  }

  public void markDeleted(Instant now) {
    this.status = "deleted";
    this.deletedAt = now;
  }

  public void attachOwner(String ownerHash) {
    String cleaned = ownerHash == null ? "" : ownerHash.trim();
    if (!cleaned.isBlank()) {
      this.ownerHash = cleaned;
    }
  }

  public void refresh(String audioRef, Instant expiresAt, Instant now) {
    this.audioRef = audioRef;
    this.status = "active";
    this.hitCount = 0;
    this.expiresAt = expiresAt;
    this.lastHitAt = now;
    this.deletedAt = null;
  }
}
