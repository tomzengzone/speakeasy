package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class GoalAutopilotEntitlementPolicyTest {
  private static final Instant NOW = Instant.parse("2026-06-06T00:00:00Z");

  private final GoalAutopilotEntitlementPolicy policy = new GoalAutopilotEntitlementPolicy();

  @Test
  void tcP02Fud005PaidActiveEntitlementAllowsFullDepthWhenQuotaAndCostAllow() {
    GoalAutopilotEntitlementPolicy.Decision decision = policy.decide(input()
        .plan("pro")
        .status("active")
        .sourceEntitlementRef("entitlement:paid-snapshot")
        .build());

    assertThat(decision.depthState()).isEqualTo("full");
    assertThat(decision.allowedDepth()).isEqualTo("full");
    assertThat(decision.diagnosticDepth()).isEqualTo("full_sample");
    assertThat(decision.plannerHorizonDays()).isEqualTo(28);
    assertThat(decision.checkpointDepth()).isEqualTo("full_checkpoint");
    assertThat(decision.explanationDepth()).isEqualTo("provider_candidate_allowed");
    assertThat(decision.providerCandidateAllowed()).isTrue();
    assertThat(decision.preciseEtaAllowed()).isTrue();
    assertThat(decision.limitationReason()).isEqualTo("paid_full_depth");
    assertThat(decision.ruleVersion()).isEqualTo(GoalAutopilotEntitlementPolicy.RULE_VERSION);
  }

  @Test
  void tcP02Fud005FreeAndMissingEntitlementsAreLimitedByServerPolicy() {
    GoalAutopilotEntitlementPolicy.Decision free = policy.decide(input()
        .plan("free")
        .status("active")
        .sourceEntitlementRef("entitlement:free-snapshot")
        .build());
    GoalAutopilotEntitlementPolicy.Decision missing = policy.decide(input()
        .plan("free")
        .status("active")
        .sourceEntitlementRef("entitlement:default_free")
        .build());

    assertLimited(free, "free_depth_limited");
    assertLimited(missing, "missing_entitlement_free_fallback");
    assertThat(free.diagnosticSampleLimit()).isEqualTo(2);
    assertThat(free.plannerSessionLimit()).isEqualTo(3);
    assertThat(free.checkpointCadence()).isEqualTo("biweekly");
    assertThat(free.providerCandidateAllowed()).isFalse();
  }

  @Test
  void tcP02Fud005ExpiredGraceRevokedAndUnknownHaveExplicitDowngradeResults() {
    assertLimited(input().status("expired").build(), "expired_entitlement_limited");
    assertLimited(input().status("active").validUntil(NOW.minusSeconds(1)).build(), "expired_entitlement_limited");
    assertLimited(input().status("grace").build(), "grace_entitlement_limited");
    assertBlocked(input().status("revoked").build(), "entitlement_blocked_revoked");
    assertBlocked(input().status("revoked").validUntil(NOW.minusSeconds(1)).build(), "entitlement_blocked_revoked");
    assertBlocked(input().status("refunded").build(), "entitlement_blocked_refunded");
    assertBlocked(input().status("unknown").build(), "unknown_entitlement_blocked");
    assertBlocked(input().status("unknown").validUntil(NOW.minusSeconds(1)).build(), "unknown_entitlement_blocked");
  }

  @Test
  void tcP02Fud005SupportAndDiagnosticLimitationsOverridePaidDepth() {
    assertBlocked(input().supportStatus("unsupported").build(), "unsupported_goal");
    assertLimited(input().supportStatus("partial").build(), "partial_goal_limited");
    assertLimited(input().confidenceBand("low").build(), "low_confidence_limited");
  }

  @Test
  void tcP02Fud005QuotaAndCostAreRequiredForFullPaidDepth() {
    assertLimited(input().quotaAvailable(false).build(), "quota_exhausted");
    assertLimited(input().costBudgetAvailable(false).build(), "cost_budget_limited");
  }

  @Test
  void validatesEntitlementPolicyInputs() {
    assertThatThrownBy(() -> policy.decide(null))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("entitlement depth input is required");
    assertThatThrownBy(() -> policy.decide(input().supportStatus("certain").build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("entitlement depth support input is invalid");
    assertThatThrownBy(() -> policy.decide(input().confidenceBand("certain").build()))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("entitlement depth support input is invalid");
  }

  private void assertLimited(GoalAutopilotEntitlementPolicy.Decision decision, String reason) {
    assertThat(decision.depthState()).isEqualTo("limited");
    assertThat(decision.allowedDepth()).isEqualTo("limited");
    assertThat(decision.limitationReason()).isEqualTo(reason);
    assertThat(decision.explanationDepth()).isEqualTo("deterministic_low_cost");
    assertThat(decision.providerCandidateAllowed()).isFalse();
    assertThat(decision.preciseEtaAllowed()).isFalse();
  }

  private void assertLimited(GoalAutopilotEntitlementPolicy.Input input, String reason) {
    assertLimited(policy.decide(input), reason);
  }

  private void assertBlocked(GoalAutopilotEntitlementPolicy.Decision decision, String reason) {
    assertThat(decision.depthState()).isEqualTo("blocked");
    assertThat(decision.allowedDepth()).isEqualTo("blocked");
    assertThat(decision.limitationReason()).isEqualTo(reason);
    assertThat(decision.diagnosticSampleLimit()).isZero();
    assertThat(decision.plannerSessionLimit()).isZero();
    assertThat(decision.providerCandidateAllowed()).isFalse();
    assertThat(decision.preciseEtaAllowed()).isFalse();
  }

  private void assertBlocked(GoalAutopilotEntitlementPolicy.Input input, String reason) {
    assertBlocked(policy.decide(input), reason);
  }

  private InputBuilder input() {
    return new InputBuilder();
  }

  private static class InputBuilder {
    private String plan = "pro";
    private String status = "active";
    private Instant validUntil;
    private String sourceEntitlementRef = "entitlement:policy-test";
    private String supportStatus = "supported";
    private String confidenceBand = "medium";
    private boolean quotaAvailable = true;
    private boolean costBudgetAvailable = true;

    InputBuilder plan(String value) {
      plan = value;
      return this;
    }

    InputBuilder status(String value) {
      status = value;
      return this;
    }

    InputBuilder validUntil(Instant value) {
      validUntil = value;
      return this;
    }

    InputBuilder sourceEntitlementRef(String value) {
      sourceEntitlementRef = value;
      return this;
    }

    InputBuilder supportStatus(String value) {
      supportStatus = value;
      return this;
    }

    InputBuilder confidenceBand(String value) {
      confidenceBand = value;
      return this;
    }

    InputBuilder quotaAvailable(boolean value) {
      quotaAvailable = value;
      return this;
    }

    InputBuilder costBudgetAvailable(boolean value) {
      costBudgetAvailable = value;
      return this;
    }

    GoalAutopilotEntitlementPolicy.Input build() {
      return new GoalAutopilotEntitlementPolicy.Input(
          plan,
          status,
          validUntil,
          sourceEntitlementRef,
          supportStatus,
          confidenceBand,
          quotaAvailable,
          costBudgetAvailable,
          NOW);
    }
  }
}
