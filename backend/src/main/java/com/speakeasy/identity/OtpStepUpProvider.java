package com.speakeasy.identity;

import java.util.UUID;

public interface OtpStepUpProvider {
  OtpStepUpStatus verify(OtpStepUpVerification verification);

  record OtpStepUpVerification(
      UUID challengeId,
      String phoneHash,
      String purpose,
      String stepUpToken,
      OtpRequestContext context) {}
}
