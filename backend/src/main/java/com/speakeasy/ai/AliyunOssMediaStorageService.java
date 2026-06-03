package com.speakeasy.ai;

import com.aliyun.oss.HttpMethod;
import com.aliyun.oss.OSS;
import com.aliyun.oss.OSSClientBuilder;
import com.aliyun.oss.model.GeneratePresignedUrlRequest;
import java.net.URL;
import java.time.Instant;
import java.util.Date;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.util.StringUtils;

public class AliyunOssMediaStorageService implements AiMediaStorageService {
  private final AiMediaProperties properties;
  private final OSS ossClient;

  public AliyunOssMediaStorageService(AiMediaProperties properties) {
    this(properties, buildClient(properties));
  }

  AliyunOssMediaStorageService(AiMediaProperties properties, OSS ossClient) {
    require(properties.getOssEndpoint(), "ALIYUN_OSS_ENDPOINT");
    require(properties.getOssBucket(), "ALIYUN_OSS_BUCKET");
    require(properties.getOssAccessKeyId(), "ALIYUN_OSS_ACCESS_KEY_ID");
    require(properties.getOssAccessKeySecret(), "ALIYUN_OSS_ACCESS_KEY_SECRET");
    this.properties = properties;
    this.ossClient = ossClient;
  }

  @Override
  public PreparedUpload prepareUpload(UploadRequest request) {
    String objectKey = objectKeyFor(request);
    Date expiresAt = Date.from(request.expiresAt());
    Map<String, String> headers = uploadHeaders(request.contentType(), request.purpose());
    GeneratePresignedUrlRequest presignRequest =
        new GeneratePresignedUrlRequest(properties.getOssBucket(), objectKey, HttpMethod.PUT);
    presignRequest.setExpiration(expiresAt);
    presignRequest.setContentType(request.contentType());
    headers.forEach((name, value) -> {
      if (!"Content-Type".equalsIgnoreCase(name)) {
        presignRequest.addHeader(name, value);
      }
    });
    URL uploadUrl = ossClient.generatePresignedUrl(presignRequest);
    return new PreparedUpload(
        objectRef(objectKey),
        objectRef(objectKey),
        uploadUrl.toString(),
        headers);
  }

  @Override
  public Map<String, String> uploadHeaders(AiMediaAsset asset) {
    return uploadHeaders(asset.getContentType(), asset.getPurpose());
  }

  @Override
  public String providerReadRef(AiMediaAsset asset, Instant now) {
    String key = objectKeyFrom(asset.getObjectRef());
    Instant expiresAt = now.plus(properties.getProviderReadTtl());
    URL readUrl =
        ossClient.generatePresignedUrl(properties.getOssBucket(), key, Date.from(expiresAt), HttpMethod.GET);
    return readUrl.toString();
  }

  @Override
  public void deleteObject(AiMediaAsset asset) {
    String objectRef = asset.getObjectRef();
    if (objectRef == null || objectRef.isBlank()) {
      return;
    }
    ossClient.deleteObject(properties.getOssBucket(), objectKeyFrom(objectRef));
  }

  private String objectKeyFor(UploadRequest request) {
    String userHash = request.userId().toString().replace("-", "").substring(0, 12);
    String extension = extensionFor(request.contentType());
    return properties.getOssObjectPrefix() + "/" + userHash + "/" + request.mediaId() + extension;
  }

  private String objectRef(String objectKey) {
    return "oss://" + properties.getOssBucket() + "/" + objectKey;
  }

  private String objectKeyFrom(String objectRef) {
    String prefix = "oss://" + properties.getOssBucket() + "/";
    if (objectRef == null || !objectRef.startsWith(prefix)) {
      throw new IllegalArgumentException("media_object_ref_mismatch");
    }
    return objectRef.substring(prefix.length());
  }

  private Map<String, String> uploadHeaders(String contentType, String purpose) {
    Map<String, String> headers = new LinkedHashMap<>();
    headers.put("Content-Type", contentType);
    headers.put("x-oss-meta-speakeasy-purpose", purpose);
    if (StringUtils.hasText(properties.getOssServerSideEncryption())) {
      headers.put("x-oss-server-side-encryption", properties.getOssServerSideEncryption());
    }
    return Map.copyOf(headers);
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

  private static OSS buildClient(AiMediaProperties properties) {
    require(properties.getOssEndpoint(), "ALIYUN_OSS_ENDPOINT");
    require(properties.getOssAccessKeyId(), "ALIYUN_OSS_ACCESS_KEY_ID");
    require(properties.getOssAccessKeySecret(), "ALIYUN_OSS_ACCESS_KEY_SECRET");
    return new OSSClientBuilder()
        .build(properties.getOssEndpoint(), properties.getOssAccessKeyId(), properties.getOssAccessKeySecret());
  }

  private static void require(String value, String key) {
    if (!StringUtils.hasText(value)) {
      throw new IllegalStateException(key + " is required when SPEAKEASY_MEDIA_STORAGE_PROVIDER=aliyun-oss");
    }
  }
}
