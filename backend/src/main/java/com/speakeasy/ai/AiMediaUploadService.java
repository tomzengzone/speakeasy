package com.speakeasy.ai;

import com.speakeasy.common.ApiException;
import java.time.Clock;
import java.time.Instant;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiMediaUploadService {
  private static final Set<String> SUPPORTED_CONTENT_TYPES =
      Set.of("audio/m4a", "audio/mp4", "audio/mpeg", "audio/wav", "audio/webm");

  private final AiMediaAssetRepository mediaAssets;
  private final AiMediaReferenceService mediaReferences;
  private final AiMediaStorageService mediaStorage;
  private final AiMediaProperties properties;
  private final Clock clock;

  public AiMediaUploadService(
      AiMediaAssetRepository mediaAssets,
      AiMediaReferenceService mediaReferences,
      AiMediaStorageService mediaStorage,
      AiMediaProperties properties,
      Clock clock) {
    this.mediaAssets = mediaAssets;
    this.mediaReferences = mediaReferences;
    this.mediaStorage = mediaStorage;
    this.properties = properties;
    this.clock = clock;
  }

  @Transactional
  public AiMediaAsset createUpload(
      UUID userId,
      String idempotencyKey,
      String purpose,
      String contentType,
      long byteSize,
      int durationSeconds,
      String checksumSha256,
      String clientUploadId) {
    String effectiveClientUploadId = firstNonBlank(clientUploadId, idempotencyKey);
    if (effectiveClientUploadId != null) {
      var existing = mediaAssets.findByUserIdAndClientUploadId(userId, effectiveClientUploadId);
      if (existing.isPresent()) {
        AiMediaAsset media = existing.get();
        media.setUploadHeaders(mediaStorage.uploadHeaders(media));
        return media;
      }
    }
    validateUploadRequest(purpose, contentType, byteSize, durationSeconds);
    UUID mediaId = UUID.randomUUID();
    Instant now = Instant.now(clock);
    Instant expiresAt = now.plus(properties.getUploadTtl());
    AiMediaStorageService.PreparedUpload upload = mediaStorage.prepareUpload(new AiMediaStorageService.UploadRequest(
        mediaId,
        userId,
        purpose,
        contentType,
        byteSize,
        durationSeconds,
        checksumSha256,
        expiresAt));
    String audioRef = "media://audio/" + mediaId;
    String auditRef = mediaReferences.auditRef(audioRef);
    AiMediaAsset media = new AiMediaAsset(
        mediaId,
        userId,
        effectiveClientUploadId,
        purpose,
        audioRef,
        upload.providerRef(),
        auditRef,
        upload.uploadUrl(),
        contentType,
        byteSize,
        durationSeconds,
        checksumSha256,
        expiresAt,
        now);
    media.assignObjectRef(upload.objectRef());
    media.setUploadHeaders(upload.uploadHeaders());
    AiMediaAsset saved = mediaAssets.save(media);
    saved.setUploadHeaders(upload.uploadHeaders());
    return saved;
  }

  @Transactional
  public AiMediaAsset completeUpload(UUID userId, UUID mediaId, String checksumSha256, String objectRef) {
    AiMediaAsset asset = mediaAssets.findById(mediaId)
        .filter(found -> found.getUserId().equals(userId))
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Media asset not found."));
    Instant now = Instant.now(clock);
    if (asset.getDeletedAt() != null || asset.getExpiresAt().isBefore(now)) {
      asset.markRejected(now);
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Media upload expired.");
    }
    if (!"pending".equals(asset.getStatus()) && !"uploaded".equals(asset.getStatus()) && !"validated".equals(asset.getStatus())) {
      throw new ApiException(
          HttpStatus.CONFLICT,
          "CONFLICT",
          "Media asset is not in a completable state.",
          Map.of("status", asset.getStatus()));
    }
    if (asset.getChecksumSha256() != null
        && checksumSha256 != null
        && !asset.getChecksumSha256().equalsIgnoreCase(checksumSha256.trim())) {
      asset.markRejected(now);
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Media checksum mismatch.");
    }
    if (!"validated".equals(asset.getStatus())) {
      String completedObjectRef;
      try {
        completedObjectRef = mediaStorage.resolveCompletedObjectRef(asset, objectRef);
      } catch (IllegalArgumentException e) {
        asset.markRejected(now);
        throw new ApiException(
            HttpStatus.UNPROCESSABLE_ENTITY,
            "SCHEMA_VALIDATION_FAILED",
            "Media object reference mismatch.",
            Map.of("media_error", e.getMessage()));
      }
      asset.markValidated(completedObjectRef, checksumSha256, now);
    }
    AiMediaAsset saved = mediaAssets.save(asset);
    saved.setUploadHeaders(mediaStorage.uploadHeaders(saved));
    return saved;
  }

  private void validateUploadRequest(String purpose, String contentType, long byteSize, int durationSeconds) {
    if (!"asr_input".equals(purpose) && !"pronunciation_input".equals(purpose)) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Unsupported media purpose.");
    }
    if (!SUPPORTED_CONTENT_TYPES.contains(contentType)) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Unsupported audio content type.");
    }
    if (byteSize <= 0 || byteSize > properties.getMaxUploadBytes()) {
      throw new ApiException(
          HttpStatus.BAD_REQUEST,
          "SCHEMA_VALIDATION_FAILED",
          "Audio file size is outside the allowed range.",
          Map.of("max_upload_bytes", properties.getMaxUploadBytes()));
    }
    if (durationSeconds <= 0 || durationSeconds > properties.getMaxUploadDurationSeconds()) {
      throw new ApiException(
          HttpStatus.BAD_REQUEST,
          "SCHEMA_VALIDATION_FAILED",
          "Audio duration is outside the allowed range.",
          Map.of("max_upload_duration_seconds", properties.getMaxUploadDurationSeconds()));
    }
  }

  private String firstNonBlank(String first, String second) {
    String cleanedFirst = first == null ? "" : first.trim();
    if (!cleanedFirst.isBlank()) {
      return cleanedFirst;
    }
    String cleanedSecond = second == null ? "" : second.trim();
    return cleanedSecond.isBlank() ? null : cleanedSecond;
  }
}
