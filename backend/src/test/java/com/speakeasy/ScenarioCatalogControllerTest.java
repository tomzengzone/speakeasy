package com.speakeasy;

import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.hasItem;
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
class ScenarioCatalogControllerTest extends BackendIntegrationTestSupport {
  @Test
  void scenarioListOnlyReturnsProductBaseOfficialScenarios() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138070");

    mvc.perform(get("/scenarios").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.scenarios.length()").value(2))
        .andExpect(jsonPath("$.scenarios[*].scenario_id", containsInAnyOrder("job_interview", "onboarding_introduction")))
        .andExpect(jsonPath("$.scenarios[*].scenario_id", not(hasItem("daily_service"))))
        .andExpect(jsonPath("$.scenarios[*].status", everyItem(org.hamcrest.Matchers.is("available"))));
  }

  @Test
  void scenarioListRequiresAuthentication() throws Exception {
    mvc.perform(get("/scenarios"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }
}
