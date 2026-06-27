package com.speakeasy.ai;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiTtsCacheEntryRepository extends JpaRepository<AiTtsCacheEntry, UUID> {
  Optional<AiTtsCacheEntry> findByCacheKey(String cacheKey);

  List<AiTtsCacheEntry> findByStatusAndExpiresAtBefore(String status, Instant expiresAt);

  List<AiTtsCacheEntry> findByOwnerHashAndDeletedAtIsNull(String ownerHash);
}
