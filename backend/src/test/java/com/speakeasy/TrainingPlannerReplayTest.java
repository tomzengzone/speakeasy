package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.training.TrainingPlannerDecision;
import java.util.List;
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
class TrainingPlannerReplayTest extends BackendIntegrationTestSupport {
  @Test
  void tcP01027PlannerDecisionsAreAuditedVersionedAndReplayable() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138570");
    String sessionId = startTraining(tokens);

    mvc.perform(post("/training/sessions/%s/planner/next".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"schema_version\":1}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.planner_decision.type").value("continue"))
        .andExpect(jsonPath("$.planner_decision.planner_version").value("p01-training-planner-v1"));

    mvc.perform(post("/training/sessions/%s/hints".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"schema_version\":1}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.planner_decision.type").value("raise_hint"))
        .andExpect(jsonPath("$.session.hint_level").value("sentence_frame"));

    submitTurn(tokens, sessionId, "planner-success-1", "I worked on a project that improved our workflow.")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.planner_decision.type").value("advance_step"));
    submitTurn(tokens, sessionId, "planner-success-2", "I worked on a project that improved our workflow.")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.planner_decision.type").value("pressure_check"))
        .andExpect(jsonPath("$.session.status").value("pressure_check"));

    List<TrainingPlannerDecision> decisions =
        trainingPlannerDecisions.findByTrainingSessionIdOrderByCreatedAtAsc(java.util.UUID.fromString(sessionId));
    assertThat(decisions).hasSizeGreaterThanOrEqualTo(4);
    assertThat(decisions).allSatisfy(decision -> {
      assertThat(decision.getPlannerVersion()).isEqualTo("p01-training-planner-v1");
      assertThat(decision.getInputSnapshot()).doesNotContain("I worked on a project");
      assertThat(decision.getOutputSnapshot()).contains("\"decision_type\"");
    });
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
