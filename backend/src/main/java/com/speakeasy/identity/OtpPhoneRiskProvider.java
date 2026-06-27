package com.speakeasy.identity;

public interface OtpPhoneRiskProvider {
  OtpRiskDecision assess(OtpPhoneRiskRequest request);

  record OtpPhoneRiskRequest(String phoneE164, String phoneHash, String purpose, OtpRequestContext context) {}
}
