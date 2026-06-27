package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
class SubscriptionRestoreEmptyTest extends BackendIntegrationTestSupport {
  @Test
  void emptyRestoreReturnsTypedSuccessWithoutGrantingEntitlement() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138500");

    mvc.perform(post("/subscriptions/restore")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "restore-empty-005")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "platform": "google"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.restore_status").value("empty"))
        .andExpect(jsonPath("$.entitlement").doesNotExist());
  }
}
