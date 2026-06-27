package com.speakeasy.identity;

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
class OtpSchemaValidationTest extends OtpIntegrationTestSupport {
  @Test
  void malformedOtpCodeIsRejectedBySchemaBeforeVerifier() throws Exception {
    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "11111111-1111-1111-1111-111111111111",
                  "phone_number": "13800138132",
                  "verification_code": "abcdef",
                  "terms_accepted": true
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }

  @Test
  void shortCaptchaTokenIsRejectedBySchemaBeforeProviderBoundary() throws Exception {
    mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "13800138133",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1",
                  "captcha_token": "short"
                }
                """))
        .andExpect(status().isUnprocessableEntity())
        .andExpect(jsonPath("$.error.code").value("SCHEMA_VALIDATION_FAILED"));
  }
}
