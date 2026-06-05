package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
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

  private ItemBuilder item(String itemRef) {
    return new ItemBuilder(itemRef);
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
