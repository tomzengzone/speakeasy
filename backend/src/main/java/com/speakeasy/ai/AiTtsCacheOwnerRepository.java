package com.speakeasy.ai;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiTtsCacheOwnerRepository extends JpaRepository<AiTtsCacheOwner, UUID> {
  Optional<AiTtsCacheOwner> findByCacheIdAndOwnerHash(UUID cacheId, String ownerHash);

  List<AiTtsCacheOwner> findByOwnerHash(String ownerHash);

  long countByCacheId(UUID cacheId);

  long deleteByCacheId(UUID cacheId);
}
