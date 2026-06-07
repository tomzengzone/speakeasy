package com.speakeasy.goal;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalBackplanRepository extends JpaRepository<GoalBackplan, UUID> {
  Optional<GoalBackplan> findFirstByGoalProfileIdAndStatusInOrderByStartDateDesc(
      UUID goalProfileId, Collection<String> statuses);

  List<GoalBackplan> findByGoalProfileIdAndStatusIn(UUID goalProfileId, Collection<String> statuses);

  List<GoalBackplan> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
