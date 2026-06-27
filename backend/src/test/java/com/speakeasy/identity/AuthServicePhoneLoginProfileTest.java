package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AccountDeletionJobRepository;
import java.time.Clock;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;

class AuthServicePhoneLoginProfileTest {
  @Test
  void schemaVersionOnePhoneLoginIsRejectedOutsideTestProfile() {
    Environment environment = mock(Environment.class);
    when(environment.getActiveProfiles()).thenReturn(new String[] {"production"});
    AuthService authService = new AuthService(
        mock(UserAccountRepository.class),
        mock(UserProfileRepository.class),
        mock(AuthIdentityRepository.class),
        mock(AuthSessionRepository.class),
        mock(AccountDeletionJobRepository.class),
        mock(OtpService.class),
        mock(PhoneNumberNormalizer.class),
        Clock.systemUTC(),
        environment);

    assertThatThrownBy(() -> authService.loginPhone("+8613800138000", "123456", true))
        .isInstanceOfSatisfying(ApiException.class, exception -> {
          assertThat(exception.getStatus()).isEqualTo(HttpStatus.UNPROCESSABLE_ENTITY);
          assertThat(exception.getCode()).isEqualTo("SCHEMA_VALIDATION_FAILED");
        });
  }
}
