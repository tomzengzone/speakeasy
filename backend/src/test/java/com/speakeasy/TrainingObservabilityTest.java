package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.training.TrainingMetricEvent;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TrainingObservabilityTest extends BackendIntegrationTestSupport {
  @Test
  void tcP01028TrainingFlowEmitsRolloutMetricsWithoutRawUserContent() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138580");
    String sessionId = startTraining(tokens);
    submitTurn(tokens, sessionId);

    mvc.perform(post("/training/sessions/%s/complete".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"schema_version\":1}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.recap.accepted_evidence_ids[0]").exists());

    assertThat(trainingMetrics.countByEventTypeAndStatus("training_session_start", "success")).isEqualTo(1);
    assertThat(trainingMetrics.countByEventTypeAndStatus("training_turn_submit", "success")).isEqualTo(1);
    assertThat(trainingMetrics.countByEventTypeAndStatus("training_planner_decision", "success")).isGreaterThanOrEqualTo(1);
    assertThat(trainingMetrics.countByEventTypeAndStatus("training_evidence_candidate", "accepted")).isEqualTo(1);
    assertThat(trainingMetrics.countByEventTypeAndStatus("training_session_complete", "success")).isEqualTo(1);

    List<TrainingMetricEvent> events =
        trainingMetrics.findByTrainingSessionIdOrderByCreatedAtAsc(UUID.fromString(sessionId));
    assertThat(events).isNotEmpty();
    assertThat(events).allSatisfy(event -> {
      assertThat(event.getSchemaVersion()).isEqualTo(1);
      assertThat(event.getAuditRef()).startsWith("training:");
    });
    assertThat(events.toString()).doesNotContain(tokens.userId());
    assertThat(events.toString()).doesNotContain("I worked on a project");
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
            .header("Idempotency-Key", "metrics-turn")
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
