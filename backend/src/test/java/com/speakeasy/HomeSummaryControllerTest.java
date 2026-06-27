package com.speakeasy;

import static org.hamcrest.Matchers.empty;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class HomeSummaryControllerTest extends BackendIntegrationTestSupport {
  @Test
  void homeSummaryReturnsEmptyStateBeforeOnboarding() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138100");

    mvc.perform(get("/home/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.onboarding_status").value("incomplete"))
        .andExpect(jsonPath("$.summary.current_scenario").isEmpty())
        .andExpect(jsonPath("$.summary.joined_scenarios", empty()))
        .andExpect(jsonPath("$.summary.next_action.action_type").value("complete_onboarding"));
  }

  @Test
  void homeSummaryDoesNotFakeUnavailableReviewWeaknessOrSessionData() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138101");

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

    mvc.perform(get("/home/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.current_scenario.scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.summary.review_status").value("not_available"))
        .andExpect(jsonPath("$.summary.weakness_status").value("not_available"))
        .andExpect(jsonPath("$.summary.unfinished_session_status").value("none"))
        .andExpect(jsonPath("$.summary.next_action.action_type").value("start_practice"));
  }

  @Test
  void completedDailyServiceAssessmentKeepsUnderstandableNoScenarioState() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138102");

    mvc.perform(post("/onboarding/assessment")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_direction": "daily_service",
                  "pain_points": ["opening"],
                  "output_level": "L1",
                  "daily_minutes": 10
                }
                """))
        .andExpect(status().isOk());

    mvc.perform(get("/home/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.onboarding_status").value("complete"))
        .andExpect(jsonPath("$.summary.current_scenario").isEmpty())
        .andExpect(jsonPath("$.summary.joined_scenarios", empty()))
        .andExpect(jsonPath("$.summary.next_action.action_type").value("choose_scenario"));
  }
}
