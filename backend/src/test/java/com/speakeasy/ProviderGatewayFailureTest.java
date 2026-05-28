package com.speakeasy;

import static org.hamcrest.Matchers.empty;
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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProviderGatewayFailureTest extends BackendIntegrationTestSupport {
  @Test
  void invalidProviderSchemaReturnsRecoverableFallback() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138220");
    String sessionId = startSession(tokens);

    mvc.perform(post("/ai/coach-turn")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "session_id": "%s",
                  "transcript": "invalid_schema"
                }
                """.formatted(sessionId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.validation_status").value("fallback"))
        .andExpect(jsonPath("$.feedback.feedback_type").value("recoverable_error"))
        .andExpect(jsonPath("$.feedback.provider_status").value("invalid_schema"));
  }

  @Test
  void failedPracticeTurnDoesNotCreatePseudoSuccessEvidence() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138221");
    String sessionId = startSession(tokens);

    mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "turn-invalid-schema")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "invalid_schema"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session_status").value("recoverable_error"))
        .andExpect(jsonPath("$.coach_feedback.validation_status").value("fallback"))
        .andExpect(jsonPath("$.recoverable_error.retryable").value(true))
        .andExpect(jsonPath("$.learning_evidence_candidates", empty()));
  }

  @Test
  void unavailableTranscriptionReturnsRecoverableSessionError() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138222");
    String sessionId = startSession(tokens);

    mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "turn-asr-unavailable")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "audio://provider_unavailable"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session_status").value("recoverable_error"))
        .andExpect(jsonPath("$.recoverable_error.code").value("asr_unavailable"));
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
