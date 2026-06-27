package com.speakeasy.content;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TargetExpressionRepository extends JpaRepository<TargetExpression, UUID> {
  List<TargetExpression> findByScenarioVersionIdAndLevelCodeOrderByTextAsc(UUID scenarioVersionId, String levelCode);
}
