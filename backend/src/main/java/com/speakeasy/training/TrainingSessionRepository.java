package com.speakeasy.training;

import java.util.Collection;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingSessionRepository extends JpaRepository<TrainingSession, UUID> {
  Optional<TrainingSession> findByTrainingSessionIdAndUserId(UUID trainingSessionId, UUID userId);

  Optional<TrainingSession> findFirstByUserIdAndScenarioIdAndLevelCodeAndStatusInOrderByUpdatedAtDesc(
      UUID userId, String scenarioId, String levelCode, Collection<String> statuses);
}
