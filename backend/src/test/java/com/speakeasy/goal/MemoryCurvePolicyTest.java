package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;

class MemoryCurvePolicyTest {
  private static final Instant NOW = Instant.parse("2026-06-05T09:00:00Z");

  private final MemoryCurvePolicy policy = new MemoryCurvePolicy();

  @Test
  void tcP02Fub011UsesForgettingRiskRetrievalEvidenceAndDefaultIntervals() {
    MemoryCurvePolicy.Result result = policy.evaluate(new MemoryCurvePolicy.Input(
        MemoryCurvePolicy.RULE_VERSION,
        "active",
        NOW,
        60,
        List.of(
            item("expr-high-risk").forgettingRisk(0.72).overlearningCount(2).retrievalSuccess(false).build(),
            item("expr-retrieval-failure").forgettingRisk(0.46).retrievalSuccess(false).recentFailures(1).build(),
            item("expr-interval-due")
                .forgettingRisk(0.20)
                .retrievalSuccess(true)
                .currentMasteryLevel("L3")
                .lastReviewedAt(NOW.minus(8, ChronoUnit.DAYS))
                .build(),
            item("expr-success-not-due")
                .forgettingRisk(0.20)
                .retrievalSuccess(true)
                .currentMasteryLevel("L4")
                .lastReviewedAt(NOW.minus(1, ChronoUnit.DAYS))
                .build())));

    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::dueDecision)
        .containsExactly("review_due", "review_due", "review_due", "review_not_due");
    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::reasonCode)
        .containsExactly(
            "high_forgetting_risk",
            "retrieval_failure_due",
            "default_interval_elapsed",
            "retrieval_success_interval_not_due");
    assertThat(result.decisions().get(0).forgettingRisk()).isEqualTo("high");
    assertThat(result.decisions().get(1).forgettingRisk()).isEqualTo("medium");
    assertThat(result.decisions().get(2).nextDueAt()).isEqualTo(NOW.plus(7, ChronoUnit.DAYS));
    assertThat(result.decisions().get(3).nextDueAt()).isEqualTo(NOW.plus(13, ChronoUnit.DAYS));
    assertThat(result.decisions()).allSatisfy(decision ->
        assertThat(decision.ruleVersion()).isEqualTo(MemoryCurvePolicy.RULE_VERSION));
  }

  @Test
  void tcP02Fub011AppliesOverlearningInterleavingAndDailyBudgetCaps() {
    MemoryCurvePolicy.Result result = policy.evaluate(new MemoryCurvePolicy.Input(
        MemoryCurvePolicy.RULE_VERSION,
        "active",
        NOW,
        20,
        List.of(
            item("expr-overlearned").forgettingRisk(0.50).overlearningCount(2).interleavingGroup("vocab").build(),
            item("expr-fluency-1").forgettingRisk(0.50).interleavingGroup("fluency").estimatedMinutes(5).build(),
            item("expr-fluency-2").forgettingRisk(0.50).interleavingGroup("fluency").estimatedMinutes(5).build(),
            item("expr-fluency-3").forgettingRisk(0.50).interleavingGroup("fluency").estimatedMinutes(5).build(),
            item("expr-grammar").forgettingRisk(0.50).interleavingGroup("grammar").estimatedMinutes(10).build(),
            item("expr-scenario-budget").forgettingRisk(0.50).interleavingGroup("scenario").estimatedMinutes(5).build())));

    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::dueDecision)
        .containsExactly(
            "skip_overlearning_cap",
            "review_due",
            "review_due",
            "interleave_alternative",
            "review_due",
            "defer_budget");
    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::reasonCode)
        .containsExactly(
            "overlearning_cap_reached",
            "due_forgetting_risk",
            "due_forgetting_risk",
            "interleaving_cap_viable_alternative",
            "due_forgetting_risk",
            "daily_memory_budget_exhausted");
    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::selectedMinutes)
        .containsExactly(0, 5, 5, 0, 10, 0);
  }

  @Test
  void tcP02Fub011BlocksMemorySelectionWhenControlIsPausedOrPolicyBlocked() {
    MemoryCurvePolicy.Result paused = policy.evaluate(new MemoryCurvePolicy.Input(
        MemoryCurvePolicy.RULE_VERSION,
        "paused",
        NOW,
        30,
        List.of(item("expr-paused").forgettingRisk(0.90).build())));
    MemoryCurvePolicy.Result policyBlocked = policy.evaluate(new MemoryCurvePolicy.Input(
        MemoryCurvePolicy.RULE_VERSION,
        "blocked_by_policy",
        NOW,
        30,
        List.of(item("expr-blocked").forgettingRisk(0.90).build())));

    assertThat(paused.decisions()).singleElement().satisfies(decision -> {
      assertThat(decision.dueDecision()).isEqualTo("blocked_by_control");
      assertThat(decision.reasonCode()).isEqualTo("control_paused");
    });
    assertThat(policyBlocked.decisions()).singleElement().satisfies(decision -> {
      assertThat(decision.dueDecision()).isEqualTo("blocked_by_control");
      assertThat(decision.reasonCode()).isEqualTo("control_blocked_by_policy");
    });
  }

  @Test
  void validatesSchemaAndItemBoundsBeforePolicyEvaluation() {
    assertThatThrownBy(() -> policy.evaluate(null))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("item policy input is required");
    assertThatThrownBy(() -> policy.evaluate(input("wrong-version", "active", NOW, 30, List.of(item("ok").build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("policy_version is invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", null, 30, List.of(item("ok").build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("evaluated_at is required");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, -1, List.of(item("ok").build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("daily_time_budget_minutes is invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 241, List.of(item("ok").build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("daily_time_budget_minutes is invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, null)))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("items are required");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, Collections.singletonList(null))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("item_ref is required");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, List.of(item(" ").build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("item_ref is required");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, List.of(item("bad-type").itemType("note").build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("item_type is invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, List.of(item("bad-level").currentMasteryLevel("L6").build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("current_mastery_level is invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, List.of(item("bad-risk").forgettingRisk(1.1).build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("forgetting_risk is invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, List.of(item("bad-counters").exposureCount(-1).build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("item counters are invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, List.of(item("bad-minutes").estimatedMinutes(0).build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("estimated_minutes is invalid");
    assertThatThrownBy(() -> policy.evaluate(input(MemoryCurvePolicy.RULE_VERSION, "active", NOW, 30, List.of(item("bad-minutes").estimatedMinutes(241).build()))))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("estimated_minutes is invalid");
  }

  @Test
  void coversDefaultIntervalsNewItemsPressureRiskAndBudgetEdgeBranches() {
    MemoryCurvePolicy.Result result = policy.evaluate(new MemoryCurvePolicy.Input(
        MemoryCurvePolicy.RULE_VERSION,
        "active",
        NOW,
        10,
        List.of(
            item("new-l0")
                .currentMasteryLevel("L0")
                .lastReviewedAt(null)
                .exposureCount(0)
                .forgettingRisk(0.10)
                .estimatedMinutes(3)
                .build(),
            item("pressure-l1")
                .currentMasteryLevel("L1")
                .pressureLevel("high")
                .forgettingRisk(0.46)
                .estimatedMinutes(3)
                .build(),
            item("repeat-l5")
                .currentMasteryLevel("L5")
                .recentFailures(2)
                .forgettingRisk(0.30)
                .estimatedMinutes(3)
                .build(),
            item("below-threshold")
                .currentMasteryLevel("L4")
                .retrievalSuccess(false)
                .forgettingRisk(0.20)
                .estimatedMinutes(3)
                .build(),
            item("high-risk-budget-bypass")
                .currentMasteryLevel("L5")
                .forgettingRisk(0.75)
                .estimatedMinutes(240)
                .build())));

    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::reasonCode)
        .containsExactly(
            "new_memory_item",
            "pressure_memory_due",
            "recent_repeated_failure",
            "below_due_threshold",
            "high_forgetting_risk");
    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::dueDecision)
        .containsExactly("review_due", "review_due", "review_due", "review_not_due", "review_due");
    assertThat(result.decisions().get(0).nextDueAt()).isEqualTo(NOW.plus(1, ChronoUnit.DAYS));
    assertThat(result.decisions().get(1).nextDueAt()).isEqualTo(NOW.plus(2, ChronoUnit.DAYS));
    assertThat(result.decisions().get(2).nextDueAt()).isEqualTo(NOW.plus(30, ChronoUnit.DAYS));
    assertThat(result.decisions().get(3).nextDueAt()).isEqualTo(NOW.minus(2, ChronoUnit.DAYS).plus(14, ChronoUnit.DAYS));
    assertThat(result.decisions().get(4).selectedMinutes()).isEqualTo(240);
  }

  @Test
  void keepsSameGroupItemsWhenNoViableInterleavingAlternativeExists() {
    MemoryCurvePolicy.Result result = policy.evaluate(new MemoryCurvePolicy.Input(
        MemoryCurvePolicy.RULE_VERSION,
        "active",
        NOW,
        30,
        List.of(
            item("same-1").interleavingGroup("fluency").forgettingRisk(0.50).estimatedMinutes(5).build(),
            item("same-2").interleavingGroup("fluency").forgettingRisk(0.50).estimatedMinutes(5).build(),
            item("same-3").interleavingGroup("fluency").forgettingRisk(0.50).estimatedMinutes(5).build(),
            item("alt-not-due").interleavingGroup("grammar").forgettingRisk(0.20).estimatedMinutes(5).build(),
            item("alt-overlearned").interleavingGroup("scenario").forgettingRisk(0.50).overlearningCount(2).estimatedMinutes(5).build(),
            item("alt-too-large").interleavingGroup("vocab").forgettingRisk(0.50).estimatedMinutes(40).build())));

    assertThat(result.decisions())
        .extracting(MemoryCurvePolicy.Decision::dueDecision)
        .containsExactly(
            "review_due",
            "review_due",
            "review_due",
            "review_not_due",
            "skip_overlearning_cap",
            "defer_budget");
  }

  private ItemBuilder item(String itemRef) {
    return new ItemBuilder(itemRef);
  }

  private MemoryCurvePolicy.Input input(
      String policyVersion,
      String controlStatus,
      Instant evaluatedAt,
      int dailyTimeBudgetMinutes,
      List<MemoryCurvePolicy.ItemInput> items) {
    return new MemoryCurvePolicy.Input(policyVersion, controlStatus, evaluatedAt, dailyTimeBudgetMinutes, items);
  }

  private static final class ItemBuilder {
    private final String itemRef;
    private String itemType = "expression";
    private String interleavingGroup = "fluency";
    private String currentMasteryLevel = "L2";
    private Instant lastReviewedAt = NOW.minus(2, ChronoUnit.DAYS);
    private int exposureCount = 2;
    private int overlearningCount = 0;
    private double forgettingRisk = 0.20;
    private Boolean retrievalSuccess = true;
    private int recentFailures = 0;
    private String pressureLevel = "standard";
    private int estimatedMinutes = 5;

    private ItemBuilder(String itemRef) {
      this.itemRef = itemRef;
    }

    private ItemBuilder itemType(String value) {
      this.itemType = value;
      return this;
    }

    private ItemBuilder interleavingGroup(String value) {
      this.interleavingGroup = value;
      return this;
    }

    private ItemBuilder currentMasteryLevel(String value) {
      this.currentMasteryLevel = value;
      return this;
    }

    private ItemBuilder lastReviewedAt(Instant value) {
      this.lastReviewedAt = value;
      return this;
    }

    private ItemBuilder exposureCount(int value) {
      this.exposureCount = value;
      return this;
    }

    private ItemBuilder overlearningCount(int value) {
      this.overlearningCount = value;
      return this;
    }

    private ItemBuilder forgettingRisk(double value) {
      this.forgettingRisk = value;
      return this;
    }

    private ItemBuilder retrievalSuccess(Boolean value) {
      this.retrievalSuccess = value;
      return this;
    }

    private ItemBuilder recentFailures(int value) {
      this.recentFailures = value;
      return this;
    }

    private ItemBuilder pressureLevel(String value) {
      this.pressureLevel = value;
      return this;
    }

    private ItemBuilder estimatedMinutes(int value) {
      this.estimatedMinutes = value;
      return this;
    }

    private MemoryCurvePolicy.ItemInput build() {
      return new MemoryCurvePolicy.ItemInput(
          itemType,
          itemRef,
          interleavingGroup,
          currentMasteryLevel,
          List.of("evidence-" + itemRef),
          lastReviewedAt,
          exposureCount,
          overlearningCount,
          forgettingRisk,
          retrievalSuccess,
          recentFailures,
          pressureLevel,
          estimatedMinutes);
    }
  }
}
