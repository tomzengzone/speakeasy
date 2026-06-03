package com.speakeasy.training;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingContentMappingRepository extends JpaRepository<TrainingContentMapping, UUID> {
  boolean existsByScenarioVersionIdAndLevelCodeAndReviewStatus(UUID scenarioVersionId, String levelCode, String reviewStatus);

  List<TrainingContentMapping> findByScenarioVersionIdAndLevelCodeAndReviewStatusOrderByOrderIndexAsc(
      UUID scenarioVersionId, String levelCode, String reviewStatus);
}
