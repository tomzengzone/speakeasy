package com.speakeasy.ops;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AccountDeletionJobRepository extends JpaRepository<AccountDeletionJob, UUID> {
  Optional<AccountDeletionJob> findFirstByUserIdOrderByRequestedAtDesc(UUID userId);

  Optional<AccountDeletionJob> findByUserIdAndIdempotencyKey(UUID userId, String idempotencyKey);
}
