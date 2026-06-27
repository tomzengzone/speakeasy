package com.speakeasy;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.empty;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class UserScenarioStateControllerTest extends BackendIntegrationTestSupport {
  @Test
  void joinScenarioMakesItVisibleInHomeSummary() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138090");

    mvc.perform(put("/user/scenarios/job_interview")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "target_level": "L2",
                  "set_current": true
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.state.scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.state.state").value("joined"))
        .andExpect(jsonPath("$.state.current").value(true))
        .andExpect(jsonPath("$.home_summary.current_scenario.scenario_id").value("job_interview"));
  }

  @Test
  void setCurrentScenarioAndLevelAffectSubsequentHomeSummary() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138091");
    join(tokens, "job_interview", "L1");
    join(tokens, "onboarding_introduction", "L1");

    mvc.perform(patch("/user/scenarios/current")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "onboarding_introduction",
                  "target_level": "L3"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.state.scenario_id").value("onboarding_introduction"))
        .andExpect(jsonPath("$.state.target_level").value("L3"))
        .andExpect(jsonPath("$.state.current").value(true));

    mvc.perform(get("/home/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.summary.current_scenario.scenario_id").value("onboarding_introduction"))
        .andExpect(jsonPath("$.summary.current_scenario.target_level").value("L3"))
        .andExpect(jsonPath("$.summary.joined_scenarios[*].scenario_id",
            containsInAnyOrder("job_interview", "onboarding_introduction")));
  }

  @Test
  void removingCurrentScenarioClearsItFromHomeSummary() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138092");
    join(tokens, "job_interview", "L1");

    mvc.perform(delete("/user/scenarios/job_interview")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.state.state").value("removed"))
        .andExpect(jsonPath("$.state.current").value(false))
        .andExpect(jsonPath("$.home_summary.current_scenario").isEmpty())
        .andExpect(jsonPath("$.home_summary.joined_scenarios", empty()));
  }

  private void join(AuthTokens tokens, String scenarioId, String targetLevel) throws Exception {
    mvc.perform(put("/user/scenarios/" + scenarioId)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "target_level": "%s",
                  "set_current": true
                }
                """.formatted(targetLevel)))
        .andExpect(status().isOk());
  }
}
