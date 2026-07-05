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
class CoachFeedbackContractTest extends BackendIntegrationTestSupport {
  @Test
  void validTurnReturnsCoachFeedbackAndScoreSignalWithoutMasteryDecision() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138280");
    String sessionId = startSession(tokens);

    mvc.perform(post("/practice/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "feedback-contract")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "I worked on a project that improved our workflow."
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.coach_feedback.summary", not(blankOrNullString())))
        .andExpect(jsonPath("$.coach_feedback.feedback_type").value("next_question"))
        .andExpect(jsonPath("$.coach_feedback.score_signal.source").value("server_side_adapter"))
        .andExpect(jsonPath("$.coach_feedback.score_signal.status").value("available"))
        .andExpect(jsonPath("$.learning_evidence_candidates[0].status").value("candidate"))
        .andExpect(jsonPath("$.mastery_status").doesNotExist());
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
