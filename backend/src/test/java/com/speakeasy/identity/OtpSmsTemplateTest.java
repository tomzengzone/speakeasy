package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class OtpSmsTemplateTest {
  @Test
  void rendersOnlySafeSmsContent() {
    String message = new OtpSmsTemplate().render("123456", Duration.ofMinutes(5));

    assertThat(message).contains("SpeakEasy", "123456", "5 minutes");
    assertThat(message.toLowerCase()).doesNotContain("user_id", "access_token", "refresh_token", "session");
  }
}
