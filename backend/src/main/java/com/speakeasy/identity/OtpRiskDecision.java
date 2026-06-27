package com.speakeasy.identity;

public enum OtpRiskDecision {
  ALLOW("allow"),
  BLOCK("block"),
  STEP_UP("step_up");

  private final String value;

  OtpRiskDecision(String value) {
    this.value = value;
  }

  public String value() {
    return value;
  }

  public static OtpRiskDecision fromValue(String value) {
    for (OtpRiskDecision decision : values()) {
      if (decision.value.equals(value)) {
        return decision;
      }
    }
    throw new IllegalArgumentException("Unknown OTP risk decision: " + value);
  }
}
