package com.speakeasy.identity;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OtpRateCounterRepository extends JpaRepository<OtpRateCounter, UUID> {
  Optional<OtpRateCounter> findBySubjectTypeAndSubjectHashAndPurposeAndWindowStartAndWindowEnd(
      String subjectType, String subjectHash, String purpose, Instant windowStart, Instant windowEnd);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select counter from OtpRateCounter counter where counter.subjectType = :subjectType and counter.subjectHash = :subjectHash and counter.purpose = :purpose and counter.windowStart = :windowStart and counter.windowEnd = :windowEnd")
  Optional<OtpRateCounter> findByUniqueKeyForUpdate(
      @Param("subjectType") String subjectType,
      @Param("subjectHash") String subjectHash,
      @Param("purpose") String purpose,
      @Param("windowStart") Instant windowStart,
      @Param("windowEnd") Instant windowEnd);
}
