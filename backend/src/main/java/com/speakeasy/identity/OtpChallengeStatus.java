package com.speakeasy.identity;

public enum OtpChallengeStatus {
  PENDING("pending"),
  ACTIVE("active"),
  CONSUMED("consumed"),
  EXPIRED("expired"),
  INVALIDATED("invalidated"),
  LOCKED("locked");

  private final String value;

  OtpChallengeStatus(String value) {
    this.value = value;
  }

  public String value() {
    return value;
  }

  public static OtpChallengeStatus fromValue(String value) {
    for (OtpChallengeStatus status : values()) {
      if (status.value.equals(value)) {
        return status;
      }
    }
    throw new IllegalArgumentException("Unknown OTP challenge status: " + value);
  }
}
