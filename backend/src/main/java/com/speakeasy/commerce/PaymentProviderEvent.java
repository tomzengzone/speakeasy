package com.speakeasy.commerce;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "payment_provider_events")
public class PaymentProviderEvent {
  @Id
  @Column(name = "provider_event_id", nullable = false)
  private String providerEventId;

  @Column(name = "platform", nullable = false)
  private String platform;

  @Column(name = "event_type", nullable = false)
  private String eventType;

  @Column(name = "received_at", nullable = false)
  private Instant receivedAt;

  @Column(name = "processed_status", nullable = false)
  private String processedStatus;

  @Column(name = "related_subscription_id")
  private UUID relatedSubscriptionId;

  @Column(name = "payload_ref")
  private String payloadRef;

  protected PaymentProviderEvent() {}
}
