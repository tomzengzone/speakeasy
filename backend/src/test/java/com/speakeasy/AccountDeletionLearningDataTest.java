package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
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
class AccountDeletionLearningDataTest extends BackendIntegrationTestSupport {
  @Autowired JdbcTemplate jdbcTemplate;

  @Test
  void deletionPurgesProductBaseLearningDataAndWritesAuditEvidence() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138390");
    UUID userId = UUID.fromString(tokens.userId());
    completeOnboarding(tokens);
    MvcResult queue = mvc.perform(get("/expressions/queue").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andReturn();
    String targetExpressionId = JsonPath.read(queue.getResponse().getContentAsString(), "$.queue_items[0].target_expression_id");
    String expressionText = JsonPath.read(queue.getResponse().getContentAsString(), "$.queue_items[0].expression_text");
    favorite(tokens, targetExpressionId, expressionText);
    acceptEvidence(tokens, targetExpressionId);
    startPracticeSession(tokens);

    assertThat(count("learning_evidences", userId)).isGreaterThan(0);
    assertThat(count("favorite_expressions", userId)).isGreaterThan(0);
    assertThat(count("practice_sessions", userId)).isGreaterThan(0);
    assertThat(count("user_scenario_states", userId)).isGreaterThan(0);

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-job-035")
            .header("X-Request-Id", "req_delete_035"))
        .andExpect(status().isAccepted());

    assertThat(count("learning_evidences", userId)).isZero();
    assertThat(count("favorite_expressions", userId)).isZero();
    assertThat(count("practice_sessions", userId)).isZero();
    assertThat(count("user_scenario_states", userId)).isZero();
    assertThat(count("user_profiles", userId)).isZero();
    assertThat(jdbcTemplate.queryForObject(
        "SELECT account_status FROM user_accounts WHERE user_id = ?", String.class, userId)).isEqualTo("deleted");
    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM audit_logs WHERE event_type = 'account_deletion_completed'", Integer.class)).isGreaterThan(0);
  }

  @Test
  void tcP02Fuc006GoalProgressProjectionPurgedOnDeletion() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140417");
    UUID userId = UUID.fromString(tokens.userId());
    createGoal(tokens);
    generatePlan(tokens);
    submitCheckpoint(tokens);

    assertThat(count("goal_profiles", userId)).isEqualTo(1);
    assertThat(count("goal_daily_plans", userId)).isGreaterThan(0);
    assertThat(count("goal_progress_forecasts", userId)).isGreaterThan(0);
    assertThat(count("goal_outcome_checkpoints", userId)).isGreaterThan(0);

    mvc.perform(get("/goal-autopilot/progress-projection")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.projection.projection_state").value("stale_plan"))
        .andExpect(jsonPath("$.projection.downgrade_reason").value("stale_plan"));

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-p02-fuc006")
            .header("X-Request-Id", "req_delete_p02_fuc006"))
        .andExpect(status().isAccepted());

    assertThat(count("goal_profiles", userId)).isZero();
    assertThat(count("goal_autopilot_controls", userId)).isZero();
    assertThat(count("goal_diagnostic_assessments", userId)).isZero();
    assertThat(count("goal_backplans", userId)).isZero();
    assertThat(count("goal_daily_plans", userId)).isZero();
    assertThat(count("goal_plan_items", userId)).isZero();
    assertThat(count("goal_progress_forecasts", userId)).isZero();
    assertThat(count("goal_outcome_checkpoints", userId)).isZero();
    assertThat(count("goal_planner_replay_audits", userId)).isZero();

    mvc.perform(get("/goal-autopilot/progress-projection")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  private int count(String tableName, UUID userId) {
    return jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?", Integer.class, userId);
  }

  private void createGoal(AuthTokens tokens) throws Exception {
    mvc.perform(post("/goal-autopilot/goals")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc006_goal")
            .header("Idempotency-Key", "learning-delete-goal-" + tokens.userId())
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_type": "ielts_speaking",
                  "target_score": 8,
                  "target_ability": "sensitive target ability must be purged before projection can be read",
                  "deadline": "%s",
                  "daily_minutes": 30,
                  "intensity_preference": "standard",
                  "diagnostic_samples": [
                    {
                      "sample_ref": "sample_1",
                      "transcript": "I can answer familiar questions, but I need stronger examples and clearer transitions for follow-up pressure.",
                      "duration_seconds": 48
                    },
                    {
                      "sample_ref": "sample_2",
                      "transcript": "I can explain a simple point, but I often repeat the same words and lose structure.",
                      "duration_seconds": 46
                    },
                    {
                      "sample_ref": "sample_3",
                      "transcript": "I want to sustain a longer answer with a specific example, a result, and a clear ending.",
                      "duration_seconds": 47
                    }
                  ]
                }
                """.formatted(java.time.LocalDate.now().plusDays(75))))
        .andExpect(status().isOk());
  }

  private void generatePlan(AuthTokens tokens) throws Exception {
    mvc.perform(post("/goal-autopilot/plans/generate")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc006_plan")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "force_replan": false,
                  "reason_code": "initial_backplan"
                }
                """))
        .andExpect(status().isOk());
  }

  private void submitCheckpoint(AuthTokens tokens) throws Exception {
    mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc006_checkpoint")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "weekly_mock",
                  "transcript": "I gave a concrete checkpoint response with a project example, follow-up answer, fluency reflection, and enough evidence to update the gap without claiming final completion.",
                  "score_hint": 6.5
                }
                """))
        .andExpect(status().isOk());
  }

  private void completeOnboarding(AuthTokens tokens) throws Exception {
    mvc.perform(post("/onboarding/assessment")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_direction": "job_interview",
                  "pain_points": ["opening"],
                  "output_level": "L1",
                  "daily_minutes": 10
                }
                """))
        .andExpect(status().isOk());
  }

  private void favorite(AuthTokens tokens, String targetExpressionId, String expressionText) throws Exception {
    mvc.perform(post("/favorites/expressions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "target_expression_id": "%s",
                  "expression_text": "%s",
                  "source_type": "queue",
                  "source_id": "queue-item"
                }
                """.formatted(targetExpressionId, expressionText)))
        .andExpect(status().isOk());
  }

  private void acceptEvidence(AuthTokens tokens, String targetExpressionId) throws Exception {
    mvc.perform(post("/learning/evidence")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_type": "practice_turn",
                  "source_id": "delete-turn",
                  "evidence_type": "mastered_expression",
                  "target_expression_id": "%s",
                  "confidence": 0.88
                }
                """.formatted(targetExpressionId)))
        .andExpect(status().isCreated());
  }

  private void startPracticeSession(AuthTokens tokens) throws Exception {
    mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "job_interview",
                  "level_code": "L1",
                  "resume_existing": true
                }
                """))
        .andExpect(status().isOk());
  }
}
