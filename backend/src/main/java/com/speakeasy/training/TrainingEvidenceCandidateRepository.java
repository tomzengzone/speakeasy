package com.speakeasy.training;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingEvidenceCandidateRepository extends JpaRepository<TrainingEvidenceCandidate, UUID> {
  List<TrainingEvidenceCandidate> findByTrainingSessionIdOrderByCreatedAtAsc(UUID trainingSessionId);

  List<TrainingEvidenceCandidate> findBySourceTurnIdOrderByCreatedAtAsc(UUID sourceTurnId);
}
