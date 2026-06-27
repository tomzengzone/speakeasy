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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpConsentContractTest extends OtpIntegrationTestSupport {
  @Test
  void missingCurrentConsentBlocksSendBeforeProviderCall() throws Exception {
    mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "13800138114",
                  "terms_accepted": false,
                  "consent_version": "old-version"
                }
                """))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_CONSENT_REQUIRED"));

    verify(smsProvider, never()).send(anyString(), anyString());
  }
}
