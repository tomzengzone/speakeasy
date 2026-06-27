package com.speakeasy;

import static org.hamcrest.Matchers.empty;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
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
class LearningHistoryWikiControllerTest extends BackendIntegrationTestSupport {
  @Test
  void historyAndWikiReflectAcceptedEvidenceAndHistoryDeletion() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138360");
    completeOnboarding(tokens);
    String targetExpressionId = firstTargetExpression(tokens);
    acceptEvidence(tokens, targetExpressionId);

    mvc.perform(get("/learning/wiki").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entries[0].target_expression_id").value(targetExpressionId));

    MvcResult history = mvc.perform(get("/learning/history").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entries[0].status").value("recorded"))
        .andReturn();
    String historyEntryId = JsonPath.read(history.getResponse().getContentAsString(), "$.entries[0].history_entry_id");

    mvc.perform(delete("/learning/history/%s".formatted(historyEntryId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNoContent());

    mvc.perform(get("/learning/history").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entries", empty()));
  }

  private void acceptEvidence(AuthTokens tokens, String targetExpressionId) throws Exception {
    mvc.perform(post("/learning/evidence")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_type": "practice_turn",
                  "source_id": "history-turn",
                  "evidence_type": "mastered_expression",
                  "target_expression_id": "%s",
                  "confidence": 0.88
                }
                """.formatted(targetExpressionId)))
        .andExpect(status().isCreated());
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
