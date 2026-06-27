package com.speakeasy.identity;

import java.time.Duration;
import org.springframework.stereotype.Component;

@Component
public class OtpSmsTemplate {
  public String render(String code, Duration ttl) {
    long minutes = Math.max(1, ttl.toMinutes());
    return "SpeakEasy code %s expires in %d minutes. Never share it with anyone.".formatted(code, minutes);
  }
}
