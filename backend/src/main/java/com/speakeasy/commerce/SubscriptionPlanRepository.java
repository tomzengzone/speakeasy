package com.speakeasy.commerce;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SubscriptionPlanRepository extends JpaRepository<SubscriptionPlan, UUID> {
  Optional<SubscriptionPlan> findByPlatformAndProductId(String platform, String productId);
}
