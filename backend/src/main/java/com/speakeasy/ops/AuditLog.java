package com.speakeasy.ops;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "audit_logs")
public class AuditLog {
  @Id
  @Column(name = "audit_log_id", nullable = false)
  private UUID auditLogId;

  @Column(name = "actor_type", nullable = false)
  private String actorType;

  @Column(name = "actor_id")
  private String actorId;

  @Column(name = "event_type", nullable = false)
  private String eventType;

  @Column(name = "target_ref")
  private String targetRef;

  @Column(name = "redacted_details")
  private String redactedDetails;

  @Column(name = "request_id")
  private String requestId;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected AuditLog() {}

  public AuditLog(UUID auditLogId, String actorType, String eventType, Instant createdAt) {
    this.auditLogId = auditLogId;
    this.actorType = actorType;
    this.eventType = eventType;
    this.createdAt = createdAt;
  }

  public AuditLog(
      UUID auditLogId,
      String actorType,
      String actorId,
      String eventType,
      String targetRef,
      String redactedDetails,
      String requestId,
      Instant createdAt) {
    this.auditLogId = auditLogId;
    this.actorType = actorType;
    this.actorId = actorId;
    this.eventType = eventType;
    this.targetRef = targetRef;
    this.redactedDetails = redactedDetails;
    this.requestId = requestId;
    this.createdAt = createdAt;
  }

  public String getRedactedDetails() {
    return redactedDetails;
  }

  public UUID getAuditLogId() {
    return auditLogId;
  }

  public String getActorType() {
    return actorType;
  }

  public String getActorId() {
    return actorId;
  }

  public String getEventType() {
    return eventType;
  }

  public String getTargetRef() {
    return targetRef;
  }

  public String getRequestId() {
    return requestId;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
