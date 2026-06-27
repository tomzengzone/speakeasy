package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;
import org.junit.jupiter.api.Test;

class OtpVerifierHashTest {
  @Test
  void hmacBindsChallengePhoneAndCode() {
    OtpHashService hashService = new OtpHashService(new OtpProperties());
    UUID challengeId = UUID.randomUUID();

    String digest = hashService.hmacDigest(challengeId, "+8613800138000", "123456");

    assertThat(hashService.constantTimeEquals(digest, hashService.hmacDigest(challengeId, "+8613800138000", "123456")))
        .isTrue();
    assertThat(hashService.constantTimeEquals(digest, hashService.hmacDigest(challengeId, "+8613800138001", "123456")))
        .isFalse();
    assertThat(hashService.constantTimeEquals(digest, hashService.hmacDigest(challengeId, "+8613800138000", "654321")))
        .isFalse();
  }
}
