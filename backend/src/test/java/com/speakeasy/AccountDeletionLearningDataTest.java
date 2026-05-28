package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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

  private int count(String tableName, UUID userId) {
    return jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?", Integer.class, userId);
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
