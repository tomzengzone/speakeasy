package com.speakeasy.ops;

import com.speakeasy.ai.AiRetentionJob;
import com.speakeasy.ai.AiRetentionService;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountDeletionRetentionRunner {
  private final AiRetentionService aiRetentionService;

  public AccountDeletionRetentionRunner(AiRetentionService aiRetentionService) {
    this.aiRetentionService = aiRetentionService;
  }

  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public AiRetentionJob runAccountDeletion(UUID userId, String idempotencyKey, String requestId) {
    return aiRetentionService.runAccountDeletion(userId, idempotencyKey, requestId);
  }
}
