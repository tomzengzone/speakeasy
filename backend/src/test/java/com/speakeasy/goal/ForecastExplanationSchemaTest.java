package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class ForecastExplanationSchemaTest {
  private final ProgressForecastPolicy policy = new ProgressForecastPolicy();
  private final ForecastExplanationCandidateValidator validator = new ForecastExplanationCandidateValidator();

  @Test
  void tcP02Fuc003AcceptsCandidateOnlyForecastExplanationThatEchoesDeterministicFacts() {
    ProgressForecastPolicy.Decision deterministic = supportedForecast();

    ForecastExplanationCandidateValidator.ValidationResult result = validator.validate(deterministic, """
        {
          "schema_version": 1,
          "output_type": "followup_c_forecast_explanation_candidate",
          "forecast_id": "forecast-sample",
          "goal_profile_id": "goal-sample",
          "source_goal_revision": 1,
          "forecast_state": "ready",
          "risk_reason_code": "checkpoint_evidence_missing",
          "learner_visible_explanation": "The forecast stays broad until a checkpoint confirms the gap.",
          "guardrails": {
            "official_score_equivalence": false,
            "goal_completion_claim_allowed": false,
            "guaranteed_eta_claim_allowed": false,
            "persistent_decision_fields_present": false,
            "forbidden_fields_detected": []
          },
          "recoverable_error": null
        }
        """);

    assertThat(result.accepted()).isTrue();
    assertThat(result.reasonCode()).isEqualTo("candidate_explanation_valid");
    assertThat(result.mutatesPersistentState()).isFalse();
  }

  @Test
  void tcP02Fuc003RejectsForbiddenForecastCompletionEtaEntitlementAndProviderFields() {
    ProgressForecastPolicy.Decision deterministic = supportedForecast();

    ForecastExplanationCandidateValidator.ValidationResult result = validator.validate(deterministic, """
        {
          "schema_version": 1,
          "output_type": "followup_c_forecast_explanation_candidate",
          "source_goal_revision": 1,
          "forecast_state": "ready",
          "risk_reason_code": "checkpoint_evidence_missing",
          "learner_visible_explanation": "You are guaranteed IELTS 8 by the ETA.",
          "guardrails": {
            "official_score_equivalence": true,
            "goal_completion_claim_allowed": true,
            "guaranteed_eta_claim_allowed": true,
            "persistent_decision_fields_present": true,
            "forbidden_fields_detected": ["goal_completed", "official_score", "entitlement"]
          },
          "goal_completed": true,
          "official_score": "IELTS 8",
          "guaranteed_eta": "2026-08-24",
          "eta_date": "2026-08-24",
          "entitlement": "premium",
          "quota_state": "available",
          "billing_state": "paid"
        }
        """);

    assertThat(result.accepted()).isFalse();
    assertThat(result.reasonCode()).isEqualTo("ai_forbidden_persistent_field");
    assertThat(result.fallbackExplanation()).contains("checkpoint_evidence_missing");
    assertThat(result.mutatesPersistentState()).isFalse();
  }

  @Test
  void tcP02Fuc003RejectsSchemaMismatchAndUsesDeterministicFallback() {
    ProgressForecastPolicy.Decision deterministic = supportedForecast();

    assertRejected("ai_schema_invalid", validator.validate(deterministic, null));
    assertRejected("ai_schema_invalid", validator.validate(deterministic, "{not-json"));
    assertRejected("ai_schema_invalid", validator.validate(deterministic, """
        {
          "schema_version": 1,
          "output_type": "wrong_candidate",
          "source_goal_revision": 1,
          "forecast_state": "ready",
          "risk_reason_code": "checkpoint_evidence_missing",
          "learner_visible_explanation": "Safe text.",
          "guardrails": {
            "official_score_equivalence": false,
            "goal_completion_claim_allowed": false,
            "guaranteed_eta_claim_allowed": false,
            "persistent_decision_fields_present": false,
            "forbidden_fields_detected": []
          }
        }
        """));
    assertRejected("ai_candidate_mismatch", validator.validate(deterministic, """
        {
          "schema_version": 1,
          "output_type": "followup_c_forecast_explanation_candidate",
          "source_goal_revision": 2,
          "forecast_state": "ready",
          "risk_reason_code": "checkpoint_evidence_missing",
          "learner_visible_explanation": "Safe text.",
          "guardrails": {
            "official_score_equivalence": false,
            "goal_completion_claim_allowed": false,
            "guaranteed_eta_claim_allowed": false,
            "persistent_decision_fields_present": false,
            "forbidden_fields_detected": []
          }
        }
        """));
  }

  private ProgressForecastPolicy.Decision supportedForecast() {
    return policy.evaluate(new ProgressForecastPolicy.Input(
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

  private void assertRejected(
      String expectedReason,
      ForecastExplanationCandidateValidator.ValidationResult result) {
    assertThat(result.accepted()).isFalse();
    assertThat(result.reasonCode()).isEqualTo(expectedReason);
    assertThat(result.mutatesPersistentState()).isFalse();
  }
}
