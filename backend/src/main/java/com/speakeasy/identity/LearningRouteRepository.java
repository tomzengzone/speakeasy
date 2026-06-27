package com.speakeasy.identity;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LearningRouteRepository extends JpaRepository<LearningRoute, UUID> {
  Optional<LearningRoute> findFirstByUserIdOrderByUpdatedAtDesc(UUID userId);
}
