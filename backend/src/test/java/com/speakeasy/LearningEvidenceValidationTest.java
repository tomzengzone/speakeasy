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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class LearningEvidenceValidationTest extends BackendIntegrationTestSupport {
  @Test
  void lowConfidenceCandidateIsRejectedAndDoesNotWriteMastery() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138340");
    completeOnboarding(tokens);
    String targetExpressionId = firstTargetExpression(tokens);

    mvc.perform(post("/learning/evidence")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_type": "practice_turn",
                  "source_id": "low-confidence-turn",
                  "evidence_type": "mastered_expression",
                  "target_expression_id": "%s",
                  "confidence": 0.40
                }
                """.formatted(targetExpressionId)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.evidence.accepted_status").value("rejected"));

    mvc.perform(get("/learning/mastery").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.mastery_records", empty()));
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
