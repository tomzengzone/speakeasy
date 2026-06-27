package com.speakeasy.ai;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_tts_cache_owners")
public class AiTtsCacheOwner {
  @Id
  @Column(name = "owner_ref_id", nullable = false)
  private UUID ownerRefId;

  @Column(name = "cache_id", nullable = false)
  private UUID cacheId;

  @Column(name = "owner_hash", nullable = false)
  private String ownerHash;

  @Column(name = "first_attached_at", nullable = false)
  private Instant firstAttachedAt;

  @Column(name = "last_hit_at", nullable = false)
  private Instant lastHitAt;

  protected AiTtsCacheOwner() {}

  public AiTtsCacheOwner(UUID ownerRefId, UUID cacheId, String ownerHash, Instant now) {
    this.ownerRefId = ownerRefId;
    this.cacheId = cacheId;
    this.ownerHash = ownerHash;
    this.firstAttachedAt = now;
    this.lastHitAt = now;
  }

  public UUID getOwnerRefId() {
    return ownerRefId;
  }

  public UUID getCacheId() {
    return cacheId;
  }

  public String getOwnerHash() {
    return ownerHash;
  }

  public Instant getFirstAttachedAt() {
    return firstAttachedAt;
  }

  public Instant getLastHitAt() {
    return lastHitAt;
  }

  public void markHit(Instant now) {
    this.lastHitAt = now;
  }
}
