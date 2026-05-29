package com.speakeasy.commerce;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "subscriptions")
public class Subscription {
  @Id
  @Column(name = "subscription_id", nullable = false)
  private UUID subscriptionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "plan_id", nullable = false)
  private UUID planId;

  @Column(name = "platform", nullable = false)
  private String platform;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "starts_at")
  private Instant startsAt;

  @Column(name = "expires_at")
  private Instant expiresAt;

  @Column(name = "grace_until")
  private Instant graceUntil;

  @Column(name = "latest_purchase_id")
  private UUID latestPurchaseId;

  protected Subscription() {}

  public Subscription(UUID subscriptionId, UUID userId, UUID planId, String platform) {
    this.subscriptionId = subscriptionId;
    this.userId = userId;
    this.planId = planId;
    this.platform = platform;
    this.status = "pending_verification";
  }

  public UUID getSubscriptionId() {
    return subscriptionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public UUID getPlanId() {
    return planId;
  }

  public String getPlatform() {
    return platform;
  }

  public String getStatus() {
    return status;
  }

  public Instant getExpiresAt() {
    return expiresAt;
  }

  public void activate(UUID latestPurchaseId, Instant startsAt, Instant expiresAt) {
    this.status = "active";
    this.latestPurchaseId = latestPurchaseId;
    this.startsAt = startsAt;
    this.expiresAt = expiresAt;
    this.graceUntil = null;
  }

  public void markGracePeriod(Instant graceUntil) {
    this.status = "grace_period";
    this.graceUntil = graceUntil;
  }

  public void downgrade(String status) {
    this.status = status;
  }
}
