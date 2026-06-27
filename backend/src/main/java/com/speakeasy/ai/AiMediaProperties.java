package com.speakeasy.ai;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "speakeasy.ai.media")
public class AiMediaProperties {
  private String metadataSigningKey = "";
  private boolean allowUnsignedHeadMetadata = false;
  private String durationHeader = "X-Speakeasy-Audio-Duration-Seconds";
  private Duration metadataTimeout = Duration.ofSeconds(5);
  private String publicBaseUrl = "https://media.speakeasy.local/audio";
  private String uploadBaseUrl = "https://upload.speakeasy.local/audio";
  private Duration uploadTtl = Duration.ofMinutes(15);
  private Duration providerReadTtl = Duration.ofMinutes(10);
  private Duration ttsCacheTtl = Duration.ofDays(7);
  private long maxUploadBytes = 10_000_000L;
  private int maxUploadDurationSeconds = 120;
  private String storageProvider = "local";
  private String ossEndpoint = "";
  private String ossBucket = "";
  private String ossAccessKeyId = "";
  private String ossAccessKeySecret = "";
  private String ossObjectPrefix = "audio/uploads";
  private String ossServerSideEncryption = "";

  public String getMetadataSigningKey() {
    return metadataSigningKey;
  }

  public void setMetadataSigningKey(String metadataSigningKey) {
    this.metadataSigningKey = metadataSigningKey == null ? "" : metadataSigningKey.trim();
  }

  public boolean isAllowUnsignedHeadMetadata() {
    return allowUnsignedHeadMetadata;
  }

  public void setAllowUnsignedHeadMetadata(boolean allowUnsignedHeadMetadata) {
    this.allowUnsignedHeadMetadata = allowUnsignedHeadMetadata;
  }

  public String getDurationHeader() {
    return durationHeader;
  }

  public void setDurationHeader(String durationHeader) {
    String cleaned = durationHeader == null ? "" : durationHeader.trim();
    this.durationHeader = cleaned.isBlank() ? this.durationHeader : cleaned;
  }

  public Duration getMetadataTimeout() {
    return metadataTimeout;
  }

  public void setMetadataTimeout(Duration metadataTimeout) {
    this.metadataTimeout = metadataTimeout == null ? Duration.ofSeconds(5) : metadataTimeout;
  }

  public String getPublicBaseUrl() {
    return publicBaseUrl;
  }

  public void setPublicBaseUrl(String publicBaseUrl) {
    String cleaned = publicBaseUrl == null ? "" : publicBaseUrl.trim();
    this.publicBaseUrl = cleaned.isBlank() ? this.publicBaseUrl : trimTrailingSlash(cleaned);
  }

  public String getUploadBaseUrl() {
    return uploadBaseUrl;
  }

  public void setUploadBaseUrl(String uploadBaseUrl) {
    String cleaned = uploadBaseUrl == null ? "" : uploadBaseUrl.trim();
    this.uploadBaseUrl = cleaned.isBlank() ? this.uploadBaseUrl : trimTrailingSlash(cleaned);
  }

  public Duration getUploadTtl() {
    return uploadTtl;
  }

  public void setUploadTtl(Duration uploadTtl) {
    this.uploadTtl = uploadTtl == null ? Duration.ofMinutes(15) : uploadTtl;
  }

  public Duration getProviderReadTtl() {
    return providerReadTtl;
  }

  public void setProviderReadTtl(Duration providerReadTtl) {
    this.providerReadTtl = providerReadTtl == null ? Duration.ofMinutes(10) : providerReadTtl;
  }

  public Duration getTtsCacheTtl() {
    return ttsCacheTtl;
  }

  public void setTtsCacheTtl(Duration ttsCacheTtl) {
    this.ttsCacheTtl = ttsCacheTtl == null ? Duration.ofDays(7) : ttsCacheTtl;
  }

  public long getMaxUploadBytes() {
    return maxUploadBytes;
  }

  public void setMaxUploadBytes(long maxUploadBytes) {
    this.maxUploadBytes = maxUploadBytes <= 0 ? this.maxUploadBytes : maxUploadBytes;
  }

  public int getMaxUploadDurationSeconds() {
    return maxUploadDurationSeconds;
  }

  public void setMaxUploadDurationSeconds(int maxUploadDurationSeconds) {
    this.maxUploadDurationSeconds = maxUploadDurationSeconds <= 0 ? this.maxUploadDurationSeconds : maxUploadDurationSeconds;
  }

  public String getStorageProvider() {
    return storageProvider;
  }

  public void setStorageProvider(String storageProvider) {
    String cleaned = storageProvider == null ? "" : storageProvider.trim();
    this.storageProvider = cleaned.isBlank() ? "local" : cleaned;
  }

  public String getOssEndpoint() {
    return ossEndpoint;
  }

  public void setOssEndpoint(String ossEndpoint) {
    this.ossEndpoint = clean(ossEndpoint);
  }

  public String getOssBucket() {
    return ossBucket;
  }

  public void setOssBucket(String ossBucket) {
    this.ossBucket = clean(ossBucket);
  }

  public String getOssAccessKeyId() {
    return ossAccessKeyId;
  }

  public void setOssAccessKeyId(String ossAccessKeyId) {
    this.ossAccessKeyId = clean(ossAccessKeyId);
  }

  public String getOssAccessKeySecret() {
    return ossAccessKeySecret;
  }

  public void setOssAccessKeySecret(String ossAccessKeySecret) {
    this.ossAccessKeySecret = clean(ossAccessKeySecret);
  }

  public String getOssObjectPrefix() {
    return ossObjectPrefix;
  }

  public void setOssObjectPrefix(String ossObjectPrefix) {
    String cleaned = clean(ossObjectPrefix);
    this.ossObjectPrefix = cleaned.isBlank() ? "audio/uploads" : trimSlashes(cleaned);
  }

  public String getOssServerSideEncryption() {
    return ossServerSideEncryption;
  }

  public void setOssServerSideEncryption(String ossServerSideEncryption) {
    this.ossServerSideEncryption = clean(ossServerSideEncryption);
  }

  private String trimTrailingSlash(String value) {
    return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
  }

  private String trimSlashes(String value) {
    String cleaned = value;
    while (cleaned.startsWith("/")) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.endsWith("/")) {
      cleaned = cleaned.substring(0, cleaned.length() - 1);
    }
    return cleaned;
  }

  private String clean(String value) {
    return value == null ? "" : value.trim();
  }
}
