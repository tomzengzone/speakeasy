package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PracticeSessionLifecycleTest extends BackendIntegrationTestSupport {
  @Test
  void startCreatesAndResumesActivePracticeSession() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138240");
    String firstSessionId = startSession(tokens, true);
    String resumedSessionId = startSession(tokens, true);

    assertThat(resumedSessionId).isEqualTo(firstSessionId);

    mvc.perform(get("/practice/sessions/%s".formatted(firstSessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.status").value("active"))
        .andExpect(jsonPath("$.session.current_turn_index").value(0))
        .andExpect(jsonPath("$.session.messages", empty()));
  }

  @Test
  void resumeExistingFalseCreatesNewSession() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138241");
    String firstSessionId = startSession(tokens, true);
    String secondSessionId = startSession(tokens, false);

    assertThat(secondSessionId).isNotEqualTo(firstSessionId);
  }

  private String startSession(AuthTokens tokens, boolean resumeExisting) throws Exception {
    MvcResult result = mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "job_interview",
                  "level_code": "L1",
                  "resume_existing": %s
                }
                """.formatted(resumeExisting)))
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.session.session_id");
  }
}
