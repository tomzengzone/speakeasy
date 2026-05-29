package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.ai.AiGatewayService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class UsageQuotaGateTest extends BackendIntegrationTestSupport {
  @Autowired AiGatewayService gateway;

  @Test
  void exhaustedQuotaBlocksProviderCallsBeforeInvocation() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138440");
    String auth = bearer(tokens.accessToken());

    mvc.perform(post("/usage/reserve")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .header("Idempotency-Key", "usage-quota-009")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "usage_family": "tts",
                  "amount": 10,
                  "source_ref": "quota-test"
                }
                """))
        .andExpect(status().isCreated());

    gateway.resetInvocationCount();
    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Could you tell me about yourself?"
                }
                """))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"));

    assertThat(gateway.invocationCount()).isZero();
  }
}
