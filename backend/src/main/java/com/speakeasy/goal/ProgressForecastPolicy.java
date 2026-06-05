package com.speakeasy.goal;

import com.speakeasy.common.ApiException;
import java.time.LocalDate;
import org.springframework.http.HttpStatus;

public class ProgressForecastPolicy {
  public static final String RULE_VERSION = "fuc-forecast-v1";

  public Decision evaluate(Input input) {
    if (input == null) {
      throw validation("forecast input is required.");
    }
    if (!RULE_VERSION.equals(input.policyVersion())) {
      throw validation("policy_version is invalid.");
    }
    if (input.today() == null) {
      throw validation("today is required.");
    }
    if (input.deadline() == null) {
      throw validation("deadline is required.");
    }
    if (input.sourceGoalRevision() < 1) {
      throw validation("source_goal_revision is invalid.");
    }
    if (input.dailyMinutes() < 5 || input.dailyMinutes() > 240) {
      throw validation("daily_minutes is invalid.");
    }

    String support = cleanOrDefault(input.supportStatus(), "partial");
    String status = cleanOrDefault(input.goalStatus(), support);
    String confidence = cleanOrDefault(input.confidenceBand(), "low");
    if (!isOneOf(support, "supported", "partial", "unsupported")
        || !isOneOf(confidence, "low", "medium", "high")) {
      throw validation("forecast status input is invalid.");
    }

    Reason reason = reason(input, support, status, confidence);
    boolean etaAllowed = isEtaAllowed(reason.code(), support, status, confidence);
    LocalDate etaDate = etaAllowed
        ? input.deadline().minusDays(Math.min(7, Math.max(0, input.dailyMinutes() / 10)))
        : null;
    LocalDate etaStart = etaAllowed ? etaDate.minusDays(input.checkpointEvidenceAvailable() ? 7 : 14) : null;
    LocalDate etaEnd = etaAllowed ? etaDate.plusDays(input.checkpointEvidenceAvailable() ? 7 : 14) : null;
    String etaWindow = etaAllowed
        ? etaStart + ".." + etaEnd
        : "not_available:" + reason.code();
    String forecastState = forecastState(reason.code(), support);
    String gapSummary = gapSummary(reason.code(), etaAllowed);
    String riskLevel = riskLevel(reason.code(), confidence, input.checkpointEvidenceAvailable());
    String fallbackReason = cleanOrDefault(input.aiExplanationFallbackReason(), "deterministic_no_provider_path");

    return new Decision(
        input.sourceGoalRevision(),
        forecastState,
        gapSummary,
        etaDate,
        etaStart,
        etaEnd,
        etaWindow,
        etaAllowed ? null : reason.code(),
        confidence,
        riskLevel,
        reason.text(),
        reason.code(),
        input.today().plusDays("partial".equals(support) ? 14 : 7),
        false,
        "product_internal_progress_only",
        reason.code(),
        "deterministic_policy",
        fallbackReason,
        RULE_VERSION);
  }

  private Reason reason(Input input, String support, String status, String confidence) {
    if (input.deleted()) {
      return new Reason("deleted", "forecast data has been deleted");
    }
    if (input.unavailable()) {
      return new Reason("unavailable", "forecast facts are unavailable");
    }
    if ("unsupported".equals(support) || "unsupported".equals(status)) {
      return new Reason("unsupported_goal", "unsupported goal cannot produce a safe progress forecast");
    }
    if ("partial".equals(support)) {
      return new Reason("partial_goal_limited", "partial goal coverage limits ETA precision");
    }
    if (input.recoveryRequired() || isOneOf(clean(input.eventSource()), "skipped", "deferred", "learner_skipped", "learner_deferred")) {
      return new Reason("recovery_required", "missed or deferred work requires recovery planning");
    }
    if (input.stalePlan()) {
      return new Reason("stale_plan", "stale plan requires replan before forecast precision");
    }
    if ("low".equals(confidence)) {
      return new Reason("low_confidence", "low confidence evidence requires another checkpoint before ETA");
    }
    String source = clean(input.eventSource());
    if ("checkpoint".equals(source)) {
      return new Reason("checkpoint_evidence_updated", "checkpoint evidence updated the goal gap");
    }
    if ("completed".equals(source)) {
      return new Reason("latest_action_completed", "latest action completed; keep the memory curve active");
    }
    if (!input.checkpointEvidenceAvailable()) {
      return new Reason("checkpoint_evidence_missing", "checkpoint evidence is not available yet");
    }
    return new Reason("forecast_supported", "forecast is supported by current accepted evidence");
  }

  private boolean isEtaAllowed(String reasonCode, String support, String status, String confidence) {
    return "supported".equals(support)
        && !"unsupported".equals(status)
        && !"low".equals(confidence)
        && !isOneOf(reasonCode,
            "partial_goal_limited",
            "unsupported_goal",
            "low_confidence",
            "stale_plan",
            "recovery_required",
            "deleted",
            "unavailable");
  }

  private String forecastState(String reasonCode, String support) {
    return switch (reasonCode) {
      case "deleted" -> "deleted";
      case "unavailable" -> "unavailable";
      case "unsupported_goal" -> "unsupported";
      case "low_confidence" -> "low_confidence";
      case "stale_plan" -> "stale_plan";
      case "recovery_required" -> "recovery_required";
      case "partial_goal_limited" -> "limited";
      default -> "partial".equals(support) ? "limited" : "ready";
    };
  }

  private String riskLevel(String reasonCode, String confidence, boolean checkpointEvidenceAvailable) {
    if (isOneOf(reasonCode,
        "partial_goal_limited",
        "unsupported_goal",
        "low_confidence",
        "stale_plan",
        "recovery_required",
        "deleted",
        "unavailable")) {
      return "high";
    }
    if (!checkpointEvidenceAvailable) {
      return "medium";
    }
    return "high".equals(confidence) ? "low" : "medium";
  }

  private String gapSummary(String reasonCode, boolean etaAllowed) {
    if (!etaAllowed) {
      return "Goal gap is estimated conservatively until confidence or support improves.";
    }
    if ("checkpoint_evidence_updated".equals(reasonCode)) {
      return "About 1.8 product-rubric bands below target in fluency and scenario fit.";
    }
    return "About 2 product-rubric bands below target in fluency and scenario fit.";
  }

  private ApiException validation(String message) {
    return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", message);
  }

  private boolean isOneOf(String value, String... allowed) {
    for (String candidate : allowed) {
      if (candidate.equals(value)) {
        return true;
      }
    }
    return false;
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
      String policyVersion,
      String supportStatus,
      String goalStatus,
      String confidenceBand,
      int dailyMinutes,
      LocalDate deadline,
      LocalDate today,
      int sourceGoalRevision,
      String eventSource,
      boolean checkpointEvidenceAvailable,
      boolean stalePlan,
      boolean recoveryRequired,
      boolean deleted,
      boolean unavailable,
      String aiExplanationFallbackReason) {}

  public record Decision(
      int sourceGoalRevision,
      String forecastState,
      String gapSummary,
      LocalDate etaDate,
      LocalDate etaRangeStart,
      LocalDate etaRangeEnd,
      String etaWindow,
      String etaUnavailableReason,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      String riskReasonCode,
      LocalDate nextCheckpointDate,
      boolean goalCompletionClaimAllowed,
      String allowedClaim,
      String explanationKey,
      String explanationSource,
      String aiExplanationUnavailableReason,
      String ruleVersion) {}

  private record Reason(String code, String text) {}
}
