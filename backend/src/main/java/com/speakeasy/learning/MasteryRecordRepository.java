package com.speakeasy.learning;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MasteryRecordRepository extends JpaRepository<MasteryRecord, UUID> {
  List<MasteryRecord> findByUserId(UUID userId);

  Optional<MasteryRecord> findByUserIdAndTargetExpressionId(UUID userId, UUID targetExpressionId);
}
