package com.speakeasy.goal;

import java.util.Collection;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalProfileRepository extends JpaRepository<GoalProfile, UUID> {
  Optional<GoalProfile> findFirstByUserIdAndStatusInOrderByUpdatedAtDesc(UUID userId, Collection<String> statuses);
}
