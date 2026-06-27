package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = {
    "speakeasy.identity.otp.resend-cooldown=1ms",
    "speakeasy.identity.otp.phone-failure-lock-threshold=2"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpFailureLockTest extends OtpIntegrationTestSupport {
  @Test
  void phonePurposeFailureThresholdLocksSendAndVerify() throws Exception {
    MvcResult first = sendOtp("13800138111");
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138111"), messageCaptor.capture());
    loginOtp(challengeId(first), "13800138111", wrongCode(extractCode(messageCaptor.getValue())))
        .andExpect(status().isUnauthorized());

    Thread.sleep(5);
    MvcResult second = sendOtp("13800138111");
    ArgumentCaptor<String> secondMessageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider, times(2)).send(eq("+8613800138111"), secondMessageCaptor.capture());
    List<String> messages = secondMessageCaptor.getAllValues();
    loginOtp(challengeId(second), "13800138111", wrongCode(extractCode(messages.get(1))))
        .andExpect(status().isUnauthorized());

    requestOtp("13800138111")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("OTP_ATTEMPTS_LOCKED"));
  }
}
