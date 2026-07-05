package com.speakeasy.ai;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ai_provider_invocation_metrics")
public class AiProviderInvocationMetric {
  @Id
  @Column(name = "metric_id", nullable = false)
  private UUID metricId;

  @Column(name = "user_hash", nullable = false)
  private String userHash;

  @Column(name = "plan", nullable = false)
  private String plan;

  @Column(name = "provider_family", nullable = false)
  private String providerFamily;

  @Column(name = "model", nullable = false)
  private String model;

  @Column(name = "capability", nullable = false)
  private String capability;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "cache_hit", nullable = false)
  private boolean cacheHit;

  @Column(name = "token_estimate")
  private Integer tokenEstimate;

  @Column(name = "audio_duration_seconds")
  private Integer audioDurationSeconds;

  @Column(name = "estimated_cost", nullable = false, precision = 12, scale = 6)
  private BigDecimal estimatedCost;

  @Column(name = "budget_bucket", nullable = false)
  private String budgetBucket;

  @Column(name = "margin_risk", nullable = false)
  private String marginRisk;

  @Column(name = "fallback_reason")
  private String fallbackReason;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected AiProviderInvocationMetric() {}

  public AiProviderInvocationMetric(
      UUID metricId,
      String userHash,
      String plan,
      String providerFamily,
      String model,
      String capability,
      String status,
      boolean cacheHit,
      Integer tokenEstimate,
      Integer audioDurationSeconds,
      BigDecimal estimatedCost,
      String budgetBucket,
      String marginRisk,
      String fallbackReason,
      Instant createdAt) {
    this.metricId = metricId;
    this.userHash = userHash;
    this.plan = plan;
    this.providerFamily = providerFamily;
    this.model = model;
    this.capability = capability;
    this.status = status;
    this.cacheHit = cacheHit;
    this.tokenEstimate = tokenEstimate;
    this.audioDurationSeconds = audioDurationSeconds;
    this.estimatedCost = estimatedCost;
    this.budgetBucket = budgetBucket;
    this.marginRisk = marginRisk;
    this.fallbackReason = fallbackReason;
    this.createdAt = createdAt;
  }

  public UUID getMetricId() {
    return metricId;
  }

  public String getUserHash() {
    return userHash;
  }

  public String getPlan() {
    return plan;
  }

  public String getProviderFamily() {
    return providerFamily;
  }

  public String getModel() {
    return model;
  }

  public String getCapability() {
    return capability;
  }

  public String getStatus() {
    return status;
  }

  public boolean isCacheHit() {
    return cacheHit;
  }

  public Integer getTokenEstimate() {
    return tokenEstimate;
  }

  public Integer getAudioDurationSeconds() {
    return audioDurationSeconds;
  }

  public BigDecimal getEstimatedCost() {
    return estimatedCost;
  }

  public String getBudgetBucket() {
    return budgetBucket;
  }

  public String getMarginRisk() {
    return marginRisk;
  }

  public String getFallbackReason() {
    return fallbackReason;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
