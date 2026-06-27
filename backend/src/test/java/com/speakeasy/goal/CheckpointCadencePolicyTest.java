package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

class CheckpointCadencePolicyTest {
  private static final LocalDate TODAY = LocalDate.of(2026, 6, 5);

  private final CheckpointCadencePolicy policy = new CheckpointCadencePolicy();

  @Test
  void tcP02Fuc004SupportedSpeakingGoalReturnsDueWeeklyTask() {
    CheckpointCadencePolicy.Decision decision = policy.evaluate(input()
        .activeBackplanCheckpointDueDate(TODAY)
        .build());

    assertThat(decision.checkpointState()).isEqualTo("CheckpointDue");
    assertThat(decision.dueStatus()).isEqualTo("due_now");
    assertThat(decision.cadence()).isEqualTo("weekly");
    assertThat(decision.limitationReason()).isNull();
    assertThat(decision.task()).isNotNull();
    assertThat(decision.task().taskType()).isEqualTo("weekly_mock");
    assertThat(decision.task().promptRef()).isEqualTo("checkpoint/ielts_speaking/weekly_mock");
    assertThat(decision.task().estimatedDurationMinutes()).isEqualTo(15);
    assertThat(decision.task().requiredEvidence()).contains("checkpoint_transcript", "rubric_observation");
    assertThat(decision.task().scoringBoundary()).contains("no_official_score_certification");
    assertThat(decision.ruleVersion()).isEqualTo(CheckpointCadencePolicy.RULE_VERSION);
  }

  @Test
  void tcP02Fuc004LatestCheckpointProducesBiweeklyNotDueDecision() {
    CheckpointCadencePolicy.Decision decision = policy.evaluate(input()
        .latestCheckpointDate(TODAY.minusDays(4))
        .build());

    assertThat(decision.checkpointState()).isEqualTo("CheckpointNotDue");
    assertThat(decision.dueStatus()).isEqualTo("not_due");
    assertThat(decision.cadence()).isEqualTo("biweekly");
    assertThat(decision.nextDueDate()).isEqualTo(TODAY.plusDays(10));
    assertThat(decision.task()).isNull();
  }

  @Test
  void tcP02Fuc005PartialGoalReturnsLimitedBiweeklyTask() {
    CheckpointCadencePolicy.Decision decision = policy.evaluate(input()
        .supportStatus("partial")
        .contentCoverage("partial_content_and_time")
        .activeBackplanCheckpointDueDate(TODAY.minusDays(1))
        .build());

    assertThat(decision.checkpointState()).isEqualTo("CheckpointLimited");
    assertThat(decision.dueStatus()).isEqualTo("overdue");
    assertThat(decision.cadence()).isEqualTo("biweekly");
    assertThat(decision.limitationReason()).isEqualTo("partial_goal_limited");
    assertThat(decision.task().taskType()).isEqualTo("biweekly_mock");
    assertThat(decision.task().aiDepth()).isEqualTo("deterministic_low_cost");
    assertThat(decision.task().limitationReason()).isEqualTo("partial_goal_limited");
  }

  @Test
  void tcP02Fuc005UnsupportedGoalReturnsUnavailableWithoutFullTask() {
    CheckpointCadencePolicy.Decision decision = policy.evaluate(input()
        .goalType("medical_board_exam_speaking")
        .supportStatus("unsupported")
        .contentCoverage("none")
        .activeBackplanCheckpointDueDate(TODAY)
        .build());

    assertThat(decision.checkpointState()).isEqualTo("CheckpointUnavailable");
    assertThat(decision.dueStatus()).isEqualTo("unavailable");
    assertThat(decision.limitationReason()).isEqualTo("unsupported_goal");
    assertThat(decision.task()).isNull();
  }

  @Test
  void tcP02Fuc006CostFallbackDowngradesAiDepthWithoutEntitlementFacts() {
    CheckpointCadencePolicy.Decision decision = policy.evaluate(input()
        .activeBackplanCheckpointDueDate(TODAY)
        .costBudgetAvailable(false)
        .build());

    assertThat(decision.checkpointState()).isEqualTo("CheckpointLimited");
    assertThat(decision.limitationReason()).isEqualTo("cost_budget_limited");
    assertThat(decision.task().aiDepth()).isEqualTo("deterministic_low_cost");
    assertThat(decision.task().scoringBoundary()).isEqualTo("product_internal_rubric_only_no_official_score_certification");
  }

  @Test
  void tcP02Fud011QuotaAndEntitlementFallbacksExposeStableDowngradeReasons() {
    CheckpointCadencePolicy.Decision quota = policy.evaluate(input()
        .activeBackplanCheckpointDueDate(TODAY)
        .quotaAvailable(false)
        .build());
    CheckpointCadencePolicy.Decision entitlement = policy.evaluate(input()
        .activeBackplanCheckpointDueDate(TODAY)
        .entitlementAllowed(false)
        .build());

    assertThat(quota.checkpointState()).isEqualTo("CheckpointLimited");
    assertThat(quota.limitationReason()).isEqualTo("quota_exhausted");
    assertThat(quota.task().aiDepth()).isEqualTo("deterministic_low_cost");
    assertThat(entitlement.checkpointState()).isEqualTo("CheckpointLimited");
    assertThat(entitlement.limitationReason()).isEqualTo("entitlement_required");
    assertThat(entitlement.task().aiDepth()).isEqualTo("deterministic_low_cost");
  }

  @Test
  void validatesCheckpointTaskInputs() {
    assertThatThrownBy(() -> policy.evaluate(null))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("checkpoint task input is required");
    assertThatThrownBy(() -> policy.evaluate(input().policyVersion("wrong").build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("policy_version is invalid");
    assertThatThrownBy(() -> policy.evaluate(input().goalType(" ").build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("goal_type is required");
    assertThatThrownBy(() -> policy.evaluate(input().supportStatus("certain").build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("support_status is invalid");
    assertThatThrownBy(() -> policy.evaluate(input().today(null).build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("today is required");
  }

  private InputBuilder input() {
    return new InputBuilder();
  }

  private static class InputBuilder {
    private String policyVersion = CheckpointCadencePolicy.RULE_VERSION;
    private String goalType = "ielts_speaking";
    private String supportStatus = "supported";
    private String contentCoverage = "sufficient_for_local_plan";
    private LocalDate today = TODAY;
    private LocalDate activeBackplanCheckpointDueDate;
    private LocalDate latestCheckpointDate;
    private boolean entitlementAllowed = true;
    private boolean quotaAvailable = true;
    private boolean costBudgetAvailable = true;

    InputBuilder policyVersion(String value) {
      policyVersion = value;
      return this;
    }

    InputBuilder goalType(String value) {
      goalType = value;
      return this;
    }

    InputBuilder supportStatus(String value) {
      supportStatus = value;
      return this;
    }

    InputBuilder contentCoverage(String value) {
      contentCoverage = value;
      return this;
    }

    InputBuilder today(LocalDate value) {
      today = value;
      return this;
    }

    InputBuilder activeBackplanCheckpointDueDate(LocalDate value) {
      activeBackplanCheckpointDueDate = value;
      return this;
    }

    InputBuilder latestCheckpointDate(LocalDate value) {
      latestCheckpointDate = value;
      return this;
    }

    InputBuilder costBudgetAvailable(boolean value) {
      costBudgetAvailable = value;
      return this;
    }

    InputBuilder quotaAvailable(boolean value) {
      quotaAvailable = value;
      return this;
    }

    InputBuilder entitlementAllowed(boolean value) {
      entitlementAllowed = value;
      return this;
    }

    CheckpointCadencePolicy.Input build() {
      return new CheckpointCadencePolicy.Input(
          policyVersion,
          goalType,
          supportStatus,
          contentCoverage,
          today,
          activeBackplanCheckpointDueDate,
          latestCheckpointDate,
          entitlementAllowed,
          quotaAvailable,
          costBudgetAvailable);
    }
  }
}
