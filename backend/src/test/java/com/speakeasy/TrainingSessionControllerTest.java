package com.speakeasy;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
class TrainingSessionControllerTest extends BackendIntegrationTestSupport {
  @Test
  void tcP01021TrainingSessionStartsFromServerSourceOfTruthAndResumes() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138500");

    MvcResult first = startTraining(tokens, "job_interview", "L1", true)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.session.session_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.session.scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.session.level_code").value("L1"))
        .andExpect(jsonPath("$.session.status").value("ready"))
        .andExpect(jsonPath("$.session.current_step_key").value("opening"))
        .andExpect(jsonPath("$.session.current_micro_action").value("SayOne"))
        .andExpect(jsonPath("$.session.scenario_version_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.session.mapping_version", startsWith("training-map:")))
        .andExpect(jsonPath("$.session.action_chain_version").value("p01-action-chain-v1"))
        .andExpect(jsonPath("$.session.action_chain", hasSize(6)))
        .andExpect(jsonPath("$.session.action_chain[0].review_status").value("reviewed"))
        .andReturn();
    String sessionId = JsonPath.read(first.getResponse().getContentAsString(), "$.session.session_id");

    startTraining(tokens, "job_interview", "L1", true)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.session_id").value(sessionId));

    mvc.perform(get("/training/sessions/%s".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.session_id").value(sessionId))
        .andExpect(jsonPath("$.session.evidence_write_status").value("not_started"));
  }

  @Test
  void tcP01021UnknownScenarioFailsClosedWithoutTwoScenePatternValidation() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138501");

    startTraining(tokens, "future_business_pitch", "L1", false)
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
  }

  private org.springframework.test.web.servlet.ResultActions startTraining(
      AuthTokens tokens, String scenarioId, String levelCode, boolean resumeExisting) throws Exception {
    return mvc.perform(post("/training/sessions")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "scenario_id": "%s",
              "level_code": "%s",
              "resume_existing": %s
            }
            """.formatted(scenarioId, levelCode, resumeExisting)));
  }
}
