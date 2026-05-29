package com.speakeasy.usage;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

@Entity
@Table(name = "usage_ledgers")
public class UsageLedger {
  @Id
  @Column(name = "ledger_id", nullable = false)
  private UUID ledgerId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "usage_family", nullable = false)
  private String usageFamily;

  @Column(name = "period", nullable = false)
  private String period;

  @Column(name = "reserved_amount", nullable = false)
  private int reservedAmount;

  @Column(name = "committed_amount", nullable = false)
  private int committedAmount;

  @Column(name = "limit_amount", nullable = false)
  private int limitAmount;

  @Column(name = "status", nullable = false)
  private String status;

  protected UsageLedger() {}

  public UsageLedger(UUID ledgerId, UUID userId, String usageFamily, String period, int limitAmount) {
    this.ledgerId = ledgerId;
    this.userId = userId;
    this.usageFamily = usageFamily;
    this.period = period;
    this.limitAmount = limitAmount;
    this.status = "available";
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

  public String getPeriod() {
    return period;
  }

  public int getReservedAmount() {
    return reservedAmount;
  }

  public int getCommittedAmount() {
    return committedAmount;
  }

  public int getLimitAmount() {
    return limitAmount;
  }

  public String getStatus() {
    return status;
  }

  public void setLimitAmount(int limitAmount) {
    this.limitAmount = limitAmount;
    refreshStatus();
  }

  public boolean canReserve(int amount) {
    return committedAmount + reservedAmount + amount <= limitAmount;
  }

  public void reserve(int amount) {
    this.reservedAmount += amount;
    refreshStatus();
  }

  public void commit(int amount) {
    this.reservedAmount = Math.max(0, this.reservedAmount - amount);
    this.committedAmount += amount;
    refreshStatus();
  }

  public void release(int amount) {
    this.reservedAmount = Math.max(0, this.reservedAmount - amount);
    refreshStatus();
  }

  private void refreshStatus() {
    this.status = committedAmount + reservedAmount >= limitAmount ? "exhausted" : "available";
  }
}
