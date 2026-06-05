package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.common.ApiException;
import com.speakeasy.goal.GoalAutopilotService;
import com.speakeasy.goal.MasteryTransitionPolicy;
import com.speakeasy.goal.NotificationOutboxService;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.ops.AccountDeletionService;
import java.time.Instant;
import java.time.LocalDate;
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
class GoalAutopilotControllerTest extends BackendIntegrationTestSupport {
  @Autowired JdbcTemplate jdbcTemplate;
  @Autowired GoalAutopilotService goalAutopilotService;
  @Autowired NotificationOutboxService notificationOutboxService;
  @Autowired AccountDeletionService accountDeletionService;

  @Test
  void tcP02Diag001CreatesGoalDiagnosticAndClaimGuardSourceOfTruth() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140201");

    createSupportedGoal(tokens)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.goal_profile.goal_type").value("ielts_speaking"))
        .andExpect(jsonPath("$.goal_profile.support_status").value("supported"))
        .andExpect(jsonPath("$.goal_profile.revision").value(1))
        .andExpect(jsonPath("$.support_decision.support_status").value("supported"))
        .andExpect(jsonPath("$.diagnostic.status").value("complete"))
        .andExpect(jsonPath("$.diagnostic.confidence_band").value("high"))
        .andExpect(jsonPath("$.diagnostic.rubric_scores", hasSize(4)))
        .andExpect(jsonPath("$.diagnostic.weakness_tags[0].tag").value("limited_extension"))
        .andExpect(jsonPath("$.diagnostic.claim_guard.official_score_equivalence").value(false))
        .andExpect(jsonPath("$.diagnostic.claim_guard.goal_completion_claim_allowed").value(false))
        .andExpect(jsonPath("$.forecast.eta_date", not(blankOrNullString())));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_mastery_initial_states WHERE source = 'initial_from_diagnostic'",
        Integer.class)).isEqualTo(4);

    mvc.perform(get("/goal-autopilot/summary")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.goal_type").value("ielts_speaking"))
        .andExpect(jsonPath("$.daily_plan").doesNotExist())
        .andExpect(jsonPath("$.next_action").doesNotExist());
  }

  @Test
  void tcP02Fuc001ForecastHardeningClaimGuard() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140290");

    createSupportedGoal(tokens)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.forecast.source_goal_revision").value(1))
        .andExpect(jsonPath("$.forecast.forecast_state").value("ready"))
        .andExpect(jsonPath("$.forecast.eta_range.start_date", not(blankOrNullString())))
        .andExpect(jsonPath("$.forecast.eta_range.end_date", not(blankOrNullString())))
        .andExpect(jsonPath("$.forecast.risk_reason_code").value("checkpoint_evidence_missing"))
        .andExpect(jsonPath("$.forecast.explanation.key").value("checkpoint_evidence_missing"))
        .andExpect(jsonPath("$.forecast.explanation.source").value("deterministic_policy"))
        .andExpect(jsonPath("$.forecast.explanation.fallback_reason").value("deterministic_no_provider_path"))
        .andExpect(jsonPath("$.forecast.explanation.candidate_only").value(true))
        .andExpect(jsonPath("$.forecast.claim_guard.official_score_equivalence").value(false))
        .andExpect(jsonPath("$.forecast.claim_guard.goal_completion_claim_allowed").value(false))
        .andExpect(jsonPath("$.forecast.updated_at", not(blankOrNullString())));

    mvc.perform(get("/goal-autopilot/forecast")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.forecast.forecast_state").value("ready"))
        .andExpect(jsonPath("$.forecast.risk_reason_code").value("checkpoint_evidence_missing"))
        .andExpect(jsonPath("$.forecast.explanation.source").value("deterministic_policy"));
  }

  @Test
  void tcP02Diag002RejectsInvalidGoalInputsAndMissingActiveGoal() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140206");

    mvc.perform(get("/goal-autopilot/summary")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));

    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": " ",
          "target_score": 8,
          "deadline": "%s",
          "daily_minutes": 30,
          "intensity_preference": "standard"
        }
        """.formatted(LocalDate.now().plusDays(75)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": "ielts_speaking",
          "target_score": 8,
          "deadline": "%s",
          "daily_minutes": 30,
          "intensity_preference": "standard"
        }
        """.formatted(LocalDate.now().minusDays(1)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": "ielts_speaking",
          "target_score": 8,
          "deadline": "%s",
          "intensity_preference": "standard"
        }
        """.formatted(LocalDate.now().plusDays(75)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": "ielts_speaking",
          "target_score": 8,
          "deadline": "%s",
          "daily_minutes": 30,
          "intensity_preference": "extreme"
        }
        """.formatted(LocalDate.now().plusDays(75)))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": "medical_board_exam_speaking",
          "target_ability": "pass a specialized medical board role play",
          "deadline": "%s",
          "daily_minutes": 30,
          "intensity_preference": "standard"
        }
        """.formatted(LocalDate.now().plusDays(75)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.support_status").value("unsupported"))
        .andExpect(jsonPath("$.support_decision.reason_code").value("goal_type_not_supported"));

    mvc.perform(get("/goal-autopilot/summary")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.support_decision.reason_code").value("goal_type_not_supported"))
        .andExpect(jsonPath("$.support_decision.rubric_available").value(false));
  }

  @Test
  void tcP02Diag003ServiceCoversGoalBoundaryAndLowConfidenceBranches() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140210");
    UUID userId = UUID.fromString(tokens.userId());

    assertThatThrownBy(() -> goalAutopilotService.createGoal(userId, new GoalAutopilotService.GoalInput(
        " ",
        8.0,
        "IELTS target",
        LocalDate.now().plusDays(75),
        30,
        "standard",
        List.of(),
        null,
        null,
        false), "req_service_blank_goal"))
        .isInstanceOf(ApiException.class);
    assertThatThrownBy(() -> goalAutopilotService.createGoal(userId, new GoalAutopilotService.GoalInput(
        "ielts_speaking",
        8.0,
        "IELTS target",
        null,
        30,
        "standard",
        List.of(),
        null,
        null,
        false), "req_service_null_deadline"))
        .isInstanceOf(ApiException.class);
    assertThatThrownBy(() -> goalAutopilotService.createGoal(userId, new GoalAutopilotService.GoalInput(
        "ielts_speaking",
        8.0,
        "IELTS target",
        LocalDate.now().plusDays(75),
        null,
        "standard",
        List.of(),
        null,
        null,
        false), "req_service_null_minutes"))
        .isInstanceOf(ApiException.class);
    assertThatThrownBy(() -> goalAutopilotService.createGoal(userId, new GoalAutopilotService.GoalInput(
        "ielts_speaking",
        8.0,
        "IELTS target",
        LocalDate.now().plusDays(75),
        241,
        "standard",
        List.of(),
        null,
        null,
        false), "req_service_large_minutes"))
        .isInstanceOf(ApiException.class);
    assertThatThrownBy(() -> goalAutopilotService.createGoal(userId, new GoalAutopilotService.GoalInput(
        "ielts_speaking",
        8.0,
        "IELTS target",
        LocalDate.now().plusDays(75),
        30,
        "extreme",
        List.of(),
        null,
        null,
        false), "req_service_bad_intensity"))
        .isInstanceOf(ApiException.class);

    var toeflOutOfRange = goalAutopilotService.createGoal(userId, new GoalAutopilotService.GoalInput(
        "toefl_speaking",
        35.0,
        null,
        LocalDate.now().plusDays(75),
        30,
        "standard",
        null,
        null,
        null,
        false), "req_service_toefl_out");
    assertThat(toeflOutOfRange.goalProfile().supportStatus()).isEqualTo("unsupported");
    assertThat(toeflOutOfRange.supportDecision().reasonCode()).isEqualTo("target_score_out_of_supported_range");

    var supportedLowConfidence = goalAutopilotService.createGoal(userId, new GoalAutopilotService.GoalInput(
        "toefl_speaking",
        26.0,
        null,
        LocalDate.now().plusDays(75),
        30,
        "standard",
        null,
        null,
        null,
        false), "req_service_toefl_supported");
    assertThat(supportedLowConfidence.goalProfile().supportStatus()).isEqualTo("supported");
    assertThat(supportedLowConfidence.diagnostic().confidenceBand()).isEqualTo("low");

    var lowConfidencePlan = goalAutopilotService.generatePlan(userId, false, null, "req_service_low_plan");
    assertThat(lowConfidencePlan.weeklyBackplan().milestone())
        .isEqualTo("collect more reliable diagnostic evidence and stabilize basic retrieval");
    assertThat(lowConfidencePlan.dailyPlan().status()).isEqualTo("partial");
  }

  @Test
  void tcP02PlanAndAuto001GeneratesMemoryPlanAndNoChoiceNextAction() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140202");
    createSupportedGoal(tokens).andExpect(status().isOk());

    MvcResult planResult = generatePlan(tokens, false, "initial_backplan")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.weekly_backplan.status").value("active"))
        .andExpect(jsonPath("$.daily_plan.status").value("ready"))
        .andExpect(jsonPath("$.daily_plan.items", hasSize(2)))
        .andExpect(jsonPath("$.daily_plan.memory_policy.policy_version").value("memory-curve-v1"))
        .andExpect(jsonPath("$.daily_plan.memory_policy.interleaving_rule").value("rotate_fluency_pronunciation_scenario_fit"))
        .andExpect(jsonPath("$.next_action.action_type").value("start_training"))
        .andExpect(jsonPath("$.next_action.reason_code").value("highest_weakness_and_memory_risk"))
        .andReturn();
    String firstPlanItemId = JsonPath.read(planResult.getResponse().getContentAsString(), "$.daily_plan.items[0].plan_item_id");

    mvc.perform(get("/goal-autopilot/actions/next")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.action.plan_item_id").value(firstPlanItemId))
        .andExpect(jsonPath("$.forecast.claim_guard.official_score_equivalence").value(false));

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(firstPlanItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_action_complete")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "completed",
                  "evidence_ref": "training_session_sample"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.action.action_type").value("review_due"))
        .andExpect(jsonPath("$.plan_update_signal.signal_type").value("none"));

    String secondPlanItemId = JsonPath.read(planResult.getResponse().getContentAsString(), "$.daily_plan.items[1].plan_item_id");
    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(secondPlanItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_action_complete_second")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "completed",
                  "evidence_ref": "review_session_sample"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.action.status").value("completed"));

    mvc.perform(get("/goal-autopilot/actions/next")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("CONFLICT"));
  }

  @Test
  void tcP02Fub001ControlIsServerOwnedAndSeparatesPolicyFromGoalProfile() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140220");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens).andExpect(status().isOk());

    mvc.perform(get("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.control.user_id").value(userId.toString()))
        .andExpect(jsonPath("$.control.control_status").value("blocked_by_policy"))
        .andExpect(jsonPath("$.control.quiet_hours_start").value("22:00"))
        .andExpect(jsonPath("$.control.timezone").value("Asia/Shanghai"))
        .andExpect(jsonPath("$.reason_code").value("missing_plan"))
        .andExpect(jsonPath("$.reminder_eligibility.eligible").value(false))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("missing_plan"));

    assertThat(count("goal_autopilot_controls", userId)).isEqualTo(1);

    generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk());

    mvc.perform(get("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.reason_code").value("eligible"))
        .andExpect(jsonPath("$.reminder_eligibility.eligible").value(true))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("eligible"));

    String updateBody = """
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
    MvcResult updateResult = mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "control-update-001")
            .header("X-Request-Id", "req_fub_control_update")
            .contentType(MediaType.APPLICATION_JSON)
            .content(updateBody))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.control.quiet_hours_start").value("21:30"))
        .andExpect(jsonPath("$.control.missed_day_policy").value("defer"))
        .andExpect(jsonPath("$.reason_code").value("control_updated"))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("consent_missing"))
        .andReturn();
    String updateResponse = updateResult.getResponse().getContentAsString();
    String updateControlUpdatedAt = JsonPath.read(updateResponse, "$.control.updated_at");
    String updateEligibilityEvaluatedAt = JsonPath.read(updateResponse, "$.reminder_eligibility.evaluated_at");

    mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "control-update-001")
            .header("X-Request-Id", "req_fub_control_update_replay")
            .contentType(MediaType.APPLICATION_JSON)
            .content(updateBody))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.updated_at").value(updateControlUpdatedAt))
        .andExpect(jsonPath("$.reminder_eligibility.evaluated_at").value(updateEligibilityEvaluatedAt));

    mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "control-update-001")
            .header("X-Request-Id", "req_fub_control_update_conflict")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "quiet_hours_start": "21:45",
                  "quiet_hours_end": "07:15",
                  "timezone": "Asia/Shanghai",
                  "notification_consent": false,
                  "intensity_override": "gentle",
                  "missed_day_policy": "defer"
                }
                """))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("IDEMPOTENCY_CONFLICT"));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT quiet_hours_start FROM goal_profiles WHERE user_id = ?", String.class, userId)).isEqualTo("22:00");
    assertThat(jdbcTemplate.queryForObject(
        "SELECT quiet_hours_start FROM goal_autopilot_controls WHERE user_id = ?", String.class, userId)).isEqualTo("21:30");
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM audit_logs WHERE actor_type = 'user' AND actor_id = ? AND event_type = 'goal_autopilot_control_updated'",
        Integer.class,
        userId.toString())).isEqualTo(1);
    assertThat(count("goal_autopilot_control_idempotency", userId)).isEqualTo(1);

    createSupportedGoal(tokens)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.revision").value(2));

    mvc.perform(get("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("blocked_by_policy"))
        .andExpect(jsonPath("$.control.quiet_hours_start").value("21:30"))
        .andExpect(jsonPath("$.control.notification_consent").value(false))
        .andExpect(jsonPath("$.control.intensity_override").value("gentle"))
        .andExpect(jsonPath("$.control.missed_day_policy").value("defer"))
        .andExpect(jsonPath("$.reason_code").value("stale_plan"))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("stale_plan"));
  }

  @Test
  void tcP02Fub002ControlDataGovernanceAndValidationAreServerSide() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140221");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens).andExpect(status().isOk());

    mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "invalid-control-002")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "quiet_hours_start": "25:00",
                  "timezone": "not/a-zone",
                  "missed_day_policy": "stack_everything"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "valid-control-002")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "notification_consent": false
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.notification_consent").value(false));

    assertThat(count("goal_autopilot_controls", userId)).isEqualTo(1);
    assertThat(count("goal_autopilot_control_idempotency", userId)).isEqualTo(1);
    assertThat(jdbcTemplate.queryForObject(
        "SELECT redacted_details FROM audit_logs WHERE actor_id = ? AND event_type = 'goal_autopilot_control_updated'",
        String.class,
        userId.toString()))
        .contains("\"data\":\"redacted\"")
        .doesNotContain("valid-control-002");

    var governanceExport = goalAutopilotService.exportControlDataGovernance(userId);
    assertThat(governanceExport.exportFamily()).isEqualTo("goal_autopilot_control");
    assertThat(governanceExport.ruleVersion()).isEqualTo("fub-control-v1");
    assertThat(governanceExport.controls()).hasSize(1);
    assertThat(governanceExport.controls().get(0).userId()).isEqualTo(userId);
    assertThat(governanceExport.controls().get(0).pauseReason()).isNull();
    assertThat(governanceExport.controls().get(0).notificationConsent()).isFalse();
    assertThat(governanceExport.controls().get(0).ruleVersion()).isEqualTo("fub-control-v1");
    assertThat(governanceExport.controls().get(0).createdAt()).isNotNull();
    assertThat(governanceExport.controls().get(0).updatedAt()).isNotNull();
    assertThat(governanceExport.idempotencyRecords()).hasSize(1);
    assertThat(governanceExport.idempotencyRecords().get(0).operation()).isEqualTo("update");
    assertThat(governanceExport.idempotencyRecords().get(0).requestHash()).hasSize(64);
    assertThat(governanceExport.idempotencyRecords().get(0).idempotencyKeyRedacted()).isTrue();
    assertThat(governanceExport.idempotencyRecords().get(0).responseJsonRedacted()).isTrue();
    assertThat(governanceExport.retentionRules())
        .extracting(rule -> rule.dataClass() + ":" + rule.action())
        .contains(
            "goal_autopilot_controls:hard_delete_on_account_deletion",
            "goal_autopilot_control_idempotency:hard_delete_on_account_deletion",
            "goal_notification_outbox_records:hard_delete_on_account_deletion",
            "goal_planner_replay_audits:hard_delete_on_account_deletion",
            "goal_recovery_plan_decisions:hard_delete_on_account_deletion",
            "goal_mastery_transition_decisions:hard_delete_on_account_deletion",
            "audit_logs:retain_redacted_minimal_audit");
    assertThat(governanceExport.deletionTables())
        .contains(
            "goal_autopilot_controls",
            "goal_autopilot_control_idempotency",
            "goal_notification_outbox_records",
            "goal_planner_replay_audits",
            "goal_recovery_plan_decisions",
            "goal_mastery_transition_decisions");
    assertThat(governanceExport.redactedAuditOnly()).isTrue();
    assertThat(governanceExport.notificationOutboxStatus()).isEqualTo("implemented_through_s005_mastery");

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-fub-control")
            .header("X-Request-Id", "req_delete_fub_control"))
        .andExpect(status().isAccepted());

    assertThat(count("goal_autopilot_controls", userId)).isZero();
    assertThat(count("goal_autopilot_control_idempotency", userId)).isZero();
  }

  @Test
  void tcP02Fub003PauseResumeIsIdempotentAndSuppressesNextAction() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140222");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens).andExpect(status().isOk());
    generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk());

    String pauseBody = """
        {
          "schema_version": 1,
          "pause_reason": "user_requested_break"
        }
        """;
    MvcResult pauseResult = mvc.perform(post("/goal-autopilot/control/pause")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "pause-fub-control")
            .header("X-Request-Id", "req_fub_pause")
            .contentType(MediaType.APPLICATION_JSON)
            .content(pauseBody))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("paused"))
        .andExpect(jsonPath("$.control.paused_at", not(blankOrNullString())))
        .andExpect(jsonPath("$.reason_code").value("paused"))
        .andExpect(jsonPath("$.reminder_eligibility.eligible").value(false))
        .andExpect(jsonPath("$.reminder_eligibility.reason_code").value("paused"))
        .andReturn();
    String pauseResponse = pauseResult.getResponse().getContentAsString();
    String pausedAt = JsonPath.read(pauseResponse, "$.control.paused_at");
    String pauseEligibilityEvaluatedAt = JsonPath.read(pauseResponse, "$.reminder_eligibility.evaluated_at");

    mvc.perform(post("/goal-autopilot/control/pause")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "pause-fub-control")
            .header("X-Request-Id", "req_fub_pause_repeat")
            .contentType(MediaType.APPLICATION_JSON)
            .content(pauseBody))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("paused"))
        .andExpect(jsonPath("$.control.paused_at").value(pausedAt))
        .andExpect(jsonPath("$.reminder_eligibility.evaluated_at").value(pauseEligibilityEvaluatedAt));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM audit_logs WHERE actor_type = 'user' AND actor_id = ? AND event_type = 'goal_autopilot_control_paused'",
        Integer.class,
        userId.toString())).isEqualTo(1);

    mvc.perform(get("/goal-autopilot/actions/next")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("CONFLICT"))
        .andExpect(jsonPath("$.error.details.reason_code").value("paused"));

    String resumeBody = """
        {
          "schema_version": 1,
          "source_event": "manual_resume"
        }
        """;
    MvcResult resumeResult = mvc.perform(post("/goal-autopilot/control/resume")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "resume-fub-control")
            .header("X-Request-Id", "req_fub_resume")
            .contentType(MediaType.APPLICATION_JSON)
            .content(resumeBody))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.control.paused_at").doesNotExist())
        .andExpect(jsonPath("$.plan_update_signal.reason_code").value("no_replan_needed"))
        .andReturn();
    String resumeResponse = resumeResult.getResponse().getContentAsString();
    String resumedAt = JsonPath.read(resumeResponse, "$.control.resumed_at");
    String resumeEligibilityEvaluatedAt = JsonPath.read(resumeResponse, "$.reminder_eligibility.evaluated_at");

    mvc.perform(post("/goal-autopilot/control/resume")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "resume-fub-control")
            .header("X-Request-Id", "req_fub_resume_repeat")
            .contentType(MediaType.APPLICATION_JSON)
            .content(resumeBody))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.control.resumed_at").value(resumedAt))
        .andExpect(jsonPath("$.reminder_eligibility.evaluated_at").value(resumeEligibilityEvaluatedAt));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM audit_logs WHERE actor_type = 'user' AND actor_id = ? AND event_type = 'goal_autopilot_control_resumed'",
        Integer.class,
        userId.toString())).isEqualTo(1);
    assertThat(count("goal_autopilot_control_idempotency", userId)).isEqualTo(2);

    mvc.perform(post("/goal-autopilot/control/resume")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "resume-fub-control-active")
            .header("X-Request-Id", "req_fub_resume_active")
            .contentType(MediaType.APPLICATION_JSON)
            .content(resumeBody))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.control.control_status").value("active"))
        .andExpect(jsonPath("$.control.resumed_at").value(resumedAt));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM audit_logs WHERE actor_type = 'user' AND actor_id = ? AND event_type = 'goal_autopilot_control_resumed'",
        Integer.class,
        userId.toString())).isEqualTo(1);
    assertThat(count("goal_autopilot_control_idempotency", userId)).isEqualTo(3);

    mvc.perform(get("/goal-autopilot/actions/next")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.action.status").value("ready"));
  }

  @Test
  void tcP02Fub007OutboxAndReplayApisExposeRedactedProjection() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140224");
    UUID userId = UUID.fromString(tokens.userId());
    MvcResult goalResult = createSupportedGoal(tokens).andExpect(status().isOk()).andReturn();
    String goalBody = goalResult.getResponse().getContentAsString();
    UUID goalProfileId = UUID.fromString(JsonPath.read(goalBody, "$.goal_profile.goal_profile_id"));
    int goalRevision = JsonPath.read(goalBody, "$.goal_profile.revision");

    MvcResult planResult = generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk()).andReturn();
    UUID planItemId = UUID.fromString(JsonPath.read(
        planResult.getResponse().getContentAsString(),
        "$.daily_plan.items[0].plan_item_id"));
    notificationOutboxService.scheduleOrUpdate(new NotificationOutboxService.ScheduleReminderCommand(
        userId,
        goalProfileId,
        goalRevision,
        planItemId,
        "evening_review",
        true,
        "eligible",
        null,
        "reminder_allowed",
        Instant.parse("2026-06-05T01:30:00Z"),
        "fub-reminder-v1"));

    MvcResult outboxResult = mvc.perform(get("/goal-autopilot/reminders/outbox")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.records", hasSize(1)))
        .andExpect(jsonPath("$.records[0].lifecycle_status").value("pending"))
        .andExpect(jsonPath("$.records[0].dedupe_key").value(
            userId + ":" + goalRevision + ":" + planItemId + ":evening_review:fub-reminder-v1"))
        .andExpect(jsonPath("$.records[0].input_snapshot_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.records[0].payload_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.records[0].failure_reason").doesNotExist())
        .andReturn();
    assertThat(outboxResult.getResponse().getContentAsString()).doesNotContain("reminder_allowed");

    mvc.perform(get("/goal-autopilot/replay-audits")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.audits", hasSize(1)))
        .andExpect(jsonPath("$.audits[0].decision_family").value("notification_outbox"))
        .andExpect(jsonPath("$.audits[0].expected_decision").value("pending"))
        .andExpect(jsonPath("$.audits[0].input_snapshot_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.audits[0].output_snapshot_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.audits[0].replay_hash").value(startsWith("sha256:")));
  }

  @Test
  void tcP02Plan002PartialGoalForceReplanAndRevisionStaleExistingPlans() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140207");

    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": "business_meeting",
          "target_ability": "",
          "deadline": "%s",
          "daily_minutes": 10,
          "intensity_preference": "gentle",
          "diagnostic_samples": [
            {
              "sample_ref": "sample_1",
              "transcript": "I can introduce an update but need help answering follow up questions.",
              "duration_seconds": 30
            }
          ]
        }
        """.formatted(LocalDate.now().plusDays(14)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.support_status").value("partial"))
        .andExpect(jsonPath("$.diagnostic.confidence_band").value("medium"))
        .andExpect(jsonPath("$.forecast.eta_date").doesNotExist());

    generatePlan(tokens, false, "partial_backplan")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.weekly_backplan.status").value("partial"))
        .andExpect(jsonPath("$.daily_plan.status").value("partial"))
        .andExpect(jsonPath("$.daily_plan.total_minutes").value(10))
        .andExpect(jsonPath("$.daily_plan.items[0].pressure_level").value("low"))
        .andExpect(jsonPath("$.daily_plan.memory_policy.forgetting_risk").value("high"));

    generatePlan(tokens, true, "manual_replan")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.weekly_backplan.status").value("partial"));

    createSupportedGoal(tokens)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.revision").value(2))
        .andExpect(jsonPath("$.goal_profile.support_status").value("supported"));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_backplans WHERE status = 'stale' AND stale_reason IN ('manual_replan','goal_revision_changed')",
        Integer.class)).isGreaterThan(0);
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_daily_plans WHERE status = 'stale'",
        Integer.class)).isGreaterThan(0);
  }

  @Test
  void tcP02Policy001UnsupportedGoalFailsClosedWithoutFullPlanOrEta() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140203");

    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": "ielts_speaking",
          "target_score": 11,
          "deadline": "%s",
          "daily_minutes": 30,
          "intensity_preference": "standard"
        }
        """.formatted(LocalDate.now().plusDays(60)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.support_status").value("unsupported"))
        .andExpect(jsonPath("$.diagnostic.status").value("unsupported"))
        .andExpect(jsonPath("$.forecast.eta_date").doesNotExist())
        .andExpect(jsonPath("$.forecast.claim_guard.official_score_equivalence").value(false));

    generatePlan(tokens, false, "unsupported_should_fail")
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("CONFLICT"));
  }

  @Test
  void tcP02Auto002CoversNoPlanInvalidOutcomeSkipDeferAndLowConfidenceCheckpoint() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140208");
    createSupportedGoal(tokens).andExpect(status().isOk());

    mvc.perform(get("/goal-autopilot/actions/next")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));

    MvcResult planResult = generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk()).andReturn();
    String firstPlanItemId = JsonPath.read(planResult.getResponse().getContentAsString(), "$.daily_plan.items[0].plan_item_id");
    String secondPlanItemId = JsonPath.read(planResult.getResponse().getContentAsString(), "$.daily_plan.items[1].plan_item_id");

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(firstPlanItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "abandoned"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(firstPlanItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_action_skip")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "skipped"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.plan_update_signal.signal_type").value("recovery_replan"))
        .andExpect(jsonPath("$.forecast.risk_reason").value("missed or deferred work requires recovery planning"));

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(secondPlanItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_action_defer")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "deferred"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.plan_update_signal.reason_code").value("learner_deferred"));

    mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "surprise_exam",
                  "transcript": "short"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_checkpoint_low")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "biweekly_mock",
                  "transcript": "short"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint.cadence").value("biweekly"))
        .andExpect(jsonPath("$.checkpoint.result_status").value("low_confidence"))
        .andExpect(jsonPath("$.forecast.confidence_band").value("low"));
  }

  @Test
  void tcP02Auto003MediumDiagnosticCheckpointKeepsMediumForecastConfidence() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140211");
    createGoal(tokens, """
        {
          "schema_version": 1,
          "goal_type": "job_interview",
          "target_ability": "answer behavioral questions with clear examples",
          "deadline": "%s",
          "daily_minutes": 30,
          "intensity_preference": "standard",
          "diagnostic_samples": [
            {
              "sample_ref": "sample_1",
              "transcript": "I can answer familiar interview questions but need stronger STAR examples.",
              "duration_seconds": 30
            }
          ]
        }
        """.formatted(LocalDate.now().plusDays(75)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.diagnostic.confidence_band").value("medium"));

    generatePlan(tokens, false, "job_interview_plan").andExpect(status().isOk());

    mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_checkpoint_medium")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "business_task",
                  "transcript": "I described the context, the action I took, the result, and a concrete metric. I still need to make the answer more concise, but the structure is much clearer than before and I can handle one follow up question without losing the thread."
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint.confidence_band").value("medium"))
        .andExpect(jsonPath("$.forecast.confidence_band").value("medium"));
  }

  @Test
  void tcP02AutoCheckpoint001CheckpointUpdatesForecastAndStalesPlan() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140204");
    createSupportedGoal(tokens).andExpect(status().isOk());
    generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk());

    mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_checkpoint")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "weekly_mock",
                  "transcript": "I spoke for two minutes, gave a concrete project example, answered one follow-up question, and noticed I still paused before extending the second example.",
                  "score_hint": 6.5
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint.result_status").value("recorded"))
        .andExpect(jsonPath("$.plan_update_signal.signal_type").value("checkpoint_replan"))
        .andExpect(jsonPath("$.forecast.forecast_state").value("stale_plan"))
        .andExpect(jsonPath("$.forecast.eta_date").doesNotExist())
        .andExpect(jsonPath("$.forecast.eta_range").doesNotExist())
        .andExpect(jsonPath("$.forecast.eta_unavailable_reason").value("stale_plan"))
        .andExpect(jsonPath("$.forecast.risk_reason_code").value("stale_plan"))
        .andExpect(jsonPath("$.forecast.risk_reason").value("stale plan requires replan before forecast precision"))
        .andExpect(jsonPath("$.forecast.claim_guard.official_score_equivalence").value(false));

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_backplans WHERE status = 'stale'", Integer.class)).isGreaterThan(0);
  }

  @Test
  void tcP02Fuc002CheckpointTaskLibrary() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140292");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens).andExpect(status().isOk());
    generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk());

    MvcResult notDueTask = mvc.perform(get("/goal-autopilot/checkpoints/task")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.checkpoint_task.checkpoint_state").value("CheckpointNotDue"))
        .andExpect(jsonPath("$.checkpoint_task.due_status").value("not_due"))
        .andExpect(jsonPath("$.checkpoint_task.cadence").value("weekly"))
        .andExpect(jsonPath("$.checkpoint_task.next_due_date", not(blankOrNullString())))
        .andExpect(jsonPath("$.checkpoint_task.task").doesNotExist())
        .andReturn();
    assertThat(notDueTask.getResponse().getContentAsString()).doesNotContain("\"task\":");

    jdbcTemplate.update(
        "UPDATE goal_backplans SET checkpoint_due_date = ? WHERE user_id = ?",
        java.sql.Date.valueOf(LocalDate.now().minusDays(1)),
        userId);

    mvc.perform(get("/goal-autopilot/checkpoints/task")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint_task.checkpoint_state").value("CheckpointDue"))
        .andExpect(jsonPath("$.checkpoint_task.due_status").value("overdue"))
        .andExpect(jsonPath("$.checkpoint_task.task.task_type").value("weekly_mock"))
        .andExpect(jsonPath("$.checkpoint_task.task.prompt_ref").value("checkpoint/ielts_speaking/weekly_mock"))
        .andExpect(jsonPath("$.checkpoint_task.task.required_evidence", hasSize(2)))
        .andExpect(jsonPath("$.checkpoint_task.task.scoring_boundary")
            .value("product_internal_rubric_only_no_official_score_certification"));

    AuthTokens partialTokens = loginPhone("+8613800140293");
    createGoal(partialTokens, """
        {
          "schema_version": 1,
          "goal_type": "ielts_speaking",
          "target_score": 8,
          "deadline": "%s",
          "daily_minutes": 10,
          "intensity_preference": "standard"
        }
        """.formatted(LocalDate.now().plusDays(75)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.support_status").value("partial"));

    mvc.perform(get("/goal-autopilot/checkpoints/task")
            .header(HttpHeaders.AUTHORIZATION, bearer(partialTokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint_task.checkpoint_state").value("CheckpointLimited"))
        .andExpect(jsonPath("$.checkpoint_task.cadence").value("biweekly"))
        .andExpect(jsonPath("$.checkpoint_task.limitation_reason").value("partial_goal_limited"))
        .andExpect(jsonPath("$.checkpoint_task.task.task_type").value("biweekly_mock"))
        .andExpect(jsonPath("$.checkpoint_task.task.ai_depth").value("deterministic_low_cost"));

    AuthTokens unsupportedTokens = loginPhone("+8613800140294");
    createGoal(unsupportedTokens, """
        {
          "schema_version": 1,
          "goal_type": "medical_board_exam_speaking",
          "target_ability": "pass a specialized medical board role play",
          "deadline": "%s",
          "daily_minutes": 30,
          "intensity_preference": "standard"
        }
        """.formatted(LocalDate.now().plusDays(75)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.support_status").value("unsupported"));

    MvcResult unsupportedTask = mvc.perform(get("/goal-autopilot/checkpoints/task")
            .header(HttpHeaders.AUTHORIZATION, bearer(unsupportedTokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint_task.checkpoint_state").value("CheckpointUnavailable"))
        .andExpect(jsonPath("$.checkpoint_task.due_status").value("unavailable"))
        .andExpect(jsonPath("$.checkpoint_task.limitation_reason").value("unsupported_goal"))
        .andExpect(jsonPath("$.checkpoint_task.task").doesNotExist())
        .andReturn();
    assertThat(unsupportedTask.getResponse().getContentAsString()).doesNotContain("\"task\":");
  }

  @Test
  void tcP02Fub013MasteryTransitionAuditIsReadOnlyAndReplayable() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140250");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens).andExpect(status().isOk());
    MvcResult planResult = generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk()).andReturn();
    UUID planItemId = UUID.fromString(JsonPath.read(
        planResult.getResponse().getContentAsString(),
        "$.daily_plan.items[0].plan_item_id"));

    completePlanItem(tokens, planItemId, "completed")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.action.status").value("ready"))
        .andExpect(jsonPath("$.forecast.claim_guard.official_score_equivalence").value(false));

    mvc.perform(get("/goal-autopilot/mastery-transitions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.transitions", hasSize(1)))
        .andExpect(jsonPath("$.transitions[0].user_id").value(userId.toString()))
        .andExpect(jsonPath("$.transitions[0].memory_item_state_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.transitions[0].direction").value("promote"))
        .andExpect(jsonPath("$.transitions[0].reason_code").value("evidence_promotion_confident_retrieval"))
        .andExpect(jsonPath("$.transitions[0].rule_version").value(MasteryTransitionPolicy.RULE_VERSION))
        .andExpect(jsonPath("$.transitions[0].evidence_refs", hasSize(3)));

    mvc.perform(get("/goal-autopilot/replay-audits")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.audits[0].decision_family").value("mastery_transition"))
        .andExpect(jsonPath("$.audits[0].expected_decision").value("promote"))
        .andExpect(jsonPath("$.audits[0].reason_code").value("evidence_promotion_confident_retrieval"))
        .andExpect(jsonPath("$.audits[0].replay_hash", startsWith("sha256:")));

    assertThat(count("goal_mastery_transition_decisions", userId)).isEqualTo(1);
    assertThat(countReplayAudits(userId, "mastery_transition")).isEqualTo(1);

    completePlanItem(tokens, planItemId, "completed").andExpect(status().isOk());

    assertThat(count("goal_mastery_transition_decisions", userId)).isEqualTo(1);
    assertThat(countReplayAudits(userId, "mastery_transition")).isEqualTo(1);
  }

  @Test
  void tcP02Data001AccountDeletionPurgesGoalAutopilotFacts() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140205");
    UUID userId = UUID.fromString(tokens.userId());
    MvcResult goalResult = createSupportedGoal(tokens).andExpect(status().isOk()).andReturn();
    String goalBody = goalResult.getResponse().getContentAsString();
    UUID goalProfileId = UUID.fromString(JsonPath.read(goalBody, "$.goal_profile.goal_profile_id"));
    int goalRevision = JsonPath.read(goalBody, "$.goal_profile.revision");
    MvcResult planResult = generatePlan(tokens, false, "initial_backplan").andExpect(status().isOk()).andReturn();
    UUID planItemId = UUID.fromString(JsonPath.read(
        planResult.getResponse().getContentAsString(),
        "$.daily_plan.items[0].plan_item_id"));
    notificationOutboxService.scheduleOrUpdate(new NotificationOutboxService.ScheduleReminderCommand(
        userId,
        goalProfileId,
        goalRevision,
        planItemId,
        "deletion_review",
        true,
        "eligible",
        null,
        "reminder_allowed",
        Instant.parse("2026-06-05T01:45:00Z"),
        "fub-reminder-v1"));
    completePlanItem(tokens, planItemId, "completed").andExpect(status().isOk());

    assertThat(count("goal_profiles", userId)).isEqualTo(1);
    assertThat(count("goal_autopilot_controls", userId)).isEqualTo(1);
    assertThat(count("goal_plan_items", userId)).isGreaterThan(0);
    assertThat(count("goal_notification_outbox_records", userId)).isEqualTo(1);
    assertThat(count("goal_mastery_transition_decisions", userId)).isEqualTo(1);
    assertThat(count("goal_planner_replay_audits", userId)).isEqualTo(2);

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-p02-001")
            .header("X-Request-Id", "req_delete_p02"))
        .andExpect(status().isAccepted());

    assertThat(count("goal_profiles", userId)).isZero();
    assertThat(count("goal_autopilot_controls", userId)).isZero();
    assertThat(count("goal_diagnostic_assessments", userId)).isZero();
    assertThat(count("goal_mastery_initial_states", userId)).isZero();
    assertThat(count("goal_backplans", userId)).isZero();
    assertThat(count("goal_daily_plans", userId)).isZero();
    assertThat(count("goal_plan_items", userId)).isZero();
    assertThat(count("goal_notification_outbox_records", userId)).isZero();
    assertThat(count("goal_mastery_transition_decisions", userId)).isZero();
    assertThat(count("goal_planner_replay_audits", userId)).isZero();
    assertThat(count("goal_progress_forecasts", userId)).isZero();
  }

  @Test
  void tcP02Data002AccountDeletionRejectsInvalidKeyAndReplaysIdempotently() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140209");
    createSupportedGoal(tokens).andExpect(status().isOk());

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "short")
            .header("X-Request-Id", "req_delete_short"))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-p02-replay")
            .header("X-Request-Id", "req_delete_replay_1"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.status").value("completed"));

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-p02-replay")
            .header("X-Request-Id", "req_delete_replay_2"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.status").value("completed"));

    assertThat(deletionJobs.findByUserIdAndIdempotencyKey(UUID.fromString(tokens.userId()), "delete-p02-replay")).isPresent();
  }

  @Test
  void tcP02Data003DeletionServiceCoversRequestedAndDeletedAccountBranches() {
    Instant now = Instant.now();
    UUID requestedUserId = UUID.randomUUID();
    UserAccount requestedUser = users.save(new UserAccount(requestedUserId, "Requested User", now));
    requestedUser.requestDeletion(now);
    users.save(requestedUser);

    assertThat(accountDeletionService.requestDeletion(
            requestedUserId, "delete-service-requested", "req_delete_service_requested").getStatus())
        .isEqualTo("completed");

    assertThatThrownBy(() -> accountDeletionService.requestDeletion(
            UUID.randomUUID(), "delete-service-missing", "req_delete_service_missing"))
        .isInstanceOf(ApiException.class);

    UUID deletedUserId = UUID.randomUUID();
    UserAccount deletedUser = users.save(new UserAccount(deletedUserId, "Deleted User", now));
    deletedUser.markDeleted(now);
    users.save(deletedUser);

    assertThatThrownBy(() -> accountDeletionService.requestDeletion(
            deletedUserId, "delete-service-deleted", "req_delete_service_deleted"))
        .isInstanceOf(ApiException.class);

    assertThatThrownBy(() -> accountDeletionService.requestDeletion(
            deletedUserId, null, "req_delete_service_null_key"))
        .isInstanceOf(ApiException.class);
    assertThatThrownBy(() -> accountDeletionService.requestDeletion(
            deletedUserId, "x".repeat(129), "req_delete_service_long_key"))
        .isInstanceOf(ApiException.class);
  }

  private org.springframework.test.web.servlet.ResultActions createSupportedGoal(AuthTokens tokens) throws Exception {
    return createGoal(tokens, """
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
        """.formatted(LocalDate.now().plusDays(75)));
  }

  private org.springframework.test.web.servlet.ResultActions createGoal(AuthTokens tokens, String body) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_p02_goal")
        .contentType(MediaType.APPLICATION_JSON)
        .content(body));
  }

  private org.springframework.test.web.servlet.ResultActions generatePlan(
      AuthTokens tokens, boolean forceReplan, String reasonCode) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_p02_plan")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": %s,
              "reason_code": "%s"
            }
            """.formatted(forceReplan, reasonCode)));
  }

  private org.springframework.test.web.servlet.ResultActions completePlanItem(
      AuthTokens tokens, UUID planItemId, String outcome) throws Exception {
    return mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(planItemId))
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_p02_complete_" + outcome)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "outcome": "%s",
              "evidence_ref": "training-turn-s005",
              "learner_note": ""
            }
            """.formatted(outcome)));
  }

  private int count(String tableName, UUID userId) {
    return jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?", Integer.class, userId);
  }

  private int countReplayAudits(UUID userId, String decisionFamily) {
    return jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_planner_replay_audits WHERE user_id = ? AND decision_family = ?",
        Integer.class,
        userId,
        decisionFamily);
  }
}
