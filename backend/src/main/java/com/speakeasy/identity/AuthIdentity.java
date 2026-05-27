package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "auth_identities")
public class AuthIdentity {
  @Id
  @Column(name = "auth_identity_id", nullable = false)
  private UUID authIdentityId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "provider", nullable = false)
  private String provider;

  @Column(name = "provider_subject", nullable = false)
  private String providerSubject;

  @Column(name = "linked_at", nullable = false)
  private Instant linkedAt;

  @Column(name = "status", nullable = false)
  private String status;

  protected AuthIdentity() {}

  public AuthIdentity(UUID authIdentityId, UUID userId, String provider, String providerSubject, Instant linkedAt) {
    this.authIdentityId = authIdentityId;
    this.userId = userId;
    this.provider = provider;
    this.providerSubject = providerSubject;
    this.linkedAt = linkedAt;
    this.status = "active";
  }

  public UUID getUserId() {
    return userId;
  }
}
