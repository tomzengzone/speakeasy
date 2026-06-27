package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotReplayFixtureTest extends BackendIntegrationTestSupport {
  private static final Instant BASE_TIME = Instant.parse("2026-06-05T02:00:00Z");

  @Autowired JdbcTemplate jdbcTemplate;
  @Autowired NotificationOutboxService outboxService;
  @Autowired PlannerReplayAuditRepository replayAudits;

  private final NotificationEligibilityPolicy eligibilityPolicy = new NotificationEligibilityPolicy();

  @Test
  void tcP02Fub015GlobalReplayCorpusComparesDecisionReasonStateAndRuleVersion() throws Exception {
    List<FixtureDecision> fixtureDecisions = List.of(
        controlSourceAndCommandFixture(),
        eligibilityFixture(),
        outboxReplayFixture(),
        recoveryReplayFixture(),
        itemPolicyReplayFixture(),
        masteryTransitionReplayFixture(),
        new FixtureDecision(
            "FUB-FIX-008",
            "global_replay",
            "all_decision_families_matched",
            "replay_match",
            "ReplayVerified",
            "followup-b-s006"));

    assertThat(fixtureDecisions)
        .extracting(FixtureDecision::fixtureId)
        .containsExactly(
            "FUB-FIX-001/002",
            "FUB-FIX-003",
            "FUB-FIX-004",
            "FUB-FIX-005",
            "FUB-FIX-006",
            "FUB-FIX-007",
            "FUB-FIX-008");
    assertThat(fixtureDecisions)
        .allSatisfy(decision -> {
          assertThat(decision.expectedDecision()).isNotBlank();
          assertThat(decision.reasonCode()).isNotBlank();
          assertThat(decision.outputState()).isNotBlank();
          assertThat(decision.ruleVersion()).isNotBlank();
        });
  }

  private FixtureDecision controlSourceAndCommandFixture() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140260");
    createSupportedGoal(tokens, "req_fub015_control_goal", "00:00", "00:00").andExpect(status().isOk());

    mvc.perform(get("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("blocked_by_policy"))
        .andExpect(jsonPath("$.control.rule_version").value("fub-control-v1"))
        .andExpect(jsonPath("$.reason_code").value("missing_plan"))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("missing_plan"))
        .andExpect(jsonPath("$.reminder_eligibility.rule_version").value(NotificationEligibilityPolicy.RULE_VERSION));

    MvcResult planResult = generatePlan(tokens, "req_fub015_control_plan", "initial_backplan")
        .andExpect(status().isOk())
        .andReturn();
    String firstPlanItemId = JsonPath.read(planResult.getResponse().getContentAsString(), "$.daily_plan.items[0].plan_item_id");

    mvc.perform(get("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.reason_code").value("eligible"))
        .andExpect(jsonPath("$.reminder_eligibility.eligible").value(true))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("eligible"))
        .andExpect(jsonPath("$.reminder_eligibility.plan_item_id").value(firstPlanItemId));

    String updatePayload = """
        {
          "schema_version": 1,
          "quiet_hours_start": "21:30",
          "quiet_hours_end": "07:15",
          "timezone": "Asia/Shanghai",
          "notification_consent": false,
          "intensity_override": "gentle",
          "missed_day_policy": "defer"
        }
        """;
    MvcResult firstUpdate = mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "fub015-control-update")
            .header("X-Request-Id", "req_fub015_control_update")
            .contentType(MediaType.APPLICATION_JSON)
            .content(updatePayload))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.reason_code").value("control_updated"))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("consent_missing"))
        .andReturn();
    String firstUpdatedAt = JsonPath.read(firstUpdate.getResponse().getContentAsString(), "$.control.updated_at");
    String firstDecisionId = JsonPath.read(firstUpdate.getResponse().getContentAsString(), "$.reminder_eligibility.decision_id");

    mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "fub015-control-update")
            .header("X-Request-Id", "req_fub015_control_update_replay")
            .contentType(MediaType.APPLICATION_JSON)
            .content(updatePayload))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.updated_at").value(firstUpdatedAt))
        .andExpect(jsonPath("$.reminder_eligibility.decision_id").value(firstDecisionId));

    mvc.perform(post("/goal-autopilot/control/pause")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "fub015-control-pause")
            .header("X-Request-Id", "req_fub015_control_pause")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "pause_reason": "user_requested_break"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("paused"))
        .andExpect(jsonPath("$.reason_code").value("paused"))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("paused"));

    mvc.perform(post("/goal-autopilot/control/resume")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "fub015-control-resume")
            .header("X-Request-Id", "req_fub015_control_resume")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_event": "manual_resume"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.control.rule_version").value("fub-control-v1"));

    return new FixtureDecision("FUB-FIX-001/002", "autopilot_control", "control_updated", "consent_missing", "active", "fub-control-v1");
  }

  private FixtureDecision eligibilityFixture() {
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
        localInstant(2026, 6, 5, 7, 30)));

    assertThat(decision.eligible()).isFalse();
    assertThat(decision.reasonCode()).isEqualTo("quiet_hours");
    assertThat(decision.nextAllowedAt()).isEqualTo(localInstant(2026, 6, 5, 8, 0));
    assertThat(decision.ruleVersion()).isEqualTo(NotificationEligibilityPolicy.RULE_VERSION);

    NotificationEligibilityPolicy.Decision precedenceDecision = eligibilityPolicy.evaluate(new NotificationEligibilityPolicy.Input(
        "paused",
        true,
        true,
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        "22:00",
        "08:00",
        "Asia/Shanghai",
        localInstant(2026, 6, 5, 7, 30)));
    assertThat(precedenceDecision.reasonCode()).isEqualTo("paused");

    return new FixtureDecision("FUB-FIX-003", "notification_eligibility", "blocked", "quiet_hours", "ReminderBlocked", decision.ruleVersion());
  }

  private FixtureDecision outboxReplayFixture() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140261");
    UUID userId = UUID.fromString(tokens.userId());
    MvcResult goalResult = createSupportedGoal(tokens, "req_fub015_outbox_goal").andExpect(status().isOk()).andReturn();
    String goalBody = goalResult.getResponse().getContentAsString();
    UUID goalProfileId = UUID.fromString(JsonPath.read(goalBody, "$.goal_profile.goal_profile_id"));
    int goalRevision = JsonPath.read(goalBody, "$.goal_profile.revision");
    MvcResult planResult = generatePlan(tokens, "req_fub015_outbox_plan", "initial_backplan").andExpect(status().isOk()).andReturn();
    UUID planItemId = UUID.fromString(JsonPath.read(
        planResult.getResponse().getContentAsString(),
        "$.daily_plan.items[0].plan_item_id"));

    NotificationOutboxService.ScheduleReminderCommand command = new NotificationOutboxService.ScheduleReminderCommand(
        userId,
        goalProfileId,
        goalRevision,
        planItemId,
        "evening_review",
        true,
        "eligible",
        null,
        "reminder_allowed",
        BASE_TIME,
        NotificationEligibilityPolicy.RULE_VERSION);
    NotificationOutboxService.OutboxRecordView pending = outboxService.scheduleOrUpdate(command);
    NotificationOutboxService.OutboxRecordView duplicate = outboxService.scheduleOrUpdate(command);
    NotificationOutboxService.OutboxRecordView scheduled = outboxService.markScheduled(pending.outboxId(), BASE_TIME.plusSeconds(30));
    NotificationOutboxService.OutboxRecordView failed =
        outboxService.recordFailure(scheduled.outboxId(), "provider_timeout", BASE_TIME.plusSeconds(90));

    assertThat(duplicate.outboxId()).isEqualTo(pending.outboxId());
    assertThat(failed.lifecycleStatus()).isEqualTo("failed");
    assertThat(failed.reasonCode()).isEqualTo("provider_timeout");
    assertThat(failed.inputSnapshotHash()).isEqualTo(pending.inputSnapshotHash());

    List<PlannerReplayAudit> audits =
        replayAudits.findByUserIdAndDecisionFamilyOrderByCreatedAtDesc(userId, "notification_outbox");
    assertThat(audits).hasSize(3);
    assertThat(audits).extracting(PlannerReplayAudit::getExpectedDecision).contains("pending", "scheduled", "failed");
    assertReplayAudit(audits.get(0), "notification_outbox", "failed", "provider_timeout", NotificationEligibilityPolicy.RULE_VERSION);

    return new FixtureDecision("FUB-FIX-004", "notification_outbox", "failed", "provider_timeout", "failed", failed.ruleVersion());
  }

  private FixtureDecision recoveryReplayFixture() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140262");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens, "req_fub015_recovery_goal").andExpect(status().isOk());
    MvcResult planResult = generatePlan(tokens, "req_fub015_recovery_plan", "initial_backplan").andExpect(status().isOk()).andReturn();
    String firstPlanItemId = JsonPath.read(planResult.getResponse().getContentAsString(), "$.daily_plan.items[0].plan_item_id");

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(firstPlanItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fub015_recovery_skip")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "skipped"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.plan_update_signal.signal_type").value("recovery_replan"));

    MvcResult recovery = mvc.perform(post("/goal-autopilot/recovery/replan")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "fub015-recovery")
            .header("X-Request-Id", "req_fub015_recovery")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_event": "skipped",
                  "plan_item_id": "%s",
                  "preferred_policy": "balanced"
                }
                """.formatted(firstPlanItemId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.recovery_decision.recovery_mode").value("defer"))
        .andExpect(jsonPath("$.recovery_decision.reason_code").value("balanced_defer_before_compress"))
        .andExpect(jsonPath("$.recovery_decision.input_snapshot_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.recovery_decision.rule_version").value(MissedDayRecoveryPlanner.RULE_VERSION))
        .andReturn();
    String decisionId = JsonPath.read(recovery.getResponse().getContentAsString(), "$.recovery_decision.decision_id");
    String dailyPlanId = JsonPath.read(recovery.getResponse().getContentAsString(), "$.daily_plan.daily_plan_id");

    mvc.perform(post("/goal-autopilot/recovery/replan")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "fub015-recovery")
            .header("X-Request-Id", "req_fub015_recovery_replay")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_event": "skipped",
                  "plan_item_id": "%s",
                  "preferred_policy": "balanced"
                }
                """.formatted(firstPlanItemId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.recovery_decision.decision_id").value(decisionId))
        .andExpect(jsonPath("$.daily_plan.daily_plan_id").value(dailyPlanId));

    List<PlannerReplayAudit> audits =
        replayAudits.findByUserIdAndDecisionFamilyOrderByCreatedAtDesc(userId, "missed_day_recovery");
    assertThat(audits).hasSize(1);
    assertReplayAudit(audits.get(0), "missed_day_recovery", "defer", "balanced_defer_before_compress", MissedDayRecoveryPlanner.RULE_VERSION);

    return new FixtureDecision("FUB-FIX-005", "missed_day_recovery", "defer", "balanced_defer_before_compress", "RecoveryPlanned", MissedDayRecoveryPlanner.RULE_VERSION);
  }

  private FixtureDecision itemPolicyReplayFixture() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140263");
    createSupportedGoal(tokens, "req_fub015_memory_goal").andExpect(status().isOk());
    generatePlan(tokens, "req_fub015_memory_plan", "initial_backplan").andExpect(status().isOk());

    String requestJson = itemPolicyRequestJson();
    MvcResult first = mvc.perform(post("/goal-autopilot/item-policy/decisions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fub015_memory_first")
            .contentType(MediaType.APPLICATION_JSON)
            .content(requestJson))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.decisions", hasSize(3)))
        .andExpect(jsonPath("$.decisions[0].due_decision").value("review_due"))
        .andExpect(jsonPath("$.decisions[0].reason_code").value("high_forgetting_risk"))
        .andExpect(jsonPath("$.replay_audit.decision_family").value("item_policy"))
        .andExpect(jsonPath("$.replay_audit.expected_decision").value("review_due"))
        .andExpect(jsonPath("$.replay_audit.reason_code").value("high_forgetting_risk"))
        .andExpect(jsonPath("$.replay_audit.rule_version").value(MemoryCurvePolicy.RULE_VERSION))
        .andReturn();

    MvcResult replay = mvc.perform(post("/goal-autopilot/item-policy/decisions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fub015_memory_replay")
            .contentType(MediaType.APPLICATION_JSON)
            .content(requestJson))
        .andExpect(status().isOk())
        .andReturn();

    assertThat(JsonPath.read(first.getResponse().getContentAsString(), "$.decisions").toString())
        .isEqualTo(JsonPath.read(replay.getResponse().getContentAsString(), "$.decisions").toString());
    assertThat((String) JsonPath.read(first.getResponse().getContentAsString(), "$.replay_audit.replay_hash"))
        .isEqualTo(JsonPath.read(replay.getResponse().getContentAsString(), "$.replay_audit.replay_hash"));

    return new FixtureDecision("FUB-FIX-006", "item_policy", "review_due", "high_forgetting_risk", "MemoryDuePlanning", MemoryCurvePolicy.RULE_VERSION);
  }

  private FixtureDecision masteryTransitionReplayFixture() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140264");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens, "req_fub015_mastery_goal").andExpect(status().isOk());
    MvcResult planResult = generatePlan(tokens, "req_fub015_mastery_plan", "initial_backplan").andExpect(status().isOk()).andReturn();
    UUID planItemId = UUID.fromString(JsonPath.read(
        planResult.getResponse().getContentAsString(),
        "$.daily_plan.items[0].plan_item_id"));

    completePlanItem(tokens, planItemId, "completed", "req_fub015_mastery_complete")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.action.status").value("ready"));

    mvc.perform(get("/goal-autopilot/mastery-transitions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.transitions", hasSize(1)))
        .andExpect(jsonPath("$.transitions[0].direction").value("promote"))
        .andExpect(jsonPath("$.transitions[0].reason_code").value("evidence_promotion_confident_retrieval"))
        .andExpect(jsonPath("$.transitions[0].rule_version").value(MasteryTransitionPolicy.RULE_VERSION));

    completePlanItem(tokens, planItemId, "completed", "req_fub015_mastery_complete_replay")
        .andExpect(status().isOk());

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_mastery_transition_decisions WHERE user_id = ?",
        Integer.class,
        userId)).isEqualTo(1);
    List<PlannerReplayAudit> audits =
        replayAudits.findByUserIdAndDecisionFamilyOrderByCreatedAtDesc(userId, "mastery_transition");
    assertThat(audits).hasSize(1);
    assertReplayAudit(audits.get(0), "mastery_transition", "promote", "evidence_promotion_confident_retrieval", MasteryTransitionPolicy.RULE_VERSION);

    return new FixtureDecision("FUB-FIX-007", "mastery_transition", "promote", "evidence_promotion_confident_retrieval", "MasteryTransitionApplied", MasteryTransitionPolicy.RULE_VERSION);
  }

  private void assertReplayAudit(
      PlannerReplayAudit audit,
      String decisionFamily,
      String expectedDecision,
      String reasonCode,
      String ruleVersion) {
    assertThat(audit.getDecisionFamily()).isEqualTo(decisionFamily);
    assertThat(audit.getExpectedDecision()).isEqualTo(expectedDecision);
    assertThat(audit.getReasonCode()).isEqualTo(reasonCode);
    assertThat(audit.getRuleVersion()).isEqualTo(ruleVersion);
    assertThat(audit.getInputSnapshotHash()).startsWith("sha256:");
    assertThat(audit.getOutputSnapshotHash()).startsWith("sha256:");
    assertThat(audit.getReplayHash()).startsWith("sha256:");
  }

  private org.springframework.test.web.servlet.ResultActions createSupportedGoal(AuthTokens tokens, String requestId)
      throws Exception {
    return createSupportedGoal(tokens, requestId, "22:00", "08:00");
  }

  private org.springframework.test.web.servlet.ResultActions createSupportedGoal(
      AuthTokens tokens, String requestId, String quietHoursStart, String quietHoursEnd) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .header("Idempotency-Key", "replay-fixture-goal-" + requestId)
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
                  "transcript": "I can answer familiar questions, but I often stop when I need to add a clear example and connect it back to the topic.",
                  "duration_seconds": 50
                },
                {
                  "sample_ref": "sample_2",
                  "transcript": "When the examiner asks a follow-up question, I understand it, but my answer becomes short and I repeat simple words.",
                  "duration_seconds": 45
                },
                {
                  "sample_ref": "sample_3",
                  "transcript": "My goal is to speak with stronger structure, more natural transitions, and enough detail to sustain a longer answer.",
                  "duration_seconds": 48
                }
              ],
              "autopilot_control": {
                "paused": false,
                "quiet_hours_start": "%s",
                "quiet_hours_end": "%s",
                "notification_consent": true,
                "intensity_override": "standard"
              }
            }
            """.formatted(LocalDate.now().plusDays(75), quietHoursStart, quietHoursEnd)));
  }

  private org.springframework.test.web.servlet.ResultActions generatePlan(AuthTokens tokens, String requestId, String reasonCode)
      throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": false,
              "reason_code": "%s"
            }
            """.formatted(reasonCode)));
  }

  private org.springframework.test.web.servlet.ResultActions completePlanItem(
      AuthTokens tokens,
      UUID planItemId,
      String outcome,
      String requestId) throws Exception {
    return mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(planItemId))
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "outcome": "%s",
              "evidence_ref": "fub015_evidence"
            }
            """.formatted(outcome)));
  }

  private String itemPolicyRequestJson() {
    return """
        {
          "schema_version": 1,
          "policy_version": "memory-curve-v1",
          "daily_time_budget_minutes": 15,
          "items": [
            {
              "item_type": "expression",
              "item_ref": "expr-high-risk",
              "interleaving_group": "fluency",
              "current_mastery_level": "L1",
              "evidence_refs": ["evidence-high"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 3,
              "overlearning_count": 2,
              "forgetting_risk": 0.72,
              "retrieval_success": false,
              "recent_failures": 2,
              "pressure_level": "high",
              "estimated_minutes": 5
            },
            {
              "item_type": "expression",
              "item_ref": "expr-fluency",
              "interleaving_group": "fluency",
              "current_mastery_level": "L2",
              "evidence_refs": ["evidence-fluency"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 2,
              "overlearning_count": 0,
              "forgetting_risk": 0.50,
              "retrieval_success": true,
              "recent_failures": 0,
              "pressure_level": "standard",
              "estimated_minutes": 5
            },
            {
              "item_type": "scenario",
              "item_ref": "scenario-budget",
              "interleaving_group": "scenario",
              "current_mastery_level": "L2",
              "evidence_refs": ["evidence-scenario"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 2,
              "overlearning_count": 0,
              "forgetting_risk": 0.50,
              "retrieval_success": true,
              "recent_failures": 0,
              "pressure_level": "standard",
              "estimated_minutes": 5
            }
          ]
        }
        """;
  }

  private static Instant localInstant(int year, int month, int day, int hour, int minute) {
    return ZonedDateTime.of(year, month, day, hour, minute, 0, 0, ZoneId.of("Asia/Shanghai")).toInstant();
  }

  private record FixtureDecision(
      String fixtureId,
      String decisionFamily,
      String expectedDecision,
      String reasonCode,
      String outputState,
      String ruleVersion) {}
}
