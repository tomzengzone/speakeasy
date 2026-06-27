package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.identity.otp.risk-mode=step_up")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpStepUpProviderBoundaryTest extends OtpIntegrationTestSupport {
  @MockBean OtpStepUpProvider stepUpProvider;

  @Test
  void passedStepUpProviderAllowsOtpVerificationToCreateSession() throws Exception {
    when(stepUpProvider.verify(any())).thenReturn(OtpStepUpStatus.PASSED);
    MvcResult send = sendOtp("13800138130");
    String challengeId = challengeId(send);
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138130"), messageCaptor.capture());
    String code = extractCode(messageCaptor.getValue());

    loginOtp(challengeId, "13800138130", code)
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_STEP_UP_REQUIRED"));

    mvc.perform(post("/auth/otp/step-up")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "%s",
                  "step_up_token": "step-up-proof-token"
                }
                """.formatted(challengeId)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.step_up_status").value("passed"));

    loginOtp(challengeId, "13800138130", code)
        .andExpect(status().isOk());

    ArgumentCaptor<OtpStepUpProvider.OtpStepUpVerification> verification =
        ArgumentCaptor.forClass(OtpStepUpProvider.OtpStepUpVerification.class);
    verify(stepUpProvider).verify(verification.capture());
    org.assertj.core.api.Assertions.assertThat(verification.getValue().stepUpToken()).isEqualTo("step-up-proof-token");
  }

  @Test
  void failedStepUpProviderDoesNotUnlockOtpVerification() throws Exception {
    when(stepUpProvider.verify(any())).thenReturn(OtpStepUpStatus.FAILED);
    MvcResult send = sendOtp("13800138134");
    String challengeId = challengeId(send);
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138134"), messageCaptor.capture());
    String code = extractCode(messageCaptor.getValue());

    mvc.perform(post("/auth/otp/step-up")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "%s",
                  "step_up_token": "step-up-proof-token"
                }
                """.formatted(challengeId)))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_RISK_BLOCKED"));

    loginOtp(challengeId, "13800138134", code)
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_STEP_UP_REQUIRED"));

    org.assertj.core.api.Assertions.assertThat(users.count()).isZero();
    org.assertj.core.api.Assertions.assertThat(sessions.count()).isZero();
  }
}
