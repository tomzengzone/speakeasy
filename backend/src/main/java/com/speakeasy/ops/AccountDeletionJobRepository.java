package com.speakeasy.ops;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AccountDeletionJobRepository extends JpaRepository<AccountDeletionJob, UUID> {
  Optional<AccountDeletionJob> findFirstByUserIdOrderByRequestedAtDesc(UUID userId);

  Optional<AccountDeletionJob> findByUserIdAndIdempotencyKey(UUID userId, String idempotencyKey);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select job from AccountDeletionJob job where job.deletionJobId = :deletionJobId")
  Optional<AccountDeletionJob> findByIdForUpdate(@Param("deletionJobId") UUID deletionJobId);
}
