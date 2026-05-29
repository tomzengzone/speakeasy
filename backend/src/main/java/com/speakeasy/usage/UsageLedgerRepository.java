package com.speakeasy.usage;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UsageLedgerRepository extends JpaRepository<UsageLedger, UUID> {
  List<UsageLedger> findByUserId(UUID userId);

  Optional<UsageLedger> findByUserIdAndUsageFamilyAndPeriod(UUID userId, String usageFamily, String period);
}
