package com.speakeasy.identity.provider;

public enum PhoneVerificationPurpose {
  LOGIN("login"),
  ACCOUNT_RECOVERY("account_recovery");

  private final String wireValue;

  PhoneVerificationPurpose(String wireValue) {
    this.wireValue = wireValue;
  }

  public String wireValue() {
    return wireValue;
  }
}
