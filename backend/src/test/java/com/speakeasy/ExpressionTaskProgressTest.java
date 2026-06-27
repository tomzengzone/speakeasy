package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
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
class ExpressionTaskProgressTest extends BackendIntegrationTestSupport {
  @Test
  void completedTaskPersistsAttemptEvidenceAndMasteryLink() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138320");
    completeOnboarding(tokens);
    MvcResult queue = queue(tokens);
    String queueItemId = JsonPath.read(queue.getResponse().getContentAsString(), "$.queue_items[0].queue_item_id");
    String targetExpressionId = JsonPath.read(queue.getResponse().getContentAsString(), "$.queue_items[0].target_expression_id");

    mvc.perform(post("/expressions/tasks/%s/complete".formatted(queueItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "result": "completed",
                  "score": 0.93,
                  "answer_text": "I worked on a small project.",
                  "transcript_ref": "manual"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.progress.attempt_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.progress.evidence_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.progress.target_expression_id").value(targetExpressionId));

    mvc.perform(get("/learning/mastery").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.mastery_records[0].target_expression_id").value(targetExpressionId))
        .andExpect(jsonPath("$.mastery_records[0].mastery_status").value("mastered"));
  }

  private MvcResult queue(AuthTokens tokens) throws Exception {
    return mvc.perform(get("/expressions/queue").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andReturn();
  }

  private void completeOnboarding(AuthTokens tokens) throws Exception {
    mvc.perform(post("/onboarding/assessment")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_direction": "job_interview",
                  "pain_points": ["opening"],
                  "output_level": "L1",
                  "daily_minutes": 10
                }
                """))
        .andExpect(status().isOk());
  }
}
