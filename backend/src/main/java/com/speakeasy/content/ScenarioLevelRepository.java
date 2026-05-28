package com.speakeasy.content;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ScenarioLevelRepository extends JpaRepository<ScenarioLevel, UUID> {
  List<ScenarioLevel> findByScenarioIdOrderByLevelCodeAsc(String scenarioId);

  Optional<ScenarioLevel> findByScenarioIdAndLevelCode(String scenarioId, String levelCode);
}
