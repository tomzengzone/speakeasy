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
}
