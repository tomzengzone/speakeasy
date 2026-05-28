package com.speakeasy.practice;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CoachFeedbackRepository extends JpaRepository<CoachFeedback, UUID> {
  Optional<CoachFeedback> findBySourceTurnId(UUID sourceTurnId);

  List<CoachFeedback> findBySessionIdOrderByCreatedAtAsc(UUID sessionId);
}
