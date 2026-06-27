package com.speakeasy.ai;

public interface AiProviderTelemetry {
  void record(Event event);

  record Event(
      String provider,
      String model,
      String usageFamily,
      String status,
      long latencyMs,
      String fallbackReason,
      String policyTier,
      Integer tokenEstimate,
      Integer audioDurationSeconds,
      String estimatedCostBucket) {}
}
