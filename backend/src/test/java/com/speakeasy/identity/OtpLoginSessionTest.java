package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.not;
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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpLoginSessionTest extends OtpIntegrationTestSupport {
  @Test
  void consumedOtpCreatesSessionThroughExistingPhoneIdentityBoundaryAndRejectsReplay() throws Exception {
    MvcResult send = sendOtp("13800138101");
    String challengeId = challengeId(send);
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138101"), messageCaptor.capture());
    String code = extractCode(messageCaptor.getValue());

    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "%s",
                  "phone_number": "13800138101",
                  "verification_code": "%s",
                  "terms_accepted": true
                }
                """.formatted(challengeId, code)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.access_token", not(blankOrNullString())))
        .andExpect(jsonPath("$.refresh_token", not(blankOrNullString())));

    assertThat(identities.findByProviderAndProviderSubject("phone", "+8613800138101")).isPresent();
    assertThat(users.count()).isEqualTo(1);
    assertThat(sessions.count()).isEqualTo(1);

    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 2,
                  "challenge_id": "%s",
                  "phone_number": "13800138101",
                  "verification_code": "%s",
                  "terms_accepted": true
                }
                """.formatted(challengeId, code)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("OTP_INVALID_CODE"));
  }
}
