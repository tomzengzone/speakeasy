package com.speakeasy.ai;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "ai_provider_sandbox_runs")
public class AiProviderSandboxRun {
  @Id
  @Column(name = "evidence_id", nullable = false, length = 120)
  private String evidenceId;

  @Column(name = "provider_family", nullable = false, length = 80)
  private String providerFamily;

  @Column(name = "capability", nullable = false, length = 40)
  private String capability;

  @Column(name = "model", length = 120)
  private String model;

  @Column(name = "fixture_ref", length = 240)
  private String fixtureRef;

  @Column(name = "latency_p50_ms")
  private Integer latencyP50Ms;

  @Column(name = "latency_p95_ms")
  private Integer latencyP95Ms;

  @Column(name = "status", nullable = false, length = 40)
  private String status;

  @Column(name = "error_code", length = 120)
  private String errorCode;

  @Column(name = "estimated_cost", precision = 12, scale = 6)
  private BigDecimal estimatedCost;

  @Column(name = "reviewed_status", nullable = false, length = 40)
  private String reviewedStatus;

  @Column(name = "evidence_ref", nullable = false, length = 240)
  private String evidenceRef;

  @Column(name = "reviewed_at")
  private Instant reviewedAt;

  @Column(name = "reviewer_ref_hash", length = 120)
  private String reviewerRefHash;

  @Column(name = "executed_at", nullable = false)
  private Instant executedAt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected AiProviderSandboxRun() {}

  public AiProviderSandboxRun(
      String evidenceId,
      String providerFamily,
      String capability,
      String model,
      String fixtureRef,
      Integer latencyP50Ms,
      Integer latencyP95Ms,
      String status,
      String errorCode,
      BigDecimal estimatedCost,
      String reviewedStatus,
      String evidenceRef,
      Instant reviewedAt,
      String reviewerRefHash,
      Instant executedAt,
      Instant createdAt) {
    this.evidenceId = evidenceId;
    this.providerFamily = providerFamily;
    this.capability = capability;
    this.model = model;
    this.fixtureRef = fixtureRef;
    this.latencyP50Ms = latencyP50Ms;
    this.latencyP95Ms = latencyP95Ms;
    this.status = status;
    this.errorCode = errorCode;
    this.estimatedCost = estimatedCost;
    this.reviewedStatus = reviewedStatus;
    this.evidenceRef = evidenceRef;
    this.reviewedAt = reviewedAt;
    this.reviewerRefHash = reviewerRefHash;
    this.executedAt = executedAt;
    this.createdAt = createdAt;
  }

  public String getEvidenceId() {
    return evidenceId;
  }

  public String getProviderFamily() {
    return providerFamily;
  }

  public String getCapability() {
    return capability;
  }

  public String getModel() {
    return model;
  }

  public String getFixtureRef() {
    return fixtureRef;
  }

  public Integer getLatencyP50Ms() {
    return latencyP50Ms;
  }

  public Integer getLatencyP95Ms() {
    return latencyP95Ms;
  }

  public String getStatus() {
    return status;
  }

  public String getErrorCode() {
    return errorCode;
  }

  public BigDecimal getEstimatedCost() {
    return estimatedCost;
  }

  public String getReviewedStatus() {
    return reviewedStatus;
  }

  public String getEvidenceRef() {
    return evidenceRef;
  }

  public Instant getReviewedAt() {
    return reviewedAt;
  }

  public String getReviewerRefHash() {
    return reviewerRefHash;
  }

  public Instant getExecutedAt() {
    return executedAt;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
