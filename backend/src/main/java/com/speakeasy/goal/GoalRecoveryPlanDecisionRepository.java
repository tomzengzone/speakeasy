package com.speakeasy.goal;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalRecoveryPlanDecisionRepository extends JpaRepository<GoalRecoveryPlanDecision, UUID> {
  Optional<GoalRecoveryPlanDecision> findByUserIdAndGoalProfileIdAndGoalRevisionAndSourceEventAndRuleVersionAndIdempotencyKey(
      UUID userId, UUID goalProfileId, int goalRevision, String sourceEvent, String ruleVersion, String idempotencyKey);
}
