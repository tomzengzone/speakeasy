package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_refresh_token_families")
public class AuthRefreshTokenFamily {
  @Id @Column(name = "family_id", nullable = false) private UUID familyId;
  @Column(name = "session_id", nullable = false) private UUID sessionId;
  @Column(name = "user_id", nullable = false) private UUID userId;
  @Column(name = "status", nullable = false) private String status;
  @Column(name = "created_at", nullable = false) private Instant createdAt;
  @Column(name = "revoked_at") private Instant revokedAt;
  @Column(name = "revoked_reason_code") private String revokedReasonCode;

  protected AuthRefreshTokenFamily() {}

  public AuthRefreshTokenFamily(UUID familyId, UUID sessionId, UUID userId, Instant createdAt) {
    this.familyId = familyId;
    this.sessionId = sessionId;
    this.userId = userId;
    this.status = "active";
    this.createdAt = createdAt;
  }

  public UUID getFamilyId() { return familyId; }
  public boolean isActive() { return "active".equals(status); }

  public void revoke(Instant now, String reasonCode) {
    if (!isActive()) return;
    status = "revoked";
    revokedAt = now;
    revokedReasonCode = reasonCode;
  }
}
