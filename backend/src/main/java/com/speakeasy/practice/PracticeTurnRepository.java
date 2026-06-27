package com.speakeasy.practice;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PracticeTurnRepository extends JpaRepository<PracticeTurn, UUID> {
  Optional<PracticeTurn> findBySessionIdAndIdempotencyKey(UUID sessionId, String idempotencyKey);

  List<PracticeTurn> findBySessionIdOrderByTurnIndexAsc(UUID sessionId);
}
