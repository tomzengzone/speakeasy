package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "otp_failure_locks")
public class OtpFailureLock {
  @Id
  @Column(name = "failure_lock_id", nullable = false)
  private UUID failureLockId;

  @Column(name = "phone_hash", nullable = false)
  private String phoneHash;

  @Column(name = "purpose", nullable = false)
  private String purpose;

  @Column(name = "failure_count", nullable = false)
  private int failureCount;

  @Column(name = "window_start", nullable = false)
  private Instant windowStart;

  @Column(name = "locked_until")
  private Instant lockedUntil;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected OtpFailureLock() {}

  public OtpFailureLock(UUID failureLockId, String phoneHash, String purpose, Instant windowStart, Instant createdAt) {
    this.failureLockId = failureLockId;
    this.phoneHash = phoneHash;
    this.purpose = purpose;
    this.windowStart = windowStart;
    this.createdAt = createdAt;
    this.updatedAt = createdAt;
  }

  public UUID getFailureLockId() {
    return failureLockId;
  }

  public String getPhoneHash() {
    return phoneHash;
  }

  public String getPurpose() {
    return purpose;
  }

  public int getFailureCount() {
    return failureCount;
  }

  public Instant getWindowStart() {
    return windowStart;
  }

  public Instant getLockedUntil() {
    return lockedUntil;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public boolean isLockedAt(Instant now) {
    return lockedUntil != null && lockedUntil.isAfter(now);
  }

  public void recordFailure(Instant updatedAt) {
    this.failureCount += 1;
    this.updatedAt = updatedAt;
  }

  public void resetWindow(Instant windowStart, Instant updatedAt) {
    this.failureCount = 0;
    this.windowStart = windowStart;
    this.lockedUntil = null;
    this.updatedAt = updatedAt;
  }

  public void lockUntil(Instant lockedUntil, Instant updatedAt) {
    this.lockedUntil = lockedUntil;
    this.updatedAt = updatedAt;
  }
}
