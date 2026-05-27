package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_sessions")
public class AuthSession {
  @Id
  @Column(name = "session_id", nullable = false)
  private UUID sessionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "access_token_hash", nullable = false)
  private String accessTokenHash;

  @Column(name = "refresh_token_hash", nullable = false)
  private String refreshTokenHash;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "issued_at", nullable = false)
  private Instant issuedAt;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "refresh_expires_at", nullable = false)
  private Instant refreshExpiresAt;

  @Column(name = "revoked_at")
  private Instant revokedAt;

  protected AuthSession() {}

  public AuthSession(
      UUID sessionId,
      UUID userId,
      String accessTokenHash,
      String refreshTokenHash,
      Instant issuedAt,
      Instant expiresAt,
      Instant refreshExpiresAt) {
    this.sessionId = sessionId;
    this.userId = userId;
    this.accessTokenHash = accessTokenHash;
    this.refreshTokenHash = refreshTokenHash;
    this.status = "active";
    this.issuedAt = issuedAt;
    this.expiresAt = expiresAt;
    this.refreshExpiresAt = refreshExpiresAt;
  }

  public UUID getSessionId() {
    return sessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public Instant getExpiresAt() {
    return expiresAt;
  }

  public Instant getRefreshExpiresAt() {
    return refreshExpiresAt;
  }

  public boolean isActiveAt(Instant now) {
    return "active".equals(status) && expiresAt.isAfter(now);
  }

  public boolean canRefreshAt(Instant now) {
    return "active".equals(status) && refreshExpiresAt.isAfter(now);
  }

  public void rotate(String accessTokenHash, String refreshTokenHash, Instant issuedAt, Instant expiresAt, Instant refreshExpiresAt) {
    this.accessTokenHash = accessTokenHash;
    this.refreshTokenHash = refreshTokenHash;
    this.issuedAt = issuedAt;
    this.expiresAt = expiresAt;
    this.refreshExpiresAt = refreshExpiresAt;
  }

  public void revoke(Instant revokedAt) {
    this.status = "revoked";
    this.revokedAt = revokedAt;
  }
}
