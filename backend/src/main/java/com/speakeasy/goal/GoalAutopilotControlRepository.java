package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalAutopilotControlRepository extends JpaRepository<GoalAutopilotControl, UUID> {
  Optional<GoalAutopilotControl> findFirstByGoalProfileIdOrderByUpdatedAtDesc(UUID goalProfileId);

  List<GoalAutopilotControl> findByUserIdOrderByUpdatedAtDesc(UUID userId);
}
