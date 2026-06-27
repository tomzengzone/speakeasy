package com.speakeasy;

import static org.hamcrest.Matchers.empty;
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
class ExpressionQueueControllerTest extends BackendIntegrationTestSupport {
  @Test
  void queueReturnsExplicitEmptyStateWithoutJoinedScenario() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138300");

    mvc.perform(get("/expressions/queue").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.state").value("empty_no_scene"))
        .andExpect(jsonPath("$.queue_items", empty()));
  }
}
