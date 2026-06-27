package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

@Component
public class DisabledOtpStepUpProvider implements OtpStepUpProvider {
  @Override
  public OtpStepUpStatus verify(OtpStepUpVerification verification) {
    throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "PROVIDER_UNAVAILABLE", "Step-up provider is not configured.");
  }
}
