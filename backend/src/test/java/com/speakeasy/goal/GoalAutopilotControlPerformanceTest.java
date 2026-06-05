package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotControlPerformanceTest extends BackendIntegrationTestSupport {
  private static final Instant BASE_TIME = Instant.parse("2026-06-05T02:00:00Z");

  @Autowired NotificationOutboxService outboxService;
  @Autowired PlannerReplayAuditRepository replayAudits;

  private final NotificationEligibilityPolicy eligibilityPolicy = new NotificationEligibilityPolicy();
  private final MissedDayRecoveryPlanner recoveryPlanner = new MissedDayRecoveryPlanner();
  private final MemoryCurvePolicy memoryCurvePolicy = new MemoryCurvePolicy();
  private final MasteryTransitionPolicy masteryTransitionPolicy = new MasteryTransitionPolicy();

  @Test
  void tcP02Fub016LocalP95BudgetsStayUnderFollowupBTargets() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140270");
    UUID userId = UUID.fromString(tokens.userId());
    MvcResult goalResult = createSupportedGoal(tokens, "req_fub016_goal").andExpect(status().isOk()).andReturn();
    String goalBody = goalResult.getResponse().getContentAsString();
    UUID goalProfileId = UUID.fromString(JsonPath.read(goalBody, "$.goal_profile.goal_profile_id"));
    int goalRevision = JsonPath.read(goalBody, "$.goal_profile.revision");
    MvcResult planResult = generatePlan(tokens, "req_fub016_plan").andExpect(status().isOk()).andReturn();
    UUID planItemId = UUID.fromString(JsonPath.read(
        planResult.getResponse().getContentAsString(),
        "$.daily_plan.items[0].plan_item_id"));

    warmUp(tokens);

    List<Long> controlLoad = new ArrayList<>();
    for (int i = 0; i < 24; i++) {
      controlLoad.add(timed(() -> mvc.perform(get("/goal-autopilot/control")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
          .andExpect(status().isOk())));
    }

    List<Long> controlCommands = new ArrayList<>();
    for (int i = 0; i < 8; i++) {
      int index = i;
      controlCommands.add(timed(() -> updateControl(tokens, index).andExpect(status().isOk())));
      controlCommands.add(timed(() -> pauseControl(tokens, index).andExpect(status().isOk())));
      controlCommands.add(timed(() -> resumeControl(tokens, index).andExpect(status().isOk())));
    }

    List<Long> notificationEligibility = new ArrayList<>();
    for (int i = 0; i < 100; i++) {
      int index = i;
      notificationEligibility.add(timed(() -> {
        NotificationEligibilityPolicy.Decision decision = eligibilityPolicy.evaluate(new NotificationEligibilityPolicy.Input(
            "active",
            false,
            false,
            false,
            false,
            false,
            true,
            true,
            true,
            true,
            "22:00",
            "08:00",
            "Asia/Shanghai",
            BASE_TIME.plusSeconds(index)));
        assertThat(decision.reasonCode()).isIn("quiet_hours", "eligible");
      }));
    }

    List<Long> outboxLifecycle = new ArrayList<>();
    for (int i = 0; i < 20; i++) {
      int index = i;
      outboxLifecycle.add(timed(() -> {
        NotificationOutboxService.OutboxRecordView pending = outboxService.scheduleOrUpdate(
            outboxCommand(userId, goalProfileId, goalRevision, planItemId, "slot_" + index, BASE_TIME.plusSeconds(index)));
        NotificationOutboxService.OutboxRecordView scheduled =
            outboxService.markScheduled(pending.outboxId(), BASE_TIME.plusSeconds(100 + index));
        outboxService.recordFailure(scheduled.outboxId(), "provider_timeout", BASE_TIME.plusSeconds(200 + index));
      }));
    }

    List<Long> recoveryReplan = new ArrayList<>();
    for (int i = 0; i < 100; i++) {
      recoveryReplan.add(timed(() -> {
        MissedDayRecoveryPlanner.Decision decision = recoveryPlanner.plan(recoveryInput());
        assertThat(decision.recoveryMode()).isEqualTo("defer");
      }));
    }

    List<Long> memoryDue = new ArrayList<>();
    MemoryCurvePolicy.Input memoryInput = memoryInput(500);
    for (int i = 0; i < 20; i++) {
      memoryDue.add(timed(() -> {
        MemoryCurvePolicy.Result result = memoryCurvePolicy.evaluate(memoryInput);
        assertThat(result.decisions()).hasSize(500);
      }));
    }

    List<Long> masteryTransition = new ArrayList<>();
    for (int i = 0; i < 100; i++) {
      masteryTransition.add(timed(() -> {
        MasteryTransitionPolicy.Decision decision = masteryTransitionPolicy.evaluate(masteryInput());
        assertThat(decision.direction()).isEqualTo("promote");
      }));
    }

    List<Long> replayVerification = new ArrayList<>();
    for (int i = 0; i < 24; i++) {
      replayVerification.add(timed(() -> {
        List<PlannerReplayAudit> audits = replayAudits.findByUserIdOrderByCreatedAtDesc(userId);
        assertThat(audits).hasSizeGreaterThanOrEqualTo(20);
        assertThat(audits).allSatisfy(audit -> {
          assertThat(audit.getInputSnapshotHash()).startsWith("sha256:");
          assertThat(audit.getOutputSnapshotHash()).startsWith("sha256:");
          assertThat(audit.getReplayHash()).startsWith("sha256:");
          assertThat(audit.getRuleVersion()).isNotBlank();
        });
      }));
    }

    assertThat(p95(controlLoad)).isLessThan(Duration.ofMillis(200).toNanos());
    assertThat(p95(controlCommands)).isLessThan(Duration.ofMillis(500).toNanos());
    assertThat(p95(notificationEligibility)).isLessThan(Duration.ofMillis(200).toNanos());
    assertThat(p95(outboxLifecycle)).isLessThan(Duration.ofMillis(300).toNanos());
    assertThat(p95(recoveryReplan)).isLessThan(Duration.ofMillis(500).toNanos());
    assertThat(p95(memoryDue)).isLessThan(Duration.ofMillis(300).toNanos());
    assertThat(p95(masteryTransition)).isLessThan(Duration.ofMillis(300).toNanos());
    assertThat(p95(replayVerification)).isLessThan(Duration.ofMillis(500).toNanos());
  }

  private void warmUp(AuthTokens tokens) throws Exception {
    mvc.perform(get("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk());
    eligibilityPolicy.evaluate(new NotificationEligibilityPolicy.Input(
        "active",
        false,
        false,
        false,
        false,
        false,
        true,
        true,
        true,
        true,
        "00:00",
        "00:00",
        "Asia/Shanghai",
        BASE_TIME));
    recoveryPlanner.plan(recoveryInput());
    memoryCurvePolicy.evaluate(memoryInput(20));
    masteryTransitionPolicy.evaluate(masteryInput());
  }

  private org.springframework.test.web.servlet.ResultActions updateControl(AuthTokens tokens, int index) throws Exception {
    boolean consent = index % 2 == 0;
    return mvc.perform(patch("/goal-autopilot/control")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("Idempotency-Key", "fub016-control-update-" + index)
        .header("X-Request-Id", "req_fub016_control_update_" + index)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "quiet_hours_start": "22:00",
              "quiet_hours_end": "08:00",
              "timezone": "Asia/Shanghai",
              "notification_consent": %s,
              "intensity_override": "standard",
              "missed_day_policy": "balanced"
            }
            """.formatted(consent)));
  }

  private org.springframework.test.web.servlet.ResultActions pauseControl(AuthTokens tokens, int index) throws Exception {
    return mvc.perform(post("/goal-autopilot/control/pause")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("Idempotency-Key", "fub016-control-pause-" + index)
        .header("X-Request-Id", "req_fub016_control_pause_" + index)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "pause_reason": "performance_fixture"
            }
            """));
  }

  private org.springframework.test.web.servlet.ResultActions resumeControl(AuthTokens tokens, int index) throws Exception {
    return mvc.perform(post("/goal-autopilot/control/resume")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("Idempotency-Key", "fub016-control-resume-" + index)
        .header("X-Request-Id", "req_fub016_control_resume_" + index)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "source_event": "manual_resume"
            }
            """));
  }

  private NotificationOutboxService.ScheduleReminderCommand outboxCommand(
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      UUID planItemId,
      String slot,
      Instant evaluatedAt) {
    return new NotificationOutboxService.ScheduleReminderCommand(
        userId,
        goalProfileId,
        goalRevision,
        planItemId,
        slot,
        true,
        "eligible",
        null,
        "reminder_allowed",
        evaluatedAt,
        NotificationEligibilityPolicy.RULE_VERSION);
  }

  private MissedDayRecoveryPlanner.Input recoveryInput() {
    return new MissedDayRecoveryPlanner.Input(
        "skipped",
        "balanced",
        "supported",
        true,
        LocalDate.of(2026, 6, 5),
        LocalDate.of(2026, 6, 20),
        30,
        "standard",
        "medium",
        List.of(
            new MissedDayRecoveryPlanner.RecoveryPlanItem(
                "item-risk-driving",
                "review",
                "memory_risk_high",
                20,
                "skipped",
                "high",
                1),
            new MissedDayRecoveryPlanner.RecoveryPlanItem(
                "item-lower-priority",
                "training",
                "supporting_drill",
                15,
                "ready",
                "medium",
                2)));
  }

  private MemoryCurvePolicy.Input memoryInput(int itemCount) {
    List<MemoryCurvePolicy.ItemInput> items = new ArrayList<>();
    for (int i = 0; i < itemCount; i++) {
      boolean highRisk = i % 10 == 0;
      items.add(new MemoryCurvePolicy.ItemInput(
          "expression",
          "expr-perf-" + i,
          i % 3 == 0 ? "fluency" : "scenario",
          "L2",
          List.of("evidence-" + i),
          BASE_TIME.minusSeconds(5L * 24 * 60 * 60),
          2,
          highRisk ? 2 : 0,
          highRisk ? 0.72 : 0.50,
          !highRisk,
          highRisk ? 2 : 0,
          highRisk ? "high" : "standard",
          1));
    }
    return new MemoryCurvePolicy.Input(MemoryCurvePolicy.RULE_VERSION, "active", BASE_TIME, 120, items);
  }

  private MasteryTransitionPolicy.Input masteryInput() {
    return new MasteryTransitionPolicy.Input(
        "L2",
        "L5",
        0.84,
        List.of("diagnostic:fluency", "training:turn-1", "retrieval:expr-1"),
        3,
        0,
        false,
        false,
        false,
        false,
        "supported",
        false);
  }

  private org.springframework.test.web.servlet.ResultActions createSupportedGoal(AuthTokens tokens, String requestId)
      throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "goal_type": "ielts_speaking",
              "target_score": 8,
              "target_ability": "confident speaking under IELTS part 2 and part 3 pressure",
              "deadline": "%s",
              "daily_minutes": 30,
              "intensity_preference": "standard",
              "diagnostic_samples": [
                {
                  "sample_ref": "sample_1",
                  "transcript": "I can answer familiar questions, but I need more detail and cleaner examples.",
                  "duration_seconds": 45
                },
                {
                  "sample_ref": "sample_2",
                  "transcript": "Follow-up questions are understandable, but my answers become short.",
                  "duration_seconds": 45
                },
                {
                  "sample_ref": "sample_3",
                  "transcript": "I want stronger structure, transitions, and enough extension for longer answers.",
                  "duration_seconds": 45
                }
              ],
              "autopilot_control": {
                "paused": false,
                "quiet_hours_start": "22:00",
                "quiet_hours_end": "08:00",
                "notification_consent": true,
                "intensity_override": "standard"
              }
            }
            """.formatted(LocalDate.now().plusDays(75))));
  }

  private org.springframework.test.web.servlet.ResultActions generatePlan(AuthTokens tokens, String requestId) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": false,
              "reason_code": "performance_budget_fixture"
            }
            """));
  }

  private long timed(ThrowingAction action) throws Exception {
    long start = System.nanoTime();
    action.run();
    return System.nanoTime() - start;
  }

  private long p95(List<Long> values) {
    List<Long> sorted = new ArrayList<>(values);
    Collections.sort(sorted);
    return sorted.get((int) Math.ceil(sorted.size() * 0.95) - 1);
  }

  @FunctionalInterface
  private interface ThrowingAction {
    void run() throws Exception;
  }
}
