package com.speakeasy.goal;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationOutboxRecordRepository extends JpaRepository<NotificationOutboxRecord, UUID> {
  Optional<NotificationOutboxRecord> findByDedupeKey(String dedupeKey);

  Optional<NotificationOutboxRecord> findByOutboxId(UUID outboxId);

  List<NotificationOutboxRecord> findByUserIdOrderByUpdatedAtDesc(UUID userId);
}
