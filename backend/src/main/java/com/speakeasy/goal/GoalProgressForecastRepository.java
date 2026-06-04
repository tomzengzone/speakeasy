package com.speakeasy.goal;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalProgressForecastRepository extends JpaRepository<GoalProgressForecast, UUID> {
  Optional<GoalProgressForecast> findFirstByGoalProfileIdOrderByUpdatedAtDesc(UUID goalProfileId);
}
