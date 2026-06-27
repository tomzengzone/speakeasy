package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.AiGatewayService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProviderGatewaySecurityContractTest extends BackendIntegrationTestSupport {
  @Autowired AiGatewayService gateway;

  @Test
  void clientCannotSubmitProviderSecretToGateway() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138200");
    gateway.resetInvocationCount();

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Hello",
                  "provider_secret": "client-must-not-send-this"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    org.assertj.core.api.Assertions.assertThat(gateway.invocationCount()).isZero();
  }

  @Test
  void clientCannotSubmitProviderTierToGateway() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138202");
    gateway.resetInvocationCount();

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Hello",
                  "provider_tier": "enterprise"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));

    org.assertj.core.api.Assertions.assertThat(gateway.invocationCount()).isZero();
  }

  @Test
  void serverSideGatewayWorksWithoutClientSecret() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138201");
    String sessionId = startSession(tokens, "job_interview", "L1");

    mvc.perform(post("/ai/coach-turn")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "session_id": "%s",
                  "transcript": "I worked on a project that improved our workflow."
                }
                """.formatted(sessionId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.validation_status").value("valid"))
        .andExpect(jsonPath("$.feedback.summary", not(blankOrNullString())))
        .andExpect(jsonPath("$.feedback.score_signal.source").value("server_side_adapter"))
        .andExpect(jsonPath("$.provider_secret").doesNotExist());
  }

  private String startSession(AuthTokens tokens, String scenarioId, String levelCode) throws Exception {
    MvcResult result = mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "%s",
                  "level_code": "%s",
                  "resume_existing": true
                }
                """.formatted(scenarioId, levelCode)))
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.session.session_id");
  }
}
