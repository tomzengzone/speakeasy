package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpRateLimitTest extends OtpIntegrationTestSupport {
  @Test
  void resendBeforeCooldownIsRateLimitedAndDoesNotSendSms() throws Exception {
    sendOtp("13800138102");

    mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "13800138102",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1"
                }
                """))
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("OTP_RATE_LIMITED"));

    verify(smsProvider, times(1)).send(anyString(), anyString());
  }
}
