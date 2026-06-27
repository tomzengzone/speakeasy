package com.speakeasy.identity;

import com.google.i18n.phonenumbers.NumberParseException;
import com.google.i18n.phonenumbers.PhoneNumberUtil;
import com.google.i18n.phonenumbers.Phonenumber.PhoneNumber;
import com.speakeasy.common.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class PhoneNumberNormalizer {
  private final PhoneNumberUtil phoneNumberUtil = PhoneNumberUtil.getInstance();
  private final OtpProperties properties;

  public PhoneNumberNormalizer(OtpProperties properties) {
    this.properties = properties;
  }

  public String normalize(String rawPhoneNumber) {
    String cleaned = rawPhoneNumber == null ? "" : rawPhoneNumber.trim();
    if (cleaned.isBlank()) {
      throw invalidPhone();
    }
    try {
      PhoneNumber parsed = phoneNumberUtil.parse(cleaned, properties.getDefaultRegion());
      if (!phoneNumberUtil.isValidNumber(parsed)) {
        throw invalidPhone();
      }
      String region = phoneNumberUtil.getRegionCodeForNumber(parsed);
      if (region == null || !properties.getAllowedCountries().contains(region)) {
        throw invalidPhone();
      }
      return phoneNumberUtil.format(parsed, PhoneNumberUtil.PhoneNumberFormat.E164);
    } catch (NumberParseException exception) {
      throw invalidPhone();
    }
  }

  private ApiException invalidPhone() {
    return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "OTP_INVALID_PHONE", "Phone number is invalid or unsupported.");
  }
}
