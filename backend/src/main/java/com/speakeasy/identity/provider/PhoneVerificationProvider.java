package com.speakeasy.identity.provider;

public interface PhoneVerificationProvider {
  void requestCode(String phoneNumber, PhoneVerificationPurpose purpose);

  void verify(String phoneNumber, String verificationCode, PhoneVerificationPurpose purpose);

  default void requestCode(String phoneNumber) {
    requestCode(phoneNumber, PhoneVerificationPurpose.LOGIN);
  }

  default void verify(String phoneNumber, String verificationCode) {
    verify(phoneNumber, verificationCode, PhoneVerificationPurpose.LOGIN);
  }
}
