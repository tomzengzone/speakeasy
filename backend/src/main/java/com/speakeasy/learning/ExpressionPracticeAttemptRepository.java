package com.speakeasy.learning;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExpressionPracticeAttemptRepository extends JpaRepository<ExpressionPracticeAttempt, UUID> {
  List<ExpressionPracticeAttempt> findByUserId(UUID userId);
}
