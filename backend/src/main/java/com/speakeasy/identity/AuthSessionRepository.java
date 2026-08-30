package com.speakeasy.identity;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthSessionRepository extends JpaRepository<AuthSession, UUID> {
  List<AuthSession> findByUserIdAndStatus(UUID userId, String status);

  List<AuthSession> findByUserIdOrderByLastActiveAtDesc(UUID userId);

  Optional<AuthSession> findBySessionIdAndUserId(UUID sessionId, UUID userId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select s from AuthSession s where s.sessionId = :sessionId")
  Optional<AuthSession> findByIdForUpdate(@Param("sessionId") UUID sessionId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select s from AuthSession s where s.userId = :userId order by s.sessionId")
  List<AuthSession> findByUserIdForUpdate(@Param("userId") UUID userId);
}
