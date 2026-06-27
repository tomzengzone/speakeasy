package com.speakeasy.ai;

import java.util.Map;

public class LocalAiMediaStorageService implements AiMediaStorageService {
  private final AiMediaProperties properties;

  public LocalAiMediaStorageService(AiMediaProperties properties) {
    this.properties = properties;
  }

  @Override
  public PreparedUpload prepareUpload(UploadRequest request) {
    String extension = extensionFor(request.contentType());
    String objectKey = "audio/uploads/" + request.userId().toString().replace("-", "").substring(0, 12)
        + "/" + request.mediaId() + extension;
    String providerRef = properties.getPublicBaseUrl() + "/" + request.mediaId() + extension;
    String uploadUrl = properties.getUploadBaseUrl() + "/" + request.mediaId() + extension;
    return new PreparedUpload(
        providerRef,
        "object://speakeasy-ai-media/" + objectKey,
        uploadUrl,
        Map.of("Content-Type", request.contentType(), "x-speakeasy-media-purpose", request.purpose()));
  }

  @Override
  public Map<String, String> uploadHeaders(AiMediaAsset asset) {
    return Map.of("Content-Type", asset.getContentType(), "x-speakeasy-media-purpose", asset.getPurpose());
  }

  protected String extensionFor(String contentType) {
    return switch (contentType) {
      case "audio/m4a", "audio/mp4" -> ".m4a";
      case "audio/mpeg" -> ".mp3";
      case "audio/wav" -> ".wav";
      case "audio/webm" -> ".webm";
      default -> ".audio";
    };
  }
}
