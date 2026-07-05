package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
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
class TrainingTurnIdempotencyTest extends BackendIntegrationTestSupport {
  @Test
  void tcP01022SameIdempotencyKeyReplaysTurnWithoutDuplicateProviderWork() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138510");
    String sessionId = startTraining(tokens);

    MvcResult first = submitTurn(tokens, sessionId, "training-turn-1", "I worked on a project that improved our workflow.")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.turn.result").value("accepted"))
        .andExpect(jsonPath("$.planner_decision.reason_code").value("target_and_task_met"))
        .andReturn();
    String turnId = JsonPath.read(first.getResponse().getContentAsString(), "$.turn.turn_id");
    long providerMetricCount = aiProviderMetrics.count();

    submitTurn(tokens, sessionId, "training-turn-1", "I worked on a project that improved our workflow.")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.turn.turn_id").value(turnId));

    assertThat(trainingTurns.count()).isEqualTo(1);
    assertThat(aiProviderMetrics.count()).isEqualTo(providerMetricCount);
  }

  @Test
  void tcP01022SameIdempotencyKeyWithDifferentPayloadIsRejected() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138511");
    String sessionId = startTraining(tokens);
    submitTurn(tokens, sessionId, "training-turn-conflict", "First answer").andExpect(status().isOk());

    submitTurn(tokens, sessionId, "training-turn-conflict", "Different answer")
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("IDEMPOTENCY_CONFLICT"));
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

  private org.springframework.test.web.servlet.ResultActions submitTurn(
      AuthTokens tokens, String sessionId, String idempotencyKey, String transcript) throws Exception {
    return mvc.perform(post("/training/sessions/%s/turns".formatted(sessionId))
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("Idempotency-Key", idempotencyKey)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "transcript": "%s"
            }
            """.formatted(transcript)));
  }
}
