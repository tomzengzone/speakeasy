package com.speakeasy.ai;

import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "speakeasy.ai", name = "provider", havingValue = "deterministic", matchIfMissing = true)
public class DeterministicAiProviderGateway implements AiProviderGateway {
  private final AtomicInteger invocationCount = new AtomicInteger();

  @Override
  public TranscribeResult transcribe(String audioRef, String languageHint) {
    invocationCount.incrementAndGet();
    String normalized = normalize(audioRef);
    if (normalized.contains("timeout") || normalized.contains("unavailable")) {
      return new TranscribeResult("", 0, "provider_unavailable");
    }
    if (normalized.contains("invalid") || normalized.contains("media_invalid")) {
      return new TranscribeResult("", 0, "no_result");
    }
    return new TranscribeResult("I worked on a project that improved our workflow.", 0.91, "available");
  }

  @Override
  public TtsResult synthesize(String text, String voice) {
    invocationCount.incrementAndGet();
    if (normalize(text).contains("unavailable")) {
      return new TtsResult("provider-unavailable", "provider_unavailable");
    }
    return new TtsResult("tts://mvp/" + Math.abs(text.hashCode()), "available");
  }

  @Override
  public ScoreResult scorePronunciation(String audioRef, String referenceText) {
    invocationCount.incrementAndGet();
    String normalized = normalize(audioRef);
    if (normalized.contains("unavailable")) {
      return new ScoreResult("pronunciation", null, null, "unavailable");
    }
    if (normalized.contains("low_confidence")) {
      return new ScoreResult("pronunciation", 0.45, 0.4, "low_confidence");
    }
    return new ScoreResult("pronunciation", 0.85, 0.86, "available");
  }

  @Override
  public CoachResult coach(UUID sessionId, String transcript, List<String> targetExpressionIds) {
    invocationCount.incrementAndGet();
    String normalized = normalize(transcript);
    if (normalized.contains("invalid_schema")) {
      return fallback("invalid_schema", "AI feedback schema validation failed. Please retry.");
    }
    if (normalized.contains("timeout") || normalized.contains("unavailable")) {
      return fallback("provider_unavailable", "Coach feedback is temporarily unavailable. Please retry.");
    }
    if (normalized.contains("off topic")) {
      return new CoachResult(
          "retry",
          "请回到当前场景，用一句英文回答面试官的问题。",
          "off_topic",
          "I worked on a small project that improved our workflow.",
          "Please answer the interview question in one sentence.",
          new ScoreResult("fluency", 0.48, 0.72, "available"),
          "valid",
          "success",
          null);
    }
    return new CoachResult(
        "next_question",
        "表达清楚，可以更自然地说明你的贡献。",
        "naturalness",
        "My main contribution was coordinating the timeline and clarifying priorities.",
        "What was the biggest challenge in that project?",
        new ScoreResult("pronunciation", 0.85, 0.86, "available"),
        "valid",
        "success",
        null);
  }

  @Override
  public int invocationCount() {
    return invocationCount.get();
  }

  @Override
  public void resetInvocationCount() {
    invocationCount.set(0);
  }

  private CoachResult fallback(String code, String summary) {
    return new CoachResult(
        "recoverable_error",
        summary,
        "none",
        null,
        "Please retry this turn when the service is available.",
        new ScoreResult("pronunciation", null, null, "unavailable"),
        "fallback",
        code,
        code);
  }

  private String normalize(String value) {
    return value == null ? "" : value.toLowerCase(Locale.ROOT);
  }
}
