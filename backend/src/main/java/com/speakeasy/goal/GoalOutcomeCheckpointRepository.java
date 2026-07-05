package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalOutcomeCheckpointRepository extends JpaRepository<GoalOutcomeCheckpoint, UUID> {
  Optional<GoalOutcomeCheckpoint> findFirstByGoalProfileIdOrderByCreatedAtDesc(UUID goalProfileId);

  List<GoalOutcomeCheckpoint> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
