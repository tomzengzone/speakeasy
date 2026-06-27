package com.speakeasy.identity;

public enum OtpStepUpStatus {
  NOT_REQUIRED("not_required"),
  PENDING("pending"),
  PASSED("passed"),
  FAILED("failed"),
  BLOCKED("blocked");

  private final String value;

  OtpStepUpStatus(String value) {
    this.value = value;
  }

  public String value() {
    return value;
  }

  public static OtpStepUpStatus fromValue(String value) {
    for (OtpStepUpStatus status : values()) {
      if (status.value.equals(value)) {
        return status;
      }
    }
    throw new IllegalArgumentException("Unknown OTP step-up status: " + value);
  }
}
