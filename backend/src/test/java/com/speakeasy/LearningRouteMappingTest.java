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
class LearningRouteMappingTest extends BackendIntegrationTestSupport {
  @Test
  void interviewAssessmentMapsToJobInterview() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138050");

    submitAssessment(tokens, "job_interview")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.route.current_scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.route.target_level").value("L2"))
        .andExpect(jsonPath("$.route.scenario_ids[0]").value("job_interview"));

    mvc.perform(get("/home/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.current_scenario.scenario_id").value("job_interview"));
  }

  @Test
  void onboardingAndWorkCommunicationMapToOnboardingIntroduction() throws Exception {
    AuthTokens onboarding = loginPhone("+8613800138051");
    AuthTokens work = loginPhone("+8613800138052");

    submitAssessment(onboarding, "onboarding_introduction")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.route.current_scenario_id").value("onboarding_introduction"));

    submitAssessment(work, "work_communication")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.route.current_scenario_id").value("onboarding_introduction"));
  }

  @Test
  void dailyServiceDoesNotCreatePracticeScenario() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138053");

    submitAssessment(tokens, "daily_service")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.route.current_scenario_id").isEmpty())
        .andExpect(jsonPath("$.route.scenario_ids", empty()));

    mvc.perform(get("/home/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.current_scenario").isEmpty())
        .andExpect(jsonPath("$.summary.joined_scenarios", empty()))
        .andExpect(jsonPath("$.summary.next_action.action_type").value("choose_scenario"));
  }

  private org.springframework.test.web.servlet.ResultActions submitAssessment(AuthTokens tokens, String goalDirection)
      throws Exception {
    return mvc.perform(post("/onboarding/assessment")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "goal_direction": "%s",
              "pain_points": ["opening"],
              "output_level": "L2",
              "daily_minutes": 15
            }
            """.formatted(goalDirection)));
  }
}
