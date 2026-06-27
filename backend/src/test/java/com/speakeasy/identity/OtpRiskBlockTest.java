package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(properties = "speakeasy.identity.otp.risk-mode=block")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpRiskBlockTest extends OtpIntegrationTestSupport {
  @Test
  void riskBlockDoesNotSendOtpOrCreateSession() throws Exception {
    requestOtp("13800138105")
        .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_RISK_BLOCKED"));

    verify(smsProvider, never()).send(anyString(), anyString());
    assertThat(challenges.count()).isZero();
    assertThat(sessions.count()).isZero();
  }
}
