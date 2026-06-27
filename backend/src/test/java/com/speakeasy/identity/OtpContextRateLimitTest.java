package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(properties = "speakeasy.identity.otp.max-device-sends-per-hour=1")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpContextRateLimitTest extends OtpIntegrationTestSupport {
  @Test
  void deviceContextLimitBlocksSecondPhoneSend() throws Exception {
    sendOtp("13800138116");

    requestOtp("13800138117")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("OTP_RATE_LIMITED"));

    verify(smsProvider, times(1)).send(anyString(), anyString());
  }
}
