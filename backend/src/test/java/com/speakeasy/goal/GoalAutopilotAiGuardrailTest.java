package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class GoalAutopilotAiGuardrailTest {
  private final ProgressForecastPolicy forecastPolicy = new ProgressForecastPolicy();
  private final ForecastExplanationCandidateValidator forecastValidator = new ForecastExplanationCandidateValidator();
  private final MasteryTransitionPolicy masteryPolicy = new MasteryTransitionPolicy();
  private final MasteryTransitionExplanationValidator masteryValidator = new MasteryTransitionExplanationValidator();

  @Test
  void tcP02Fud010RejectsForecastCandidateWithCommercialPersistentDecisionFields() {
    ProgressForecastPolicy.Decision deterministic = supportedForecast();

    ForecastExplanationCandidateValidator.ValidationResult result = forecastValidator.validate(deterministic, """
        {
          "schema_version": 1,
          "output_type": "followup_c_forecast_explanation_candidate",
          "source_goal_revision": 1,
          "forecast_state": "ready",
          "risk_reason_code": "checkpoint_evidence_missing",
          "learner_visible_explanation": "This is an internal practice forecast.",
          "guardrails": {
            "official_score_equivalence": false,
            "goal_completion_claim_allowed": false,
            "guaranteed_eta_claim_allowed": false,
            "persistent_decision_fields_present": false,
            "forbidden_fields_detected": []
          },
          "entitlement": "pro",
          "quota_state": "available",
          "billing_state": "paid",
          "final_mastery_level": "L5",
          "release_approval": true,
          "product_base_merge_approved": true
        }
        """);

    assertRejected(result);
  }

  @Test
  void tcP02Fud010RejectsMasteryCandidateWithReleaseApprovalFields() {
    MasteryTransitionPolicy.Decision deterministic = masteryPolicy.evaluate(new MasteryTransitionPolicy.Input(
        "L2",
        "L3",
        0.82,
        List.of("training:turn-1", "checkpoint:weekly-1"),
        3,
        0,
        false,
        false,
        false,
        false,
        "supported",
        false));

    MasteryTransitionExplanationValidator.ValidationResult result = masteryValidator.validate(deterministic, """
        {
          "schema_version": 1,
          "output_type": "followup_b_mastery_transition_explanation_candidate",
          "transition_id": "transition-s005",
          "memory_item_state_id": "memory-item-s005",
          "previous_level": "L2",
          "proposed_level": "L3",
          "accepted_level": "L3",
          "transition_direction": "promote",
          "reason_code": "evidence_promotion_confident_retrieval",
          "learner_visible_explanation": "This internal practice item has stronger evidence.",
          "evidence_summary": {
            "accepted_evidence_count": 3,
            "latest_evidence_refs": ["training:turn-1", "checkpoint:weekly-1"]
          },
          "guardrails": {
            "official_score_equivalence": false,
            "goal_completion_claim_allowed": false,
            "persistent_decision_fields_present": false,
            "forbidden_fields_detected": []
          },
          "release_approval": true,
          "release_ready": true,
          "product_base_merge_approved": true
        }
        """);

    assertRejected(result);
  }

  private ProgressForecastPolicy.Decision supportedForecast() {
    return forecastPolicy.evaluate(new ProgressForecastPolicy.Input(
        ProgressForecastPolicy.RULE_VERSION,
        "supported",
        "active",
        "medium",
        30,
        LocalDate.of(2026, 8, 24),
        LocalDate.of(2026, 6, 5),
        1,
        "goal_intake",
        false,
        false,
        false,
        false,
        false,
        "deterministic_no_provider_path"));
  }

  private void assertRejected(ForecastExplanationCandidateValidator.ValidationResult result) {
    assertThat(result.accepted()).isFalse();
    assertThat(result.reasonCode()).isEqualTo("ai_forbidden_persistent_field");
    assertThat(result.mutatesPersistentState()).isFalse();
  }

  private void assertRejected(MasteryTransitionExplanationValidator.ValidationResult result) {
    assertThat(result.accepted()).isFalse();
    assertThat(result.reasonCode()).isEqualTo("ai_forbidden_persistent_field");
    assertThat(result.mutatesPersistentState()).isFalse();
  }
}
