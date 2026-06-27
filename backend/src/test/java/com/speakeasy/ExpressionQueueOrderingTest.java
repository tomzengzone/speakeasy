package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.List;
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
class ExpressionQueueOrderingTest extends BackendIntegrationTestSupport {
  @Test
  void queuePrioritizesEvidenceItemsAndDedupesStableExpressionIds() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138310");
    completeOnboarding(tokens);
    MvcResult firstQueue = queue(tokens);
    String targetExpressionId = JsonPath.read(firstQueue.getResponse().getContentAsString(), "$.queue_items[0].target_expression_id");

    mvc.perform(post("/learning/evidence")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_type": "practice_turn",
                  "source_id": "turn-1",
                  "evidence_type": "mastered_expression",
                  "target_expression_id": "%s",
                  "confidence": 0.91
                }
                """.formatted(targetExpressionId)))
        .andExpect(status().isCreated());

    MvcResult orderedQueue = queue(tokens);
    List<String> targetIds = JsonPath.read(orderedQueue.getResponse().getContentAsString(), "$.queue_items[*].target_expression_id");
    assertThat(targetIds.stream().filter(targetExpressionId::equals).count()).isEqualTo(1);
    assertThat(JsonPath.<String>read(orderedQueue.getResponse().getContentAsString(), "$.queue_items[0].target_expression_id"))
        .isEqualTo(targetExpressionId);
    assertThat(JsonPath.<Integer>read(orderedQueue.getResponse().getContentAsString(), "$.queue_items[0].priority")).isLessThan(300);
  }

  private MvcResult queue(AuthTokens tokens) throws Exception {
    return mvc.perform(get("/expressions/queue").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.queue_items[0].queue_item_id", not(blankOrNullString())))
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
