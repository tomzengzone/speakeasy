package com.speakeasy.training;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingPlannerDecisionRepository extends JpaRepository<TrainingPlannerDecision, UUID> {
  List<TrainingPlannerDecision> findByTrainingSessionIdOrderByCreatedAtAsc(UUID trainingSessionId);

  Optional<TrainingPlannerDecision> findFirstByTrainingSessionIdOrderByCreatedAtDesc(UUID trainingSessionId);

  Optional<TrainingPlannerDecision> findBySourceTurnId(UUID sourceTurnId);
}
