package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TrainingAccountDeletionRetentionTest extends BackendIntegrationTestSupport {
  @Autowired JdbcTemplate jdbcTemplate;

  @Test
  void tcP01024AccountDeletionPurgesTrainingSourceOfTruthAndEvidenceTrace() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138540");
    UUID userId = UUID.fromString(tokens.userId());
    String sessionId = startTraining(tokens);
    submitTurn(tokens, sessionId);

    assertThat(count("training_sessions", userId)).isGreaterThan(0);
    assertThat(count("training_turns", userId)).isGreaterThan(0);
    assertThat(count("training_planner_decisions", userId)).isGreaterThan(0);
    assertThat(count("training_evidence_candidates", userId)).isGreaterThan(0);
    assertThat(count("training_metric_events", userId)).isGreaterThan(0);
    assertThat(count("learning_evidences", userId)).isGreaterThan(0);

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-training-024")
            .header("X-Request-Id", "req_delete_training_024"))
        .andExpect(status().isAccepted());

    assertThat(count("training_sessions", userId)).isZero();
    assertThat(count("training_turns", userId)).isZero();
    assertThat(count("training_planner_decisions", userId)).isZero();
    assertThat(count("training_evidence_candidates", userId)).isZero();
    assertThat(count("training_metric_events", userId)).isZero();
    assertThat(count("learning_evidences", userId)).isZero();
  }

  private int count(String tableName, UUID userId) {
    return jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?", Integer.class, userId);
  }

  private String startTraining(AuthTokens tokens) throws Exception {
    MvcResult result = mvc.perform(post("/training/sessions")
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
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.session.session_id");
  }

  private void submitTurn(AuthTokens tokens, String sessionId) throws Exception {
    mvc.perform(post("/training/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "training-delete-turn")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "I worked on a project that improved our workflow."
                }
                """))
        .andExpect(status().isOk());
  }
}
