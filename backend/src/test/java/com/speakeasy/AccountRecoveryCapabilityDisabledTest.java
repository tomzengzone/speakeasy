package com.speakeasy;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.identity.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AccountRecoveryCapabilityDisabledTest extends BackendIntegrationTestSupport {
  @SpyBean AuthService authService;

  @Test
  void defaultDisabledCapabilityRejectsCodeRequestsBeforeProviderOrIdentityEffects()
      throws Exception {
    long usersBefore = users.count();
    long sessionsBefore = sessions.count();

    mvc.perform(post("/auth/account-recovery/phone/verification-codes")
            .header("X-Request-Id", "req-recovery-disabled-code")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138690",
                  "device_id": "install-recovery-disabled"
                }
                """))
        .andExpect(status().isServiceUnavailable())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, containsString("no-store")))
        .andExpect(header().string("X-Request-Id", "req-recovery-disabled-code"))
        .andExpect(jsonPath("$.error.code").value("AUTH_SERVICE_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));

    verify(authService, never()).requestPhoneAccountRecoveryCode(anyString());
    org.assertj.core.api.Assertions.assertThat(users.count()).isEqualTo(usersBefore);
    org.assertj.core.api.Assertions.assertThat(sessions.count()).isEqualTo(sessionsBefore);
  }

  @Test
  void defaultDisabledCapabilityRejectsCompletionBeforeProviderOrSessionEffects()
      throws Exception {
    long usersBefore = users.count();
    long sessionsBefore = sessions.count();

    mvc.perform(post("/auth/account-recovery/phone")
            .header("X-Request-Id", "req-recovery-disabled-complete")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "phone_number": "+8613800138691",
                  "verification_code": "654321",
                  "device_id": "install-recovery-disabled"
                }
                """))
        .andExpect(status().isServiceUnavailable())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, containsString("no-store")))
        .andExpect(header().string("X-Request-Id", "req-recovery-disabled-complete"))
        .andExpect(jsonPath("$.error.code").value("AUTH_SERVICE_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));

    verify(authService, never()).recoverPhoneAccount(anyString(), anyString(), anyString());
    org.assertj.core.api.Assertions.assertThat(users.count()).isEqualTo(usersBefore);
    org.assertj.core.api.Assertions.assertThat(sessions.count()).isEqualTo(sessionsBefore);
  }
}
