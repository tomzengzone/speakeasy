package com.speakeasy.goal;

import com.speakeasy.common.ApiException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.springframework.http.HttpStatus;

public class MemoryCurvePolicy {
  public static final String RULE_VERSION = "memory-curve-v1";

  private static final double HIGH_RISK_THRESHOLD = 0.70;
  private static final double DUE_RISK_THRESHOLD = 0.45;
  private static final int OVERLEARNING_CAP = 2;
  private static final int INTERLEAVING_CAP = 2;
  private static final Set<String> CONTROL_BLOCKING_STATUSES = Set.of("paused", "blocked_by_policy");
  private static final Set<String> ITEM_TYPES = Set.of("expression", "scenario", "diagnostic_weakness", "plan_item");
  private static final Set<String> MASTERY_LEVELS = Set.of("L0", "L1", "L2", "L3", "L4", "L5");

  public Result evaluate(Input input) {
    validate(input);
    if (CONTROL_BLOCKING_STATUSES.contains(input.controlStatus())) {
      String reason = "paused".equals(input.controlStatus()) ? "control_paused" : "control_blocked_by_policy";
      return new Result(input.items().stream()
          .map(item -> decision(item, "blocked_by_control", reason, null, riskBand(item.forgettingRisk()), 0))
          .toList());
    }

    List<Candidate> candidates = input.items().stream().map(item -> candidate(item, input.evaluatedAt())).toList();
    List<Decision> decisions = new ArrayList<>();
    int selectedMinutes = 0;
    String selectedGroup = null;
    int selectedGroupCount = 0;

    for (int index = 0; index < candidates.size(); index++) {
      Candidate candidate = candidates.get(index);
      ItemInput item = candidate.item();

      if (candidate.highRiskOverride()) {
        decisions.add(decision(item, "review_due", candidate.reasonCode(), nextDueAt(item, input.evaluatedAt()), candidate.riskBand(), item.estimatedMinutes()));
        selectedMinutes += item.estimatedMinutes();
        selectedGroupCount = sameGroup(selectedGroup, item.interleavingGroup()) ? selectedGroupCount + 1 : 1;
        selectedGroup = item.interleavingGroup();
        continue;
      }
      if (item.overlearningCount() >= OVERLEARNING_CAP) {
        decisions.add(decision(item, "skip_overlearning_cap", "overlearning_cap_reached", input.evaluatedAt().plus(1, ChronoUnit.DAYS), candidate.riskBand(), 0));
        continue;
      }
      if (!candidate.due()) {
        decisions.add(decision(item, "review_not_due", candidate.reasonCode(), candidate.nextDueAt(), candidate.riskBand(), 0));
        continue;
      }
      if (selectedMinutes + item.estimatedMinutes() > input.dailyTimeBudgetMinutes()) {
        decisions.add(decision(item, "defer_budget", "daily_memory_budget_exhausted", input.evaluatedAt().plus(1, ChronoUnit.DAYS), candidate.riskBand(), 0));
        continue;
      }
      if (sameGroup(selectedGroup, item.interleavingGroup())
          && selectedGroupCount >= INTERLEAVING_CAP
          && hasViableInterleavingAlternative(candidates, index + 1, item.interleavingGroup(), input.dailyTimeBudgetMinutes() - selectedMinutes)) {
        decisions.add(decision(item, "interleave_alternative", "interleaving_cap_viable_alternative", input.evaluatedAt().plus(1, ChronoUnit.DAYS), candidate.riskBand(), 0));
        continue;
      }

      decisions.add(decision(item, "review_due", candidate.reasonCode(), nextDueAt(item, input.evaluatedAt()), candidate.riskBand(), item.estimatedMinutes()));
      selectedMinutes += item.estimatedMinutes();
      selectedGroupCount = sameGroup(selectedGroup, item.interleavingGroup()) ? selectedGroupCount + 1 : 1;
      selectedGroup = item.interleavingGroup();
    }

    return new Result(List.copyOf(decisions));
  }

  private Candidate candidate(ItemInput item, Instant evaluatedAt) {
    String riskBand = riskBand(item.forgettingRisk());
    if (item.forgettingRisk() >= HIGH_RISK_THRESHOLD) {
      return new Candidate(item, true, true, "high_forgetting_risk", riskBand, scheduledDueAt(item, evaluatedAt));
    }
    if (item.recentFailures() >= 2) {
      return new Candidate(item, true, true, "recent_repeated_failure", riskBand, scheduledDueAt(item, evaluatedAt));
    }
    if (item.exposureCount() == 0 && item.lastReviewedAt() == null) {
      return new Candidate(item, false, true, "new_memory_item", riskBand, scheduledDueAt(item, evaluatedAt));
    }
    if (Boolean.FALSE.equals(item.retrievalSuccess()) && item.forgettingRisk() >= DUE_RISK_THRESHOLD) {
      return new Candidate(item, false, true, "retrieval_failure_due", riskBand, scheduledDueAt(item, evaluatedAt));
    }
    if (item.forgettingRisk() >= DUE_RISK_THRESHOLD) {
      String reason = "high".equals(item.pressureLevel()) ? "pressure_memory_due" : "due_forgetting_risk";
      return new Candidate(item, false, true, reason, riskBand, scheduledDueAt(item, evaluatedAt));
    }
    if (intervalElapsed(item, evaluatedAt)) {
      return new Candidate(item, false, true, "default_interval_elapsed", riskBand, scheduledDueAt(item, evaluatedAt));
    }
    String reason = Boolean.TRUE.equals(item.retrievalSuccess())
        ? "retrieval_success_interval_not_due"
        : "below_due_threshold";
    return new Candidate(item, false, false, reason, riskBand, scheduledDueAt(item, evaluatedAt));
  }

  private boolean hasViableInterleavingAlternative(
      List<Candidate> candidates, int startIndex, String currentGroup, int remainingMinutes) {
    for (int index = startIndex; index < candidates.size(); index++) {
      Candidate candidate = candidates.get(index);
      ItemInput item = candidate.item();
      if (!sameGroup(currentGroup, item.interleavingGroup())
          && candidate.due()
          && (candidate.highRiskOverride() || item.overlearningCount() < OVERLEARNING_CAP)
          && item.estimatedMinutes() <= remainingMinutes) {
        return true;
      }
    }
    return false;
  }

  private boolean intervalElapsed(ItemInput item, Instant evaluatedAt) {
    if (item.lastReviewedAt() == null) {
      return false;
    }
    return !item.lastReviewedAt().plus(defaultIntervalDays(item.currentMasteryLevel()), ChronoUnit.DAYS).isAfter(evaluatedAt);
  }

  private Instant nextDueAt(ItemInput item, Instant evaluatedAt) {
    return evaluatedAt.plus(defaultIntervalDays(item.currentMasteryLevel()), ChronoUnit.DAYS);
  }

  private Instant scheduledDueAt(ItemInput item, Instant evaluatedAt) {
    if (item.lastReviewedAt() == null) {
      return evaluatedAt;
    }
    return item.lastReviewedAt().plus(defaultIntervalDays(item.currentMasteryLevel()), ChronoUnit.DAYS);
  }

  private int defaultIntervalDays(String masteryLevel) {
    return switch (masteryLevel) {
      case "L0" -> 1;
      case "L1" -> 2;
      case "L2" -> 4;
      case "L3" -> 7;
      case "L4" -> 14;
      default -> 30;
    };
  }

  private String riskBand(double forgettingRisk) {
    if (forgettingRisk >= HIGH_RISK_THRESHOLD) {
      return "high";
    }
    if (forgettingRisk >= DUE_RISK_THRESHOLD) {
      return "medium";
    }
    return "low";
  }

  private Decision decision(
      ItemInput item,
      String dueDecision,
      String reasonCode,
      Instant nextDueAt,
      String riskBand,
      int selectedMinutes) {
    return new Decision(
        item.itemType(),
        item.itemRef(),
        item.interleavingGroup(),
        item.currentMasteryLevel(),
        item.evidenceRefs(),
        item.lastReviewedAt(),
        item.exposureCount(),
        item.overlearningCount(),
        riskBand,
        dueDecision,
        nextDueAt,
        reasonCode,
        RULE_VERSION,
        selectedMinutes);
  }

  private boolean sameGroup(String left, String right) {
    return left != null && right != null && left.equals(right);
  }

  private void validate(Input input) {
    if (input == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "item policy input is required.");
    }
    if (!RULE_VERSION.equals(input.policyVersion())) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "policy_version is invalid.");
    }
    if (input.evaluatedAt() == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "evaluated_at is required.");
    }
    if (input.dailyTimeBudgetMinutes() < 0 || input.dailyTimeBudgetMinutes() > 240) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "daily_time_budget_minutes is invalid.");
    }
    if (input.items() == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "items are required.");
    }
    input.items().forEach(this::validateItem);
  }

  private void validateItem(ItemInput item) {
    if (item == null || item.itemRef() == null || item.itemRef().isBlank()) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "item_ref is required.");
    }
    if (!ITEM_TYPES.contains(item.itemType())) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "item_type is invalid.");
    }
    if (!MASTERY_LEVELS.contains(item.currentMasteryLevel())) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "current_mastery_level is invalid.");
    }
    if (item.forgettingRisk() < 0 || item.forgettingRisk() > 1) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "forgetting_risk is invalid.");
    }
    if (item.exposureCount() < 0 || item.overlearningCount() < 0 || item.recentFailures() < 0) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "item counters are invalid.");
    }
    if (item.estimatedMinutes() < 1 || item.estimatedMinutes() > 240) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "estimated_minutes is invalid.");
    }
  }

  public record Input(
      String policyVersion,
      String controlStatus,
      Instant evaluatedAt,
      int dailyTimeBudgetMinutes,
      List<ItemInput> items) {}

  public record ItemInput(
      String itemType,
      String itemRef,
      String interleavingGroup,
      String currentMasteryLevel,
      List<String> evidenceRefs,
      Instant lastReviewedAt,
      int exposureCount,
      int overlearningCount,
      double forgettingRisk,
      Boolean retrievalSuccess,
      int recentFailures,
      String pressureLevel,
      int estimatedMinutes) {}

  public record Decision(
      String itemType,
      String itemRef,
      String interleavingGroup,
      String currentMasteryLevel,
      List<String> evidenceRefs,
      Instant lastReviewedAt,
      int exposureCount,
      int overlearningCount,
      String forgettingRisk,
      String dueDecision,
      Instant nextDueAt,
      String reasonCode,
      String ruleVersion,
      int selectedMinutes) {}

  public record Result(List<Decision> decisions) {}

  private record Candidate(
      ItemInput item,
      boolean highRiskOverride,
      boolean due,
      String reasonCode,
      String riskBand,
      Instant nextDueAt) {}
}
