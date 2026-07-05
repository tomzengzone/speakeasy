package com.speakeasy.goal;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlannerReplayAuditRepository extends JpaRepository<PlannerReplayAudit, UUID> {
  List<PlannerReplayAudit> findByUserIdOrderByCreatedAtDesc(UUID userId);

  List<PlannerReplayAudit> findByUserIdAndDecisionFamilyOrderByCreatedAtDesc(UUID userId, String decisionFamily);
}
