package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class OtpCodeGeneratorTest {
  @Test
  void generatesSixDigitNumericCodesByDefault() {
    OtpCodeGenerator generator = new OtpCodeGenerator(new OtpProperties());

    for (int index = 0; index < 20; index++) {
      assertThat(generator.generate()).matches("\\d{6}");
    }
  }

  @Test
  void refusesConfiguredLengthBelowSix() {
    OtpProperties properties = new OtpProperties();
    properties.setCodeLength(4);

    assertThat(new OtpCodeGenerator(properties).generate()).matches("\\d{6}");
  }
}
