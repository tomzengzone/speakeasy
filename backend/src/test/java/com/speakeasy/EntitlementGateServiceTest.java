package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.commerce.EntitlementSnapshot;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class EntitlementGateServiceTest extends BackendIntegrationTestSupport {
  @Test
  void freeUsersAreBlockedFromPaidScenarioLevelsAndPaidUsersAreAllowed() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138420");

    mvc.perform(get("/scenarios/job_interview/levels/L3")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("ENTITLEMENT_REQUIRED"));

    entitlements.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        UUID.fromString(tokens.userId()),
        "pro",
        "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
        "{\"ai\":100,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}",
        Instant.now()));

    mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "job_interview",
                  "level_code": "L3",
                  "resume_existing": true
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.level_code").value("L3"));
  }
}
