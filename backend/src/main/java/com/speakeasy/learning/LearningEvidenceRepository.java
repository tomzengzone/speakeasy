package com.speakeasy.learning;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LearningEvidenceRepository extends JpaRepository<LearningEvidence, UUID> {
  List<LearningEvidence> findByUserIdAndAcceptedStatusOrderByCreatedAtDesc(UUID userId, String acceptedStatus);
}
