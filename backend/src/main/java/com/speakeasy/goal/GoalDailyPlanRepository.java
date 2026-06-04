package com.speakeasy.goal;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalDailyPlanRepository extends JpaRepository<GoalDailyPlan, UUID> {
  Optional<GoalDailyPlan> findFirstByGoalProfileIdAndPlanDateAndStatusInOrderByCreatedAtDesc(
      UUID goalProfileId, LocalDate planDate, Collection<String> statuses);

  Optional<GoalDailyPlan> findFirstByGoalProfileIdAndStatusInOrderByPlanDateDesc(
      UUID goalProfileId, Collection<String> statuses);

  List<GoalDailyPlan> findByGoalProfileIdAndStatusIn(UUID goalProfileId, Collection<String> statuses);
}
