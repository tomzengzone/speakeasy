package com.speakeasy.learning;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LearningHistoryEntryRepository extends JpaRepository<LearningHistoryEntry, UUID> {
  List<LearningHistoryEntry> findByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, String status);

  Optional<LearningHistoryEntry> findByHistoryEntryIdAndUserId(UUID historyEntryId, UUID userId);
}
