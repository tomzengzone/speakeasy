package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.commerce.SubscriptionPlan;
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
class GoogleSubscriptionVerificationTest extends BackendIntegrationTestSupport {
  @Test
  void googleVerificationGrantsServerOwnedPaidEntitlement() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138470");
    plans.save(new SubscriptionPlan(UUID.randomUUID(), "google", "speakeasy.monthly", "monthly"));

    mvc.perform(post("/subscriptions/google/verify")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "google-verify-002")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purchase_token": "google_valid_purchase_token_002",
                  "product_id": "speakeasy.monthly"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.verification_status").value("verified"))
        .andExpect(jsonPath("$.subscription_status").value("active"))
        .andExpect(jsonPath("$.entitlement.plan").value("pro"))
        .andExpect(jsonPath("$.entitlement.generated_at", not(blankOrNullString())));
  }
}
