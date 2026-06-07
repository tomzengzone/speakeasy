package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalDiagnosticAssessmentRepository extends JpaRepository<GoalDiagnosticAssessment, UUID> {
  Optional<GoalDiagnosticAssessment> findFirstByGoalProfileIdOrderByCreatedAtDesc(UUID goalProfileId);

  List<GoalDiagnosticAssessment> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
