package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_sessions")
public class AuthSession {
  @Id @Column(name = "session_id", nullable = false) private UUID sessionId;
  @Column(name = "user_id", nullable = false) private UUID userId;
  @Column(name = "refresh_token_family_id", nullable = false) private UUID refreshTokenFamilyId;
  @Column(name = "status", nullable = false) private String status;
  @Column(name = "created_at", nullable = false) private Instant createdAt;
  @Column(name = "last_active_at", nullable = false) private Instant lastActiveAt;
  @Column(name = "idle_expires_at", nullable = false) private Instant idleExpiresAt;
  @Column(name = "absolute_expires_at", nullable = false) private Instant absoluteExpiresAt;
  @Column(name = "device_id") private String deviceId;
  @Column(name = "device_name", nullable = false) private String deviceName;
  @Column(name = "platform", nullable = false) private String platform;
  @Column(name = "app_version") private String appVersion;
  @Column(name = "security_epoch", nullable = false) private long securityEpoch;
  @Column(name = "revoked_at") private Instant revokedAt;
  @Column(name = "revoked_reason_code") private String revokedReasonCode;

  protected AuthSession() {}

  public AuthSession(
      UUID sessionId, UUID userId, UUID refreshTokenFamilyId, Instant createdAt, Instant idleExpiresAt,
      Instant absoluteExpiresAt, String deviceId, String deviceName, String platform,
      String appVersion, long securityEpoch) {
    this.sessionId = sessionId;
    this.userId = userId;
    this.refreshTokenFamilyId = refreshTokenFamilyId;
    this.status = "active";
    this.createdAt = createdAt;
    this.lastActiveAt = createdAt;
    this.idleExpiresAt = idleExpiresAt;
    this.absoluteExpiresAt = absoluteExpiresAt;
    this.deviceId = clean(deviceId, null);
    this.deviceName = clean(deviceName, "Unknown device");
    this.platform = clean(platform, "unknown");
    this.appVersion = clean(appVersion, null);
    this.securityEpoch = securityEpoch;
  }

  public UUID getSessionId() { return sessionId; }
  public UUID getUserId() { return userId; }
  public UUID getRefreshTokenFamilyId() { return refreshTokenFamilyId; }
  public Instant getCreatedAt() { return createdAt; }
  public Instant getLastActiveAt() { return lastActiveAt; }
  public Instant getIdleExpiresAt() { return idleExpiresAt; }
  public Instant getAbsoluteExpiresAt() { return absoluteExpiresAt; }
  public String getDeviceName() { return deviceName; }
  public String getPlatform() { return platform; }
  public String getAppVersion() { return appVersion; }
  public long getSecurityEpoch() { return securityEpoch; }
  public String getStatus() { return status; }
  public String getRevokedReasonCode() { return revokedReasonCode; }

  public boolean isActive() { return "active".equals(status); }
  public boolean isSessionExpiredAt(Instant now) {
    return !idleExpiresAt.isAfter(now) || !absoluteExpiresAt.isAfter(now);
  }

  public void touch(Instant now, Duration idleTtl) {
    lastActiveAt = now;
    Instant candidate = now.plus(idleTtl);
    idleExpiresAt = candidate.isBefore(absoluteExpiresAt) ? candidate : absoluteExpiresAt;
  }

  public void revoke(Instant revokedAt) { revoke(revokedAt, "logout"); }

  public void revoke(Instant revokedAt, String reasonCode) {
    if (!isActive()) return;
    status = "revoked";
    this.revokedAt = revokedAt;
    revokedReasonCode = clean(reasonCode, "revoked");
  }

  private static String clean(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value.trim();
  }
}
