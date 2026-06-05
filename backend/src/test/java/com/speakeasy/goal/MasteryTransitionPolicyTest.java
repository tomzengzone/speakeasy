package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import org.junit.jupiter.api.Test;

class MasteryTransitionPolicyTest {
  private final MasteryTransitionPolicy policy = new MasteryTransitionPolicy();
  private final MasteryTransitionExplanationValidator explanationValidator =
      new MasteryTransitionExplanationValidator();

  @Test
  void tcP02Fub013PromotesAtMostOneLevelFromAcceptedEvidence() {
    MasteryTransitionPolicy.Decision decision = policy.evaluate(new MasteryTransitionPolicy.Input(
        "L2",
        "L5",
        0.92,
        List.of("diagnostic:fluency", "training:turn-1", "retrieval:expr-1"),
        3,
        0,
        false,
        false,
        false,
        false,
        "supported",
        false));

    assertThat(decision.previousLevel()).isEqualTo("L2");
    assertThat(decision.proposedLevel()).isEqualTo("L3");
    assertThat(decision.acceptedLevel()).isEqualTo("L3");
    assertThat(decision.direction()).isEqualTo("promote");
    assertThat(decision.reasonCode()).startsWith("evidence_promotion");
    assertThat(decision.evidenceRefs()).containsExactly("diagnostic:fluency", "training:turn-1", "retrieval:expr-1");
    assertThat(decision.ruleVersion()).isEqualTo(MasteryTransitionPolicy.RULE_VERSION);
  }

  @Test
  void tcP02Fub013HoldsForLowConfidencePartialUnsupportedAndFatigueProtectedEvidence() {
    assertHoldReason(policy.evaluate(input("L2", 0.64).build()), "low_confidence");
    assertHoldReason(policy.evaluate(input("L2", 0.82).acceptedEvidenceCount(1).build()), "insufficient_evidence");
    assertHoldReason(policy.evaluate(input("L2", 0.82).supportStatus("partial").build()), "partial_goal_limited");
    assertHoldReason(policy.evaluate(input("L2", 0.82).supportStatus("unsupported").build()), "unsupported_goal");
    assertHoldReason(policy.evaluate(input("L2", 0.82).fatigueProtected(true).build()), "fatigue_protected");
  }

  @Test
  void tcP02Fub013DemotesForRepeatedFailureRetrievalAndCheckpointRegression() {
    MasteryTransitionPolicy.Decision repeatedFailure = policy.evaluate(
        input("L3", 0.82).recentFailures(2).retrievalRegression(true).build());
    MasteryTransitionPolicy.Decision checkpointRegression = policy.evaluate(
        input("L4", 0.70).checkpointRegression(true).build());

    assertThat(repeatedFailure.acceptedLevel()).isEqualTo("L2");
    assertThat(repeatedFailure.direction()).isEqualTo("demote");
    assertThat(repeatedFailure.reasonCode()).isEqualTo("retrieval_regression");
    assertThat(checkpointRegression.acceptedLevel()).isEqualTo("L3");
    assertThat(checkpointRegression.direction()).isEqualTo("demote");
    assertThat(checkpointRegression.reasonCode()).isEqualTo("checkpoint_regression");
  }

  @Test
  void rejectsAiPersistentMasteryFields() {
    MasteryTransitionPolicy.Decision deterministic = policy.evaluate(input("L2", 0.80).build());
    MasteryTransitionExplanationValidator.ValidationResult result =
        explanationValidator.validate(deterministic, """
            {
              "schema_version": 1,
              "output_type": "followup_b_mastery_transition_explanation_candidate",
              "transition_id": "transition-sample",
              "memory_item_state_id": "memory-item-sample",
              "previous_level": "L2",
              "proposed_level": "L3",
              "accepted_level": "L3",
              "transition_direction": "promote",
              "reason_code": "evidence_promotion_confident_retrieval",
              "learner_visible_explanation": "You are now officially ready for IELTS 8.",
              "evidence_summary": {
                "accepted_evidence_count": 3,
                "latest_evidence_refs": ["training:turn-1"]
              },
              "guardrails": {
                "official_score_equivalence": true,
                "goal_completion_claim_allowed": true,
                "persistent_decision_fields_present": true,
                "forbidden_fields_detected": ["final_mastery_level"]
              },
              "final_mastery_level": "L5",
              "review_due_at": "2026-06-06T09:00:00Z",
              "notification_schedule": "daily",
              "goal_completed": true,
              "official_score": "IELTS 8"
            }
            """);

    assertThat(result.accepted()).isFalse();
    assertThat(result.reasonCode()).isEqualTo("ai_forbidden_persistent_field");
    assertThat(result.fallbackExplanation()).contains("internal practice signal");
    assertThat(result.mutatesPersistentState()).isFalse();
  }

  @Test
  void acceptsSafeCandidateOnlyExplanationThatEchoesDeterministicDecision() {
    MasteryTransitionPolicy.Decision deterministic = policy.evaluate(input("L1", 0.74).build());
    MasteryTransitionExplanationValidator.ValidationResult result =
        explanationValidator.validate(deterministic, """
            {
              "schema_version": 1,
              "output_type": "followup_b_mastery_transition_explanation_candidate",
              "transition_id": "transition-sample",
              "memory_item_state_id": "memory-item-sample",
              "previous_level": "L1",
              "proposed_level": "L2",
              "accepted_level": "L2",
              "transition_direction": "promote",
              "reason_code": "evidence_promotion_confident_retrieval",
              "learner_visible_explanation": "You moved from L1 to L2 for this internal practice item because accepted evidence is stronger.",
              "evidence_summary": {
                "accepted_evidence_count": 3,
                "latest_evidence_refs": ["training:turn-1"]
              },
              "guardrails": {
                "official_score_equivalence": false,
                "goal_completion_claim_allowed": false,
                "persistent_decision_fields_present": false,
                "forbidden_fields_detected": []
              }
            }
            """);

    assertThat(result.accepted()).isTrue();
    assertThat(result.reasonCode()).isEqualTo("candidate_explanation_valid");
    assertThat(result.mutatesPersistentState()).isFalse();
  }

  @Test
  void coversTransitionValidationHoldAndDemotionBoundaries() {
    assertThatThrownBy(() -> policy.evaluate(input(null, 0.80).build()))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("previous_level");
    assertThatThrownBy(() -> policy.evaluate(input("L2", 0.80).targetLevel("L9").build()))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("target_level");
    assertThatThrownBy(() -> policy.evaluate(input("L2", 1.01).build()))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("confidence");
    assertThatThrownBy(() -> policy.evaluate(input("L2", -0.01).build()))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("confidence");

    assertHoldReason(policy.evaluate(input("L2", 0.82).contradictoryEvidence(true).build()), "contradictory_evidence");
    assertHoldReason(policy.evaluate(input("L2", 0.82).targetLevel("L2").build()), "target_level_not_above_current");
    assertHoldReason(policy.evaluate(input("L2", 0.82).lowConfidenceOverride(true).build()), "low_confidence");
    assertHoldReason(policy.evaluate(input("L2", 0.90).evidenceRefs(null).build()), "insufficient_evidence");
    assertHoldReason(policy.evaluate(input("L5", 1.00).targetLevel(null).build()), "target_level_not_above_current");

    MasteryTransitionPolicy.Decision repeatedFailure =
        policy.evaluate(input("L3", 0.70).recentFailures(2).build());
    MasteryTransitionPolicy.Decision demoteAtFloor =
        policy.evaluate(input("L0", 0.70).recentFailures(2).build());
    MasteryTransitionPolicy.Decision defaultSupportPromotion =
        policy.evaluate(input("L1", 0.70).supportStatus(null).targetLevel(null).build());

    assertThat(repeatedFailure.direction()).isEqualTo("demote");
    assertThat(repeatedFailure.reasonCode()).isEqualTo("repeated_failure");
    assertThat(repeatedFailure.acceptedLevel()).isEqualTo("L2");
    assertThat(demoteAtFloor.direction()).isEqualTo("demote");
    assertThat(demoteAtFloor.acceptedLevel()).isEqualTo("L0");
    assertThat(defaultSupportPromotion.direction()).isEqualTo("promote");
    assertThat(defaultSupportPromotion.acceptedLevel()).isEqualTo("L2");
  }

  @Test
  void rejectsInvalidMismatchedUnsafeAndGuardrailBlockedExplanationCandidates() {
    MasteryTransitionPolicy.Decision deterministic = policy.evaluate(input("L1", 0.74).build());

    assertRejected("ai_schema_invalid", explanationValidator.validate(deterministic, null));
    assertRejected("ai_schema_invalid", explanationValidator.validate(deterministic, " "));
    assertRejected("ai_schema_invalid", explanationValidator.validate(deterministic, "{not-json"));
    assertRejected("ai_schema_invalid", explanationValidator.validate(deterministic, "[]"));
    assertRejected("ai_schema_invalid", explanationValidator.validate(deterministic, """
        {
          "schema_version": 1,
          "output_type": "followup_b_mastery_transition_explanation_candidate"
        }
        """));
    assertRejected("ai_schema_invalid", explanationValidator.validate(
        deterministic,
        candidateJson(deterministic, "wrong_output_type", deterministic.reasonCode(), safeGuardrails(), "Internal practice signal only.")));
    assertRejected("ai_candidate_mismatch", explanationValidator.validate(
        deterministic,
        candidateJson(deterministic, "followup_b_mastery_transition_explanation_candidate", "low_confidence", safeGuardrails(), "Internal practice signal only.")));
    assertRejected("ai_forbidden_persistent_field", explanationValidator.validate(
        deterministic,
        candidateJson(deterministic, "followup_b_mastery_transition_explanation_candidate", deterministic.reasonCode(), safeGuardrails(), "This is an official IELTS 8 result.")));
    assertRejected("ai_forbidden_persistent_field", explanationValidator.validate(
        deterministic,
        candidateJson(deterministic, "followup_b_mastery_transition_explanation_candidate", deterministic.reasonCode(), guardrails("true", "false", "false", "[]"), "Internal practice signal only.")));
    assertRejected("ai_forbidden_persistent_field", explanationValidator.validate(
        deterministic,
        candidateJson(deterministic, "followup_b_mastery_transition_explanation_candidate", deterministic.reasonCode(), guardrails("false", "true", "false", "[]"), "Internal practice signal only.")));
    assertRejected("ai_forbidden_persistent_field", explanationValidator.validate(
        deterministic,
        candidateJson(deterministic, "followup_b_mastery_transition_explanation_candidate", deterministic.reasonCode(), guardrails("false", "false", "true", "[]"), "Internal practice signal only.")));
    assertRejected("ai_forbidden_persistent_field", explanationValidator.validate(
        deterministic,
        candidateJson(deterministic, "followup_b_mastery_transition_explanation_candidate", deterministic.reasonCode(), guardrails("false", "false", "false", "[\"final_mastery_level\"]"), "Internal practice signal only.")));
  }

  @Test
  void acceptsFencedExplanationJsonAndRejectsNestedForbiddenPersistentFields() {
    MasteryTransitionPolicy.Decision deterministic = policy.evaluate(input("L1", 0.74).build());
    MasteryTransitionExplanationValidator.ValidationResult fenced = explanationValidator.validate(deterministic, """
        ```json
        %s
        ```
        """.formatted(candidateJson(
            deterministic,
            "followup_b_mastery_transition_explanation_candidate",
            deterministic.reasonCode(),
            safeGuardrails(),
            "You moved from L1 to L2 for this internal practice item.")));
    MasteryTransitionExplanationValidator.ValidationResult nestedForbidden =
        explanationValidator.validate(deterministic, """
            {
              "schema_version": 1,
              "output_type": "followup_b_mastery_transition_explanation_candidate",
              "transition_id": "transition-sample",
              "memory_item_state_id": "memory-item-sample",
              "previous_level": "L1",
              "proposed_level": "L2",
              "accepted_level": "L2",
              "transition_direction": "promote",
              "reason_code": "evidence_promotion_confident_retrieval",
              "learner_visible_explanation": "Internal practice signal only.",
              "evidence_summary": {
                "accepted_evidence_count": 3,
                "latest_evidence_refs": ["training:turn-1"],
                "unsafe_nested": [{"billing_state": "active"}]
              },
              "guardrails": {
                "official_score_equivalence": false,
                "goal_completion_claim_allowed": false,
                "persistent_decision_fields_present": false,
                "forbidden_fields_detected": []
              }
            }
            """);

    assertThat(fenced.accepted()).isTrue();
    assertThat(fenced.reasonCode()).isEqualTo("candidate_explanation_valid");
    assertRejected("ai_forbidden_persistent_field", nestedForbidden);
  }

  private void assertHoldReason(MasteryTransitionPolicy.Decision decision, String reasonCode) {
    assertThat(decision.direction()).isEqualTo("hold");
    assertThat(decision.acceptedLevel()).isEqualTo(decision.previousLevel());
    assertThat(decision.reasonCode()).isEqualTo(reasonCode);
  }

  private void assertRejected(
      String expectedReasonCode,
      MasteryTransitionExplanationValidator.ValidationResult result) {
    assertThat(result.accepted()).isFalse();
    assertThat(result.reasonCode()).isEqualTo(expectedReasonCode);
    assertThat(result.fallbackExplanation()).contains("internal practice signal");
    assertThat(result.mutatesPersistentState()).isFalse();
  }

  private InputBuilder input(String currentLevel, double confidence) {
    return new InputBuilder(currentLevel, confidence);
  }

  private String safeGuardrails() {
    return guardrails("false", "false", "false", "[]");
  }

  private String guardrails(
      String officialScoreEquivalence,
      String goalCompletionClaimAllowed,
      String persistentDecisionFieldsPresent,
      String forbiddenFieldsDetected) {
    return """
        "official_score_equivalence": %s,
        "goal_completion_claim_allowed": %s,
        "persistent_decision_fields_present": %s,
        "forbidden_fields_detected": %s
        """.formatted(
            officialScoreEquivalence,
            goalCompletionClaimAllowed,
            persistentDecisionFieldsPresent,
            forbiddenFieldsDetected);
  }

  private String candidateJson(
      MasteryTransitionPolicy.Decision decision,
      String outputType,
      String reasonCode,
      String guardrails,
      String explanation) {
    return """
        {
          "schema_version": 1,
          "output_type": "%s",
          "transition_id": "transition-sample",
          "memory_item_state_id": "memory-item-sample",
          "previous_level": "%s",
          "proposed_level": "%s",
          "accepted_level": "%s",
          "transition_direction": "%s",
          "reason_code": "%s",
          "learner_visible_explanation": "%s",
          "evidence_summary": {
            "accepted_evidence_count": 3,
            "latest_evidence_refs": ["training:turn-1"]
          },
          "guardrails": {
            %s
          }
        }
        """.formatted(
            outputType,
            decision.previousLevel(),
            decision.proposedLevel(),
            decision.acceptedLevel(),
            decision.direction(),
            reasonCode,
            explanation,
            guardrails);
  }

  private static final class InputBuilder {
    private final String currentLevel;
    private final double confidence;
    private String targetLevel = "L5";
    private List<String> evidenceRefs = List.of("diagnostic:fluency", "training:turn-1", "retrieval:expr-1");
    private int acceptedEvidenceCount = 3;
    private int recentFailures;
    private boolean retrievalRegression;
    private boolean checkpointRegression;
    private boolean fatigueProtected;
    private String supportStatus = "supported";
    private boolean contradictoryEvidence;
    private boolean lowConfidenceOverride;

    private InputBuilder(String currentLevel, double confidence) {
      this.currentLevel = currentLevel;
      this.confidence = confidence;
    }

    private InputBuilder acceptedEvidenceCount(int value) {
      this.acceptedEvidenceCount = value;
      return this;
    }

    private InputBuilder targetLevel(String value) {
      this.targetLevel = value;
      return this;
    }

    private InputBuilder evidenceRefs(List<String> value) {
      this.evidenceRefs = value;
      return this;
    }

    private InputBuilder recentFailures(int value) {
      this.recentFailures = value;
      return this;
    }

    private InputBuilder retrievalRegression(boolean value) {
      this.retrievalRegression = value;
      return this;
    }

    private InputBuilder checkpointRegression(boolean value) {
      this.checkpointRegression = value;
      return this;
    }

    private InputBuilder fatigueProtected(boolean value) {
      this.fatigueProtected = value;
      return this;
    }

    private InputBuilder supportStatus(String value) {
      this.supportStatus = value;
      return this;
    }

    private InputBuilder contradictoryEvidence(boolean value) {
      this.contradictoryEvidence = value;
      return this;
    }

    private InputBuilder lowConfidenceOverride(boolean value) {
      this.lowConfidenceOverride = value;
      return this;
    }

    private MasteryTransitionPolicy.Input build() {
      return new MasteryTransitionPolicy.Input(
          currentLevel,
          targetLevel,
          confidence,
          evidenceRefs,
          acceptedEvidenceCount,
          recentFailures,
          retrievalRegression,
          checkpointRegression,
          fatigueProtected,
          contradictoryEvidence,
          supportStatus,
          lowConfidenceOverride);
    }
  }
}
