package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;

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

  private void assertHoldReason(MasteryTransitionPolicy.Decision decision, String reasonCode) {
    assertThat(decision.direction()).isEqualTo("hold");
    assertThat(decision.acceptedLevel()).isEqualTo(decision.previousLevel());
    assertThat(decision.reasonCode()).isEqualTo(reasonCode);
  }

  private InputBuilder input(String currentLevel, double confidence) {
    return new InputBuilder(currentLevel, confidence);
  }

  private static final class InputBuilder {
    private final String currentLevel;
    private final double confidence;
    private int acceptedEvidenceCount = 3;
    private int recentFailures;
    private boolean retrievalRegression;
    private boolean checkpointRegression;
    private boolean fatigueProtected;
    private String supportStatus = "supported";
    private boolean contradictoryEvidence;

    private InputBuilder(String currentLevel, double confidence) {
      this.currentLevel = currentLevel;
      this.confidence = confidence;
    }

    private InputBuilder acceptedEvidenceCount(int value) {
      this.acceptedEvidenceCount = value;
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

    private MasteryTransitionPolicy.Input build() {
      return new MasteryTransitionPolicy.Input(
          currentLevel,
          "L5",
          confidence,
          List.of("diagnostic:fluency", "training:turn-1", "retrieval:expr-1"),
          acceptedEvidenceCount,
          recentFailures,
          retrievalRegression,
          checkpointRegression,
          fatigueProtected,
          contradictoryEvidence,
          supportStatus,
          false);
    }
  }
}
