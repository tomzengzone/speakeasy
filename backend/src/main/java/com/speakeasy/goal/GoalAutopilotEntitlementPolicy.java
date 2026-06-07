package com.speakeasy.goal;

import com.speakeasy.common.ApiException;
import java.time.Instant;
import java.util.Locale;
import java.util.Set;
import org.springframework.http.HttpStatus;

public class GoalAutopilotEntitlementPolicy {
  public static final String RULE_VERSION = "fud-entitlement-depth-v1";

  private static final Set<String> PAID_PLANS = Set.of("pro", "premium", "paid", "monthly", "yearly");

  public Decision decide(Input input) {
    if (input == null) {
      throw validation("entitlement depth input is required.");
    }
    String supportStatus = cleanOrDefault(input.supportStatus(), "partial");
    String confidenceBand = cleanOrDefault(input.confidenceBand(), "low");
    if (!Set.of("supported", "partial", "unsupported").contains(supportStatus)
        || !Set.of("low", "medium", "high").contains(confidenceBand)) {
      throw validation("entitlement depth support input is invalid.");
    }

    String sourceRef = cleanOrDefault(input.sourceEntitlementRef(), "entitlement:unknown");
    if ("unsupported".equals(supportStatus)) {
      return blocked("unsupported_goal", sourceRef);
    }
    if ("partial".equals(supportStatus)) {
      return limited("partial_goal_limited", sourceRef);
    }
    if ("low".equals(confidenceBand)) {
      return limited("low_confidence_limited", sourceRef);
    }

    String plan = cleanOrDefault(input.plan(), "unknown").toLowerCase(Locale.ROOT);
    String status = cleanOrDefault(input.status(), "unknown").toLowerCase(Locale.ROOT);
    Instant now = input.now() == null ? Instant.now() : input.now();
    boolean timeExpired = input.validUntil() != null && !input.validUntil().isAfter(now);
    boolean missingSnapshot = "entitlement:default_free".equals(sourceRef);

    if (missingSnapshot) {
      return limited("missing_entitlement_free_fallback", sourceRef);
    }
    if (Set.of("revoked", "refunded", "canceled", "cancelled").contains(status)) {
      return blocked("entitlement_blocked_" + status, sourceRef);
    }
    if (!Set.of("active", "expired", "grace").contains(status)) {
      return blocked("unknown_entitlement_blocked", sourceRef);
    }
    if (timeExpired || "expired".equals(status)) {
      return limited("expired_entitlement_limited", sourceRef);
    }
    if ("grace".equals(status)) {
      return limited("grace_entitlement_limited", sourceRef);
    }
    if (!PAID_PLANS.contains(plan)) {
      return limited("free_depth_limited", sourceRef);
    }
    if (!input.quotaAvailable()) {
      return limited("quota_exhausted", sourceRef);
    }
    if (!input.costBudgetAvailable()) {
      return limited("cost_budget_limited", sourceRef);
    }

    return new Decision(
        "full",
        "full",
        "full_sample",
        3,
        "full_horizon",
        28,
        6,
        "full_checkpoint",
        "weekly",
        "provider_candidate_allowed",
        true,
        true,
        "paid_full_depth",
        sourceRef,
        RULE_VERSION);
  }

  private Decision limited(String reason, String sourceRef) {
    return new Decision(
        "limited",
        "limited",
        "minimum_sample",
        2,
        "limited_horizon",
        7,
        3,
        "low_cost_checkpoint",
        "biweekly",
        "deterministic_low_cost",
        false,
        false,
        reason,
        sourceRef,
        RULE_VERSION);
  }

  private Decision blocked(String reason, String sourceRef) {
    return new Decision(
        "blocked",
        "blocked",
        "blocked",
        0,
        "blocked",
        0,
        0,
        "blocked",
        "none",
        "blocked",
        false,
        false,
        reason,
        sourceRef,
        RULE_VERSION);
  }

  private ApiException validation(String message) {
    return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", message);
  }

  private String clean(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }

  private String cleanOrDefault(String value, String fallback) {
    String cleaned = clean(value);
    return cleaned == null ? fallback : cleaned;
  }

  public record Input(
      String plan,
      String status,
      Instant validUntil,
      String sourceEntitlementRef,
      String supportStatus,
      String confidenceBand,
      boolean quotaAvailable,
      boolean costBudgetAvailable,
      Instant now) {}

  public record Decision(
      String depthState,
      String allowedDepth,
      String diagnosticDepth,
      int diagnosticSampleLimit,
      String plannerDepth,
      int plannerHorizonDays,
      int plannerSessionLimit,
      String checkpointDepth,
      String checkpointCadence,
      String explanationDepth,
      boolean providerCandidateAllowed,
      boolean preciseEtaAllowed,
      String limitationReason,
      String sourceEntitlementRef,
      String ruleVersion) {
    public boolean blocked() {
      return "blocked".equals(depthState);
    }
  }
}
