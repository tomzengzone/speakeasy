package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpSendFlowTest extends OtpIntegrationTestSupport {
  @Test
  void sendOtpCreatesChallengeButNoAccountOrSession() throws Exception {
    requestOtp("13800138100")
        .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk())
        .andExpect(jsonPath("$.schema_version").value(2))
        .andExpect(jsonPath("$.challenge_id").isNotEmpty())
        .andExpect(jsonPath("$.expires_at").isNotEmpty())
        .andExpect(jsonPath("$.resend_after_seconds").value(60))
        .andExpect(jsonPath("$.risk_decision").value("allow"));

    verify(smsProvider).send(anyString(), anyString());
    assertThat(challenges.count()).isEqualTo(1);
    assertThat(users.count()).isZero();
    assertThat(identities.count()).isZero();
    assertThat(sessions.count()).isZero();
  }
}
