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

@SpringBootTest(properties = "speakeasy.identity.otp.resend-cooldown=1ms")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpResendInvalidationTest extends OtpIntegrationTestSupport {
  @Test
  void resendInvalidatesPreviousActiveChallengeWithoutResettingFlow() throws Exception {
    MvcResult first = sendOtp("13800138110");
    Thread.sleep(5);
    MvcResult second = sendOtp("13800138110");

    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider, times(2)).send(eq("+8613800138110"), messageCaptor.capture());
    List<String> messages = messageCaptor.getAllValues();
    String firstCode = extractCode(messages.get(0));
    String secondCode = extractCode(messages.get(1));

    loginOtp(challengeId(first), "13800138110", firstCode)
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("OTP_INVALID_CODE"));
    loginOtp(challengeId(second), "13800138110", secondCode)
        .andExpect(status().isOk());
  }
}
