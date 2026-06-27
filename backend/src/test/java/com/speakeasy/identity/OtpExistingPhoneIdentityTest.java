package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.identity.otp.resend-cooldown=1ms")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpExistingPhoneIdentityTest extends OtpIntegrationTestSupport {
  @Test
  void existingVerifiedPhoneIdentityResolvesOriginalUser() throws Exception {
    MvcResult firstSend = sendOtp("13800138113");
    ArgumentCaptor<String> messageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider).send(eq("+8613800138113"), messageCaptor.capture());

    MvcResult firstLogin = loginOtp(challengeId(firstSend), "13800138113", extractCode(messageCaptor.getValue()))
        .andExpect(status().isOk())
        .andReturn();
    MvcResult secondSend = sendOtp("13800138113");
    ArgumentCaptor<String> secondMessageCaptor = ArgumentCaptor.forClass(String.class);
    verify(smsProvider, times(2)).send(eq("+8613800138113"), secondMessageCaptor.capture());
    List<String> messages = secondMessageCaptor.getAllValues();
    MvcResult secondLogin = loginOtp(challengeId(secondSend), "13800138113", extractCode(messages.get(1)))
        .andExpect(status().isOk())
        .andReturn();

    assertThat(JsonPath.<String>read(secondLogin.getResponse().getContentAsString(), "$.user.user_id"))
        .isEqualTo(JsonPath.read(firstLogin.getResponse().getContentAsString(), "$.user.user_id"));
    assertThat(users.count()).isEqualTo(1);
    assertThat(identities.count()).isEqualTo(1);
  }
}
