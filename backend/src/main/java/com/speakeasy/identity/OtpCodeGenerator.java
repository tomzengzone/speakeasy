package com.speakeasy.identity;

import java.security.SecureRandom;
import org.springframework.stereotype.Component;

@Component
public class OtpCodeGenerator {
  private final SecureRandom secureRandom = new SecureRandom();
  private final OtpProperties properties;

  public OtpCodeGenerator(OtpProperties properties) {
    this.properties = properties;
  }

  public String generate() {
    int length = properties.getCodeLength();
    StringBuilder builder = new StringBuilder(length);
    for (int index = 0; index < length; index++) {
      builder.append(secureRandom.nextInt(10));
    }
    return builder.toString();
  }
}
