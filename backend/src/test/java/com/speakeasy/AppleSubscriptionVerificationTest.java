package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
class AppleSubscriptionVerificationTest extends BackendIntegrationTestSupport {
  @Test
  void appleVerificationGrantsServerOwnedPaidEntitlement() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138460");
    plans.save(new SubscriptionPlan(UUID.randomUUID(), "apple", "speakeasy.monthly", "monthly"));

    mvc.perform(post("/subscriptions/apple/verify")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "apple-verify-001")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transaction_id": "apple_valid_tx_001",
                  "original_transaction_id": "apple_original_tx_001",
                  "product_id": "speakeasy.monthly",
                  "app_account_token": "%s"
                }
                """.formatted(tokens.userId())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.verification_status").value("verified"))
        .andExpect(jsonPath("$.subscription_status").value("active"))
        .andExpect(jsonPath("$.entitlement.plan").value("pro"))
        .andExpect(jsonPath("$.entitlement.features.advanced_scenarios").value(true))
        .andExpect(jsonPath("$.entitlement.generated_at", not(blankOrNullString())));

    mvc.perform(get("/entitlements").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement.plan").value("pro"))
        .andExpect(jsonPath("$.entitlement.features.advanced_scenarios").value(true));
  }
}
