package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import org.junit.jupiter.api.Test;

class NotificationEligibilityPolicyTest {
  private static final ZoneId SHANGHAI = ZoneId.of("Asia/Shanghai");

  private final NotificationEligibilityPolicy policy = new NotificationEligibilityPolicy();

  @Test
  void tcP02Fub005ReturnsFirstMatchingReasonByPrecedence() {
    assertReason(fixture().lowerPriorityBlocks().controlStatus("paused"), "paused");
    assertReason(fixture().lowerPriorityBlocks().controlPolicyBlocked(true), "blocked_by_policy");
    assertReason(fixture().lowerPriorityBlocks().unsupportedGoal(true), "unsupported_goal");
    assertReason(fixture().lowerPriorityBlocks().partialGoalLimited(true), "partial_goal_limited");
    assertReason(fixture().lowerPriorityBlocks().stalePlan(true), "stale_plan");
    assertReason(fixture().lowerPriorityBlocks().missingPlan(true), "missing_plan");
    assertReason(fixture().lowerPriorityBlocks().notificationConsent(false), "consent_missing");
    assertReason(fixture().lowerPriorityBlocks().platformPermissionGranted(false), "permission_denied");
    assertReason(fixture().lowerPriorityBlocks().entitlementAllowed(false), "entitlement_blocked");
    assertReason(fixture().lowerPriorityBlocks().quotaAvailable(false), "quota_exhausted");
    assertReason(fixture().insideCrossMidnightQuietHours(), "quiet_hours");
    assertReason(fixture(), "eligible");
  }

  @Test
  void tcP02Fub005EvaluatesQuietHoursSameDayCrossMidnightAndDisabledWindow() {
    NotificationEligibilityPolicy.Decision sameDay = policy.evaluate(fixture()
        .quietHours("09:00", "17:00")
        .evaluatedAt(localInstant(2026, 6, 4, 10, 15))
        .build());
    assertThat(sameDay.reasonCode()).isEqualTo("quiet_hours");
    assertThat(sameDay.nextAllowedAt()).isEqualTo(localInstant(2026, 6, 4, 17, 0));
    assertThat(sameDay.explanationKey()).isEqualTo("reminder_blocked_quiet_hours");

    NotificationEligibilityPolicy.Decision crossMidnightEvening = policy.evaluate(fixture()
        .quietHours("22:00", "08:00")
        .evaluatedAt(localInstant(2026, 6, 4, 23, 30))
        .build());
    assertThat(crossMidnightEvening.reasonCode()).isEqualTo("quiet_hours");
    assertThat(crossMidnightEvening.nextAllowedAt()).isEqualTo(localInstant(2026, 6, 5, 8, 0));

    NotificationEligibilityPolicy.Decision crossMidnightMorning = policy.evaluate(fixture()
        .quietHours("22:00", "08:00")
        .evaluatedAt(localInstant(2026, 6, 5, 7, 30))
        .build());
    assertThat(crossMidnightMorning.reasonCode()).isEqualTo("quiet_hours");
    assertThat(crossMidnightMorning.nextAllowedAt()).isEqualTo(localInstant(2026, 6, 5, 8, 0));

    NotificationEligibilityPolicy.Decision disabled = policy.evaluate(fixture()
        .quietHours("22:00", "22:00")
        .evaluatedAt(localInstant(2026, 6, 4, 22, 30))
        .build());
    assertThat(disabled.reasonCode()).isEqualTo("eligible");
    assertThat(disabled.eligible()).isTrue();
    assertThat(disabled.nextAllowedAt()).isNull();
  }

  private void assertReason(Fixture fixture, String reasonCode) {
    NotificationEligibilityPolicy.Decision decision = policy.evaluate(fixture.build());
    assertThat(decision.reasonCode()).isEqualTo(reasonCode);
    assertThat(decision.eligible()).isEqualTo("eligible".equals(reasonCode));
    assertThat(decision.ruleVersion()).isEqualTo(NotificationEligibilityPolicy.RULE_VERSION);
  }

  private Fixture fixture() {
    return new Fixture();
  }

  private static Instant localInstant(int year, int month, int day, int hour, int minute) {
    return ZonedDateTime.of(year, month, day, hour, minute, 0, 0, SHANGHAI).toInstant();
  }

  private static final class Fixture {
    private String controlStatus = "active";
    private boolean controlPolicyBlocked = false;
    private boolean unsupportedGoal = false;
    private boolean partialGoalLimited = false;
    private boolean stalePlan = false;
    private boolean missingPlan = false;
    private boolean notificationConsent = true;
    private boolean platformPermissionGranted = true;
    private boolean entitlementAllowed = true;
    private boolean quotaAvailable = true;
    private String quietHoursStart = "00:00";
    private String quietHoursEnd = "00:00";
    private Instant evaluatedAt = localInstant(2026, 6, 4, 12, 0);

    private Fixture lowerPriorityBlocks() {
      unsupportedGoal = true;
      partialGoalLimited = true;
      stalePlan = true;
      missingPlan = true;
      notificationConsent = false;
      platformPermissionGranted = false;
      entitlementAllowed = false;
      quotaAvailable = false;
      return insideCrossMidnightQuietHours();
    }

    private Fixture insideCrossMidnightQuietHours() {
      quietHoursStart = "22:00";
      quietHoursEnd = "08:00";
      evaluatedAt = localInstant(2026, 6, 4, 23, 0);
      return this;
    }

    private Fixture controlStatus(String value) {
      controlStatus = value;
      return this;
    }

    private Fixture controlPolicyBlocked(boolean value) {
      controlPolicyBlocked = value;
      return this;
    }

    private Fixture unsupportedGoal(boolean value) {
      unsupportedGoal = value;
      return this;
    }

    private Fixture partialGoalLimited(boolean value) {
      unsupportedGoal = false;
      partialGoalLimited = value;
      return this;
    }

    private Fixture stalePlan(boolean value) {
      unsupportedGoal = false;
      partialGoalLimited = false;
      stalePlan = value;
      return this;
    }

    private Fixture missingPlan(boolean value) {
      unsupportedGoal = false;
      partialGoalLimited = false;
      stalePlan = false;
      missingPlan = value;
      return this;
    }

    private Fixture notificationConsent(boolean value) {
      unsupportedGoal = false;
      partialGoalLimited = false;
      stalePlan = false;
      missingPlan = false;
      notificationConsent = value;
      return this;
    }

    private Fixture platformPermissionGranted(boolean value) {
      unsupportedGoal = false;
      partialGoalLimited = false;
      stalePlan = false;
      missingPlan = false;
      notificationConsent = true;
      platformPermissionGranted = value;
      return this;
    }

    private Fixture entitlementAllowed(boolean value) {
      unsupportedGoal = false;
      partialGoalLimited = false;
      stalePlan = false;
      missingPlan = false;
      notificationConsent = true;
      platformPermissionGranted = true;
      entitlementAllowed = value;
      return this;
    }

    private Fixture quotaAvailable(boolean value) {
      unsupportedGoal = false;
      partialGoalLimited = false;
      stalePlan = false;
      missingPlan = false;
      notificationConsent = true;
      platformPermissionGranted = true;
      entitlementAllowed = true;
      quotaAvailable = value;
      return this;
    }

    private Fixture quietHours(String start, String end) {
      quietHoursStart = start;
      quietHoursEnd = end;
      return this;
    }

    private Fixture evaluatedAt(Instant value) {
      evaluatedAt = value;
      return this;
    }

    private NotificationEligibilityPolicy.Input build() {
      return new NotificationEligibilityPolicy.Input(
          controlStatus,
          controlPolicyBlocked,
          unsupportedGoal,
          partialGoalLimited,
          stalePlan,
          missingPlan,
          notificationConsent,
          platformPermissionGranted,
          entitlementAllowed,
          quotaAvailable,
          quietHoursStart,
          quietHoursEnd,
          "Asia/Shanghai",
          evaluatedAt);
    }
  }
}
