package com.speakeasy.commerce;

import com.speakeasy.usage.UsageLedger;
import com.speakeasy.usage.UsageLedgerRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;

@Service
public class CommercialFoundationService {
  private final SubscriptionPlanRepository plans;
  private final EntitlementSnapshotRepository entitlements;
  private final UsageLedgerRepository usageLedgers;
  private final Clock clock;

  public CommercialFoundationService(
      SubscriptionPlanRepository plans,
      EntitlementSnapshotRepository entitlements,
      UsageLedgerRepository usageLedgers,
      Clock clock) {
    this.plans = plans;
    this.entitlements = entitlements;
    this.usageLedgers = usageLedgers;
    this.clock = clock;
  }

  public List<SubscriptionPlan> listPlans() {
    return plans.findAll();
  }

  public Optional<EntitlementSnapshot> latestEntitlement(UUID userId) {
    return entitlements.findByUserIdOrderByGeneratedAtDesc(userId).stream().findFirst();
  }

  public EntitlementSnapshot defaultFreeEntitlement(UUID userId) {
    return new EntitlementSnapshot(
        UUID.randomUUID(),
        userId,
        "free",
        "{\"basic_scenarios\":true,\"advanced_scenarios\":false,\"ai_feedback\":true}",
        "{\"ai\":10,\"asr\":10,\"tts\":10,\"scoring\":10,\"training\":3}",
        Instant.now(clock));
  }

  public List<UsageLedger> usageSummary(UUID userId) {
    return usageLedgers.findByUserId(userId);
  }
}
