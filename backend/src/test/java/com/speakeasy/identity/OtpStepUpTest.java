package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.identity.otp.risk-mode=step_up")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpStepUpTest extends OtpIntegrationTestSupport {
  @Test
  void stepUpRiskDeniesSessionAndDoesNotTreatCaptchaAsStepUpProof() throws Exception {
    MvcResult send = sendOtp("13800138106");
    String challengeId = challengeId(send);
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138106"), messageCaptor.capture());
    String code = extractCode(messageCaptor.getValue());

    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "%s",
                  "phone_number": "13800138106",
                  "verification_code": "%s",
                  "terms_accepted": true
                }
                """.formatted(challengeId, code)))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_STEP_UP_REQUIRED"));

    mvc.perform(post("/auth/otp/step-up")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "%s",
                  "step_up_token": "captcha-token-is-not-step-up"
                }
                """.formatted(challengeId)))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("PROVIDER_UNAVAILABLE"));
  }
}
