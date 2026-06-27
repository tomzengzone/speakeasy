package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalMasteryTransitionDecisionRepository
    extends JpaRepository<GoalMasteryTransitionDecision, UUID> {
  List<GoalMasteryTransitionDecision> findByUserIdOrderByCreatedAtDesc(UUID userId);

  Optional<GoalMasteryTransitionDecision>
      findByUserIdAndGoalProfileIdAndGoalRevisionAndMemoryItemStateIdAndInputSnapshotHashAndRuleVersion(
          UUID userId,
          UUID goalProfileId,
          int goalRevision,
          String memoryItemStateId,
          String inputSnapshotHash,
          String ruleVersion);
}
