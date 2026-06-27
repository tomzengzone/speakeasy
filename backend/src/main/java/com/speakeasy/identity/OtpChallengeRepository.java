package com.speakeasy.identity;

import jakarta.persistence.LockModeType;
import java.time.Instant;
import java.util.Collection;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

public interface OtpChallengeRepository extends JpaRepository<OtpChallenge, UUID> {
  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select challenge from OtpChallenge challenge where challenge.challengeId = :challengeId and challenge.status = :status")
  Optional<OtpChallenge> findByChallengeIdAndStatusForUpdate(
      @Param("challengeId") UUID challengeId, @Param("status") OtpChallengeStatus status);

  default Optional<OtpChallenge> findActiveByIdForUpdate(UUID challengeId) {
    return findByChallengeIdAndStatusForUpdate(challengeId, OtpChallengeStatus.ACTIVE);
  }

  Optional<OtpChallenge> findFirstByPhoneHashAndPurposeAndStatusOrderByCreatedAtDesc(
      String phoneHash, String purpose, OtpChallengeStatus status);

  Optional<OtpChallenge> findFirstByPhoneHashAndPurposeAndStatusInOrderBySentAtDesc(
      String phoneHash, String purpose, Collection<OtpChallengeStatus> statuses);

  default Optional<OtpChallenge> findLatestActiveByPhoneHashAndPurpose(String phoneHash, String purpose) {
    return findFirstByPhoneHashAndPurposeAndStatusOrderByCreatedAtDesc(phoneHash, purpose, OtpChallengeStatus.ACTIVE);
  }

  default Optional<OtpChallenge> findLatestSuccessfulSendByPhoneHashAndPurpose(String phoneHash, String purpose) {
    return findFirstByPhoneHashAndPurposeAndStatusInOrderBySentAtDesc(
        phoneHash,
        purpose,
        java.util.List.of(
            OtpChallengeStatus.ACTIVE,
            OtpChallengeStatus.CONSUMED,
            OtpChallengeStatus.EXPIRED,
            OtpChallengeStatus.LOCKED));
  }

  @Transactional
  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query("update OtpChallenge challenge set challenge.status = :expiredStatus, challenge.updatedAt = :updatedAt where challenge.status = :activeStatus and challenge.expiresAt <= :expiresBefore")
  int markExpiredActiveChallenges(
      @Param("expiresBefore") Instant expiresBefore,
      @Param("activeStatus") OtpChallengeStatus activeStatus,
      @Param("expiredStatus") OtpChallengeStatus expiredStatus,
      @Param("updatedAt") Instant updatedAt);

  default int markExpiredActiveChallenges(Instant expiresBefore, Instant updatedAt) {
    return markExpiredActiveChallenges(expiresBefore, OtpChallengeStatus.ACTIVE, OtpChallengeStatus.EXPIRED, updatedAt);
  }

  @Transactional
  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query("update OtpChallenge challenge set challenge.status = :invalidatedStatus, challenge.invalidatedAt = :invalidatedAt, challenge.updatedAt = :invalidatedAt where challenge.expiresAt <= :expiresBefore and challenge.status <> :consumedStatus")
  int invalidateExpiredChallenges(
      @Param("expiresBefore") Instant expiresBefore,
      @Param("invalidatedStatus") OtpChallengeStatus invalidatedStatus,
      @Param("consumedStatus") OtpChallengeStatus consumedStatus,
      @Param("invalidatedAt") Instant invalidatedAt);

  default int invalidateExpiredChallenges(Instant expiresBefore, Instant invalidatedAt) {
    return invalidateExpiredChallenges(
        expiresBefore, OtpChallengeStatus.INVALIDATED, OtpChallengeStatus.CONSUMED, invalidatedAt);
  }

  @Transactional
  long deleteByExpiresAtBefore(Instant expiresBefore);
}
