package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpConsumedCooldownTest extends OtpIntegrationTestSupport {
  @Test
  void consumedChallengeStillEnforcesPhoneResendCooldown() throws Exception {
    MvcResult send = sendOtp("13800138131");
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138131"), messageCaptor.capture());

    loginOtp(challengeId(send), "13800138131", extractCode(messageCaptor.getValue()))
        .andExpect(status().isOk());

    requestOtp("13800138131")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("OTP_RATE_LIMITED"));

    verify(smsProvider, times(1)).send(eq("+8613800138131"), org.mockito.ArgumentMatchers.anyString());
  }
}
