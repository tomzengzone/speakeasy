package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalAutopilotControlIdempotencyRepository extends JpaRepository<GoalAutopilotControlIdempotency, UUID> {
  Optional<GoalAutopilotControlIdempotency>
      findByUserIdAndGoalProfileIdAndGoalRevisionAndOperationAndIdempotencyKey(
          UUID userId, UUID goalProfileId, int goalRevision, String operation, String idempotencyKey);

  List<GoalAutopilotControlIdempotency> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
