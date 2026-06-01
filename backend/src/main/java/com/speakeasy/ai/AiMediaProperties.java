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
  private Duration ttsCacheTtl = Duration.ofDays(7);
  private long maxUploadBytes = 10_000_000L;
  private int maxUploadDurationSeconds = 120;

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

  private String trimTrailingSlash(String value) {
    return value.endsWith("/") ? value.substring(0, value.length() - 1) : value;
  }
}
