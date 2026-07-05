package com.speakeasy;

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
class TrainingSessionAuthorizationTest extends BackendIntegrationTestSupport {
  @Test
  void tcP01022TrainingSessionsAreUserScoped() throws Exception {
    AuthTokens owner = loginPhone("+8613800138520");
    AuthTokens other = loginPhone("+8613800138521");
    String sessionId = startTraining(owner);

    mvc.perform(get("/training/sessions/%s".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(other.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));

    mvc.perform(post("/training/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(other.accessToken()))
            .header("Idempotency-Key", "unauthorized-turn")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "I should not access another user's session."
                }
                """))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
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
}
