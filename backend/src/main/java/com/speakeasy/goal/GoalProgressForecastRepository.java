package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

public interface GoalProgressForecastRepository extends JpaRepository<GoalProgressForecast, UUID> {
  Optional<GoalProgressForecast> findFirstByGoalProfileIdOrderByUpdatedAtDesc(UUID goalProfileId);

  List<GoalProgressForecast> findByUserIdOrderByUpdatedAtDesc(UUID userId);

  @Transactional
  void deleteByUserId(UUID userId);
}
