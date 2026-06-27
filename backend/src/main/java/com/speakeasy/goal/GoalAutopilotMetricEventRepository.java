package com.speakeasy.goal;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalAutopilotMetricEventRepository extends JpaRepository<GoalAutopilotMetricEvent, UUID> {
  long countByEventTypeAndStatus(String eventType, String status);

  List<GoalAutopilotMetricEvent> findByUserHashOrderByCreatedAtAsc(String userHash);

  long deleteByUserHash(String userHash);
}
