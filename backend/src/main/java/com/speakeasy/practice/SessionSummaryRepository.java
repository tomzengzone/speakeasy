package com.speakeasy.practice;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SessionSummaryRepository extends JpaRepository<SessionSummary, UUID> {
  Optional<SessionSummary> findBySessionId(UUID sessionId);
}
