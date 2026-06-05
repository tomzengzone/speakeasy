package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class MissedDayRecoveryPlannerTest {
  private final MissedDayRecoveryPlanner planner = new MissedDayRecoveryPlanner();

  @Test
  void tcP02Fub009ChoosesReplaceWhenSafetyOrFatigueOverridesPreference() {
    MissedDayRecoveryPlanner.Decision unsafe = planner.plan(fixture()
        .activeSafePlan(false)
        .preferredPolicy("defer")
        .build());

    assertThat(unsafe.recoveryMode()).isEqualTo("replace");
    assertThat(unsafe.reasonCode()).isEqualTo("replace_missing_safe_plan");
    assertThat(unsafe.plannedMinutes()).isEqualTo(10);
    assertThat(unsafe.affectedPlanItemRefs()).containsExactly("risk_item", "lower_item");

    MissedDayRecoveryPlanner.Decision fatigued = planner.plan(fixture()
        .fatigueRisk("high")
        .preferredPolicy("compress")
        .build());

    assertThat(fatigued.recoveryMode()).isEqualTo("replace");
    assertThat(fatigued.reasonCode()).isEqualTo("replace_feasibility_or_fatigue");
    assertThat(fatigued.plannedMinutes()).isLessThanOrEqualTo(30);
  }

  @Test
  void tcP02Fub009ResolvesBalancedAndSpecificTieBreakersDeterministically() {
    MissedDayRecoveryPlanner.Decision balanced = planner.plan(fixture().preferredPolicy("balanced").build());
    assertThat(balanced.recoveryMode()).isEqualTo("defer");
    assertThat(balanced.reasonCode()).isEqualTo("balanced_defer_before_compress");
    assertThat(balanced.affectedPlanItemRefs()).containsExactly("lower_item");

    MissedDayRecoveryPlanner.Decision compress = planner.plan(fixture().preferredPolicy("compress").build());
    assertThat(compress.recoveryMode()).isEqualTo("compress");
    assertThat(compress.reasonCode()).isEqualTo("compress_risk_work_within_budget");
    assertThat(compress.affectedPlanItemRefs()).containsExactly("risk_item");

    MissedDayRecoveryPlanner.Decision replace = planner.plan(fixture().preferredPolicy("replace").build());
    assertThat(replace.recoveryMode()).isEqualTo("replace");
    assertThat(replace.reasonCode()).isEqualTo("replace_policy_smaller_block");
  }

  @Test
  void tcP02Fub009CompressesWithinBudgetWithoutStackingEveryOverdueItem() {
    MissedDayRecoveryPlanner.Decision decision = planner.plan(fixture()
        .preferredPolicy("balanced")
        .deadline(LocalDate.of(2026, 6, 7))
        .items(List.of(new MissedDayRecoveryPlanner.RecoveryPlanItem(
            "risk_item",
            "training",
            "highest_weakness_and_memory_risk",
            24,
            "pending",
            "high",
            1)))
        .build());

    assertThat(decision.recoveryMode()).isEqualTo("compress");
    assertThat(decision.reasonCode()).isEqualTo("balanced_compress_without_defer_slack");
    assertThat(decision.plannedMinutes()).isLessThanOrEqualTo(30);
    assertThat(decision.affectedPlanItemRefs()).containsExactly("risk_item");
    assertThat(decision.ruleVersion()).isEqualTo(MissedDayRecoveryPlanner.RULE_VERSION);
  }

  private Fixture fixture() {
    return new Fixture();
  }

  private static final class Fixture {
    private String sourceEvent = "missed_day";
    private String preferredPolicy = "balanced";
    private String supportStatus = "supported";
    private boolean activeSafePlan = true;
    private LocalDate planningDate = LocalDate.of(2026, 6, 5);
    private LocalDate deadline = LocalDate.of(2026, 6, 20);
    private int dailyMinutes = 30;
    private String intensity = "standard";
    private String fatigueRisk = "medium";
    private List<MissedDayRecoveryPlanner.RecoveryPlanItem> items = List.of(
        new MissedDayRecoveryPlanner.RecoveryPlanItem(
            "risk_item",
            "training",
            "highest_weakness_and_memory_risk",
            18,
            "pending",
            "high",
            1),
        new MissedDayRecoveryPlanner.RecoveryPlanItem(
            "lower_item",
            "training",
            "milestone_maintenance",
            12,
            "pending",
            "low",
            2));

    private Fixture sourceEvent(String value) {
      sourceEvent = value;
      return this;
    }

    private Fixture preferredPolicy(String value) {
      preferredPolicy = value;
      return this;
    }

    private Fixture activeSafePlan(boolean value) {
      activeSafePlan = value;
      return this;
    }

    private Fixture deadline(LocalDate value) {
      deadline = value;
      return this;
    }

    private Fixture fatigueRisk(String value) {
      fatigueRisk = value;
      return this;
    }

    private Fixture items(List<MissedDayRecoveryPlanner.RecoveryPlanItem> value) {
      items = value;
      return this;
    }

    private MissedDayRecoveryPlanner.Input build() {
      return new MissedDayRecoveryPlanner.Input(
          sourceEvent,
          preferredPolicy,
          supportStatus,
          activeSafePlan,
          planningDate,
          deadline,
          dailyMinutes,
          intensity,
          fatigueRisk,
          items);
    }
  }
}
