package com.speakeasy;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class UsageReservationLifecycleTest extends BackendIntegrationTestSupport {
  @Test
  void usageCanBeReservedCommittedAndReleasedWithLedgerEvidence() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138430");
    String auth = bearer(tokens.accessToken());

    String committedReservationId = reserve(auth, "usage-reserve-017-a", "ai", 2);
    mvc.perform(post("/usage/commit")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "reservation_id": "%s",
                  "provider_usage_event_ref": "provider-ai-017-a"
                }
                """.formatted(committedReservationId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.reservation.status").value("committed"));

    String releasedReservationId = reserve(auth, "usage-reserve-017-b", "ai", 1);
    mvc.perform(post("/usage/release")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "reservation_id": "%s",
                  "provider_usage_event_ref": "provider-ai-017-b"
                }
                """.formatted(releasedReservationId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.reservation.status").value("released"));

    mvc.perform(get("/usage/summary").header(HttpHeaders.AUTHORIZATION, auth))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.usage[0].usage_family").value("ai"))
        .andExpect(jsonPath("$.usage[0].committed_amount").value(2))
        .andExpect(jsonPath("$.usage[0].reserved_amount").value(0));
  }

  private String reserve(String auth, String idempotencyKey, String usageFamily, int amount) throws Exception {
    MvcResult result = mvc.perform(post("/usage/reserve")
            .header(HttpHeaders.AUTHORIZATION, auth)
            .header("Idempotency-Key", idempotencyKey)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "usage_family": "%s",
                  "amount": %d,
                  "source_ref": "test"
                }
                """.formatted(usageFamily, amount)))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.reservation.reservation_id", not(blankOrNullString())))
        .andExpect(jsonPath("$.reservation.status").value("reserved"))
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.reservation.reservation_id");
  }
}
