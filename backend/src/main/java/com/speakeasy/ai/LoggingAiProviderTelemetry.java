package com.speakeasy.ai;

import java.util.logging.Logger;
import org.springframework.stereotype.Component;

@Component
public class LoggingAiProviderTelemetry implements AiProviderTelemetry {
  private static final Logger logger = Logger.getLogger(LoggingAiProviderTelemetry.class.getName());

  @Override
  public void record(Event event) {
    logger.info(
        () ->
            "ai_provider_event provider=%s model=%s family=%s status=%s latency_ms=%d fallback=%s policy_tier=%s token_estimate=%s audio_duration_seconds=%s cost_bucket=%s"
                .formatted(
                    safe(event.provider()),
                    safe(event.model()),
                    safe(event.usageFamily()),
                    safe(event.status()),
                    event.latencyMs(),
                    safe(event.fallbackReason()),
                    safe(event.policyTier()),
                    value(event.tokenEstimate()),
                    value(event.audioDurationSeconds()),
                    safe(event.estimatedCostBucket())));
  }

  private String safe(String value) {
    return value == null || value.isBlank() ? "none" : value.replaceAll("[\\r\\n\\t ]+", "_");
  }

  private String value(Integer value) {
    return value == null ? "none" : value.toString();
  }
}
