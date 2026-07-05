package com.speakeasy.learning;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SavedExpressionRepository extends JpaRepository<SavedExpression, UUID> {
  List<SavedExpression> findByUserIdAndStatus(UUID userId, String status);
}
