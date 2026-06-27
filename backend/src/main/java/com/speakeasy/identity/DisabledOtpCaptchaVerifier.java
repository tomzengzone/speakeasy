package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class DisabledOtpCaptchaVerifier implements OtpCaptchaVerifier {
  @Override
  public void verify(String captchaToken, OtpRequestContext context) {
    throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "CAPTCHA provider is not configured.");
  }
}
