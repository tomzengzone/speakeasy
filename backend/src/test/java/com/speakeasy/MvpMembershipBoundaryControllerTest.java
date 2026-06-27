package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MvpMembershipBoundaryControllerTest extends BackendIntegrationTestSupport {
  @Test
  void membershipBoundaryDoesNotPretendCommercialReadiness() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138410");

    mvc.perform(get("/membership/boundary").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.membership.state").value("entry-only"))
        .andExpect(jsonPath("$.membership.commercial_status").value("commercial-not-ready"))
        .andExpect(jsonPath("$.membership.current_plan").value("free"))
        .andExpect(jsonPath("$.membership.platform_limits[0].platform").value("android"))
        .andExpect(jsonPath("$.membership.platform_limits[0].status").value("platform-limited"));
  }

  @Test
  void androidPurchaseAndRestoreReturnPlatformLimitedBoundary() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138411");

    mvc.perform(post("/membership/android/purchase").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.platform_limit.platform").value("android"))
        .andExpect(jsonPath("$.platform_limit.action").value("purchase"))
        .andExpect(jsonPath("$.platform_limit.status").value("platform-limited"))
        .andExpect(jsonPath("$.platform_limit.reason_code").value("ANDROID_BILLING_NOT_CONNECTED"));

    mvc.perform(post("/membership/android/restore").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.platform_limit.platform").value("android"))
        .andExpect(jsonPath("$.platform_limit.action").value("restore"))
        .andExpect(jsonPath("$.platform_limit.status").value("platform-limited"))
        .andExpect(jsonPath("$.platform_limit.reason_code").value("ANDROID_BILLING_NOT_CONNECTED"));
  }
}
