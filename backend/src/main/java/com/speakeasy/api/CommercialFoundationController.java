package com.speakeasy.api;

import com.speakeasy.commerce.CommercialFoundationService;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.PaymentProviderService;
import com.speakeasy.commerce.SubscriptionPlan;
import com.speakeasy.common.ApiException;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.security.CurrentUser;
import com.speakeasy.usage.UsageLedger;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.usage.UsageReservation;
import com.speakeasy.usage.UsageService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class CommercialFoundationController {
  private static final TypeReference<Map<String, Object>> OBJECT_MAP = new TypeReference<>() {};

  private final CommercialFoundationService service;
  private final UsageService usageService;
  private final PaymentProviderService paymentProviderService;
  private final ObjectMapper objectMapper;

  public CommercialFoundationController(
      CommercialFoundationService service,
      UsageService usageService,
      PaymentProviderService paymentProviderService,
      ObjectMapper objectMapper) {
    this.service = service;
    this.usageService = usageService;
    this.paymentProviderService = paymentProviderService;
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

  @PostMapping("/entitlements/refresh")
  public EntitlementSnapshotResponse refreshEntitlements(@AuthenticationPrincipal CurrentUser currentUser) {
    return getEntitlements(currentUser);
  }

  @GetMapping("/usage/summary")
  public UsageSummaryResponse getUsageSummary(@AuthenticationPrincipal CurrentUser currentUser) {
    return new UsageSummaryResponse(1, service.usageSummary(currentUser.userId()).stream().map(UsageLedgerDto::from).toList());
  }

  @PostMapping("/usage/reserve")
  @ResponseStatus(HttpStatus.CREATED)
  public UsageReservationResponse reserveUsage(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @Valid @RequestBody UsageReserveRequest request) {
    return UsageReservationResponse.from(usageService.reserve(
        currentUser.userId(),
        request.usageFamily(),
        request.amount(),
        idempotencyKey,
        request.sourceRef()));
  }

  @PostMapping("/usage/commit")
  public UsageReservationResponse commitUsage(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody UsageTransitionRequest request) {
    return UsageReservationResponse.from(usageService.commit(
        currentUser.userId(), request.reservationId(), request.providerUsageEventRef()));
  }

  @PostMapping("/usage/release")
  public UsageReservationResponse releaseUsage(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody UsageTransitionRequest request) {
    return UsageReservationResponse.from(usageService.release(
        currentUser.userId(), request.reservationId(), request.providerUsageEventRef()));
  }

  @PostMapping("/subscriptions/apple/verify")
  public SubscriptionVerificationResponse verifyAppleSubscription(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @Valid @RequestBody AppleVerifyRequest request) {
    requireIdempotencyKey(idempotencyKey);
    return SubscriptionVerificationResponse.from(paymentProviderService.verifyApple(
        currentUser.userId(),
        request.transactionId(),
        request.originalTransactionId(),
        request.productId(),
        request.appAccountToken()));
  }

  @PostMapping("/subscriptions/google/verify")
  public SubscriptionVerificationResponse verifyGoogleSubscription(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @Valid @RequestBody GoogleVerifyRequest request) {
    requireIdempotencyKey(idempotencyKey);
    return SubscriptionVerificationResponse.from(paymentProviderService.verifyGoogle(
        currentUser.userId(), request.purchaseToken(), request.productId()));
  }

  @PostMapping("/subscriptions/restore")
  public RestoreSubscriptionResponse restoreSubscription(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @Valid @RequestBody RestoreSubscriptionRequest request) {
    requireIdempotencyKey(idempotencyKey);
    return RestoreSubscriptionResponse.from(paymentProviderService.restore(currentUser.userId(), request.platform()));
  }

  @PostMapping("/subscriptions/webhook/apple")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public void receiveAppleSubscriptionWebhook(
      @RequestHeader(value = "X-Provider-Signature", required = false) String signature,
      @Valid @RequestBody ProviderWebhookRequest request) {
    paymentProviderService.receiveWebhook(
        "apple", signature, request.providerEventId(), request.platform(), request.eventType(), request.receivedPayloadRef());
  }

  @PostMapping("/subscriptions/webhook/google")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public void receiveGoogleSubscriptionWebhook(
      @RequestHeader(value = "X-Provider-Signature", required = false) String signature,
      @Valid @RequestBody ProviderWebhookRequest request) {
    paymentProviderService.receiveWebhook(
        "google", signature, request.providerEventId(), request.platform(), request.eventType(), request.receivedPayloadRef());
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

  private void requireIdempotencyKey(String idempotencyKey) {
    if (idempotencyKey == null || idempotencyKey.length() < 8 || idempotencyKey.length() > 128) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
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

  public record UsageReserveRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String usageFamily,
      @NotNull @Min(1) Integer amount,
      String sourceRef) {}

  public record UsageTransitionRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotNull UUID reservationId,
      String providerUsageEventRef) {}

  public record UsageReservationResponse(int schemaVersion, UsageReservationDto reservation) implements SchemaResponse {
    static UsageReservationResponse from(UsageReservation reservation) {
      return new UsageReservationResponse(1, UsageReservationDto.from(reservation));
    }
  }

  public record UsageReservationDto(UUID reservationId, String usageFamily, int amount, String status, Instant expiresAt) {
    static UsageReservationDto from(UsageReservation reservation) {
      return new UsageReservationDto(
          reservation.getReservationId(),
          reservation.getUsageFamily(),
          reservation.getAmount(),
          reservation.getStatus(),
          reservation.getExpiresAt());
    }
  }

  public record AppleVerifyRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String transactionId,
      @NotBlank String originalTransactionId,
      @NotBlank String productId,
      @NotBlank String appAccountToken) {}

  public record GoogleVerifyRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String purchaseToken,
      @NotBlank String productId) {}

  public record SubscriptionVerificationResponse(
      int schemaVersion,
      String verificationStatus,
      String subscriptionStatus,
      EntitlementSnapshotDto entitlement) implements SchemaResponse {
    static SubscriptionVerificationResponse from(PaymentProviderService.VerificationResult result) {
      return new SubscriptionVerificationResponse(
          1,
          result.verificationStatus(),
          result.subscriptionStatus(),
          EntitlementSnapshotDto.from(result.entitlement(), Map.of(
              "basic_scenarios", true,
              "advanced_scenarios", "pro".equals(result.entitlement().getPlan()),
              "ai_feedback", true)));
    }
  }

  public record RestoreSubscriptionRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String platform,
      String providerAccountToken) {}

  public record RestoreSubscriptionResponse(
      int schemaVersion,
      String restoreStatus,
      EntitlementSnapshotDto entitlement) implements SchemaResponse {
    static RestoreSubscriptionResponse from(PaymentProviderService.RestoreResult result) {
      return new RestoreSubscriptionResponse(
          1,
          result.restoreStatus(),
          result.entitlement() == null ? null : EntitlementSnapshotDto.from(result.entitlement(), Map.of(
              "basic_scenarios", true,
              "advanced_scenarios", "pro".equals(result.entitlement().getPlan()),
              "ai_feedback", true)));
    }
  }

  public record ProviderWebhookRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String providerEventId,
      @NotBlank String platform,
      @NotBlank String eventType,
      @NotBlank String receivedPayloadRef) {}
}
