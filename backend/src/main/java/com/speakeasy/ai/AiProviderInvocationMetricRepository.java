package com.speakeasy.ai;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AiProviderInvocationMetricRepository extends JpaRepository<AiProviderInvocationMetric, UUID> {
  List<AiProviderInvocationMetric> findByCreatedAtGreaterThanEqual(Instant createdAt);

  long deleteByUserHash(String userHash);
}
