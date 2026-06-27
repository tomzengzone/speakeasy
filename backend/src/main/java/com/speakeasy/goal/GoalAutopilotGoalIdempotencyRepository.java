package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalAutopilotGoalIdempotencyRepository extends JpaRepository<GoalAutopilotGoalIdempotency, UUID> {
  Optional<GoalAutopilotGoalIdempotency> findByUserIdAndIdempotencyKey(UUID userId, String idempotencyKey);

  List<GoalAutopilotGoalIdempotency> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
