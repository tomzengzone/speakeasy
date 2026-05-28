package com.speakeasy.practice;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PracticeSessionRepository extends JpaRepository<PracticeSession, UUID> {
  Optional<PracticeSession> findByPracticeSessionIdAndUserId(UUID practiceSessionId, UUID userId);

  Optional<PracticeSession> findFirstByUserIdAndScenarioIdAndLevelCodeAndStatusInOrderByUpdatedAtDesc(
      UUID userId, String scenarioId, String levelCode, Collection<String> statuses);

  Optional<PracticeSession> findFirstByUserIdAndStatusInOrderByUpdatedAtDesc(UUID userId, Collection<String> statuses);

  List<PracticeSession> findByUserId(UUID userId);
}
