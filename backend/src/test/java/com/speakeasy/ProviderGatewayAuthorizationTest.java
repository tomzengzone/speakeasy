package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProviderGatewayAuthorizationTest extends BackendIntegrationTestSupport {
  @Autowired AiGatewayService gateway;

  @Test
  void unauthenticatedGatewayRequestDoesNotInvokeProvider() throws Exception {
    gateway.resetInvocationCount();

    mvc.perform(post("/ai/coach-turn")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "session_id": "00000000-0000-0000-0000-000000000001",
                  "transcript": "hello"
                }
                """))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));

    assertThat(gateway.invocationCount()).isZero();
  }

  @Test
  void sessionMismatchDoesNotInvokeProvider() throws Exception {
    AuthTokens owner = loginPhone("+8613800138230");
    AuthTokens other = loginPhone("+8613800138231");
    String sessionId = startSession(owner);
    gateway.resetInvocationCount();

    mvc.perform(post("/ai/coach-turn")
            .header(HttpHeaders.AUTHORIZATION, bearer(other.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "session_id": "%s",
                  "transcript": "hello"
                }
                """.formatted(sessionId)))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));

    assertThat(gateway.invocationCount()).isZero();
  }

  private String startSession(AuthTokens tokens) throws Exception {
    MvcResult result = mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "job_interview",
                  "level_code": "L1",
                  "resume_existing": true
                }
                """))
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.session.session_id");
  }
}
