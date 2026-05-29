package com.speakeasy.commerce;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "purchases")
public class Purchase {
  @Id
  @Column(name = "purchase_id", nullable = false)
  private UUID purchaseId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "platform", nullable = false)
  private String platform;

  @Column(name = "provider_transaction_id", nullable = false)
  private String providerTransactionId;

  @Column(name = "product_id", nullable = false)
  private String productId;

  @Column(name = "verification_status", nullable = false)
  private String verificationStatus;

  @Column(name = "purchased_at", nullable = false)
  private Instant purchasedAt;

  protected Purchase() {}

  public Purchase(UUID purchaseId, UUID userId, String platform, String providerTransactionId, String productId, Instant purchasedAt) {
    this.purchaseId = purchaseId;
    this.userId = userId;
    this.platform = platform;
    this.providerTransactionId = providerTransactionId;
    this.productId = productId;
    this.verificationStatus = "pending";
    this.purchasedAt = purchasedAt;
  }

  public UUID getPurchaseId() {
    return purchaseId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getPlatform() {
    return platform;
  }

  public String getProviderTransactionId() {
    return providerTransactionId;
  }

  public String getProductId() {
    return productId;
  }

  public String getVerificationStatus() {
    return verificationStatus;
  }

  public void markVerified() {
    this.verificationStatus = "verified";
  }
}
