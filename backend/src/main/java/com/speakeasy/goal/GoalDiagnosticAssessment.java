package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_diagnostic_assessments")
public class GoalDiagnosticAssessment {
  @Id
  @Column(name = "diagnostic_assessment_id", nullable = false)
  private UUID diagnosticAssessmentId;

  @Column(name = "goal_profile_id", nullable = false)
  private UUID goalProfileId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "confidence_band", nullable = false)
  private String confidenceBand;

  @Column(name = "sample_count", nullable = false)
  private int sampleCount;

  @Column(name = "rubric_scores_json", nullable = false)
  private String rubricScoresJson;

  @Column(name = "weakness_tags_json", nullable = false)
  private String weaknessTagsJson;

  @Column(name = "claim_guard_json", nullable = false)
  private String claimGuardJson;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalDiagnosticAssessment() {}

  public GoalDiagnosticAssessment(
      UUID diagnosticAssessmentId,
      UUID goalProfileId,
      UUID userId,
      String status,
      String confidenceBand,
      int sampleCount,
      String rubricScoresJson,
      String weaknessTagsJson,
      String claimGuardJson,
      String reasonCode,
      Instant createdAt) {
    this.diagnosticAssessmentId = diagnosticAssessmentId;
    this.goalProfileId = goalProfileId;
    this.userId = userId;
    this.status = status;
    this.confidenceBand = confidenceBand;
    this.sampleCount = sampleCount;
    this.rubricScoresJson = rubricScoresJson;
    this.weaknessTagsJson = weaknessTagsJson;
    this.claimGuardJson = claimGuardJson;
    this.reasonCode = reasonCode;
    this.createdAt = createdAt;
  }

  public UUID getDiagnosticAssessmentId() {
    return diagnosticAssessmentId;
  }

  public String getStatus() {
    return status;
  }

  public String getConfidenceBand() {
    return confidenceBand;
  }

  public int getSampleCount() {
    return sampleCount;
  }

  public String getRubricScoresJson() {
    return rubricScoresJson;
  }

  public String getWeaknessTagsJson() {
    return weaknessTagsJson;
  }

  public String getClaimGuardJson() {
    return claimGuardJson;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
