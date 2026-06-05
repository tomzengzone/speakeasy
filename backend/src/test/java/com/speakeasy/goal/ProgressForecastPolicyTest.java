package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class ProgressForecastPolicyTest {
  private static final LocalDate TODAY = LocalDate.of(2026, 6, 5);
  private static final LocalDate DEADLINE = LocalDate.of(2026, 8, 24);

  private final ProgressForecastPolicy policy = new ProgressForecastPolicy();

  @Test
  void tcP02Fuc001SupportedForecastExposesRangeClaimGuardAndFallbackMetadata() {
    ProgressForecastPolicy.Decision decision = policy.evaluate(input().build());

    assertThat(decision.forecastState()).isEqualTo("ready");
    assertThat(decision.sourceGoalRevision()).isEqualTo(2);
    assertThat(decision.etaDate()).isEqualTo(LocalDate.of(2026, 8, 21));
    assertThat(decision.etaRangeStart()).isEqualTo(LocalDate.of(2026, 8, 7));
    assertThat(decision.etaRangeEnd()).isEqualTo(LocalDate.of(2026, 9, 4));
    assertThat(decision.etaUnavailableReason()).isNull();
    assertThat(decision.riskReasonCode()).isEqualTo("checkpoint_evidence_missing");
    assertThat(decision.riskReason()).isEqualTo("checkpoint evidence is not available yet");
    assertThat(decision.goalCompletionClaimAllowed()).isFalse();
    assertThat(decision.explanationKey()).isEqualTo("checkpoint_evidence_missing");
    assertThat(decision.explanationSource()).isEqualTo("deterministic_policy");
    assertThat(decision.aiExplanationUnavailableReason()).isEqualTo("deterministic_no_provider_path");
    assertThat(decision.ruleVersion()).isEqualTo(ProgressForecastPolicy.RULE_VERSION);
  }

  @Test
  void tcP02Fuc001LimitsEtaForPartialUnsupportedLowStaleRecoveryDeletedAndUnavailable() {
    assertLimited(input().supportStatus("partial").build(), "limited", "partial_goal_limited");
    assertLimited(input().supportStatus("unsupported").goalStatus("unsupported").build(), "unsupported", "unsupported_goal");
    assertLimited(input().confidenceBand("low").build(), "low_confidence", "low_confidence");
    assertLimited(input().stalePlan(true).build(), "stale_plan", "stale_plan");
    assertLimited(input().eventSource("skipped").recoveryRequired(true).build(), "recovery_required", "recovery_required");
    assertLimited(input().deleted(true).build(), "deleted", "deleted");
    assertLimited(input().unavailable(true).build(), "unavailable", "unavailable");
  }

  @Test
  void tcP02Fuc001CheckpointAndCompletionReasonsRemainObservable() {
    ProgressForecastPolicy.Decision checkpoint = policy.evaluate(input()
        .eventSource("checkpoint")
        .checkpointEvidenceAvailable(true)
        .stalePlan(true)
        .build());
    ProgressForecastPolicy.Decision completed = policy.evaluate(input()
        .eventSource("completed")
        .checkpointEvidenceAvailable(true)
        .build());

    assertThat(checkpoint.riskReasonCode()).isEqualTo("checkpoint_evidence_updated");
    assertThat(checkpoint.riskReason()).isEqualTo("checkpoint evidence updated the goal gap");
    assertThat(checkpoint.forecastState()).isEqualTo("ready");
    assertThat(completed.riskReasonCode()).isEqualTo("latest_action_completed");
    assertThat(completed.riskReason()).isEqualTo("latest action completed; keep the memory curve active");
  }

  @Test
  void validatesForecastPolicyInputs() {
    assertThatThrownBy(() -> policy.evaluate(null))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("forecast input is required");
    assertThatThrownBy(() -> policy.evaluate(input().policyVersion("wrong").build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("policy_version is invalid");
    assertThatThrownBy(() -> policy.evaluate(input().today(null).build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("today is required");
    assertThatThrownBy(() -> policy.evaluate(input().deadline(null).build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("deadline is required");
    assertThatThrownBy(() -> policy.evaluate(input().sourceGoalRevision(0).build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("source_goal_revision is invalid");
    assertThatThrownBy(() -> policy.evaluate(input().dailyMinutes(4).build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("daily_minutes is invalid");
    assertThatThrownBy(() -> policy.evaluate(input().confidenceBand("certain").build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("forecast status input is invalid");
  }

  private void assertLimited(ProgressForecastPolicy.Input input, String expectedState, String expectedReason) {
    ProgressForecastPolicy.Decision decision = policy.evaluate(input);

    assertThat(decision.forecastState()).isEqualTo(expectedState);
    assertThat(decision.etaDate()).isNull();
    assertThat(decision.etaRangeStart()).isNull();
    assertThat(decision.etaRangeEnd()).isNull();
    assertThat(decision.etaUnavailableReason()).isEqualTo(expectedReason);
    assertThat(decision.riskReasonCode()).isEqualTo(expectedReason);
    assertThat(decision.goalCompletionClaimAllowed()).isFalse();
  }

  private InputBuilder input() {
    return new InputBuilder();
  }

  private static class InputBuilder {
    private String policyVersion = ProgressForecastPolicy.RULE_VERSION;
    private String supportStatus = "supported";
    private String goalStatus = "active";
    private String confidenceBand = "medium";
    private int dailyMinutes = 30;
    private LocalDate deadline = DEADLINE;
    private LocalDate today = TODAY;
    private int sourceGoalRevision = 2;
    private String eventSource = "goal_intake";
    private boolean checkpointEvidenceAvailable;
    private boolean stalePlan;
    private boolean recoveryRequired;
    private boolean deleted;
    private boolean unavailable;
    private String aiExplanationFallbackReason = "deterministic_no_provider_path";

    InputBuilder policyVersion(String value) {
      policyVersion = value;
      return this;
    }

    InputBuilder supportStatus(String value) {
      supportStatus = value;
      return this;
    }

    InputBuilder goalStatus(String value) {
      goalStatus = value;
      return this;
    }

    InputBuilder confidenceBand(String value) {
      confidenceBand = value;
      return this;
    }

    InputBuilder dailyMinutes(int value) {
      dailyMinutes = value;
      return this;
    }

    InputBuilder deadline(LocalDate value) {
      deadline = value;
      return this;
    }

    InputBuilder today(LocalDate value) {
      today = value;
      return this;
    }

    InputBuilder sourceGoalRevision(int value) {
      sourceGoalRevision = value;
      return this;
    }

    InputBuilder eventSource(String value) {
      eventSource = value;
      return this;
    }

    InputBuilder checkpointEvidenceAvailable(boolean value) {
      checkpointEvidenceAvailable = value;
      return this;
    }

    InputBuilder stalePlan(boolean value) {
      stalePlan = value;
      return this;
    }

    InputBuilder recoveryRequired(boolean value) {
      recoveryRequired = value;
      return this;
    }

    InputBuilder deleted(boolean value) {
      deleted = value;
      return this;
    }

    InputBuilder unavailable(boolean value) {
      unavailable = value;
      return this;
    }

    ProgressForecastPolicy.Input build() {
      return new ProgressForecastPolicy.Input(
          policyVersion,
          supportStatus,
          goalStatus,
          confidenceBand,
          dailyMinutes,
          deadline,
          today,
          sourceGoalRevision,
          eventSource,
          checkpointEvidenceAvailable,
          stalePlan,
          recoveryRequired,
          deleted,
          unavailable,
          aiExplanationFallbackReason);
    }
  }
}
