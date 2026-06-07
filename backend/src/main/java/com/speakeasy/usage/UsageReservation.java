package com.speakeasy.usage;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "usage_reservations")
public class UsageReservation {
  @Id
  @Column(name = "reservation_id", nullable = false)
  private UUID reservationId;

  @Column(name = "ledger_id", nullable = false)
  private UUID ledgerId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "usage_family", nullable = false)
  private String usageFamily;

  @Column(name = "amount", nullable = false)
  private int amount;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "idempotency_key", nullable = false)
  private String idempotencyKey;

  @Column(name = "source_ref", nullable = false)
  private String sourceRef;

  @Column(name = "provider_usage_event_ref")
  private String providerUsageEventRef;

  @Column(name = "reserved_at", nullable = false)
  private Instant reservedAt;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  protected UsageReservation() {}

  public UsageReservation(UUID reservationId, UUID ledgerId, UUID userId, String usageFamily, int amount, String idempotencyKey, Instant reservedAt, Instant expiresAt) {
    this(reservationId, ledgerId, userId, usageFamily, amount, idempotencyKey, "legacy", reservedAt, expiresAt);
  }

  public UsageReservation(
      UUID reservationId,
      UUID ledgerId,
      UUID userId,
      String usageFamily,
      int amount,
      String idempotencyKey,
      String sourceRef,
      Instant reservedAt,
      Instant expiresAt) {
    this.reservationId = reservationId;
    this.ledgerId = ledgerId;
    this.userId = userId;
    this.usageFamily = usageFamily;
    this.amount = amount;
    this.status = "reserved";
    this.idempotencyKey = idempotencyKey;
    this.sourceRef = sourceRef;
    this.reservedAt = reservedAt;
    this.expiresAt = expiresAt;
  }

  public UUID getReservationId() {
    return reservationId;
  }

  public UUID getLedgerId() {
    return ledgerId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getUsageFamily() {
    return usageFamily;
  }

  public int getAmount() {
    return amount;
  }

  public String getStatus() {
    return status;
  }

  public String getIdempotencyKey() {
    return idempotencyKey;
  }

  public String getSourceRef() {
    return sourceRef;
  }

  public String getProviderUsageEventRef() {
    return providerUsageEventRef;
  }

  public Instant getExpiresAt() {
    return expiresAt;
  }

  public boolean sameReservePayload(String usageFamily, int amount, String sourceRef) {
    return this.usageFamily.equals(usageFamily) && this.amount == amount && this.sourceRef.equals(sourceRef);
  }

  public void commit(String providerUsageEventRef) {
    if ("reserved".equals(status)) {
      this.status = "committed";
      this.providerUsageEventRef = providerUsageEventRef;
    }
  }

  public void release(String providerUsageEventRef) {
    if ("reserved".equals(status)) {
      this.status = "released";
      this.providerUsageEventRef = providerUsageEventRef;
    }
  }
}
