package com.speakeasy.commerce;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "entitlement_snapshots")
public class EntitlementSnapshot {
  @Id
  @Column(name = "entitlement_snapshot_id", nullable = false)
  private UUID entitlementSnapshotId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "source_subscription_id")
  private UUID sourceSubscriptionId;

  @Column(name = "plan", nullable = false)
  private String plan;

  @Column(name = "feature_flags", nullable = false)
  private String featureFlags;

  @Column(name = "quota_limits", nullable = false)
  private String quotaLimits;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "valid_until")
  private Instant validUntil;

  @Column(name = "generated_at", nullable = false)
  private Instant generatedAt;

  protected EntitlementSnapshot() {}

  public EntitlementSnapshot(UUID id, UUID userId, String plan, String featureFlags, String quotaLimits, Instant generatedAt) {
    this(id, userId, null, plan, featureFlags, quotaLimits, "active", null, generatedAt);
  }

  public EntitlementSnapshot(
      UUID id,
      UUID userId,
      UUID sourceSubscriptionId,
      String plan,
      String featureFlags,
      String quotaLimits,
      String status,
      Instant validUntil,
      Instant generatedAt) {
    this.entitlementSnapshotId = id;
    this.userId = userId;
    this.sourceSubscriptionId = sourceSubscriptionId;
    this.plan = plan;
    this.featureFlags = featureFlags;
    this.quotaLimits = quotaLimits;
    this.status = status;
    this.validUntil = validUntil;
    this.generatedAt = generatedAt;
  }

  public String getPlan() {
    return plan;
  }

  public UUID getEntitlementSnapshotId() {
    return entitlementSnapshotId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getFeatureFlags() {
    return featureFlags;
  }

  public String getQuotaLimits() {
    return quotaLimits;
  }

  public String getStatus() {
    return status;
  }

  public Instant getGeneratedAt() {
    return generatedAt;
  }

  public Instant getValidUntil() {
    return validUntil;
  }
}
