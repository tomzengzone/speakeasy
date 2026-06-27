package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import java.util.Set;
import org.junit.jupiter.api.Test;

class OtpPhoneNormalizationTest {
  @Test
  void normalizesSupportedPhoneToE164() {
    OtpProperties properties = new OtpProperties();
    PhoneNumberNormalizer normalizer = new PhoneNumberNormalizer(properties);

    assertThat(normalizer.normalize("13800138000")).isEqualTo("+8613800138000");
    assertThat(normalizer.normalize("+1 415 555 2671")).isEqualTo("+14155552671");
  }

  @Test
  void rejectsInvalidOrUnsupportedPhone() {
    OtpProperties properties = new OtpProperties();
    properties.setAllowedCountries(Set.of("US"));
    PhoneNumberNormalizer normalizer = new PhoneNumberNormalizer(properties);

    assertThatThrownBy(() -> normalizer.normalize("13800138000"))
        .isInstanceOfSatisfying(ApiException.class, exception ->
            assertThat(exception.getCode()).isEqualTo("OTP_INVALID_PHONE"));
    assertThatThrownBy(() -> normalizer.normalize("not-a-phone"))
        .isInstanceOfSatisfying(ApiException.class, exception ->
            assertThat(exception.getCode()).isEqualTo("OTP_INVALID_PHONE"));
  }
}
