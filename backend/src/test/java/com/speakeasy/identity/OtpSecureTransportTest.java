package com.speakeasy.identity;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import org.mockito.ArgumentCaptor;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = {
    "speakeasy.identity.otp.enforce-secure-transport=true",
    "speakeasy.identity.otp.risk-mode=step_up"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpSecureTransportTest extends OtpIntegrationTestSupport {
  @Test
  void insecureTransportIsRejectedBeforeProviderCall() throws Exception {
    requestOtp("13800138112")
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_INSECURE_TRANSPORT"));

    verify(smsProvider, never()).send(anyString(), anyString());
  }

  @Test
  void forwardedProtoIsRejectedWhenProxyTrustIsNotConfigured() throws Exception {
    mvc.perform(post("/auth/otp/send")
            .contentType(MediaType.APPLICATION_JSON)
            .header("X-Forwarded-Proto", "https")
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "13800138112",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1"
                }
                """))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_INSECURE_TRANSPORT"));

    verify(smsProvider, never()).send(anyString(), anyString());
  }

  @Test
  void insecurePhoneLoginVerifyIsRejectedBeforeChallengeConsumption() throws Exception {
    MvcResult send = requestOtpSecure("13800138128");
    String challengeId = JsonPath.read(send.getResponse().getContentAsString(), "$.challenge_id");
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(anyString(), messageCaptor.capture());

    loginOtp(challengeId, "13800138128", extractCode(messageCaptor.getValue()))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("OTP_INSECURE_TRANSPORT"));
  }

  @Test
  void insecureStepUpIsRejectedBeforeProviderBoundary() throws Exception {
    MvcResult send = requestOtpSecure("13800138129");
    String challengeId = JsonPath.read(send.getResponse().getContentAsString(), "$.challenge_id");

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
        .andExpect(jsonPath("$.error.code").value("OTP_INSECURE_TRANSPORT"));
  }

  private MvcResult requestOtpSecure(String phoneNumber) throws Exception {
    return mvc.perform(post("/auth/otp/send")
            .secure(true)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "phone_number": "%s",
                  "terms_accepted": true,
                  "consent_version": "terms-privacy-v1"
                }
                """.formatted(phoneNumber)))
        .andExpect(status().isOk())
        .andReturn();
  }
}
