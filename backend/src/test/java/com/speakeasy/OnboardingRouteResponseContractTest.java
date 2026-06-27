package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
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
class OnboardingRouteResponseContractTest extends BackendIntegrationTestSupport {
  @Test
  void completedAssessmentReturnsOpenApiRouteShape() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138060");

    mvc.perform(post("/onboarding/assessment")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_direction": "job_interview",
                  "pain_points": ["opening", "follow-up"],
                  "output_level": "L1",
                  "daily_minutes": 10
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.route.current_scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.route.target_level").value("L1"))
        .andExpect(jsonPath("$.route.scenario_ids[0]").value("job_interview"))
        .andExpect(jsonPath("$.assessment_id").doesNotExist())
        .andExpect(jsonPath("$.route.route_id").doesNotExist())
        .andExpect(jsonPath("$.route.source_assessment_id").doesNotExist())
        .andExpect(jsonPath("$.route.created_at").doesNotExist())
        .andExpect(jsonPath("$.route.updated_at").doesNotExist());
  }

  @Test
  void completedAssessmentMakesCurrentUserStateReadable() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138061");

    mvc.perform(post("/onboarding/assessment")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_direction": "job_interview",
                  "pain_points": ["opening"],
                  "output_level": "L2",
                  "daily_minutes": 12
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.route.current_scenario_id", not(blankOrNullString())));

    mvc.perform(get("/home/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.current_scenario.scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.summary.current_scenario.target_level").value("L2"));
  }
}
