package com.speakeasy.identity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_accounts")
public class UserAccount {
  @Id
  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "display_name", nullable = false)
  private String displayName;

  @Column(name = "avatar_ref")
  private String avatarRef;

  @Column(name = "locale", nullable = false)
  private String locale;

  @Column(name = "account_status", nullable = false)
  private String accountStatus;

  @Column(name = "onboarding_status", nullable = false)
  private String onboardingStatus;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected UserAccount() {}

  public UserAccount(UUID userId, String displayName, Instant now) {
    this.userId = userId;
    this.displayName = displayName;
    this.locale = "zh-CN";
    this.accountStatus = "active";
    this.onboardingStatus = "incomplete";
    this.createdAt = now;
    this.updatedAt = now;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getDisplayName() {
    return displayName;
  }

  public String getAvatarRef() {
    return avatarRef;
  }

  public String getLocale() {
    return locale;
  }

  public String getAccountStatus() {
    return accountStatus;
  }

  public String getOnboardingStatus() {
    return onboardingStatus;
  }

  public void updateDisplayName(String displayName, Instant updatedAt) {
    if (displayName != null && !displayName.isBlank()) {
      this.displayName = displayName.trim();
      this.updatedAt = updatedAt;
    }
  }

  public void updateAvatarRef(String avatarRef, Instant updatedAt) {
    if (avatarRef != null) {
      this.avatarRef = avatarRef.trim();
      this.updatedAt = updatedAt;
    }
  }

  public void requestDeletion(Instant updatedAt) {
    this.accountStatus = "deletion_requested";
    this.updatedAt = updatedAt;
  }

  public void markDeleted(Instant updatedAt) {
    this.displayName = "Deleted User";
    this.avatarRef = null;
    this.accountStatus = "deleted";
    this.onboardingStatus = "deleted";
    this.updatedAt = updatedAt;
  }

  public void completeOnboarding(Instant updatedAt) {
    this.onboardingStatus = "complete";
    this.updatedAt = updatedAt;
  }
}
