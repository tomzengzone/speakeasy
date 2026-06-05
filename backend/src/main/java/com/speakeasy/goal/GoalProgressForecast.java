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

  @Column(name = "source_goal_revision", nullable = false)
  private int sourceGoalRevision;

  @Column(name = "forecast_state", nullable = false)
  private String forecastState;

  @Column(name = "gap_summary", nullable = false)
  private String gapSummary;

  @Column(name = "eta_date")
  private LocalDate etaDate;

  @Column(name = "eta_range_start")
  private LocalDate etaRangeStart;

  @Column(name = "eta_range_end")
  private LocalDate etaRangeEnd;

  @Column(name = "eta_window", nullable = false)
  private String etaWindow;

  @Column(name = "eta_unavailable_reason")
  private String etaUnavailableReason;

  @Column(name = "confidence_band", nullable = false)
  private String confidenceBand;

  @Column(name = "risk_level", nullable = false)
  private String riskLevel;

  @Column(name = "risk_reason", nullable = false)
  private String riskReason;

  @Column(name = "risk_reason_code", nullable = false)
  private String riskReasonCode;

  @Column(name = "next_checkpoint_date", nullable = false)
  private LocalDate nextCheckpointDate;

  @Column(name = "claim_guard_json", nullable = false)
  private String claimGuardJson;

  @Column(name = "explanation_key", nullable = false)
  private String explanationKey;

  @Column(name = "explanation_source", nullable = false)
  private String explanationSource;

  @Column(name = "ai_explanation_unavailable_reason", nullable = false)
  private String aiExplanationUnavailableReason;

  @Column(name = "rule_version", nullable = false)
  private String ruleVersion;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected GoalProgressForecast() {}

  public GoalProgressForecast(
      UUID forecastId,
      UUID goalProfileId,
      UUID userId,
      int sourceGoalRevision,
      String forecastState,
      String gapSummary,
      LocalDate etaDate,
      LocalDate etaRangeStart,
      LocalDate etaRangeEnd,
      String etaWindow,
      String etaUnavailableReason,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      String riskReasonCode,
      LocalDate nextCheckpointDate,
      String claimGuardJson,
      String explanationKey,
      String explanationSource,
      String aiExplanationUnavailableReason,
      String ruleVersion,
      Instant updatedAt) {
    this.forecastId = forecastId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    update(
        sourceGoalRevision,
        forecastState,
        gapSummary,
        etaDate,
        etaRangeStart,
        etaRangeEnd,
        etaWindow,
        etaUnavailableReason,
        confidenceBand,
        riskLevel,
        riskReason,
        riskReasonCode,
        nextCheckpointDate,
        claimGuardJson,
        explanationKey,
        explanationSource,
        aiExplanationUnavailableReason,
        ruleVersion,
        updatedAt);
  }

  public void update(
      int sourceGoalRevision,
      String forecastState,
      String gapSummary,
      LocalDate etaDate,
      LocalDate etaRangeStart,
      LocalDate etaRangeEnd,
      String etaWindow,
      String etaUnavailableReason,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      String riskReasonCode,
      LocalDate nextCheckpointDate,
      String claimGuardJson,
      String explanationKey,
      String explanationSource,
      String aiExplanationUnavailableReason,
      String ruleVersion,
      Instant updatedAt) {
    this.sourceGoalRevision = sourceGoalRevision;
    this.forecastState = forecastState;
    this.gapSummary = gapSummary;
    this.etaDate = etaDate;
    this.etaRangeStart = etaRangeStart;
    this.etaRangeEnd = etaRangeEnd;
    this.etaWindow = etaWindow;
    this.etaUnavailableReason = etaUnavailableReason;
    this.confidenceBand = confidenceBand;
    this.riskLevel = riskLevel;
    this.riskReason = riskReason;
    this.riskReasonCode = riskReasonCode;
    this.nextCheckpointDate = nextCheckpointDate;
    this.claimGuardJson = claimGuardJson;
    this.explanationKey = explanationKey;
    this.explanationSource = explanationSource;
    this.aiExplanationUnavailableReason = aiExplanationUnavailableReason;
    this.ruleVersion = ruleVersion;
    this.updatedAt = updatedAt;
  }

  public UUID getForecastId() {
    return forecastId;
  }

  public int getSourceGoalRevision() {
    return sourceGoalRevision;
  }

  public String getForecastState() {
    return forecastState;
  }

  public String getGapSummary() {
    return gapSummary;
  }

  public LocalDate getEtaDate() {
    return etaDate;
  }

  public LocalDate getEtaRangeStart() {
    return etaRangeStart;
  }

  public LocalDate getEtaRangeEnd() {
    return etaRangeEnd;
  }

  public String getEtaWindow() {
    return etaWindow;
  }

  public String getEtaUnavailableReason() {
    return etaUnavailableReason;
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

  public String getRiskReasonCode() {
    return riskReasonCode;
  }

  public LocalDate getNextCheckpointDate() {
    return nextCheckpointDate;
  }

  public String getClaimGuardJson() {
    return claimGuardJson;
  }

  public String getExplanationKey() {
    return explanationKey;
  }

  public String getExplanationSource() {
    return explanationSource;
  }

  public String getAiExplanationUnavailableReason() {
    return aiExplanationUnavailableReason;
  }

  public String getRuleVersion() {
    return ruleVersion;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
