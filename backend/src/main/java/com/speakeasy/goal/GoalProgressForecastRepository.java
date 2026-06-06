package com.speakeasy.goal;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

public interface GoalProgressForecastRepository extends JpaRepository<GoalProgressForecast, UUID> {
  Optional<GoalProgressForecast> findFirstByGoalProfileIdOrderByUpdatedAtDesc(UUID goalProfileId);

  @Transactional
  void deleteByUserId(UUID userId);
}
