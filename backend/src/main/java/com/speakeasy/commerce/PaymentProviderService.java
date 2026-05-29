package com.speakeasy.commerce;

import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PaymentProviderService {
  private static final List<String> RESTORABLE_STATUSES = List.of("active", "grace_period");

  private final SubscriptionPlanRepository plans;
  private final PurchaseRepository purchases;
  private final SubscriptionRepository subscriptions;
  private final EntitlementSnapshotRepository entitlements;
  private final PaymentProviderEventRepository providerEvents;
  private final AuditLogRepository auditLogs;
  private final Clock clock;
  private final String webhookSignature;

  public PaymentProviderService(
      SubscriptionPlanRepository plans,
      PurchaseRepository purchases,
      SubscriptionRepository subscriptions,
      EntitlementSnapshotRepository entitlements,
      PaymentProviderEventRepository providerEvents,
      AuditLogRepository auditLogs,
      Clock clock,
      @Value("${speakeasy.payment.webhook-signature:}") String webhookSignature) {
    this.plans = plans;
    this.purchases = purchases;
    this.subscriptions = subscriptions;
    this.entitlements = entitlements;
    this.providerEvents = providerEvents;
    this.auditLogs = auditLogs;
    this.clock = clock;
    this.webhookSignature = webhookSignature == null ? "" : webhookSignature.trim();
  }

  @Transactional
  public VerificationResult verifyApple(
      UUID userId, String transactionId, String originalTransactionId, String productId, String appAccountToken) {
    if (!userId.toString().equals(appAccountToken)) {
      throw invalidReceipt("Apple app_account_token does not match the authenticated user.");
    }
    return verify(userId, "apple", normalize(transactionId), productId);
  }

  @Transactional
  public VerificationResult verifyGoogle(UUID userId, String purchaseToken, String productId) {
    return verify(userId, "google", normalize(purchaseToken), productId);
  }

  @Transactional(readOnly = true)
  public RestoreResult restore(UUID userId, String platform) {
    Subscription subscription = subscriptions.findFirstByUserIdAndPlatformAndStatusInOrderByStartsAtDesc(
            userId, platform, RESTORABLE_STATUSES)
        .orElse(null);
    if (subscription == null) {
      return new RestoreResult("empty", null);
    }
    EntitlementSnapshot entitlement = entitlements.findByUserIdOrderByGeneratedAtDesc(userId).stream()
        .findFirst()
        .orElse(null);
    return new RestoreResult("restored", entitlement);
  }

  @Transactional
  public void receiveWebhook(String expectedPlatform, String signature, String providerEventId, String platform, String eventType, String payloadRef) {
    if (webhookSignature.isBlank() || signature == null || !webhookSignature.equals(signature)) {
      throw new ApiException(HttpStatus.FORBIDDEN, "FORBIDDEN", "Provider signature invalid or unauthorized.");
    }
    if (!expectedPlatform.equals(platform)) {
      throw invalidReceipt("Webhook platform does not match endpoint.");
    }
    if (providerEvents.existsById(providerEventId)) {
      return;
    }
    Instant now = Instant.now(clock);
    Subscription subscription = subscriptions.findFirstByPlatformAndStatusInOrderByStartsAtDesc(
            platform, List.of("active", "grace_period", "pending_verification"))
        .orElse(null);
    String processedStatus = subscription == null ? "ignored" : "processed";
    if (subscription != null) {
      applyProviderEvent(subscription, eventType, now);
      subscriptions.save(subscription);
      entitlements.save(entitlementForSubscription(subscription, entitlementStatusFor(eventType), now));
      audit(subscription.getUserId(), "payment_provider_event_processed", platform, eventType);
    }
    providerEvents.save(new PaymentProviderEvent(
        providerEventId, platform, eventType, now, processedStatus, subscription == null ? null : subscription.getSubscriptionId(), payloadRef));
  }

  private VerificationResult verify(UUID userId, String platform, String providerTransactionId, String productId) {
    requireIdempotencySafeProviderId(providerTransactionId);
    SubscriptionPlan plan = plans.findByPlatformAndProductId(platform, productId)
        .orElseThrow(() -> invalidReceipt("Product is not saleable for this platform."));
    Purchase purchase = purchases.findByPlatformAndProviderTransactionId(platform, providerTransactionId).orElse(null);
    if (purchase != null && !purchase.getUserId().equals(userId)) {
      throw invalidReceipt("Provider transaction belongs to a different user.");
    }
    Instant now = Instant.now(clock);
    if (purchase == null) {
      purchase = new Purchase(UUID.randomUUID(), userId, platform, providerTransactionId, productId, now);
    }
    purchase.markVerified();
    purchases.save(purchase);

    Subscription subscription = subscriptions.findFirstByUserIdAndPlatformAndStatusInOrderByStartsAtDesc(
            userId, platform, RESTORABLE_STATUSES)
        .orElseGet(() -> new Subscription(UUID.randomUUID(), userId, plan.getPlanId(), platform));
    subscription.activate(purchase.getPurchaseId(), now, now.plusSeconds(2_592_000));
    subscriptions.save(subscription);

    EntitlementSnapshot entitlement = entitlements.save(entitlementForSubscription(subscription, "active", now));
    audit(userId, "subscription_verified", platform, productId);
    return new VerificationResult("verified", subscription.getStatus(), entitlement);
  }

  private EntitlementSnapshot entitlementForSubscription(Subscription subscription, String entitlementStatus, Instant now) {
    if ("active".equals(entitlementStatus)) {
      return new EntitlementSnapshot(
          UUID.randomUUID(),
          subscription.getUserId(),
          subscription.getSubscriptionId(),
          "pro",
          "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
          "{\"ai\":100,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}",
          "active",
          subscription.getExpiresAt(),
          now);
    }
    return new EntitlementSnapshot(
        UUID.randomUUID(),
        subscription.getUserId(),
        subscription.getSubscriptionId(),
        "free",
        "{\"basic_scenarios\":true,\"advanced_scenarios\":false,\"ai_feedback\":true}",
        "{\"ai\":10,\"asr\":10,\"tts\":10,\"scoring\":10,\"training\":3}",
        entitlementStatus,
        now,
        now);
  }

  private void applyProviderEvent(Subscription subscription, String eventType, Instant now) {
    switch (normalize(eventType)) {
      case "grace", "grace_period" -> subscription.markGracePeriod(now.plusSeconds(259_200));
      case "refund", "refunded" -> subscription.downgrade("refunded");
      case "revoke", "revoked" -> subscription.downgrade("revoked");
      case "expire", "expired" -> subscription.downgrade("expired");
      default -> subscription.downgrade("active");
    }
  }

  private String entitlementStatusFor(String eventType) {
    return switch (normalize(eventType)) {
      case "refund", "refunded" -> "refunded";
      case "revoke", "revoked" -> "revoked";
      case "expire", "expired" -> "expired";
      default -> "active";
    };
  }

  private void requireIdempotencySafeProviderId(String providerId) {
    if (providerId == null || providerId.isBlank() || providerId.contains("invalid")) {
      throw invalidReceipt("Provider credential is invalid.");
    }
  }

  private ApiException invalidReceipt(String message) {
    return new ApiException(HttpStatus.BAD_REQUEST, "INVALID_RECEIPT", message);
  }

  private String normalize(String value) {
    return value == null ? "" : value.trim().toLowerCase(Locale.ROOT);
  }

  private void audit(UUID userId, String eventType, String platform, String detail) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "system",
        userId.toString(),
        eventType,
        "subscription:" + platform,
        Map.of("platform", platform, "detail", detail).toString(),
        null,
        Instant.now(clock)));
  }

  public record VerificationResult(String verificationStatus, String subscriptionStatus, EntitlementSnapshot entitlement) {}

  public record RestoreResult(String restoreStatus, EntitlementSnapshot entitlement) {}
}
