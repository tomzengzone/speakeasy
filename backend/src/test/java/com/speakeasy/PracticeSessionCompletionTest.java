package com.speakeasy;

import static org.hamcrest.Matchers.hasItem;
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
class PracticeSessionCompletionTest extends BackendIntegrationTestSupport {
  @Test
  void completeSessionReturnsSummaryEvidenceCandidateInput() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138260");
    String sessionId = startSession(tokens);
    submitTurn(tokens, sessionId);

    mvc.perform(post("/practice/sessions/%s/complete".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.session_id").value(sessionId))
        .andExpect(jsonPath("$.summary.learned_items", hasItem("My main contribution was coordinating the timeline and clarifying priorities.")))
        .andExpect(jsonPath("$.summary.weak_points", hasItem("naturalness")))
        .andExpect(jsonPath("$.summary.next_focus", not(blankOrNullString())));
  }

  private void submitTurn(AuthTokens tokens, String sessionId) throws Exception {
    mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "completion-turn")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "I worked on a project that improved our workflow."
                }
                """))
        .andExpect(status().isOk());
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
