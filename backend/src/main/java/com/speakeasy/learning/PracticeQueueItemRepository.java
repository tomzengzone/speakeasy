package com.speakeasy.learning;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PracticeQueueItemRepository extends JpaRepository<PracticeQueueItem, UUID> {
  List<PracticeQueueItem> findByUserIdAndStatus(UUID userId, String status);

  Optional<PracticeQueueItem> findByQueueItemIdAndUserId(UUID queueItemId, UUID userId);

  Optional<PracticeQueueItem> findFirstByUserIdAndTargetExpressionIdAndStatusIn(
      UUID userId, UUID targetExpressionId, Collection<String> statuses);
}
