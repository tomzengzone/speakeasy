package com.speakeasy.identity.provider;

public interface PhoneVerificationProvider {
  void requestCode(String phoneNumber);

  void verify(String phoneNumber, String verificationCode);
}
