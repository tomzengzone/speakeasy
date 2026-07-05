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
class MvpReportPlaceholderControllerTest extends BackendIntegrationTestSupport {
  @Test
  void reportReturnsEmptyPlaceholderInsteadOfFakeLearningReport() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138420");

    mvc.perform(get("/learning/report/summary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.report_status").value("empty"))
        .andExpect(jsonPath("$.sections", empty()))
        .andExpect(jsonPath("$.placeholder.status").value("not-implemented"))
        .andExpect(jsonPath("$.placeholder.reason_code").value("REPORT_NOT_IMPLEMENTED"));
  }

  @Test
  void offlineContentAndAchievementsReturnPlaceholders() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138421");

    mvc.perform(get("/offline-content/status").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.placeholder.surface").value("offline_content"))
        .andExpect(jsonPath("$.placeholder.status").value("not-implemented"));

    mvc.perform(get("/achievements/status").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.placeholder.surface").value("achievements"))
        .andExpect(jsonPath("$.placeholder.status").value("not-implemented"));
  }
}
