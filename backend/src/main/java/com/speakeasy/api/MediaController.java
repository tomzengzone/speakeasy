package com.speakeasy.api;

import com.speakeasy.ai.AiMediaAsset;
import com.speakeasy.ai.AiMediaUploadService;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MediaController {
  private final AiMediaUploadService mediaUploadService;

  public MediaController(AiMediaUploadService mediaUploadService) {
    this.mediaUploadService = mediaUploadService;
  }

  @PostMapping("/media/audio/uploads")
  @ResponseStatus(HttpStatus.CREATED)
  public MediaAssetResponse createAudioUpload(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader("Idempotency-Key") String idempotencyKey,
      @Valid @RequestBody AudioUploadCreateRequest request) {
    AiMediaAsset media = mediaUploadService.createUpload(
        currentUser.userId(),
        idempotencyKey,
        request.purpose(),
        request.contentType(),
        request.byteSize(),
        request.durationSeconds(),
        request.checksumSha256(),
        request.clientUploadId());
    return MediaAssetResponse.from(media);
  }

  @PostMapping("/media/audio/uploads/{media_id}/complete")
  public MediaAssetResponse completeAudioUpload(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable("media_id") UUID mediaId,
      @Valid @RequestBody AudioUploadCompleteRequest request) {
    AiMediaAsset media =
        mediaUploadService.completeUpload(currentUser.userId(), mediaId, request.checksumSha256(), request.objectRef());
    return MediaAssetResponse.from(media);
  }

  public record AudioUploadCreateRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String purpose,
      @NotBlank String contentType,
      @Min(1) long byteSize,
      @Min(1) int durationSeconds,
      String checksumSha256,
      String clientUploadId) {}

  public record AudioUploadCompleteRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      String checksumSha256,
      String objectRef) {}

  public record MediaAssetResponse(int schemaVersion, MediaAssetDto media) implements SchemaResponse {
    static MediaAssetResponse from(AiMediaAsset media) {
      return new MediaAssetResponse(1, MediaAssetDto.from(media));
    }
  }

  public record MediaAssetDto(
      UUID mediaId,
      String audioRef,
      String ownerRef,
      String purpose,
      String status,
      String contentType,
      long byteSize,
      int durationSeconds,
      String uploadUrl,
      Map<String, String> uploadHeaders,
      String checksumSha256,
      Instant expiresAt) {
    static MediaAssetDto from(AiMediaAsset media) {
      return new MediaAssetDto(
          media.getMediaId(),
          media.getAudioRef(),
          "user:" + media.getUserId().toString().replace("-", "").substring(0, 12),
          media.getPurpose(),
          media.getStatus(),
          media.getContentType(),
          media.getByteSize(),
          media.getDurationSeconds(),
          media.getUploadUrl(),
          media.getUploadHeaders().isEmpty() ? Map.of("x-speakeasy-media-purpose", media.getPurpose()) : media.getUploadHeaders(),
          media.getChecksumSha256(),
          media.getExpiresAt());
    }
  }
}
