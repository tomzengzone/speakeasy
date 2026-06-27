package com.speakeasy;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ScenarioContentControllerTest extends BackendIntegrationTestSupport {
  @Test
  void scenarioDetailReturnsVersionedContentSummary() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138080");

    mvc.perform(get("/scenarios/job_interview").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.scenario.scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.scenario.title").value("英语面试"))
        .andExpect(jsonPath("$.scenario.levels", containsInAnyOrder("L1", "L2", "L3")))
        .andExpect(jsonPath("$.scenario.version").value("2026.05-mvp-seed"))
        .andExpect(jsonPath("$.scenario.expression_count", greaterThanOrEqualTo(6)))
        .andExpect(jsonPath("$.scenario.access.allowed").value(true));
  }

  @Test
  void scenarioLevelReturnsTargetExpressionsForValidLevels() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138081");

    mvc.perform(get("/scenarios/onboarding_introduction/levels/L2")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.scenario_id").value("onboarding_introduction"))
        .andExpect(jsonPath("$.level_code").value("L2"))
        .andExpect(jsonPath("$.target_expressions.length()").value(2))
        .andExpect(jsonPath("$.target_expressions[0].target_expression_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.dialogue_assets.length()").value(0))
        .andExpect(jsonPath("$.action_chain_steps.length()").value(0));
  }

  @Test
  void invalidLevelReturnsDeterministicNotFound() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138082");

    mvc.perform(get("/scenarios/job_interview/levels/L9")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
  }
}
