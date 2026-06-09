package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotRuntimeGateTest extends BackendIntegrationTestSupport {
  private static final String RUNTIME_PROPERTY_SOURCE = "goal-autopilot-runtime-test";

  @Autowired ConfigurableEnvironment environment;
  @Autowired JdbcTemplate jdbcTemplate;

  @AfterEach
  void clearRuntimeProperties() {
    environment.getPropertySources().remove(RUNTIME_PROPERTY_SOURCE);
  }

  @Test
  void tcP02Fud001FeatureFlagDisabledBlocksMutationsBeforeWritesAndAudits() throws Exception {
    setRuntimeGate(false, false, "operator_disabled");
    AuthTokens tokens = loginPhone("+8613800140701");
    UUID userId = UUID.fromString(tokens.userId());

    createGoal(tokens, "req_fud_disabled_goal")
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("GOAL_AUTOPILOT_RUNTIME_DISABLED"))
        .andExpect(jsonPath("$.error.request_id").value("req_fud_disabled_goal"))
        .andExpect(jsonPath("$.error.details.reason_code").value("feature_disabled"))
        .andExpect(jsonPath("$.error.details.runtime_state").value("RuntimeDisabled"))
        .andExpect(jsonPath("$.error.details.audit_log_id", not(blankOrNullString())));

    assertThat(countRows("goal_profiles", userId)).isZero();
    assertThat(countRows("goal_diagnostic_assessments", userId)).isZero();
    assertThat(countRows("goal_backplans", userId)).isZero();

    generatePlan(tokens, "req_fud_disabled_plan")
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.details.reason_code").value("feature_disabled"));

    assertThat(blockedAuditCount(userId)).isEqualTo(2);
    String auditDetails = jdbcTemplate.queryForObject(
        "SELECT redacted_details FROM audit_logs WHERE actor_id = ? AND event_type = 'goal_autopilot_runtime_blocked' AND target_ref = 'goal_autopilot_runtime:goal_create_or_update'",
        String.class,
        userId.toString());
    assertThat(auditDetails)
        .contains("\"reason_code\":\"feature_disabled\"")
        .contains("\"operation\":\"goal_create_or_update\"")
        .doesNotContain("diagnostic_samples")
        .doesNotContain("target_score");

    mvc.perform(get("/goal-autopilot/progress-projection")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fud_disabled_projection"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.projection.projection_state").value("unavailable"))
        .andExpect(jsonPath("$.projection.downgrade_reason").value("feature_disabled"))
        .andExpect(jsonPath("$.projection.goal").doesNotExist())
        .andExpect(jsonPath("$.projection.progress").doesNotExist())
        .andExpect(jsonPath("$.projection.latest_checkpoint").doesNotExist())
        .andExpect(jsonPath("$.projection.surface_fragments", hasSize(3)))
        .andExpect(jsonPath("$.projection.surface_fragments[0].eligible").value(false));
  }

  @Test
  void tcP02Fud002KillSwitchHidesExistingProjectionAndFailsClosed() throws Exception {
    setRuntimeGate(true, false, "operator_disabled");
    AuthTokens tokens = loginPhone("+8613800140702");
    UUID userId = UUID.fromString(tokens.userId());
    createGoal(tokens, "req_fud_enabled_goal").andExpect(status().isOk());
    String planResponse = generatePlan(tokens, "req_fud_enabled_plan")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.daily_plan.items", hasSize(2)))
        .andReturn()
        .getResponse()
        .getContentAsString();
    String planItemId = JsonPath.read(planResponse, "$.daily_plan.items[0].plan_item_id");

    mvc.perform(get("/goal-autopilot/progress-projection")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.projection.projection_state").value("ready"))
        .andExpect(jsonPath("$.projection.progress.eta_date", not(blankOrNullString())))
        .andExpect(jsonPath("$.projection.next_action.plan_item_id").value(planItemId));

    setRuntimeGate(true, true, "release_hold");

    mvc.perform(get("/goal-autopilot/progress-projection")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fud_kill_projection"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.projection.projection_state").value("unavailable"))
        .andExpect(jsonPath("$.projection.downgrade_reason").value("kill_switch_active"))
        .andExpect(jsonPath("$.projection.goal").doesNotExist())
        .andExpect(jsonPath("$.projection.next_action").doesNotExist())
        .andExpect(jsonPath("$.projection.progress").doesNotExist())
        .andExpect(jsonPath("$.projection.latest_checkpoint").doesNotExist())
        .andExpect(jsonPath("$.projection.source_refs", hasSize(0)));

    mvc.perform(get("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("blocked_by_policy"))
        .andExpect(jsonPath("$.control.pause_reason").value("kill_switch_active"))
        .andExpect(jsonPath("$.reason_code").value("kill_switch_active"))
        .andExpect(jsonPath("$.reminder_eligibility.eligible").value(false));

    mvc.perform(get("/goal-autopilot/summary")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.details.reason_code").value("kill_switch_active"))
        .andExpect(jsonPath("$.error.details.kill_switch_reason").value("release_hold"));
    expectRuntimeDisabledGet(tokens, "/goal-autopilot/daily-plan", "kill_switch_active");
    expectRuntimeDisabledGet(tokens, "/goal-autopilot/mastery-transitions", "kill_switch_active");
    expectRuntimeDisabledGet(tokens, "/goal-autopilot/reminders/outbox", "kill_switch_active");
    expectRuntimeDisabledGet(tokens, "/goal-autopilot/replay-audits", "kill_switch_active");

    mvc.perform(post("/goal-autopilot/reminders/eligibility")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fud_kill_reminder_eligibility")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "plan_item_id": "%s",
                  "reminder_slot": "evening_review",
                  "platform_permission": "granted"
                }
                """.formatted(planItemId)))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.request_id").value("req_fud_kill_reminder_eligibility"))
        .andExpect(jsonPath("$.error.details.reason_code").value("kill_switch_active"))
        .andExpect(jsonPath("$.error.details.audit_log_id", not(blankOrNullString())));

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(planItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fud_kill_complete")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "completed"
                }
                """))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.request_id").value("req_fud_kill_complete"))
        .andExpect(jsonPath("$.error.details.reason_code").value("kill_switch_active"))
        .andExpect(jsonPath("$.error.details.audit_log_id", not(blankOrNullString())));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT status FROM goal_plan_items WHERE plan_item_id = ?",
        String.class,
        UUID.fromString(planItemId))).isEqualTo("active");
    assertThat(blockedAuditCount(userId)).isEqualTo(2);
  }

  private void setRuntimeGate(boolean enabled, boolean killSwitchEnabled, String reason) {
    environment.getPropertySources().remove(RUNTIME_PROPERTY_SOURCE);
    environment.getPropertySources().addFirst(new MapPropertySource(
        RUNTIME_PROPERTY_SOURCE,
        Map.of(
            "speakeasy.goal-autopilot.runtime.enabled", Boolean.toString(enabled),
            "speakeasy.goal-autopilot.runtime.kill-switch.enabled", Boolean.toString(killSwitchEnabled),
            "speakeasy.goal-autopilot.runtime.kill-switch.reason", reason)));
  }

  private ResultActions createGoal(AuthTokens tokens, String requestId) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "goal_type": "ielts_speaking",
              "target_score": 8,
              "target_ability": "IELTS speaking with structured examples",
              "deadline": "%s",
              "daily_minutes": 30,
              "intensity_preference": "standard",
              "diagnostic_samples": [
                {
                  "sample_ref": "fud_sample_1",
                  "transcript": "I can answer familiar questions, but I need more structure, examples, and smoother follow-up responses.",
                  "duration_seconds": 45
                },
                {
                  "sample_ref": "fud_sample_2",
                  "transcript": "My target is to speak with clearer transitions, less hesitation, and better topic expansion.",
                  "duration_seconds": 40
                },
                {
                  "sample_ref": "fud_sample_3",
                  "transcript": "I want daily practice that automatically tells me what to train, review, and retest.",
                  "duration_seconds": 35
                }
              ],
              "autopilot_control": {
                "quiet_hours_start": "22:00",
                "quiet_hours_end": "08:00",
                "notification_consent": true
              }
            }
            """.formatted(LocalDate.now().plusDays(75))));
  }

  private ResultActions generatePlan(AuthTokens tokens, String requestId) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": false,
              "reason_code": "initial_backplan"
            }
            """));
  }

  private void expectRuntimeDisabledGet(AuthTokens tokens, String path, String reasonCode) throws Exception {
    mvc.perform(get(path)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("GOAL_AUTOPILOT_RUNTIME_DISABLED"))
        .andExpect(jsonPath("$.error.details.reason_code").value(reasonCode));
  }

  private int countRows(String tableName, UUID userId) {
    return jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?", Integer.class, userId);
  }

  private int blockedAuditCount(UUID userId) {
    return jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM audit_logs WHERE actor_id = ? AND event_type = 'goal_autopilot_runtime_blocked'",
        Integer.class,
        userId.toString());
  }
}
