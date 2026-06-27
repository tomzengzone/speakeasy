package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class DisabledOtpSmsProvider implements OtpSmsProvider {
  @Override
  public void send(String e164Phone, String message) {
    throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "OTP SMS provider is not configured.");
  }
}
