package com.speakeasy.ai;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public interface AiMediaStorageService {
  PreparedUpload prepareUpload(UploadRequest request);

  default Map<String, String> uploadHeaders(AiMediaAsset asset) {
    return Map.of("Content-Type", asset.getContentType(), "x-speakeasy-media-purpose", asset.getPurpose());
  }

  default String providerReadRef(AiMediaAsset asset, Instant now) {
    return asset.getProviderRef();
  }

  default String resolveCompletedObjectRef(AiMediaAsset asset, String suppliedObjectRef) {
    String expected = clean(asset.getObjectRef());
    String supplied = clean(suppliedObjectRef);
    if (expected.isBlank()) {
      return supplied;
    }
    if (supplied.isBlank() || expected.equals(supplied)) {
      return expected;
    }
    throw new IllegalArgumentException("media_object_ref_mismatch");
  }

  default void deleteObject(AiMediaAsset asset) {
    // Local/dev storage keeps deletion as metadata-only unless a concrete adapter overrides this.
  }

  private static String clean(String value) {
    return value == null ? "" : value.trim();
  }

  record UploadRequest(
      UUID mediaId,
      UUID userId,
      String purpose,
      String contentType,
      long byteSize,
      int durationSeconds,
      String checksumSha256,
      Instant expiresAt) {}

  record PreparedUpload(
      String providerRef,
      String objectRef,
      String uploadUrl,
      Map<String, String> uploadHeaders) {}
}
