package com.speakeasy.ops;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AccountDeletionRetryIdempotencyRepository extends JpaRepository<AccountDeletionRetryIdempotency, UUID> {
  Optional<AccountDeletionRetryIdempotency> findByDeletionJobIdAndIdempotencyKey(UUID deletionJobId, String idempotencyKey);
}
