package com.speakeasy.ai;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Transient;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "ai_media_assets")
public class AiMediaAsset {
  @Id
  @Column(name = "media_id", nullable = false)
  private UUID mediaId;

  @Column(name = "user_id", nullable = false)
  private UUID userId;

  @Column(name = "client_upload_id")
  private String clientUploadId;

  @Column(name = "purpose", nullable = false)
  private String purpose;

  @Column(name = "audio_ref", nullable = false)
  private String audioRef;

  @Column(name = "provider_ref", nullable = false)
  private String providerRef;

  @Column(name = "audit_ref", nullable = false)
  private String auditRef;

  @Column(name = "upload_url")
  private String uploadUrl;

  @Column(name = "object_ref")
  private String objectRef;

  @Column(name = "content_type", nullable = false)
  private String contentType;

  @Column(name = "byte_size", nullable = false)
  private long byteSize;

  @Column(name = "duration_seconds", nullable = false)
  private int durationSeconds;

  @Column(name = "checksum_sha256")
  private String checksumSha256;

  @Column(name = "status", nullable = false)
  private String status;

  @Column(name = "expires_at", nullable = false)
  private Instant expiresAt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "completed_at")
  private Instant completedAt;

  @Column(name = "deleted_at")
  private Instant deletedAt;

  @Transient
  private Map<String, String> uploadHeaders = Map.of();

  protected AiMediaAsset() {}

  public AiMediaAsset(
      UUID mediaId,
      UUID userId,
      String clientUploadId,
      String purpose,
      String audioRef,
      String providerRef,
      String auditRef,
      String uploadUrl,
      String contentType,
      long byteSize,
      int durationSeconds,
      String checksumSha256,
      Instant expiresAt,
      Instant createdAt) {
    this.mediaId = mediaId;
    this.userId = userId;
    this.clientUploadId = clean(clientUploadId);
    this.purpose = purpose;
    this.audioRef = audioRef;
    this.providerRef = providerRef;
    this.auditRef = auditRef;
    this.uploadUrl = uploadUrl;
    this.contentType = contentType;
    this.byteSize = byteSize;
    this.durationSeconds = durationSeconds;
    this.checksumSha256 = clean(checksumSha256);
    this.status = "pending";
    this.expiresAt = expiresAt;
    this.createdAt = createdAt;
  }

  public UUID getMediaId() {
    return mediaId;
  }

  public UUID getUserId() {
    return userId;
  }

  public String getClientUploadId() {
    return clientUploadId;
  }

  public String getPurpose() {
    return purpose;
  }

  public String getAudioRef() {
    return audioRef;
  }

  public String getProviderRef() {
    return providerRef;
  }

  public String getAuditRef() {
    return auditRef;
  }

  public String getUploadUrl() {
    return uploadUrl;
  }

  public String getObjectRef() {
    return objectRef;
  }

  public String getContentType() {
    return contentType;
  }

  public long getByteSize() {
    return byteSize;
  }

  public int getDurationSeconds() {
    return durationSeconds;
  }

  public String getChecksumSha256() {
    return checksumSha256;
  }

  public String getStatus() {
    return status;
  }

  public Instant getExpiresAt() {
    return expiresAt;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getCompletedAt() {
    return completedAt;
  }

  public Instant getDeletedAt() {
    return deletedAt;
  }

  public Map<String, String> getUploadHeaders() {
    return uploadHeaders;
  }

  public void setUploadHeaders(Map<String, String> uploadHeaders) {
    this.uploadHeaders = uploadHeaders == null ? Map.of() : Map.copyOf(uploadHeaders);
  }

  public boolean isValidatedAt(Instant now) {
    return "validated".equals(status) && deletedAt == null && expiresAt.isAfter(now);
  }

  public void assignObjectRef(String objectRef) {
    this.objectRef = clean(objectRef);
  }

  public void markValidated(String objectRef, String checksumSha256, Instant completedAt) {
    this.objectRef = clean(objectRef);
    if (this.checksumSha256 == null || this.checksumSha256.isBlank()) {
      this.checksumSha256 = clean(checksumSha256);
    }
    this.status = "validated";
    this.completedAt = completedAt;
  }

  public void markRejected(Instant completedAt) {
    this.status = "rejected";
    this.completedAt = completedAt;
  }

  public void markDeleted(Instant deletedAt) {
    this.status = "deleted";
    this.deletedAt = deletedAt;
  }

  private String clean(String value) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? null : cleaned;
  }
}
