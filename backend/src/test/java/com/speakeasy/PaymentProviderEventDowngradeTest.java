package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
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
class PaymentProviderEventDowngradeTest extends BackendIntegrationTestSupport {
  @Test
  void providerRefundEventDowngradesEntitlementAndIsIdempotent() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138510");
    plans.save(new SubscriptionPlan(UUID.randomUUID(), "apple", "speakeasy.monthly", "monthly"));
    verifyApple(tokens);

    sendRefundWebhook("apple-refund-event-006");
    sendRefundWebhook("apple-refund-event-006");

    mvc.perform(get("/entitlements").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement.plan").value("free"))
        .andExpect(jsonPath("$.entitlement.status").value("refunded"))
        .andExpect(jsonPath("$.entitlement.features.advanced_scenarios").value(false));

    assertThat(providerEvents.count()).isEqualTo(1);
  }

  private void verifyApple(AuthTokens tokens) throws Exception {
    mvc.perform(post("/subscriptions/apple/verify")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "provider-event-verify-006")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transaction_id": "apple_valid_tx_006",
                  "original_transaction_id": "apple_original_tx_006",
                  "product_id": "speakeasy.monthly",
                  "app_account_token": "%s"
                }
                """.formatted(tokens.userId())))
        .andExpect(status().isOk());
  }

  private void sendRefundWebhook(String providerEventId) throws Exception {
    mvc.perform(post("/subscriptions/webhook/apple")
            .header("X-Provider-Signature", "provider-test-signature")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "provider_event_id": "%s",
                  "platform": "apple",
                  "event_type": "refunded",
                  "received_payload_ref": "payload://apple/refund"
                }
                """.formatted(providerEventId)))
        .andExpect(status().isAccepted());
  }
}
