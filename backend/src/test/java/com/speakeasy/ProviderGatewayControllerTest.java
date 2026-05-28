package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
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
class ProviderGatewayControllerTest extends BackendIntegrationTestSupport {
  @Test
  void gatewayReturnsNormalizedSuccessResults() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138210");
    String auth = bearer(tokens.accessToken());
    String sessionId = startSession(tokens);

    mvc.perform(post("/ai/transcribe")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "audio://valid"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.transcript", not(blankOrNullString())));

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Could you tell me about yourself?"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.audio_ref", not(blankOrNullString())));

    mvc.perform(post("/ai/pronunciation")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "audio_ref": "audio://valid",
                  "reference_text": "Could you tell me about yourself?"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.score_signal.status").value("available"))
        .andExpect(jsonPath("$.score_signal.source").value("server_side_adapter"));

    mvc.perform(post("/ai/coach-turn")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "session_id": "%s",
                  "transcript": "I worked on a project that improved our workflow."
                }
                """.formatted(sessionId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.validation_status").value("valid"))
        .andExpect(jsonPath("$.feedback.next_prompt", not(blankOrNullString())));
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
