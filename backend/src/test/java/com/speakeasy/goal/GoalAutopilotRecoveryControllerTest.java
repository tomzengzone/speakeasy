package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.lessThanOrEqualTo;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import java.time.LocalDate;
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
class GoalAutopilotRecoveryControllerTest extends BackendIntegrationTestSupport {
  @Autowired JdbcTemplate jdbcTemplate;

  @Test
  void tcP02Fub010RecoveryReplanDefersWithoutOverdueStackingAndReplaysIdempotently() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140230");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens).andExpect(status().isOk());
    MvcResult planResult = generatePlan(tokens).andExpect(status().isOk()).andReturn();
    String planBody = planResult.getResponse().getContentAsString();
    String sourceDailyPlanId = JsonPath.read(planBody, "$.daily_plan.daily_plan_id");
    String firstPlanItemId = JsonPath.read(planBody, "$.daily_plan.items[0].plan_item_id");

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(firstPlanItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fub010_skip")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "skipped"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.plan_update_signal.signal_type").value("recovery_replan"));

    MvcResult recoveryResult = mvc.perform(post("/goal-autopilot/recovery/replan")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "recovery-fub010")
            .header("X-Request-Id", "req_fub010_recovery")
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
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.recovery_decision.source_event").value("skipped"))
        .andExpect(jsonPath("$.recovery_decision.recovery_mode").value("defer"))
        .andExpect(jsonPath("$.recovery_decision.reason_code").value("balanced_defer_before_compress"))
        .andExpect(jsonPath("$.recovery_decision.affected_plan_item_refs", hasSize(1)))
        .andExpect(jsonPath("$.recovery_decision.input_snapshot_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.recovery_decision.rule_version").value(MissedDayRecoveryPlanner.RULE_VERSION))
        .andExpect(jsonPath("$.daily_plan.daily_plan_id").value(not(sourceDailyPlanId)))
        .andExpect(jsonPath("$.daily_plan.status").value("ready"))
        .andExpect(jsonPath("$.daily_plan.total_minutes").value(lessThanOrEqualTo(30)))
        .andExpect(jsonPath("$.daily_plan.items", hasSize(1)))
        .andExpect(jsonPath("$.daily_plan.items[0].reason_code").value("recovery_defer_preserve_risk"))
        .andExpect(jsonPath("$.daily_plan.items[0].duration_minutes").value(lessThanOrEqualTo(30)))
        .andExpect(jsonPath("$.plan_update_signal.signal_type").value("recovery_replan"))
        .andReturn();
    String recoveryBody = recoveryResult.getResponse().getContentAsString();
    String decisionId = JsonPath.read(recoveryBody, "$.recovery_decision.decision_id");
    String recoveryDailyPlanId = JsonPath.read(recoveryBody, "$.daily_plan.daily_plan_id");

    mvc.perform(post("/goal-autopilot/recovery/replan")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "recovery-fub010")
            .header("X-Request-Id", "req_fub010_recovery_replay")
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
        .andExpect(jsonPath("$.daily_plan.daily_plan_id").value(recoveryDailyPlanId));

    mvc.perform(get("/goal-autopilot/daily-plan")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.daily_plan.daily_plan_id").value(recoveryDailyPlanId))
        .andExpect(jsonPath("$.daily_plan.items", hasSize(1)));

    assertThat(count("goal_recovery_plan_decisions", userId)).isEqualTo(1);
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_daily_plans WHERE user_id = ? AND status = 'stale'",
        Integer.class,
        userId)).isGreaterThan(0);
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_backplans WHERE user_id = ? AND status = 'stale' AND stale_reason = 'balanced_defer_before_compress'",
        Integer.class,
        userId)).isGreaterThan(0);
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_plan_items WHERE daily_plan_id = ?",
        Integer.class,
        UUID.fromString(recoveryDailyPlanId))).isEqualTo(1);
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COALESCE(SUM(duration_minutes), 0) FROM goal_plan_items WHERE daily_plan_id = ?",
        Integer.class,
        UUID.fromString(recoveryDailyPlanId))).isLessThanOrEqualTo(30);
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_planner_replay_audits WHERE user_id = ? AND decision_family = 'missed_day_recovery' AND expected_decision = 'defer'",
        Integer.class,
        userId)).isEqualTo(1);
  }

  @Test
  void tcP02Fub010RejectsInvalidRecoverySourceEvent() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140231");
    createSupportedGoal(tokens).andExpect(status().isOk());
    generatePlan(tokens).andExpect(status().isOk());

    mvc.perform(post("/goal-autopilot/recovery/replan")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "recovery-bad-source")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_event": "stack_everything"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  private org.springframework.test.web.servlet.ResultActions createSupportedGoal(AuthTokens tokens) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_fub010_goal")
        .header("Idempotency-Key", "recovery-goal-" + tokens.userId())
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
                "quiet_hours_start": "22:00",
                "quiet_hours_end": "08:00",
                "notification_consent": true,
                "intensity_override": "standard"
              }
            }
            """.formatted(LocalDate.now().plusDays(75))));
  }

  private org.springframework.test.web.servlet.ResultActions generatePlan(AuthTokens tokens) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_fub010_plan")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": false,
              "reason_code": "initial_backplan"
            }
            """));
  }

  private int count(String tableName, UUID userId) {
    return jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?", Integer.class, userId);
  }
}
