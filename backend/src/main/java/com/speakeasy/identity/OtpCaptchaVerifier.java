package com.speakeasy.identity;

public interface OtpCaptchaVerifier {
  void verify(String captchaToken, OtpRequestContext context);
}
