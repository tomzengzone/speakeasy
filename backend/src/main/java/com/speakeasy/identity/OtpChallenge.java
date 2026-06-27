package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "otp_challenges")
public class OtpChallenge {
  @Id
  @Column(name = "challenge_id", nullable = false)
  private UUID challengeId;

  @Column(name = "phone_e164", nullable = false)
  private String phoneE164;

  @Column(name = "phone_hash", nullable = false)
  private String phoneHash;

  @Column(name = "purpose", nullable = false)
  private String purpose;

  @Convert(converter = OtpChallengeStatusConverter.class)
  @Column(name = "status", nullable = false)
  private OtpChallengeStatus status;

  @Column(name = "hash_version", nullable = false)
  private String hashVersion;

  @Column(name = "otp_hmac_digest", nullable = false)
  private String otpHmacDigest;

  @Column(name = "sent_at", nullable = false)
  private Instant sentAt;

  @Column(name = "active_at", nullable = false)
  private Instant activeAt;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "consumed_at")
  private Instant consumedAt;

  @Column(name = "invalidated_at")
  private Instant invalidatedAt;

  @Column(name = "attempt_count", nullable = false)
  private int attemptCount;

  @Column(name = "max_attempts", nullable = false)
  private int maxAttempts;

  @Column(name = "context_hash")
  private String contextHash;

  @Convert(converter = OtpRiskDecisionConverter.class)
  @Column(name = "risk_decision", nullable = false)
  private OtpRiskDecision riskDecision;

  @Convert(converter = OtpStepUpStatusConverter.class)
  @Column(name = "step_up_status", nullable = false)
  private OtpStepUpStatus stepUpStatus;

  @Column(name = "request_id")
  private String requestId;

  @Column(name = "retention_policy_version", nullable = false)
  private String retentionPolicyVersion;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected OtpChallenge() {}

  public OtpChallenge(
      UUID challengeId,
      String phoneE164,
      String phoneHash,
      String purpose,
      String hashVersion,
      String otpHmacDigest,
      Instant sentAt,
      Instant activeAt,
      Instant expiresAt,
      int maxAttempts,
      String contextHash,
      OtpRiskDecision riskDecision,
      OtpStepUpStatus stepUpStatus,
      String requestId,
      String retentionPolicyVersion,
      Instant createdAt) {
    this.challengeId = challengeId;
    this.phoneE164 = phoneE164;
    this.phoneHash = phoneHash;
    this.purpose = purpose;
    this.status = OtpChallengeStatus.PENDING;
    this.hashVersion = hashVersion;
    this.otpHmacDigest = otpHmacDigest;
    this.sentAt = sentAt;
    this.activeAt = activeAt;
    this.expiresAt = expiresAt;
    this.maxAttempts = maxAttempts;
    this.contextHash = contextHash;
    this.riskDecision = riskDecision;
    this.stepUpStatus = stepUpStatus;
    this.requestId = requestId;
    this.retentionPolicyVersion = retentionPolicyVersion;
    this.createdAt = createdAt;
    this.updatedAt = createdAt;
  }

  public UUID getChallengeId() {
    return challengeId;
  }

  public String getPhoneE164() {
    return phoneE164;
  }

  public String getPhoneHash() {
    return phoneHash;
  }

  public String getPurpose() {
    return purpose;
  }

  public OtpChallengeStatus getStatus() {
    return status;
  }

  public String getHashVersion() {
    return hashVersion;
  }

  public String getOtpHmacDigest() {
    return otpHmacDigest;
  }

  public Instant getSentAt() {
    return sentAt;
  }

  public Instant getActiveAt() {
    return activeAt;
  }

  public Instant getExpiresAt() {
    return expiresAt;
  }

  public Instant getConsumedAt() {
    return consumedAt;
  }

  public Instant getInvalidatedAt() {
    return invalidatedAt;
  }

  public int getAttemptCount() {
    return attemptCount;
  }

  public int getMaxAttempts() {
    return maxAttempts;
  }

  public String getContextHash() {
    return contextHash;
  }

  public OtpRiskDecision getRiskDecision() {
    return riskDecision;
  }

  public OtpStepUpStatus getStepUpStatus() {
    return stepUpStatus;
  }

  public String getRequestId() {
    return requestId;
  }

  public String getRetentionPolicyVersion() {
    return retentionPolicyVersion;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public boolean isActiveAt(Instant now) {
    return OtpChallengeStatus.ACTIVE.equals(status) && expiresAt.isAfter(now);
  }

  public void activate(Instant activeAt) {
    this.status = OtpChallengeStatus.ACTIVE;
    this.activeAt = activeAt;
    this.updatedAt = activeAt;
  }

  public void recordAttempt(Instant updatedAt) {
    this.attemptCount += 1;
    this.updatedAt = updatedAt;
  }

  public void updateStepUpStatus(OtpStepUpStatus stepUpStatus, Instant updatedAt) {
    this.stepUpStatus = stepUpStatus;
    this.updatedAt = updatedAt;
  }

  public void consume(Instant consumedAt) {
    this.status = OtpChallengeStatus.CONSUMED;
    this.consumedAt = consumedAt;
    this.updatedAt = consumedAt;
  }

  public void expire(Instant updatedAt) {
    this.status = OtpChallengeStatus.EXPIRED;
    this.updatedAt = updatedAt;
  }

  public void invalidate(Instant invalidatedAt) {
    this.status = OtpChallengeStatus.INVALIDATED;
    this.invalidatedAt = invalidatedAt;
    this.updatedAt = invalidatedAt;
  }

  public void lock(Instant updatedAt) {
    this.status = OtpChallengeStatus.LOCKED;
    this.updatedAt = updatedAt;
  }
}
