package com.speakeasy.goal;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface GoalMasteryInitialStateRepository extends JpaRepository<GoalMasteryInitialState, UUID> {
  List<GoalMasteryInitialState> findByGoalProfileId(UUID goalProfileId);

  void deleteByGoalProfileId(UUID goalProfileId);
}
