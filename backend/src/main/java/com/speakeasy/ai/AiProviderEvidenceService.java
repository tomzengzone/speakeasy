package com.speakeasy.ai;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiProviderEvidenceService {
  private static final Set<String> VALID_STATUS = Set.of("planned", "executed", "failed", "blocked");
  private static final Set<String> VALID_REVIEWED_STATUS = Set.of("pending", "approved", "rejected");

  private final AiProviderSandboxRunRepository sandboxRuns;

  public AiProviderEvidenceService(AiProviderSandboxRunRepository sandboxRuns) {
    this.sandboxRuns = sandboxRuns;
  }

  @Transactional(readOnly = true)
  public EvidenceList listEvidence() {
    return new EvidenceList(
        1,
        sandboxRuns.findAllByOrderByExecutedAtDescCreatedAtDescEvidenceIdAsc().stream()
            .map(Evidence::from)
            .toList());
  }

  private static String contractStatus(String value) {
    String cleaned = normalize(value);
    return VALID_STATUS.contains(cleaned) ? cleaned : "blocked";
  }

  private static String contractReviewedStatus(String value) {
    String cleaned = normalize(value);
    return VALID_REVIEWED_STATUS.contains(cleaned) ? cleaned : "pending";
  }

  private static String normalize(String value) {
    return value == null ? "" : value.toLowerCase(Locale.ROOT).trim();
  }

  private static String redactedEvidenceRef(String value) {
    String cleaned = value == null ? "" : value.trim();
    if (cleaned.isBlank()) {
      return "redacted:missing-evidence-ref";
    }
    String lower = cleaned.toLowerCase(Locale.ROOT);
    if (containsSensitiveMarker(lower)) {
      return "redacted:evidence-ref";
    }
    return cleaned.length() <= 240 ? cleaned : cleaned.substring(0, 240);
  }

  private static boolean containsSensitiveMarker(String value) {
    return value.contains("api_key")
        || value.contains("apikey")
        || value.contains("access_key")
        || value.contains("accesskey")
        || value.contains("secret")
        || value.contains("authorization")
        || value.contains("bearer")
        || value.contains("signature")
        || value.contains("x-oss")
        || value.contains("token=")
        || value.contains("signed")
        || value.contains("raw_payload")
        || value.contains("raw_audio")
        || value.contains("full_transcript")
        || value.contains("transcript=")
        || ((value.startsWith("http://") || value.startsWith("https://")) && value.contains("?"));
  }

  public record EvidenceList(int schemaVersion, List<Evidence> evidence) {}

  public record Evidence(
      String evidenceId,
      String providerFamily,
      String capability,
      String status,
      String reviewedStatus,
      String evidenceRef,
      Integer latencyP50Ms,
      Integer latencyP95Ms,
      BigDecimal estimatedCost,
      Instant executedAt) {
    static Evidence from(AiProviderSandboxRun run) {
      return new Evidence(
          run.getEvidenceId(),
          run.getProviderFamily(),
          run.getCapability(),
          contractStatus(run.getStatus()),
          contractReviewedStatus(run.getReviewedStatus()),
          redactedEvidenceRef(run.getEvidenceRef()),
          run.getLatencyP50Ms(),
          run.getLatencyP95Ms(),
          run.getEstimatedCost(),
          run.getExecutedAt());
    }
  }
}
