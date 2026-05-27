package com.speakeasy.api;

import com.speakeasy.commerce.CommercialFoundationService;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.SubscriptionPlan;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.security.CurrentUser;
import com.speakeasy.usage.UsageLedger;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CommercialFoundationController {
  private static final TypeReference<Map<String, Object>> OBJECT_MAP = new TypeReference<>() {};

  private final CommercialFoundationService service;
  private final ObjectMapper objectMapper;

  public CommercialFoundationController(CommercialFoundationService service, ObjectMapper objectMapper) {
    this.service = service;
    this.objectMapper = objectMapper;
  }

  @GetMapping("/subscription/plans")
  public SubscriptionPlanListResponse listSubscriptionPlans() {
    return new SubscriptionPlanListResponse(1, service.listPlans().stream().map(SubscriptionPlanDto::from).toList());
  }

  @GetMapping("/entitlements")
  public EntitlementSnapshotResponse getEntitlements(@AuthenticationPrincipal CurrentUser currentUser) {
    EntitlementSnapshot entitlement =
        service.latestEntitlement(currentUser.userId())
            .orElseGet(() -> service.defaultFreeEntitlement(currentUser.userId()));
    return new EntitlementSnapshotResponse(1, EntitlementSnapshotDto.from(entitlement, parseObject(entitlement.getFeatureFlags())));
  }

  @GetMapping("/usage/summary")
  public UsageSummaryResponse getUsageSummary(@AuthenticationPrincipal CurrentUser currentUser) {
    return new UsageSummaryResponse(1, service.usageSummary(currentUser.userId()).stream().map(UsageLedgerDto::from).toList());
  }

  @GetMapping("/admin/release-health")
  public ReleaseHealthResponse getReleaseHealth() {
    return new ReleaseHealthResponse(1, "warn", List.of(Map.of(
        "name", "PB-P0-BE-001A",
        "status", "warn",
        "message", "Backend/DB foundation exists; provider and release gates remain pending.")));
  }

  private Map<String, Object> parseObject(String json) {
    try {
      return objectMapper.readValue(json, OBJECT_MAP);
    } catch (Exception e) {
      return Map.of();
    }
  }

  public record SubscriptionPlanListResponse(int schemaVersion, List<SubscriptionPlanDto> plans) implements SchemaResponse {}

  public record SubscriptionPlanDto(String planId, String platform, String productId, String billingPeriod, String status) {
    static SubscriptionPlanDto from(SubscriptionPlan plan) {
      return new SubscriptionPlanDto(
          plan.getPlanId().toString(),
          plan.getPlatform(),
          plan.getProductId(),
          plan.getBillingPeriod(),
          plan.getStatus());
    }
  }

  public record EntitlementSnapshotResponse(int schemaVersion, EntitlementSnapshotDto entitlement) implements SchemaResponse {}

  public record EntitlementSnapshotDto(
      String plan, String status, Map<String, Object> features, Instant validUntil, Instant generatedAt) {
    static EntitlementSnapshotDto from(EntitlementSnapshot entitlement, Map<String, Object> features) {
      return new EntitlementSnapshotDto(
          entitlement.getPlan(),
          entitlement.getStatus(),
          features,
          entitlement.getValidUntil(),
          entitlement.getGeneratedAt());
    }
  }

  public record UsageSummaryResponse(int schemaVersion, List<UsageLedgerDto> usage) implements SchemaResponse {}

  public record UsageLedgerDto(
      String usageFamily, String period, int committedAmount, int reservedAmount, int limitAmount, String status) {
    static UsageLedgerDto from(UsageLedger ledger) {
      return new UsageLedgerDto(
          ledger.getUsageFamily(),
          ledger.getPeriod(),
          ledger.getCommittedAmount(),
          ledger.getReservedAmount(),
          ledger.getLimitAmount(),
          ledger.getStatus());
    }
  }

  public record ReleaseHealthResponse(int schemaVersion, String status, List<Map<String, String>> checks) implements SchemaResponse {}
}
