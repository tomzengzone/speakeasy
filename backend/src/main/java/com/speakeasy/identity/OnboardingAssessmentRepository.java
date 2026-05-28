package com.speakeasy.identity;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OnboardingAssessmentRepository extends JpaRepository<OnboardingAssessment, UUID> {
  List<OnboardingAssessment> findByUserIdOrderByCompletedAtDesc(UUID userId);
}
