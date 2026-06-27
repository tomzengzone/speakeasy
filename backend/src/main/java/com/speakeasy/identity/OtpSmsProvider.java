package com.speakeasy.identity;

public interface OtpSmsProvider {
  void send(String e164Phone, String message);
}
