package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(properties = "speakeasy.identity.otp.captcha-required=true")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpCaptchaTest extends OtpIntegrationTestSupport {
  @Test
  void captchaRequiredBlocksOtpSendBeforeProviderCall() throws Exception {
    mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "13800138104",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1"
                }
                """))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_CAPTCHA_REQUIRED"));

    verify(smsProvider, never()).send(anyString(), anyString());
  }

  @Test
  void captchaTokenDoesNotPassWithoutServerVerifier() throws Exception {
    mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "13800138124",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1",
                  "captcha_token": "client-supplied-token"
                }
                """))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("PROVIDER_UNAVAILABLE"));

    verify(smsProvider, never()).send(anyString(), anyString());
  }
}
