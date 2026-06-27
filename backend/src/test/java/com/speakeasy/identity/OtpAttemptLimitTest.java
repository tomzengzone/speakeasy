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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpAttemptLimitTest extends OtpIntegrationTestSupport {
  @Test
  void challengeLocksAfterMaxWrongAttemptsAndCannotLaterVerify() throws Exception {
    MvcResult send = sendOtp("13800138107");
    String challengeId = challengeId(send);
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138107"), messageCaptor.capture());
    String code = extractCode(messageCaptor.getValue());
    String wrongCode = wrongCode(code);

    for (int index = 0; index < 5; index++) {
      mvc.perform(post("/auth/login/phone")
              .contentType(MediaType.APPLICATION_JSON)
              .content(loginBody(challengeId, "13800138107", wrongCode)))
          .andExpect(status().isUnauthorized())
          .andExpect(jsonPath("$.error.code").value("OTP_INVALID_CODE"));
    }

    mvc.perform(post("/auth/login/phone")
            .contentType(MediaType.APPLICATION_JSON)
            .content(loginBody(challengeId, "13800138107", code)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("OTP_INVALID_CODE"));
  }

  private String loginBody(String challengeId, String phoneNumber, String code) {
    return """
        {
          "schema_version": 2,
          "challenge_id": "%s",
          "phone_number": "%s",
          "verification_code": "%s",
          "terms_accepted": true
        }
        """.formatted(challengeId, phoneNumber, code);
  }
}
