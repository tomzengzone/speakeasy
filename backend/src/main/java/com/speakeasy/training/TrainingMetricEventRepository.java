package com.speakeasy.training;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingMetricEventRepository extends JpaRepository<TrainingMetricEvent, UUID> {
  long countByEventTypeAndStatus(String eventType, String status);

  List<TrainingMetricEvent> findByTrainingSessionIdOrderByCreatedAtAsc(UUID trainingSessionId);
}
