package com.speakeasy.goal;

import com.speakeasy.common.ApiException;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import org.springframework.http.HttpStatus;

public class CheckpointCadencePolicy {
  public static final String RULE_VERSION = "fuc-checkpoint-task-v1";

  private static final Set<String> SUPPORT_STATUSES = Set.of("supported", "partial", "unsupported");
  private static final Set<String> SPEAKING_GOALS = Set.of("ielts_speaking", "toefl_speaking");
  private static final Set<String> BUSINESS_GOALS = Set.of("business_meeting", "job_interview", "onboarding_introduction");

  public Decision evaluate(Input input) {
    if (input == null) {
      throw validation("checkpoint task input is required.");
    }
    if (!RULE_VERSION.equals(input.policyVersion())) {
      throw validation("policy_version is invalid.");
    }
    String goalType = clean(input.goalType());
    if (goalType == null) {
      throw validation("goal_type is required.");
    }
    String supportStatus = cleanOrDefault(input.supportStatus(), "partial");
    if (!SUPPORT_STATUSES.contains(supportStatus)) {
      throw validation("support_status is invalid.");
    }
    if (input.today() == null) {
      throw validation("today is required.");
    }

    String contentCoverage = cleanOrDefault(input.contentCoverage(), "none");
    String limitationReason = limitationReason(input, supportStatus);
    String cadence = cadence(goalType, supportStatus, input.latestCheckpointDate());
    LocalDate dueDate = dueDate(cadence, input.activeBackplanCheckpointDueDate(), input.latestCheckpointDate(), input.today());

    if ("unsupported".equals(supportStatus) || !isSupportedGoalType(goalType)) {
      return new Decision(
          "CheckpointUnavailable",
          "unavailable",
          dueDate,
          null,
          cadence,
          "unsupported_goal",
          supportStatus,
          contentCoverage,
          null,
          RULE_VERSION);
    }

    boolean due = !input.today().isBefore(dueDate);
    if (!due) {
      return new Decision(
          "CheckpointNotDue",
          "not_due",
          dueDate,
          dueDate,
          cadence,
          limitationReason,
          supportStatus,
          contentCoverage,
          null,
          RULE_VERSION);
    }

    boolean limited = "partial".equals(supportStatus) || limitationReason != null;
    TaskDefinition task = taskDefinition(goalType, supportStatus, cadence, limitationReason);
    return new Decision(
        limited ? "CheckpointLimited" : "CheckpointDue",
        input.today().isAfter(dueDate) ? "overdue" : "due_now",
        dueDate,
        dueDate,
        cadence,
        limitationReason,
        supportStatus,
        contentCoverage,
        task,
        RULE_VERSION);
  }

  private LocalDate dueDate(
      String cadence, LocalDate activeBackplanCheckpointDueDate, LocalDate latestCheckpointDate, LocalDate today) {
    if (latestCheckpointDate != null) {
      return latestCheckpointDate.plusDays("biweekly".equals(cadence) ? 14 : 7);
    }
    return activeBackplanCheckpointDueDate == null ? today : activeBackplanCheckpointDueDate;
  }

  private String cadence(String goalType, String supportStatus, LocalDate latestCheckpointDate) {
    if ("partial".equals(supportStatus) || latestCheckpointDate != null) {
      return "biweekly";
    }
    return "weekly";
  }

  private TaskDefinition taskDefinition(String goalType, String supportStatus, String cadence, String limitationReason) {
    String taskType = taskType(goalType, cadence);
    boolean business = BUSINESS_GOALS.contains(goalType);
    boolean limited = limitationReason != null || "partial".equals(supportStatus);
    return new TaskDefinition(
        goalType + ":" + taskType + ":" + cadence,
        taskType,
        cadence,
        goalType,
        "checkpoint/" + goalType + "/" + taskType,
        limited ? 8 : business ? 12 : 15,
        business
            ? List.of("checkpoint_transcript", "scenario_outcome_note")
            : List.of("checkpoint_transcript", "rubric_observation"),
        business ? "business_communication_rubric_v1" : "product_speaking_rubric_v1",
        supportStatus,
        limitationReason,
        limited ? "deterministic_low_cost" : "deterministic_candidate_allowed",
        "product_internal_rubric_only_no_official_score_certification");
  }

  private String taskType(String goalType, String cadence) {
    if (BUSINESS_GOALS.contains(goalType)) {
      return "business_task";
    }
    return "biweekly".equals(cadence) ? "biweekly_mock" : "weekly_mock";
  }

  private boolean isSupportedGoalType(String goalType) {
    return SPEAKING_GOALS.contains(goalType) || BUSINESS_GOALS.contains(goalType);
  }

  private String limitationReason(Input input, String supportStatus) {
    if ("unsupported".equals(supportStatus)) {
      return "unsupported_goal";
    }
    if ("partial".equals(supportStatus)) {
      return "partial_goal_limited";
    }
    if (!input.entitlementAllowed()) {
      return "entitlement_limited";
    }
    if (!input.quotaAvailable() || !input.costBudgetAvailable()) {
      return "cost_quota_limited";
    }
    return null;
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
      String policyVersion,
      String goalType,
      String supportStatus,
      String contentCoverage,
      LocalDate today,
      LocalDate activeBackplanCheckpointDueDate,
      LocalDate latestCheckpointDate,
      boolean entitlementAllowed,
      boolean quotaAvailable,
      boolean costBudgetAvailable) {}

  public record Decision(
      String checkpointState,
      String dueStatus,
      LocalDate dueDate,
      LocalDate nextDueDate,
      String cadence,
      String limitationReason,
      String supportStatus,
      String contentCoverage,
      TaskDefinition task,
      String ruleVersion) {}

  public record TaskDefinition(
      String taskId,
      String taskType,
      String cadence,
      String goalType,
      String promptRef,
      int estimatedDurationMinutes,
      List<String> requiredEvidence,
      String rubricRef,
      String supportStatus,
      String limitationReason,
      String aiDepth,
      String scoringBoundary) {}
}
