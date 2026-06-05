package com.speakeasy.goal;

import com.speakeasy.common.ApiException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import org.springframework.http.HttpStatus;

public class MissedDayRecoveryPlanner {
  public static final String RULE_VERSION = "fub-recovery-v1";

  private static final Set<String> VALID_SOURCE_EVENTS =
      Set.of("missed_day", "skipped", "deferred", "resume_after_pause_gap", "stale_plan", "expired_item");
  private static final Set<String> VALID_POLICIES = Set.of("balanced", "compress", "defer", "replace");

  public Decision plan(Input input) {
    validate(input);
    String policy = input.preferredPolicy() == null || input.preferredPolicy().isBlank()
        ? "balanced"
        : input.preferredPolicy().trim();
    List<RecoveryPlanItem> unfinished = input.items().stream()
        .filter(item -> !"completed".equals(item.status()))
        .sorted(Comparator.comparingInt(RecoveryPlanItem::priority))
        .toList();
    int cap = dailyCap(input.dailyMinutes(), input.intensity());

    if (!input.activeSafePlan() || "unsupported".equals(input.supportStatus()) || unfinished.isEmpty()) {
      return replaceDecision(input, unfinished, cap, "replace_missing_safe_plan");
    }

    RecoveryPlanItem riskItem = unfinished.stream().filter(this::isRiskDriving).findFirst().orElse(unfinished.get(0));
    List<RecoveryPlanItem> lowerPriority = unfinished.stream()
        .filter(item -> !item.planItemId().equals(riskItem.planItemId()))
        .toList();
    int compressedMinutes = Math.min(cap, Math.max(5, (int) Math.ceil(riskItem.durationMinutes() * 0.6)));

    if ("high".equals(input.fatigueRisk()) || compressedMinutes > cap) {
      return replaceDecision(input, unfinished, cap, "replace_feasibility_or_fatigue");
    }

    boolean deferViable = hasDeadlineSlack(input) && !lowerPriority.isEmpty();
    boolean compressViable = compressedMinutes <= cap;
    if ("defer".equals(policy) && deferViable) {
      return deferDecision(input, lowerPriority, riskItem, cap, "preserve_risk_item_without_overload");
    }
    if ("compress".equals(policy) && compressViable) {
      return compressDecision(input, riskItem, compressedMinutes, "compress_risk_work_within_budget");
    }
    if ("replace".equals(policy)) {
      return replaceDecision(input, unfinished, cap, "replace_policy_smaller_block");
    }
    if (deferViable) {
      return deferDecision(input, lowerPriority, riskItem, cap, "balanced_defer_before_compress");
    }
    if (compressViable) {
      return compressDecision(input, riskItem, compressedMinutes, "balanced_compress_without_defer_slack");
    }
    return replaceDecision(input, unfinished, cap, "balanced_replace_fallback");
  }

  private void validate(Input input) {
    if (input == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "recovery input is required.");
    }
    if (!VALID_SOURCE_EVENTS.contains(input.sourceEvent())) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "source_event is invalid.");
    }
    String policy = input.preferredPolicy() == null || input.preferredPolicy().isBlank()
        ? "balanced"
        : input.preferredPolicy().trim();
    if (!VALID_POLICIES.contains(policy)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "preferred_policy is invalid.");
    }
    if (input.dailyMinutes() < 5 || input.dailyMinutes() > 240) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "daily_minutes is invalid.");
    }
    if (input.planningDate() == null || input.deadline() == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "planning dates are required.");
    }
    if (input.items() == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "plan items are required.");
    }
  }

  private boolean isRiskDriving(RecoveryPlanItem item) {
    return "high".equals(item.memoryRisk())
        || "review".equals(item.itemType())
        || item.reasonCode().contains("risk")
        || item.reasonCode().contains("memory");
  }

  private boolean hasDeadlineSlack(Input input) {
    return ChronoUnit.DAYS.between(input.planningDate(), input.deadline()) >= 3;
  }

  private int dailyCap(int dailyMinutes, String intensity) {
    int allowance = "intensive".equals(intensity) ? Math.min(10, Math.max(5, dailyMinutes / 4)) : 0;
    return dailyMinutes + allowance;
  }

  private Decision deferDecision(
      Input input, List<RecoveryPlanItem> affectedItems, RecoveryPlanItem preservedItem, int cap, String reasonCode) {
    return new Decision(
        "defer",
        reasonCode,
        affectedItems.stream().map(RecoveryPlanItem::planItemId).toList(),
        Math.min(cap, Math.max(5, preservedItem.durationMinutes())),
        "RecoveryPlanned",
        input.sourceEvent(),
        RULE_VERSION);
  }

  private Decision compressDecision(Input input, RecoveryPlanItem affectedItem, int plannedMinutes, String reasonCode) {
    return new Decision(
        "compress",
        reasonCode,
        List.of(affectedItem.planItemId()),
        plannedMinutes,
        "RecoveryPlanned",
        input.sourceEvent(),
        RULE_VERSION);
  }

  private Decision replaceDecision(Input input, List<RecoveryPlanItem> affectedItems, int cap, String reasonCode) {
    return new Decision(
        "replace",
        reasonCode,
        affectedItems.stream().map(RecoveryPlanItem::planItemId).toList(),
        Math.min(cap, Math.max(5, Math.min(10, input.dailyMinutes()))),
        "RecoveryPlanned",
        input.sourceEvent(),
        RULE_VERSION);
  }

  public record Input(
      String sourceEvent,
      String preferredPolicy,
      String supportStatus,
      boolean activeSafePlan,
      LocalDate planningDate,
      LocalDate deadline,
      int dailyMinutes,
      String intensity,
      String fatigueRisk,
      List<RecoveryPlanItem> items) {}

  public record RecoveryPlanItem(
      String planItemId,
      String itemType,
      String reasonCode,
      int durationMinutes,
      String status,
      String memoryRisk,
      int priority) {}

  public record Decision(
      String recoveryMode,
      String reasonCode,
      List<String> affectedPlanItemRefs,
      int plannedMinutes,
      String outputState,
      String sourceEvent,
      String ruleVersion) {}
}
