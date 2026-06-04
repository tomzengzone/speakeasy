package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "goal_progress_forecasts")
public class GoalProgressForecast {
  @Id
  @Column(name = "forecast_id", nullable = false)
  private UUID forecastId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "gap_summary", nullable = false)
  private String gapSummary;

  @Column(name = "eta_date")
  private LocalDate etaDate;

  @Column(name = "eta_window", nullable = false)
  private String etaWindow;

  @Column(name = "confidence_band", nullable = false)
  private String confidenceBand;

  @Column(name = "risk_level", nullable = false)
  private String riskLevel;

  @Column(name = "risk_reason", nullable = false)
  private String riskReason;

  @Column(name = "next_checkpoint_date", nullable = false)
  private LocalDate nextCheckpointDate;

  @Column(name = "claim_guard_json", nullable = false)
  private String claimGuardJson;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected GoalProgressForecast() {}

  public GoalProgressForecast(
      UUID forecastId,
      UUID goalProfileId,
      UUID userId,
      String gapSummary,
      LocalDate etaDate,
      String etaWindow,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      LocalDate nextCheckpointDate,
      String claimGuardJson,
      Instant updatedAt) {
    this.forecastId = forecastId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    update(gapSummary, etaDate, etaWindow, confidenceBand, riskLevel, riskReason, nextCheckpointDate, claimGuardJson, updatedAt);
  }

  public void update(
      String gapSummary,
      LocalDate etaDate,
      String etaWindow,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      LocalDate nextCheckpointDate,
      String claimGuardJson,
      Instant updatedAt) {
    this.gapSummary = gapSummary;
    this.etaDate = etaDate;
    this.etaWindow = etaWindow;
    this.confidenceBand = confidenceBand;
    this.riskLevel = riskLevel;
    this.riskReason = riskReason;
    this.nextCheckpointDate = nextCheckpointDate;
    this.claimGuardJson = claimGuardJson;
    this.updatedAt = updatedAt;
  }

  public UUID getForecastId() {
    return forecastId;
  }

  public String getGapSummary() {
    return gapSummary;
  }

  public LocalDate getEtaDate() {
    return etaDate;
  }

  public String getEtaWindow() {
    return etaWindow;
  }

  public String getConfidenceBand() {
    return confidenceBand;
  }

  public String getRiskLevel() {
    return riskLevel;
  }

  public String getRiskReason() {
    return riskReason;
  }

  public LocalDate getNextCheckpointDate() {
    return nextCheckpointDate;
  }

  public String getClaimGuardJson() {
    return claimGuardJson;
  }
}
