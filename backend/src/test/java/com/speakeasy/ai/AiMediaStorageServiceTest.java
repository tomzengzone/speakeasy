package com.speakeasy.ai;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.aliyun.oss.HttpMethod;
import com.aliyun.oss.OSS;
import com.aliyun.oss.model.GeneratePresignedUrlRequest;
import java.net.URL;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

class AiMediaStorageServiceTest {
  @Test
  void aliyunOssAdapterCreatesCanonicalObjectRefAndSignedUrls() throws Exception {
    AiMediaProperties properties = aliyunProperties();
    OSS oss = mock(OSS.class);
    when(oss.generatePresignedUrl(any(GeneratePresignedUrlRequest.class)))
        .thenReturn(new URL("https://speakeasy-ai-media-staging.oss-cn-hangzhou.aliyuncs.com/upload?Signature=redacted"));
    when(oss.generatePresignedUrl(eq("speakeasy-ai-media-staging"), anyString(), any(Date.class), eq(HttpMethod.GET)))
        .thenReturn(new URL("https://speakeasy-ai-media-staging.oss-cn-hangzhou.aliyuncs.com/read?Signature=redacted"));

    AliyunOssMediaStorageService storage = new AliyunOssMediaStorageService(properties, oss);
    UUID mediaId = UUID.fromString("11111111-1111-1111-1111-111111111111");
    UUID userId = UUID.fromString("22222222-2222-2222-2222-222222222222");

    AiMediaStorageService.PreparedUpload upload = storage.prepareUpload(new AiMediaStorageService.UploadRequest(
        mediaId,
        userId,
        "asr_input",
        "audio/m4a",
        240000,
        12,
        "checksum",
        Instant.parse("2026-06-03T12:00:00Z")));

    assertThat(upload.objectRef())
        .isEqualTo("oss://speakeasy-ai-media-staging/audio/uploads/222222222222/11111111-1111-1111-1111-111111111111.m4a");
    assertThat(upload.providerRef()).isEqualTo(upload.objectRef());
    assertThat(upload.uploadUrl()).contains("Signature=redacted");
    assertThat(upload.uploadHeaders()).containsEntry("Content-Type", "audio/m4a");
    assertThat(upload.uploadHeaders()).containsEntry("x-oss-meta-speakeasy-purpose", "asr_input");
    assertThat(upload.uploadHeaders()).containsEntry("x-oss-server-side-encryption", "KMS");
    ArgumentCaptor<GeneratePresignedUrlRequest> presignCaptor =
        ArgumentCaptor.forClass(GeneratePresignedUrlRequest.class);
    verify(oss).generatePresignedUrl(presignCaptor.capture());
    GeneratePresignedUrlRequest presignRequest = presignCaptor.getValue();
    assertThat(presignRequest.getBucketName()).isEqualTo("speakeasy-ai-media-staging");
    assertThat(presignRequest.getKey())
        .isEqualTo("audio/uploads/222222222222/11111111-1111-1111-1111-111111111111.m4a");
    assertThat(presignRequest.getMethod()).isEqualTo(HttpMethod.PUT);
    assertThat(presignRequest.getContentType()).isEqualTo("audio/m4a");
    assertThat(presignRequest.getHeaders()).containsEntry("x-oss-meta-speakeasy-purpose", "asr_input");
    assertThat(presignRequest.getHeaders()).containsEntry("x-oss-server-side-encryption", "KMS");

    AiMediaAsset asset = new AiMediaAsset(
        mediaId,
        userId,
        "client-upload",
        "asr_input",
        "media://audio/" + mediaId,
        upload.providerRef(),
        "media:audit",
        upload.uploadUrl(),
        "audio/m4a",
        240000,
        12,
        "checksum",
        Instant.parse("2026-06-03T12:00:00Z"),
        Instant.parse("2026-06-03T11:45:00Z"));
    asset.assignObjectRef(upload.objectRef());
    asset.markValidated(upload.objectRef(), "checksum", Instant.parse("2026-06-03T11:50:00Z"));

    assertThat(storage.providerReadRef(asset, Instant.parse("2026-06-03T11:55:00Z")))
        .contains("Signature=redacted");
    storage.deleteObject(asset);

    verify(oss, times(1)).generatePresignedUrl(
        eq("speakeasy-ai-media-staging"),
        eq("audio/uploads/222222222222/11111111-1111-1111-1111-111111111111.m4a"),
        any(Date.class),
        eq(HttpMethod.GET));
    verify(oss).deleteObject(
        "speakeasy-ai-media-staging",
        "audio/uploads/222222222222/11111111-1111-1111-1111-111111111111.m4a");
  }

  @Test
  void localAdapterRejectsForgedCompletedObjectRef() {
    AiMediaProperties properties = new AiMediaProperties();
    LocalAiMediaStorageService storage = new LocalAiMediaStorageService(properties);
    UUID mediaId = UUID.fromString("33333333-3333-3333-3333-333333333333");
    UUID userId = UUID.fromString("44444444-4444-4444-4444-444444444444");
    AiMediaStorageService.PreparedUpload upload = storage.prepareUpload(new AiMediaStorageService.UploadRequest(
        mediaId,
        userId,
        "asr_input",
        "audio/m4a",
        100,
        5,
        "checksum",
        Instant.now().plus(Duration.ofMinutes(15))));
    AiMediaAsset asset = new AiMediaAsset(
        mediaId,
        userId,
        "client-upload",
        "asr_input",
        "media://audio/" + mediaId,
        upload.providerRef(),
        "media:audit",
        upload.uploadUrl(),
        "audio/m4a",
        100,
        5,
        "checksum",
        Instant.now().plus(Duration.ofMinutes(15)),
        Instant.now());
    asset.assignObjectRef(upload.objectRef());

    assertThat(storage.resolveCompletedObjectRef(asset, null)).isEqualTo(upload.objectRef());
    org.junit.jupiter.api.Assertions.assertThrows(
        IllegalArgumentException.class,
        () -> storage.resolveCompletedObjectRef(asset, "object://speakeasy-ai-media/forged.m4a"));
  }

  private AiMediaProperties aliyunProperties() {
    AiMediaProperties properties = new AiMediaProperties();
    properties.setOssEndpoint("https://oss-cn-hangzhou.aliyuncs.com");
    properties.setOssBucket("speakeasy-ai-media-staging");
    properties.setOssAccessKeyId("test-key");
    properties.setOssAccessKeySecret("test-secret");
    properties.setOssObjectPrefix("audio/uploads");
    properties.setOssServerSideEncryption("KMS");
    return properties;
  }
}
