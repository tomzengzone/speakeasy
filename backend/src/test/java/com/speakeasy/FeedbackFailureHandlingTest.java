package com.speakeasy;

import static org.hamcrest.Matchers.empty;
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
class FeedbackFailureHandlingTest extends BackendIntegrationTestSupport {
  @Test
  void playbackFailureIsTypedWithoutLosingSession() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138290");
    String sessionId = startSession(tokens);

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "provider unavailable"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("provider_unavailable"));

    mvc.perform(get("/practice/sessions/%s".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.status").value("active"));
  }

  @Test
  void invalidProviderOutputIsNotVisibleAsSuccessfulFeedback() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138291");
    String sessionId = startSession(tokens);

    mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "invalid-output")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "invalid_schema"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.coach_feedback.feedback_type").value("recoverable_error"))
        .andExpect(jsonPath("$.coach_feedback.validation_status").value("fallback"))
        .andExpect(jsonPath("$.learning_evidence_candidates", empty()));
  }

  private String startSession(AuthTokens tokens) throws Exception {
    MvcResult result = mvc.perform(post("/practice/sessions")
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
