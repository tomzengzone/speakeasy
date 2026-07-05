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
class LearningEvidenceProjectionTest extends BackendIntegrationTestSupport {
  @Test
  void acceptedEvidenceProjectsToEvidenceMasteryReviewWikiHistoryAndQueue() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138350");
    completeOnboarding(tokens);
    String targetExpressionId = firstTargetExpression(tokens);

    mvc.perform(post("/learning/evidence")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_type": "practice_turn",
                  "source_id": "accepted-turn",
                  "evidence_type": "mastered_expression",
                  "target_expression_id": "%s",
                  "confidence": 0.88
                }
                """.formatted(targetExpressionId)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.evidence.accepted_status").value("accepted"));

    mvc.perform(get("/learning/evidence").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.evidence[0].target_expression_id").value(targetExpressionId));
    mvc.perform(get("/learning/mastery").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.mastery_records[0].mastery_status").value("mastered"));
    mvc.perform(get("/review/items").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.review_items[0].target_expression_id").value(targetExpressionId));
    mvc.perform(get("/learning/wiki").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entries[0].target_expression_id").value(targetExpressionId));
    mvc.perform(get("/learning/history").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entries[0].title", not(blankOrNullString())));
    mvc.perform(get("/expressions/queue").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.queue_items[0].priority").value(100));
  }

  private String firstTargetExpression(AuthTokens tokens) throws Exception {
    MvcResult queue = mvc.perform(get("/expressions/queue").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(queue.getResponse().getContentAsString(), "$.queue_items[0].target_expression_id");
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
