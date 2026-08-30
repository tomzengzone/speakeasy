package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.common.ApiException;
import com.speakeasy.identity.provider.PhoneVerificationProvider;
import com.speakeasy.identity.provider.PhoneVerificationPurpose;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.auth.account-recovery-enabled=true")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PhoneAccountRecoveryProviderFailureTest {
  @Autowired MockMvc mvc;
  @MockBean(name = "phoneVerificationProvider") PhoneVerificationProvider phoneVerification;

  @Test
  void expiredAndInvalidCodesHaveTheSamePrivacySafeHttpContract() throws Exception {
    String phone = "+8613800138660";
    doThrow(providerRejected()).when(phoneVerification).verify(
        eq(phone), anyString(), eq(PhoneVerificationPurpose.ACCOUNT_RECOVERY));

    MvcResult expired = complete(phone, "000001", "req-recovery-code-a")
        .andExpect(status().isUnauthorized())
        .andReturn();
    MvcResult invalid = complete(phone, "999999", "req-recovery-code-b")
        .andExpect(status().isUnauthorized())
        .andReturn();

    assertPrivacySafeVerificationFailure(expired, "req-recovery-code-a");
    assertPrivacySafeVerificationFailure(invalid, "req-recovery-code-b");
    assertThat(normalizedErrorBody(expired)).isEqualTo(normalizedErrorBody(invalid));
  }

  @Test
  void providerUnavailabilityIsRetryableAndNoStoreForBothRecoveryEndpoints()
      throws Exception {
    String phone = "+8613800138661";
    doThrow(providerUnavailable()).when(phoneVerification).requestCode(
        phone, PhoneVerificationPurpose.ACCOUNT_RECOVERY);
    doThrow(providerUnavailable()).when(phoneVerification).verify(
        phone, "654321", PhoneVerificationPurpose.ACCOUNT_RECOVERY);

    mvc.perform(post("/auth/account-recovery/phone/verification-codes")
            .header("X-Request-Id", "req-recovery-provider-request")
            .contentType(MediaType.APPLICATION_JSON)
            .content(requestCodeBody(phone)))
        .andExpect(status().isServiceUnavailable())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "no-store"))
        .andExpect(header().string("X-Request-Id", "req-recovery-provider-request"))
        .andExpect(jsonPath("$.error.code").value("AUTH_SERVICE_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));

    complete(phone, "654321", "req-recovery-provider-complete")
        .andExpect(status().isServiceUnavailable())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "no-store"))
        .andExpect(header().string("X-Request-Id", "req-recovery-provider-complete"))
        .andExpect(jsonPath("$.error.code").value("AUTH_SERVICE_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));
  }

  private org.springframework.test.web.servlet.ResultActions complete(
      String phone, String code, String requestId) throws Exception {
    return mvc.perform(post("/auth/account-recovery/phone")
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "phone_number": "%s",
              "verification_code": "%s",
              "device_id": "install-provider-failure"
            }
            """.formatted(phone, code)));
  }

  private void assertPrivacySafeVerificationFailure(MvcResult result, String requestId)
      throws Exception {
    assertThat(result.getResponse().getHeader(HttpHeaders.CACHE_CONTROL)).isEqualTo("no-store");
    assertThat(result.getResponse().getHeader("X-Request-Id")).isEqualTo(requestId);
    String body = result.getResponse().getContentAsString();
    assertThat(body)
        .contains("\"code\":\"ACCOUNT_RECOVERY_VERIFICATION_FAILED\"")
        .contains("\"message\":\"Account recovery could not be verified.\"")
        .contains("\"details\":{}")
        .doesNotContain("expired", "invalid", "phone", "identity", "session", "token");
  }

  private String normalizedErrorBody(MvcResult result) throws Exception {
    return result.getResponse().getContentAsString()
        .replace("req-recovery-code-a", "request-id")
        .replace("req-recovery-code-b", "request-id");
  }

  private String requestCodeBody(String phone) {
    return """
        {
          "schema_version": 1,
          "phone_number": "%s",
          "device_id": "install-provider-failure"
        }
        """.formatted(phone);
  }

  private ApiException providerRejected() {
    return new ApiException(
        HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Provider rejected verification.");
  }

  private ApiException providerUnavailable() {
    return new ApiException(
        HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "Provider unavailable.");
  }
}
