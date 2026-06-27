package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "otp_rate_counters")
public class OtpRateCounter {
  @Id
  @Column(name = "rate_counter_id", nullable = false)
  private UUID rateCounterId;

  @Column(name = "subject_type", nullable = false)
  private String subjectType;

  @Column(name = "subject_hash", nullable = false)
  private String subjectHash;

  @Column(name = "purpose", nullable = false)
  private String purpose;

  @Column(name = "window_start", nullable = false)
  private Instant windowStart;

  @Column(name = "window_end", nullable = false)
  private Instant windowEnd;

  @Column(name = "count", nullable = false)
  private int count;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected OtpRateCounter() {}

  public OtpRateCounter(
      UUID rateCounterId,
      String subjectType,
      String subjectHash,
      String purpose,
      Instant windowStart,
      Instant windowEnd,
      Instant createdAt) {
    this.rateCounterId = rateCounterId;
    this.subjectType = subjectType;
    this.subjectHash = subjectHash;
    this.purpose = purpose;
    this.windowStart = windowStart;
    this.windowEnd = windowEnd;
    this.createdAt = createdAt;
    this.updatedAt = createdAt;
  }

  public UUID getRateCounterId() {
    return rateCounterId;
  }

  public String getSubjectType() {
    return subjectType;
  }

  public String getSubjectHash() {
    return subjectHash;
  }

  public String getPurpose() {
    return purpose;
  }

  public Instant getWindowStart() {
    return windowStart;
  }

  public Instant getWindowEnd() {
    return windowEnd;
  }

  public int getCount() {
    return count;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }

  public void increment(Instant updatedAt) {
    this.count += 1;
    this.updatedAt = updatedAt;
  }
}
