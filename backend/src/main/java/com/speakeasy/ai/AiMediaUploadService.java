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
  private final AiMediaProperties properties;
  private final Clock clock;

  public AiMediaUploadService(
      AiMediaAssetRepository mediaAssets,
      AiMediaReferenceService mediaReferences,
      AiMediaProperties properties,
      Clock clock) {
    this.mediaAssets = mediaAssets;
    this.mediaReferences = mediaReferences;
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
        return existing.get();
      }
    }
    validateUploadRequest(purpose, contentType, byteSize, durationSeconds);
    UUID mediaId = UUID.randomUUID();
    Instant now = Instant.now(clock);
    Instant expiresAt = now.plus(properties.getUploadTtl());
    String extension = extensionFor(contentType);
    String providerRef = properties.getPublicBaseUrl() + "/" + mediaId + extension;
    String signedProviderRef = mediaReferences.signTrustedAudioRef(providerRef, durationSeconds, byteSize);
    String uploadUrl = properties.getUploadBaseUrl() + "/" + mediaId + extension;
    String audioRef = "media://audio/" + mediaId;
    String auditRef = mediaReferences.auditRef(audioRef);
    return mediaAssets.save(new AiMediaAsset(
        mediaId,
        userId,
        effectiveClientUploadId,
        purpose,
        audioRef,
        signedProviderRef,
        auditRef,
        uploadUrl,
        contentType,
        byteSize,
        durationSeconds,
        checksumSha256,
        expiresAt,
        now));
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
      asset.markValidated(objectRef, checksumSha256, now);
    }
    return mediaAssets.save(asset);
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

  private String extensionFor(String contentType) {
    return switch (contentType) {
      case "audio/m4a", "audio/mp4" -> ".m4a";
      case "audio/mpeg" -> ".mp3";
      case "audio/wav" -> ".wav";
      case "audio/webm" -> ".webm";
      default -> ".audio";
    };
  }
}
