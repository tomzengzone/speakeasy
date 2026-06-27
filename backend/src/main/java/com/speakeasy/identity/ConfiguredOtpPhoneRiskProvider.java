package com.speakeasy.identity;

import org.springframework.stereotype.Component;

@Component
public class ConfiguredOtpPhoneRiskProvider implements OtpPhoneRiskProvider {
  private final OtpProperties properties;

  public ConfiguredOtpPhoneRiskProvider(OtpProperties properties) {
    this.properties = properties;
  }

  @Override
  public OtpRiskDecision assess(OtpPhoneRiskRequest request) {
    return switch (properties.getRiskMode()) {
      case "block" -> OtpRiskDecision.BLOCK;
      case "step_up" -> OtpRiskDecision.STEP_UP;
      default -> OtpRiskDecision.ALLOW;
    };
  }
}
