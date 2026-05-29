package com.speakeasy.commerce;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SubscriptionRepository extends JpaRepository<Subscription, UUID> {
  Optional<Subscription> findFirstByUserIdAndPlatformAndStatusInOrderByStartsAtDesc(
      UUID userId, String platform, List<String> statuses);

  Optional<Subscription> findFirstByPlatformAndStatusInOrderByStartsAtDesc(String platform, List<String> statuses);
}
