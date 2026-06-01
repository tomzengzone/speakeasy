package com.speakeasy.ai;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiRetentionJobRepository extends JpaRepository<AiRetentionJob, UUID> {
  Optional<AiRetentionJob> findByIdempotencyKey(String idempotencyKey);
}
