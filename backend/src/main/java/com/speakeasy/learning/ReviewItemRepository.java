package com.speakeasy.learning;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReviewItemRepository extends JpaRepository<ReviewItem, UUID> {
  List<ReviewItem> findByUserIdAndStatusAndDueAtLessThanEqualOrderByDueAtAsc(UUID userId, String status, Instant dueAt);

  Optional<ReviewItem> findByReviewItemIdAndUserId(UUID reviewItemId, UUID userId);
}
