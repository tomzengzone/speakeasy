package com.speakeasy.identity;

import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AuthRefreshTokenFamilyRepository extends JpaRepository<AuthRefreshTokenFamily, UUID> {
  Optional<AuthRefreshTokenFamily> findBySessionId(UUID sessionId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select f from AuthRefreshTokenFamily f where f.familyId = :familyId")
  Optional<AuthRefreshTokenFamily> findByIdForUpdate(@Param("familyId") UUID familyId);
}
