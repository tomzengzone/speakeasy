package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
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
class FavoriteExpressionControllerTest extends BackendIntegrationTestSupport {
  @Test
  void duplicateFavoriteUsesStableExpressionIdAndDeleteRemovesFromList() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138330");
    completeOnboarding(tokens);
    MvcResult queue = mvc.perform(get("/expressions/queue").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andReturn();
    String targetExpressionId = JsonPath.read(queue.getResponse().getContentAsString(), "$.queue_items[0].target_expression_id");
    String expressionText = JsonPath.read(queue.getResponse().getContentAsString(), "$.queue_items[0].expression_text");

    String firstFavoriteId = favorite(tokens, targetExpressionId, expressionText);
    String secondFavoriteId = favorite(tokens, targetExpressionId, expressionText);
    assertThat(secondFavoriteId).isEqualTo(firstFavoriteId);

    mvc.perform(get("/favorites/expressions").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.favorites.length()").value(1));

    mvc.perform(delete("/favorites/expressions/%s".formatted(firstFavoriteId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNoContent());

    mvc.perform(get("/favorites/expressions").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.favorites", empty()));
  }

  private String favorite(AuthTokens tokens, String targetExpressionId, String expressionText) throws Exception {
    MvcResult result = mvc.perform(post("/favorites/expressions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "target_expression_id": "%s",
                  "expression_text": "%s",
                  "source_type": "queue",
                  "source_id": "queue-item"
                }
                """.formatted(targetExpressionId, expressionText)))
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.favorite.favorite_id");
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
