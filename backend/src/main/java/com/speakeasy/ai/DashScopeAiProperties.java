package com.speakeasy.ai;

import java.time.Duration;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "speakeasy.ai.dashscope")
public class DashScopeAiProperties {
  private String apiKey = "";
  private String compatibleBaseUrl = "https://dashscope.aliyuncs.com/compatible-mode/v1";
  private String apiBaseUrl = "https://dashscope.aliyuncs.com/api/v1";
  private String llmModel = "qwen-plus";
  private String ttsUrl = "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation";
  private String ttsModel = "qwen3-tts-flash";
  private String ttsVoice = "Cherry";
  private String asrModel = "paraformer-v2";
  private int maxTextChars = 1200;
  private int maxAsrDurationSeconds = 120;
  private long maxAsrBytes = 10_000_000L;
  private int asrPollAttempts = 6;
  private Duration requestTimeout = Duration.ofSeconds(20);

  public String getApiKey() {
    return apiKey;
  }

  public void setApiKey(String apiKey) {
    this.apiKey = safe(apiKey);
  }

  public String getCompatibleBaseUrl() {
    return compatibleBaseUrl;
  }

  public void setCompatibleBaseUrl(String compatibleBaseUrl) {
    this.compatibleBaseUrl = safeOrDefault(compatibleBaseUrl, this.compatibleBaseUrl);
  }

  public String getApiBaseUrl() {
    return apiBaseUrl;
  }

  public void setApiBaseUrl(String apiBaseUrl) {
    this.apiBaseUrl = safeOrDefault(apiBaseUrl, this.apiBaseUrl);
  }

  public String getLlmModel() {
    return llmModel;
  }

  public void setLlmModel(String llmModel) {
    this.llmModel = safeOrDefault(llmModel, this.llmModel);
  }

  public String getTtsUrl() {
    return ttsUrl;
  }

  public void setTtsUrl(String ttsUrl) {
    this.ttsUrl = safeOrDefault(ttsUrl, this.ttsUrl);
  }

  public String getTtsModel() {
    return ttsModel;
  }

  public void setTtsModel(String ttsModel) {
    this.ttsModel = safeOrDefault(ttsModel, this.ttsModel);
  }

  public String getTtsVoice() {
    return ttsVoice;
  }

  public void setTtsVoice(String ttsVoice) {
    this.ttsVoice = safeOrDefault(ttsVoice, this.ttsVoice);
  }

  public String getAsrModel() {
    return asrModel;
  }

  public void setAsrModel(String asrModel) {
    this.asrModel = safeOrDefault(asrModel, this.asrModel);
  }

  public int getMaxTextChars() {
    return maxTextChars;
  }

  public void setMaxTextChars(int maxTextChars) {
    this.maxTextChars = Math.max(1, maxTextChars);
  }

  public int getMaxAsrDurationSeconds() {
    return maxAsrDurationSeconds;
  }

  public void setMaxAsrDurationSeconds(int maxAsrDurationSeconds) {
    this.maxAsrDurationSeconds = Math.max(1, maxAsrDurationSeconds);
  }

  public long getMaxAsrBytes() {
    return maxAsrBytes;
  }

  public void setMaxAsrBytes(long maxAsrBytes) {
    this.maxAsrBytes = Math.max(1, maxAsrBytes);
  }

  public int getAsrPollAttempts() {
    return asrPollAttempts;
  }

  public void setAsrPollAttempts(int asrPollAttempts) {
    this.asrPollAttempts = Math.max(1, asrPollAttempts);
  }

  public Duration getRequestTimeout() {
    return requestTimeout;
  }

  public void setRequestTimeout(Duration requestTimeout) {
    this.requestTimeout = requestTimeout == null ? Duration.ofSeconds(20) : requestTimeout;
  }

  private String safe(String value) {
    return value == null ? "" : value.trim();
  }

  private String safeOrDefault(String value, String fallback) {
    String cleaned = safe(value);
    return cleaned.isBlank() ? fallback : cleaned;
  }
}
