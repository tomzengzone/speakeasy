package com.speakeasy.training;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingTurnRepository extends JpaRepository<TrainingTurn, UUID> {
  Optional<TrainingTurn> findByTrainingSessionIdAndIdempotencyKey(UUID trainingSessionId, String idempotencyKey);

  List<TrainingTurn> findByTrainingSessionIdOrderByTurnIndexAsc(UUID trainingSessionId);
}
