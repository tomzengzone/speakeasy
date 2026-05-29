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
class CommercialAbuseControlTest extends BackendIntegrationTestSupport {
  @Autowired AiGatewayService gateway;

  @Test
  void repeatedHighCostProviderCallsAreCappedAndAudited() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138450");
    String auth = bearer(tokens.accessToken());
    gateway.resetInvocationCount();

    for (int i = 0; i < 10; i++) {
      mvc.perform(post("/ai/tts")
              .header(HttpHeaders.AUTHORIZATION, auth)
              .contentType(MediaType.APPLICATION_JSON)
              .content("""
                  {
                    "schema_version": 1,
                    "text": "abuse control sample %d"
                  }
                  """.formatted(i)))
          .andExpect(status().isOk())
          .andExpect(jsonPath("$.status").value("available"));
    }

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "abuse control sample blocked"
                }
                """))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"));

    assertThat(gateway.invocationCount()).isEqualTo(10);
    assertThat(auditLogs.count()).isGreaterThanOrEqualTo(11);
  }
}
