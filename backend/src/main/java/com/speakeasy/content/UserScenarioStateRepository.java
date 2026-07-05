package com.speakeasy.content;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserScenarioStateRepository extends JpaRepository<UserScenarioState, UUID> {
  List<UserScenarioState> findByUserId(UUID userId);

  List<UserScenarioState> findByUserIdAndState(UUID userId, String state);

  Optional<UserScenarioState> findByUserIdAndScenarioId(UUID userId, String scenarioId);
}
