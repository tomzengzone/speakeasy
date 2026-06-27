package com.speakeasy.goal;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalPlanItemRepository extends JpaRepository<GoalPlanItem, UUID> {
  List<GoalPlanItem> findByDailyPlanIdOrderByOrderIndexAsc(UUID dailyPlanId);

  Optional<GoalPlanItem> findByPlanItemIdAndUserId(UUID planItemId, UUID userId);

  Optional<GoalPlanItem> findFirstByDailyPlanIdAndStatusInOrderByOrderIndexAsc(UUID dailyPlanId, Collection<String> statuses);

  List<GoalPlanItem> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
