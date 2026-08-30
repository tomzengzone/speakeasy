package com.speakeasy;

import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.identity.ratelimit.AuthRateLimitStore;
import com.speakeasy.identity.ratelimit.AuthRateLimitAudit;
import com.speakeasy.identity.ratelimit.AuthRateLimitStoreUnavailableException;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = {
    "speakeasy.auth.rate-limit.mode=enforce",
    "speakeasy.auth.rate-limit.key-secret=http-test-secret"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthRateLimitHttpTest {
  @Autowired MockMvc mvc;
  @Autowired UserAccountRepository users;
  @MockBean AuthRateLimitStore store;
  @MockBean AuthRateLimitAudit rateLimitAudit;

  @Test
  void returnsTheStandard429ContractBeforeAuthenticationWork() throws Exception {
    when(store.consume(anyList())).thenReturn(
        new AuthRateLimitStore.Decision(false, Duration.ofSeconds(1), "account"));
    long usersBeforeRequest = users.count();

    mvc.perform(post("/auth/login/phone")
            .header("X-Request-Id", "rate-limit-http-test")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138000",
                  "verification_code": "123456",
                  "terms_accepted": true,
                  "device_id": "install-123"
                }
                """))
        .andExpect(status().isTooManyRequests())
        .andExpect(header().string("Retry-After", "5"))
        .andExpect(header().string("X-Request-Id", "rate-limit-http-test"))
        .andExpect(header().string("Cache-Control", "no-store"))
        .andExpect(jsonPath("$.error.code").value("AUTH_RATE_LIMITED"))
        .andExpect(jsonPath("$.error.request_id").value("rate-limit-http-test"))
        .andExpect(jsonPath("$.error.details.endpoint").value("phone-login"))
        .andExpect(jsonPath("$.error.details.dimension").value("account"));

    org.assertj.core.api.Assertions.assertThat(users.count()).isEqualTo(usersBeforeRequest);
  }

  @Test
  void enforceModeReturns503WhenTheSharedLimiterIsUnavailable() throws Exception {
    when(store.consume(anyList())).thenThrow(
        new AuthRateLimitStoreUnavailableException(new IllegalStateException("redis offline")));

    mvc.perform(post("/auth/refresh")
            .header("X-Request-Id", "rate-limit-unavailable-test")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "refresh_token": "opaque-refresh-token",
                  "device_id": "install-123"
                }
                """))
        .andExpect(status().isServiceUnavailable())
        .andExpect(header().string("Retry-After", "5"))
        .andExpect(header().string("Cache-Control", "no-store"))
        .andExpect(jsonPath("$.error.code").value("AUTH_SERVICE_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.request_id").value("rate-limit-unavailable-test"));
  }
}
