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

@SpringBootTest(properties = "speakeasy.identity.otp.max-ip-sends-per-day=1")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpIpDailyRateLimitTest extends OtpIntegrationTestSupport {
  @Test
  void ipDailyLimitBlocksSecondPhoneSendAcrossDeviceContexts() throws Exception {
    sendOtp("13800138125");

    requestOtp("13800138126", "device-otp-test-2", "install-otp-test-2")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("OTP_RATE_LIMITED"));

    verify(smsProvider, times(1)).send(anyString(), anyString());
  }
}
