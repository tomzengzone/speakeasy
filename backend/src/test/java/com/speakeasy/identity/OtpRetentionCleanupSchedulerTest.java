package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.Test;

class OtpRetentionCleanupSchedulerTest {
  @Test
  void schedulerUsesExistingOtpCleanupBoundary() {
    OtpService otpService = mock(OtpService.class);
    when(otpService.invalidateExpiredChallengeMaterial()).thenReturn(3);

    OtpRetentionCleanupScheduler scheduler = new OtpRetentionCleanupScheduler(otpService);

    assertThat(scheduler.runOnceForOperator()).isEqualTo(3);
    verify(otpService).invalidateExpiredChallengeMaterial();
  }
}
