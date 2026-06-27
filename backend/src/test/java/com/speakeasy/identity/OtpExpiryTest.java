package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.identity.otp.challenge-ttl=1ms")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpExpiryTest extends OtpIntegrationTestSupport {
  @Test
  void expiredChallengeCannotCreateSession() throws Exception {
    MvcResult send = sendOtp("13800138115");
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138115"), messageCaptor.capture());
    Thread.sleep(5);

    loginOtp(challengeId(send), "13800138115", extractCode(messageCaptor.getValue()))
        .andExpect(status().isGone())
        .andExpect(jsonPath("$.error.code").value("OTP_EXPIRED"));
  }
}
