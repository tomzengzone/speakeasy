package com.speakeasy;

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
class SubscriptionRestoreTest extends BackendIntegrationTestSupport {
  @Test
  void restoreReturnsExistingActiveProviderSubscription() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138490");
    plans.save(new SubscriptionPlan(UUID.randomUUID(), "apple", "speakeasy.monthly", "monthly"));
    verifyApple(tokens);

    mvc.perform(post("/subscriptions/restore")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "restore-004")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "platform": "apple",
                  "provider_account_token": "restore-user"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.restore_status").value("restored"))
        .andExpect(jsonPath("$.entitlement.plan").value("pro"));
  }

  private void verifyApple(AuthTokens tokens) throws Exception {
    mvc.perform(post("/subscriptions/apple/verify")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "restore-verify-004")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transaction_id": "apple_valid_tx_004",
                  "original_transaction_id": "apple_original_tx_004",
                  "product_id": "speakeasy.monthly",
                  "app_account_token": "%s"
                }
                """.formatted(tokens.userId())))
        .andExpect(status().isOk());
  }
}
