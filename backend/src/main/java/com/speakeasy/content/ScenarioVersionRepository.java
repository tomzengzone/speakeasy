package com.speakeasy.content;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ScenarioVersionRepository extends JpaRepository<ScenarioVersion, UUID> {
  Optional<ScenarioVersion> findFirstByScenarioIdAndContentStatusOrderByPublishedAtDesc(
      String scenarioId, String contentStatus);

  Optional<ScenarioVersion>
      findFirstByScenarioIdAndContentStatusAndPublishedAtIsNotNullOrderByPublishedAtDescScenarioVersionIdAsc(
          String scenarioId, String contentStatus);

  List<ScenarioVersion>
      findByScenarioIdInAndContentStatusAndPublishedAtIsNotNullOrderByScenarioIdAscPublishedAtDescScenarioVersionIdAsc(
          Collection<String> scenarioIds, String contentStatus);
}
