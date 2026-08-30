package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_access_tokens")
public class AuthAccessToken {
  @Id @Column(name = "token_id", nullable = false) private UUID tokenId;
  @Column(name = "token_hash", nullable = false) private String tokenHash;
  @Column(name = "session_id", nullable = false) private UUID sessionId;
  @Column(name = "user_id", nullable = false) private UUID userId;
  @Column(name = "client_id", nullable = false) private String clientId;
  @Column(name = "audience", nullable = false) private String audience;
  @Column(name = "scope", nullable = false) private String scope;
  @Column(name = "status", nullable = false) private String status;
  @Column(name = "issued_at", nullable = false) private Instant issuedAt;
  @Column(name = "expires_at", nullable = false) private Instant expiresAt;
  @Column(name = "revoked_at") private Instant revokedAt;

  protected AuthAccessToken() {}

  public AuthAccessToken(
      UUID tokenId,
      String tokenHash,
      UUID sessionId,
      UUID userId,
      String clientId,
      String audience,
      String scope,
      Instant issuedAt,
      Instant expiresAt) {
    this.tokenId = tokenId;
    this.tokenHash = tokenHash;
    this.sessionId = sessionId;
    this.userId = userId;
    this.clientId = clientId;
    this.audience = audience;
    this.scope = scope;
    this.status = "active";
    this.issuedAt = issuedAt;
    this.expiresAt = expiresAt;
  }

  public UUID getTokenId() { return tokenId; }
  public UUID getSessionId() { return sessionId; }
  public UUID getUserId() { return userId; }
  public String getClientId() { return clientId; }
  public String getAudience() { return audience; }
  public String getScope() { return scope; }
  public Instant getIssuedAt() { return issuedAt; }
  public Instant getExpiresAt() { return expiresAt; }

  public boolean isActive() { return "active".equals(status); }
  public boolean isExpiredAt(Instant now) { return !expiresAt.isAfter(now); }
}
