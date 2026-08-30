package com.speakeasy.identity;

import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AuthRefreshTokenRepository extends JpaRepository<AuthRefreshToken, UUID> {
  interface TokenLocator {
    UUID getTokenId();
    UUID getFamilyId();
    UUID getSessionId();
    UUID getUserId();
  }

  Optional<TokenLocator> findProjectedByTokenHash(String tokenHash);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select t from AuthRefreshToken t where t.tokenId = :tokenId")
  Optional<AuthRefreshToken> findByIdForUpdate(@Param("tokenId") UUID tokenId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select t from AuthRefreshToken t where t.familyId = :familyId order by t.tokenId")
  List<AuthRefreshToken> findByFamilyIdForUpdate(@Param("familyId") UUID familyId);
}
