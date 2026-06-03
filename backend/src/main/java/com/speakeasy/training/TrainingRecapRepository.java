package com.speakeasy.training;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TrainingRecapRepository extends JpaRepository<TrainingRecap, UUID> {
  Optional<TrainingRecap> findByTrainingSessionId(UUID trainingSessionId);
}
