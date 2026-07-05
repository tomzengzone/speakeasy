package com.speakeasy.training;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "training_metric_events")
public class TrainingMetricEvent {
  @Id
  @Column(name = "metric_event_id", nullable = false)
  private UUID metricEventId;

  @Column(name = "training_session_id")
  private UUID trainingSessionId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "event_type", nullable = false)
  private String eventType;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "provider_family")
  private String providerFamily;

  @Column(name = "latency_bucket")
  private String latencyBucket;

  @Column(name = "fallback_reason")
  private String fallbackReason;

  @Column(name = "schema_version", nullable = false)
  private int schemaVersion;

  @Column(name = "audit_ref", nullable = false)
  private String auditRef;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  protected TrainingMetricEvent() {}

  public TrainingMetricEvent(
      UUID metricEventId,
      UUID trainingSessionId,
      UUID userId,
      String eventType,
      String status,
      String providerFamily,
      String latencyBucket,
      String fallbackReason,
      int schemaVersion,
      String auditRef,
      Instant createdAt) {
    this.metricEventId = metricEventId;
    this.trainingSessionId = trainingSessionId;
    this.userId = userId;
    this.eventType = eventType;
    this.status = status;
    this.providerFamily = providerFamily;
    this.latencyBucket = latencyBucket;
    this.fallbackReason = fallbackReason;
    this.schemaVersion = schemaVersion;
    this.auditRef = auditRef;
    this.createdAt = createdAt;
  }

  public UUID getMetricEventId() {
    return metricEventId;
  }

  public UUID getTrainingSessionId() {
    return trainingSessionId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getEventType() {
    return eventType;
  }

  public String getStatus() {
    return status;
  }

  public String getProviderFamily() {
    return providerFamily;
  }

  public String getLatencyBucket() {
    return latencyBucket;
  }

  public String getFallbackReason() {
    return fallbackReason;
  }

  public int getSchemaVersion() {
    return schemaVersion;
  }

  public String getAuditRef() {
    return auditRef;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }
}
