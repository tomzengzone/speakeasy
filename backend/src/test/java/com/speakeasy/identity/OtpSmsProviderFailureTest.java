package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;

import com.speakeasy.common.ApiException;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpSmsProviderFailureTest extends OtpIntegrationTestSupport {
  @Test
  void providerFailureCreatesNoVerifiableChallengeOrSession() throws Exception {
    doThrow(new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "SMS failed."))
        .when(smsProvider).send(anyString(), anyString());

    requestOtp("13800138103")
        .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("PROVIDER_UNAVAILABLE"));

    assertThat(challenges.findAll())
        .hasSize(1)
        .allMatch(challenge -> OtpChallengeStatus.INVALIDATED.equals(challenge.getStatus()));
    assertThat(users.count()).isZero();
    assertThat(sessions.count()).isZero();
  }
}
