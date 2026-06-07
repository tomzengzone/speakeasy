package com.speakeasy.usage;

import com.speakeasy.commerce.EntitlementGateService;
import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UsageService {
  private static final int RESERVATION_TTL_SECONDS = 900;

  private final UsageLedgerRepository ledgers;
  private final UsageReservationRepository reservations;
  private final EntitlementGateService entitlementGateService;
  private final AuditLogRepository auditLogs;
  private final Clock clock;

  public UsageService(
      UsageLedgerRepository ledgers,
      UsageReservationRepository reservations,
      EntitlementGateService entitlementGateService,
      AuditLogRepository auditLogs,
      Clock clock) {
    this.ledgers = ledgers;
    this.reservations = reservations;
    this.entitlementGateService = entitlementGateService;
    this.auditLogs = auditLogs;
    this.clock = clock;
  }

  @Transactional
  public UsageReservation reserve(UUID userId, String usageFamily, int amount, String idempotencyKey, String sourceRef) {
    validateReserveRequest(usageFamily, amount, idempotencyKey);
    String safeSourceRef = safe(sourceRef);
    UsageReservation existing = reservations.findByUserIdAndIdempotencyKey(userId, idempotencyKey).orElse(null);
    if (existing != null) {
      if (!existing.sameReservePayload(usageFamily, amount, safeSourceRef)) {
        throw new ApiException(HttpStatus.CONFLICT, "IDEMPOTENCY_CONFLICT", "Idempotency key reused with different usage payload.");
      }
      return existing;
    }
    UsageLedger ledger = currentLedger(userId, usageFamily);
    if (!ledger.canReserve(amount)) {
      audit(userId, "usage_limit_exceeded", usageFamily, Map.of("amount", amount, "source_ref", safe(sourceRef)));
      throw new ApiException(
          HttpStatus.TOO_MANY_REQUESTS,
          "USAGE_LIMIT_EXCEEDED",
          "Usage limit exceeded.",
          Map.of(
              "usage_family", usageFamily,
              "committed_amount", ledger.getCommittedAmount(),
              "reserved_amount", ledger.getReservedAmount(),
              "limit_amount", ledger.getLimitAmount()));
    }
    Instant now = Instant.now(clock);
    ledger.reserve(amount);
    ledgers.save(ledger);
    UsageReservation reservation = reservations.save(new UsageReservation(
        UUID.randomUUID(),
        ledger.getLedgerId(),
        userId,
        usageFamily,
        amount,
        idempotencyKey,
        safeSourceRef,
        now,
        now.plusSeconds(RESERVATION_TTL_SECONDS)));
    audit(userId, "usage_reserved", usageFamily, Map.of("amount", amount, "source_ref", safeSourceRef));
    return reservation;
  }

  @Transactional
  public UsageReservation commit(UUID userId, UUID reservationId, String providerUsageEventRef) {
    UsageReservation reservation = requireReservation(userId, reservationId);
    if ("reserved".equals(reservation.getStatus())) {
      String safeEventRef = safe(providerUsageEventRef);
      UsageLedger ledger = ledgers.findById(reservation.getLedgerId())
          .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Usage ledger is missing."));
      ledger.commit(reservation.getAmount());
      reservation.commit(safeEventRef);
      ledgers.save(ledger);
      reservations.save(reservation);
      audit(userId, "usage_committed", reservation.getUsageFamily(),
          Map.of("amount", reservation.getAmount(), "provider_usage_event_ref", safeEventRef));
    }
    return reservation;
  }

  @Transactional
  public UsageReservation release(UUID userId, UUID reservationId, String providerUsageEventRef) {
    UsageReservation reservation = requireReservation(userId, reservationId);
    if ("reserved".equals(reservation.getStatus())) {
      String safeEventRef = safe(providerUsageEventRef);
      UsageLedger ledger = ledgers.findById(reservation.getLedgerId())
          .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Usage ledger is missing."));
      ledger.release(reservation.getAmount());
      reservation.release(safeEventRef);
      ledgers.save(ledger);
      reservations.save(reservation);
      audit(userId, "usage_released", reservation.getUsageFamily(),
          Map.of("amount", reservation.getAmount(), "provider_usage_event_ref", safeEventRef));
    }
    return reservation;
  }

  public UsageReservation reserveProviderCall(UUID userId, String usageFamily, String sourceRef) {
    return reserve(userId, usageFamily, 1, "provider-" + usageFamily + "-" + UUID.randomUUID(), sourceRef);
  }

  private UsageLedger currentLedger(UUID userId, String usageFamily) {
    String period = YearMonth.now(clock.withZone(ZoneOffset.UTC)).toString();
    int limit = entitlementGateService.limitFor(userId, usageFamily);
    UsageLedger ledger = ledgers.findByUserIdAndUsageFamilyAndPeriod(userId, usageFamily, period)
        .orElseGet(() -> new UsageLedger(UUID.randomUUID(), userId, usageFamily, period, limit));
    ledger.setLimitAmount(limit);
    return ledgers.save(ledger);
  }

  private UsageReservation requireReservation(UUID userId, UUID reservationId) {
    return reservations.findByReservationIdAndUserId(reservationId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Usage reservation was not found."));
  }

  private void validateReserveRequest(String usageFamily, int amount, String idempotencyKey) {
    if (!isSupportedUsageFamily(usageFamily)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Unsupported usage family.");
    }
    if (amount < 1) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Usage amount must be positive.");
    }
    if (idempotencyKey == null || idempotencyKey.length() < 8 || idempotencyKey.length() > 128) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
    }
  }

  private boolean isSupportedUsageFamily(String usageFamily) {
    return "ai".equals(usageFamily)
        || "asr".equals(usageFamily)
        || "tts".equals(usageFamily)
        || "scoring".equals(usageFamily)
        || "training".equals(usageFamily);
  }

  private void audit(UUID userId, String eventType, String usageFamily, Map<String, Object> details) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "user",
        userId.toString(),
        eventType,
        "usage:" + usageFamily,
        details.toString(),
        null,
        Instant.now(clock)));
  }

  private String safe(String value) {
    if (value == null || value.isBlank()) {
      return "none";
    }
    String cleaned = value.trim();
    if (cleaned.startsWith("http://") || cleaned.startsWith("https://") || cleaned.length() > 96) {
      return "ref_sha256:" + sha256(cleaned).substring(0, 16);
    }
    return cleaned;
  }

  private String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException("sha256 unavailable", e);
    }
  }
}
