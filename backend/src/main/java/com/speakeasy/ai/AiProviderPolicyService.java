package com.speakeasy.ai;

import com.speakeasy.commerce.EntitlementGateService;
import com.speakeasy.common.ApiException;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

@Service
public class AiProviderPolicyService {
  private static final TierPolicy FREE = new TierPolicy("free", 1200, 60, 5_000_000L);
  private static final TierPolicy PRO = new TierPolicy("pro", 2400, 180, 20_000_000L);
  private static final TierPolicy ENTERPRISE = new TierPolicy("enterprise", 4000, 600, 100_000_000L);

  private final EntitlementGateService entitlementGateService;
  private final AiProviderTelemetry telemetry;
  private final AiMediaReferenceService mediaReferenceService;
  private final AiCostMetricsService costMetricsService;
  private final String providerName;

  public AiProviderPolicyService(
      EntitlementGateService entitlementGateService,
      AiProviderTelemetry telemetry,
      AiMediaReferenceService mediaReferenceService,
      AiCostMetricsService costMetricsService,
      @Value("${speakeasy.ai.provider:deterministic}") String providerName) {
    this.entitlementGateService = entitlementGateService;
    this.telemetry = telemetry;
    this.mediaReferenceService = mediaReferenceService;
    this.costMetricsService = costMetricsService;
    this.providerName = providerName == null ? "deterministic" : providerName.trim();
  }

  public String validateText(UUID userId, String usageFamily, String text) {
    Instant started = Instant.now();
    TierPolicy policy = policyFor(userId);
    String cleaned = text == null ? "" : text.trim();
    if (cleaned.length() > policy.maxTextChars()) {
      record(policy, usageFamily, "rejected", started, "text_length_exceeded", tokenEstimate(cleaned), null);
      costMetricsService.recordPolicyRejection(userId, usageFamily, policy.tier(), tokenEstimate(cleaned), null, "text_length_exceeded");
      throw limitExceeded(
          usageFamily,
          policy,
          "Text input exceeds the current plan limit.",
          Map.of("max_text_chars", policy.maxTextChars()));
    }
    record(policy, usageFamily, "allowed", started, "", tokenEstimate(cleaned), null);
    return policy.tier();
  }

  public String validateAudioRef(UUID userId, String usageFamily, String audioRef) {
    Instant started = Instant.now();
    TierPolicy policy = policyFor(userId);
    boolean requiresTrustedMedia = "dashscope".equalsIgnoreCase(providerName);
    AiMediaReferenceService.TrustedAudioRef media =
        mediaReferenceService.inspectAudioRef(audioRef, requiresTrustedMedia);
    if (requiresTrustedMedia && !media.valid()) {
      record(policy, usageFamily, "rejected", started, media.invalidReason(), null, null);
      costMetricsService.recordPolicyRejection(userId, usageFamily, policy.tier(), null, null, media.invalidReason());
      throw new ApiException(
          HttpStatus.UNPROCESSABLE_ENTITY,
          "SCHEMA_VALIDATION_FAILED",
          "Audio ref must carry trusted backend media metadata.",
          Map.of("usage_family", usageFamily, "policy_tier", policy.tier(), "media_error", media.invalidReason()));
    }
    Integer duration = media.durationSeconds();
    if (duration != null && duration > policy.maxAudioDurationSeconds()) {
      record(policy, usageFamily, "rejected", started, "audio_duration_exceeded", null, duration);
      costMetricsService.recordPolicyRejection(userId, usageFamily, policy.tier(), null, duration, "audio_duration_exceeded");
      throw limitExceeded(
          usageFamily,
          policy,
          "Audio duration exceeds the current plan limit.",
          Map.of("max_audio_duration_seconds", policy.maxAudioDurationSeconds()));
    }
    Long bytes = media.bytes();
    if (bytes != null && bytes > policy.maxAudioBytes()) {
      record(policy, usageFamily, "rejected", started, "audio_size_exceeded", null, duration);
      costMetricsService.recordPolicyRejection(userId, usageFamily, policy.tier(), null, duration, "audio_size_exceeded");
      throw limitExceeded(
          usageFamily,
          policy,
          "Audio size exceeds the current plan limit.",
          Map.of("max_audio_bytes", policy.maxAudioBytes()));
    }
    record(policy, usageFamily, "allowed", started, "", null, duration);
    return policy.tier();
  }

  private TierPolicy policyFor(UUID userId) {
    String plan = entitlementGateService.planFor(userId).toLowerCase(Locale.ROOT);
    if (plan.contains("enterprise")) {
      return ENTERPRISE;
    }
    if (plan.contains("pro") || plan.contains("monthly") || plan.contains("yearly") || plan.contains("paid")) {
      return PRO;
    }
    return FREE;
  }

  private ApiException limitExceeded(
      String usageFamily, TierPolicy policy, String message, Map<String, Object> extraDetails) {
    java.util.LinkedHashMap<String, Object> details = new java.util.LinkedHashMap<>();
    details.put("usage_family", usageFamily);
    details.put("policy_tier", policy.tier());
    details.putAll(extraDetails);
    return new ApiException(HttpStatus.TOO_MANY_REQUESTS, "USAGE_LIMIT_EXCEEDED", message, details);
  }

  private void record(
      TierPolicy policy,
      String usageFamily,
      String status,
      Instant started,
      String fallbackReason,
      Integer tokenEstimate,
      Integer audioDurationSeconds) {
    long latencyMs = Math.max(0, Duration.between(started, Instant.now()).toMillis());
    telemetry.record(
        new AiProviderTelemetry.Event(
            "ai-gateway",
            "policy",
            usageFamily,
            status,
            latencyMs,
            fallbackReason == null ? "" : fallbackReason,
            policy.tier(),
            tokenEstimate,
            audioDurationSeconds,
            costBucket(tokenEstimate, audioDurationSeconds)));
  }

  private String costBucket(Integer tokenEstimate, Integer audioDurationSeconds) {
    int units = (tokenEstimate == null ? 0 : tokenEstimate) + (audioDurationSeconds == null ? 0 : audioDurationSeconds * 2);
    if (units <= 100) {
      return "low";
    }
    if (units <= 600) {
      return "medium";
    }
    return "high";
  }

  private Integer tokenEstimate(String text) {
    if (text == null || text.isBlank()) {
      return 0;
    }
    return Math.max(1, text.length() / 4);
  }

  private record TierPolicy(String tier, int maxTextChars, int maxAudioDurationSeconds, long maxAudioBytes) {}
}
