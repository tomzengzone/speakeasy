package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_refresh_tokens")
public class AuthRefreshToken {
  @Id @Column(name = "token_id", nullable = false) private UUID tokenId;
  @Column(name = "family_id", nullable = false) private UUID familyId;
  @Column(name = "session_id", nullable = false) private UUID sessionId;
  @Column(name = "user_id", nullable = false) private UUID userId;
  @Column(name = "parent_token_id") private UUID parentTokenId;
  @Column(name = "token_hash", nullable = false) private String tokenHash;
  @Column(name = "status", nullable = false) private String status;
  @Column(name = "issued_at", nullable = false) private Instant issuedAt;
  @Column(name = "used_at") private Instant usedAt;
  @Column(name = "expires_at", nullable = false) private Instant expiresAt;
  @Column(name = "revoked_at") private Instant revokedAt;

  protected AuthRefreshToken() {}

  public AuthRefreshToken(
      UUID tokenId, UUID familyId, UUID sessionId, UUID userId, UUID parentTokenId,
      String tokenHash, Instant issuedAt, Instant expiresAt) {
    this.tokenId = tokenId;
    this.familyId = familyId;
    this.sessionId = sessionId;
    this.userId = userId;
    this.parentTokenId = parentTokenId;
    this.tokenHash = tokenHash;
    this.status = "active";
    this.issuedAt = issuedAt;
    this.expiresAt = expiresAt;
  }

  public UUID getTokenId() { return tokenId; }
  public UUID getFamilyId() { return familyId; }
  public UUID getSessionId() { return sessionId; }
  public UUID getUserId() { return userId; }
  public String getStatus() { return status; }
  public boolean isExpiredAt(Instant now) { return !expiresAt.isAfter(now); }

  public void markUsed(Instant now) {
    status = "used";
    usedAt = now;
  }

  public void revoke(Instant now) {
    if ("active".equals(status)) {
      status = "revoked";
      revokedAt = now;
    }
  }
}
