package com.speakeasy.goal;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;

public class NotificationEligibilityPolicy {
  public static final String RULE_VERSION = "fub-reminder-v1";

  public Decision evaluate(Input input) {
    Instant evaluatedAt = input.evaluatedAt() == null ? Instant.now() : input.evaluatedAt();
    if ("paused".equals(input.controlStatus())) {
      return blocked("paused", null, evaluatedAt);
    }
    if (input.controlPolicyBlocked() || "blocked_by_policy".equals(input.controlStatus())) {
      return blocked("blocked_by_policy", null, evaluatedAt);
    }
    if (input.unsupportedGoal()) {
      return blocked("unsupported_goal", null, evaluatedAt);
    }
    if (input.partialGoalLimited()) {
      return blocked("partial_goal_limited", null, evaluatedAt);
    }
    if (input.stalePlan()) {
      return blocked("stale_plan", null, evaluatedAt);
    }
    if (input.missingPlan()) {
      return blocked("missing_plan", null, evaluatedAt);
    }
    if (!input.notificationConsent()) {
      return blocked("consent_missing", null, evaluatedAt);
    }
    if (!input.platformPermissionGranted()) {
      return blocked("permission_denied", null, evaluatedAt);
    }
    if (!input.entitlementAllowed()) {
      return blocked("entitlement_blocked", null, evaluatedAt);
    }
    if (!input.quotaAvailable()) {
      return blocked("quota_exhausted", null, evaluatedAt);
    }
    Instant nextAllowedAt = nextAllowedAfterQuietHours(input.quietHoursStart(), input.quietHoursEnd(), input.timezone(), evaluatedAt);
    if (nextAllowedAt != null) {
      return blocked("quiet_hours", nextAllowedAt, evaluatedAt);
    }
    return new Decision(true, "eligible", null, "reminder_allowed", evaluatedAt, RULE_VERSION);
  }

  private Decision blocked(String reasonCode, Instant nextAllowedAt, Instant evaluatedAt) {
    return new Decision(false, reasonCode, nextAllowedAt, explanationKey(reasonCode), evaluatedAt, RULE_VERSION);
  }

  private Instant nextAllowedAfterQuietHours(String startValue, String endValue, String timezone, Instant evaluatedAt) {
    if (isBlank(startValue) || isBlank(endValue)) {
      return null;
    }
    LocalTime start = LocalTime.parse(startValue.trim());
    LocalTime end = LocalTime.parse(endValue.trim());
    if (start.equals(end)) {
      return null;
    }
    ZoneId zone = ZoneId.of(isBlank(timezone) ? "Asia/Shanghai" : timezone.trim());
    ZonedDateTime localNow = evaluatedAt.atZone(zone);
    LocalTime now = localNow.toLocalTime();
    if (start.isBefore(end)) {
      if (!now.isBefore(start) && now.isBefore(end)) {
        return ZonedDateTime.of(localNow.toLocalDate(), end, zone).toInstant();
      }
      return null;
    }
    if (!now.isBefore(start)) {
      LocalDate nextDay = localNow.toLocalDate().plusDays(1);
      return ZonedDateTime.of(nextDay, end, zone).toInstant();
    }
    if (now.isBefore(end)) {
      return ZonedDateTime.of(localNow.toLocalDate(), end, zone).toInstant();
    }
    return null;
  }

  public String explanationKey(String reasonCode) {
    return switch (reasonCode) {
      case "eligible" -> "reminder_allowed";
      case "paused" -> "reminder_blocked_paused";
      case "blocked_by_policy" -> "reminder_blocked_by_policy";
      case "unsupported_goal" -> "reminder_blocked_unsupported_goal";
      case "partial_goal_limited" -> "reminder_blocked_partial_goal";
      case "stale_plan" -> "reminder_blocked_stale_plan";
      case "missing_plan" -> "reminder_blocked_missing_plan";
      case "consent_missing" -> "reminder_blocked_consent_missing";
      case "permission_denied" -> "reminder_blocked_permission_denied";
      case "entitlement_blocked" -> "reminder_blocked_entitlement";
      case "quota_exhausted" -> "reminder_blocked_quota";
      case "quiet_hours" -> "reminder_blocked_quiet_hours";
      default -> "reminder_blocked_missing_plan";
    };
  }

  private boolean isBlank(String value) {
    return value == null || value.isBlank();
  }

  public record Input(
      String controlStatus,
      boolean controlPolicyBlocked,
      boolean unsupportedGoal,
      boolean partialGoalLimited,
      boolean stalePlan,
      boolean missingPlan,
      boolean notificationConsent,
      boolean platformPermissionGranted,
      boolean entitlementAllowed,
      boolean quotaAvailable,
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      Instant evaluatedAt) {}

  public record Decision(
      boolean eligible,
      String reasonCode,
      Instant nextAllowedAt,
      String explanationKey,
      Instant evaluatedAt,
      String ruleVersion) {}
}
