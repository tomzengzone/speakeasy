package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class OtpRetentionCleanupTest extends OtpIntegrationTestSupport {
  @Autowired OtpService otpService;
  @Autowired OtpHashService hashService;

  @Test
  void cleanupInvalidatesExpiredChallengeMaterialAfterRetentionWindow() {
    Instant now = Instant.now().minus(26, ChronoUnit.HOURS);
    UUID challengeId = UUID.randomUUID();
    String phone = "+8613800138109";
    challenges.save(new OtpChallenge(
        challengeId,
        phone,
        hashService.sha256(phone),
        OtpService.PURPOSE_LOGIN_OR_REGISTER,
        "hmac-sha256-v1",
        hashService.hmacDigest(challengeId, phone, "123456"),
        now,
        now,
        now.plus(5, ChronoUnit.MINUTES),
        5,
        "context",
        OtpRiskDecision.ALLOW,
        OtpStepUpStatus.NOT_REQUIRED,
        "req-retention",
        "otp-retention-v1",
        now));

    assertThat(otpService.invalidateExpiredChallengeMaterial()).isEqualTo(1);

    assertThat(challenges.findById(challengeId).orElseThrow().getStatus()).isEqualTo(OtpChallengeStatus.INVALIDATED);
  }
}
