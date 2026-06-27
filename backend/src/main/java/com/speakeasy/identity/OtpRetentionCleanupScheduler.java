package com.speakeasy.identity;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "speakeasy.identity.otp", name = "retention-cleanup-enabled", havingValue = "true")
public class OtpRetentionCleanupScheduler {
  private final OtpService otpService;

  public OtpRetentionCleanupScheduler(OtpService otpService) {
    this.otpService = otpService;
  }

  @Scheduled(fixedDelayString = "${speakeasy.identity.otp.retention-cleanup-fixed-delay:PT1H}")
  public void runScheduledCleanup() {
    runOnceForOperator();
  }

  int runOnceForOperator() {
    return otpService.invalidateExpiredChallengeMaterial();
  }
}
