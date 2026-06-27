package com.speakeasy.identity;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OtpFailureLockRepository extends JpaRepository<OtpFailureLock, UUID> {
  Optional<OtpFailureLock> findByPhoneHashAndPurpose(String phoneHash, String purpose);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select failureLock from OtpFailureLock failureLock where failureLock.phoneHash = :phoneHash and failureLock.purpose = :purpose")
  Optional<OtpFailureLock> findByPhoneHashAndPurposeForUpdate(
      @Param("phoneHash") String phoneHash, @Param("purpose") String purpose);
}
