package com.speakeasy.goal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "goal_autopilot_metric_events")
public class GoalAutopilotMetricEvent {
  @Id
  @Column(name = "metric_event_id", nullable = false)
  private UUID metricEventId;

  @Column(name = "user_hash", nullable = false)
  private String userHash;

  @Column(name = "event_type", nullable = false)
  private String eventType;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "reason_code", nullable = false)
  private String reasonCode;

  @Column(name = "source_path", nullable = false)
  private String sourcePath;

  @Column(name = "target_ref", nullable = false)
  private String targetRef;

  @Column(name = "audit_ref", nullable = false)
  private String auditRef;

  @Column(name = "schema_version", nullable = false)
  private int schemaVersion;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected GoalAutopilotMetricEvent() {}

  public GoalAutopilotMetricEvent(
      UUID metricEventId,
      String userHash,
      String eventType,
      String status,
      String reasonCode,
      String sourcePath,
      String targetRef,
      String auditRef,
      int schemaVersion,
      Instant createdAt) {
    this.metricEventId = metricEventId;
    this.userHash = userHash;
    this.eventType = eventType;
    this.status = status;
    this.reasonCode = reasonCode;
    this.sourcePath = sourcePath;
    this.targetRef = targetRef;
    this.auditRef = auditRef;
    this.schemaVersion = schemaVersion;
    this.createdAt = createdAt;
  }

  public UUID getMetricEventId() {
    return metricEventId;
  }

  public String getUserHash() {
    return userHash;
  }

  public String getEventType() {
    return eventType;
  }

  public String getStatus() {
    return status;
  }

  public String getReasonCode() {
    return reasonCode;
  }

  public String getSourcePath() {
    return sourcePath;
  }

  public String getTargetRef() {
    return targetRef;
  }

  public String getAuditRef() {
    return auditRef;
  }

  public int getSchemaVersion() {
    return schemaVersion;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
