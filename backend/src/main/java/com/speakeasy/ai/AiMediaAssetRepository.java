package com.speakeasy.ai;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiMediaAssetRepository extends JpaRepository<AiMediaAsset, UUID> {
  Optional<AiMediaAsset> findByUserIdAndClientUploadId(UUID userId, String clientUploadId);

  List<AiMediaAsset> findByDeletedAtIsNullAndExpiresAtBefore(Instant expiresAt);

  List<AiMediaAsset> findByUserIdAndDeletedAtIsNull(UUID userId);
}
