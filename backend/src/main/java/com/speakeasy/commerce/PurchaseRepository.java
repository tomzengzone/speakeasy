package com.speakeasy.commerce;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PurchaseRepository extends JpaRepository<Purchase, UUID> {
  Optional<Purchase> findByPlatformAndProviderTransactionId(String platform, String providerTransactionId);
}
