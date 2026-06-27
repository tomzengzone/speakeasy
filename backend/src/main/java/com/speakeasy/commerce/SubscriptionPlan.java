package com.speakeasy.commerce;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "subscription_plans")
public class SubscriptionPlan {
  @Id
  @Column(name = "plan_id", nullable = false)
  private UUID planId;

  @Column(name = "platform", nullable = false)
  private String platform;

  @Column(name = "product_id", nullable = false)
  private String productId;

  @Column(name = "billing_period", nullable = false)
  private String billingPeriod;

  @Column(name = "entitlement_template_id")
  private String entitlementTemplateId;

  @Column(name = "status", nullable = false)
  private String status;

  protected SubscriptionPlan() {}

  public SubscriptionPlan(UUID planId, String platform, String productId, String billingPeriod) {
    this.planId = planId;
    this.platform = platform;
    this.productId = productId;
    this.billingPeriod = billingPeriod;
    this.status = "saleable";
  }

  public UUID getPlanId() {
    return planId;
  }

  public String getPlatform() {
    return platform;
  }

  public String getProductId() {
    return productId;
  }

  public String getBillingPeriod() {
    return billingPeriod;
  }

  public String getStatus() {
    return status;
  }
}
