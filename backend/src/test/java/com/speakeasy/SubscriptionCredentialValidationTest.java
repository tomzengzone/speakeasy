package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
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
class SubscriptionCredentialValidationTest extends BackendIntegrationTestSupport {
  @Test
  void invalidProviderCredentialOrUserMismatchDoesNotGrantEntitlement() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138480");
    plans.save(new SubscriptionPlan(UUID.randomUUID(), "apple", "speakeasy.monthly", "monthly"));

    mvc.perform(post("/subscriptions/apple/verify")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "apple-invalid-003")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transaction_id": "apple_invalid_tx_003",
                  "original_transaction_id": "apple_original_tx_003",
                  "product_id": "speakeasy.monthly",
                  "app_account_token": "%s"
                }
                """.formatted(tokens.userId())))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("INVALID_RECEIPT"));

    mvc.perform(post("/subscriptions/apple/verify")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "apple-user-mismatch-003")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transaction_id": "apple_valid_tx_003",
                  "original_transaction_id": "apple_original_tx_003",
                  "product_id": "speakeasy.monthly",
                  "app_account_token": "00000000-0000-0000-0000-000000000999"
                }
                """))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.error.code").value("INVALID_RECEIPT"));

    assertThat(entitlements.findByUserIdOrderByGeneratedAtDesc(UUID.fromString(tokens.userId()))).isEmpty();
  }
}
