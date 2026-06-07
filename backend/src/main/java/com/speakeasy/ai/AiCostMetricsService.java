package com.speakeasy.ai;

import com.speakeasy.commerce.EntitlementGateService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiCostMetricsService {
  private static final BigDecimal TOKEN_UNIT_COST = new BigDecimal("0.000020");
  private static final BigDecimal AUDIO_SECOND_COST = new BigDecimal("0.000500");

  private final AiProviderInvocationMetricRepository metrics;
  private final EntitlementGateService entitlementGateService;
  private final DashScopeAiProperties dashScopeProperties;
  private final Clock clock;
  private final String providerName;
  private final BigDecimal warningThreshold;
  private final BigDecimal exceededThreshold;

  public AiCostMetricsService(
      AiProviderInvocationMetricRepository metrics,
      EntitlementGateService entitlementGateService,
      DashScopeAiProperties dashScopeProperties,
      Clock clock,
      @Value("${speakeasy.ai.provider:deterministic}") String providerName,
      @Value("${speakeasy.ai.ops.daily-budget-warning-cost:0.05}") String warningThreshold,
      @Value("${speakeasy.ai.ops.daily-budget-exceeded-cost:0.10}") String exceededThreshold) {
    this.metrics = metrics;
    this.entitlementGateService = entitlementGateService;
    this.dashScopeProperties = dashScopeProperties;
    this.clock = clock;
    this.providerName = providerName == null || providerName.isBlank() ? "deterministic" : providerName.trim();
    this.warningThreshold = decimal(warningThreshold, "0.05");
    this.exceededThreshold = decimal(exceededThreshold, "0.10");
  }

  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public AiProviderInvocationMetric recordInvocation(
      UUID userId,
      String usageFamily,
      String providerStatus,
      boolean cacheHit,
      Integer tokenEstimate,
      Integer audioDurationSeconds,
      String fallbackReason) {
    String status = normalizeStatus(providerStatus, fallbackReason);
    BigDecimal estimatedCost = estimateCost(status, cacheHit, tokenEstimate, audioDurationSeconds);
    String plan = planFor(userId);
    return metrics.save(new AiProviderInvocationMetric(
        UUID.randomUUID(),
        userHash(userId),
        plan,
        providerFamily(),
        modelFor(usageFamily),
        capabilityFor(usageFamily),
        status,
        cacheHit,
        tokenEstimate,
        audioDurationSeconds,
        estimatedCost,
        "daily_user",
        marginRisk(plan, status, estimatedCost),
        safeReason(fallbackReason),
        Instant.now(clock)));
  }

  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public AiProviderInvocationMetric recordPolicyRejection(
      UUID userId,
      String usageFamily,
      String plan,
      Integer tokenEstimate,
      Integer audioDurationSeconds,
      String fallbackReason) {
    BigDecimal estimatedCost = BigDecimal.ZERO.setScale(6, RoundingMode.HALF_UP);
    return metrics.save(new AiProviderInvocationMetric(
        UUID.randomUUID(),
        userHash(userId),
        normalizePlan(plan),
        "ai-gateway",
        "policy",
        capabilityFor(usageFamily),
        "rejected",
        false,
        tokenEstimate,
        audioDurationSeconds,
        estimatedCost,
        "daily_user",
        "watch",
        safeReason(fallbackReason),
        Instant.now(clock)));
  }

  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public AiProviderInvocationMetric recordDeterministicNoProvider(
      UUID userId,
      String usageFamily,
      String plan,
      Integer tokenEstimate,
      String fallbackReason) {
    return metrics.save(new AiProviderInvocationMetric(
        UUID.randomUUID(),
        userHash(userId),
        normalizePlan(plan == null || plan.isBlank() ? planFor(userId) : plan),
        providerFamily(),
        modelFor(usageFamily),
        capabilityFor(usageFamily),
        "deterministic_no_provider",
        false,
        tokenEstimate,
        null,
        BigDecimal.ZERO.setScale(6, RoundingMode.HALF_UP),
        "daily_user",
        "low",
        safeReason(fallbackReason == null || fallbackReason.isBlank() ? "deterministic_no_provider_call" : fallbackReason),
        Instant.now(clock)));
  }

  @Transactional(readOnly = true)
  public CostMetrics dashboard() {
    LocalDate today = LocalDate.now(clock.withZone(ZoneOffset.UTC));
    Instant from = today.atStartOfDay().toInstant(ZoneOffset.UTC);
    List<AiProviderInvocationMetric> rows = metrics.findByCreatedAtGreaterThanEqual(from);
    Map<MetricKey, MutableAggregate> groups = new LinkedHashMap<>();
    for (AiProviderInvocationMetric row : rows) {
      String period = row.getCreatedAt().atZone(ZoneOffset.UTC).toLocalDate().toString();
      MetricKey key = new MetricKey(
          period,
          row.getPlan(),
          row.getUserHash(),
          row.getProviderFamily(),
          row.getModel(),
          row.getCapability(),
          row.getStatus(),
          row.isCacheHit(),
          row.getFallbackReason() == null ? "" : row.getFallbackReason(),
          row.getBudgetBucket(),
          row.getMarginRisk());
      groups.computeIfAbsent(key, ignored -> new MutableAggregate()).add(row);
    }

    List<CostMetric> aggregated = new ArrayList<>();
    for (Map.Entry<MetricKey, MutableAggregate> entry : groups.entrySet()) {
      MetricKey key = entry.getKey();
      MutableAggregate aggregate = entry.getValue();
      aggregated.add(new CostMetric(
          key.period(),
          key.plan(),
          key.userHash(),
          key.providerFamily(),
          key.model(),
          key.capability(),
          key.status(),
          key.cacheHit(),
          aggregate.callCount,
          aggregate.audioDurationSeconds == 0 ? null : aggregate.audioDurationSeconds,
          aggregate.tokenEstimate == 0 ? null : aggregate.tokenEstimate,
          aggregate.estimatedCost.setScale(6, RoundingMode.HALF_UP),
          key.fallbackReason(),
          key.budgetBucket(),
          key.marginRisk()));
    }
    aggregated.sort(Comparator.comparing(CostMetric::estimatedCost).reversed().thenComparing(CostMetric::capability));
    return new CostMetrics(1, dashboardStatus(rows), aggregated);
  }

  @Transactional(readOnly = true)
  public List<AiProviderInvocationMetric> userMetrics(UUID userId) {
    return metrics.findByUserHashOrderByCreatedAtDesc(userHash(userId));
  }

  public String redactedUserHash(UUID userId) {
    return userHash(userId);
  }

  private String dashboardStatus(List<AiProviderInvocationMetric> rows) {
    if (rows.isEmpty()) {
      return "normal";
    }
    long unavailable = rows.stream().filter(row -> "provider_unavailable".equals(row.getStatus())).count();
    if (rows.size() >= 3 && unavailable * 2 >= rows.size()) {
      return "provider_anomaly";
    }
    BigDecimal total = rows.stream()
        .map(AiProviderInvocationMetric::getEstimatedCost)
        .reduce(BigDecimal.ZERO, BigDecimal::add);
    if (total.compareTo(exceededThreshold) >= 0) {
      return "budget_exceeded";
    }
    if (total.compareTo(warningThreshold) >= 0) {
      return "budget_warning";
    }
    return "normal";
  }

  private String planFor(UUID userId) {
    return normalizePlan(entitlementGateService.planFor(userId));
  }

  private String normalizePlan(String value) {
    String cleaned = value == null ? "" : value.toLowerCase(Locale.ROOT).trim();
    if (cleaned.contains("premium") || cleaned.contains("enterprise")) {
      return "premium";
    }
    if (cleaned.contains("pro") || cleaned.contains("paid") || cleaned.contains("monthly") || cleaned.contains("yearly")) {
      return "pro";
    }
    return "free";
  }

  private String providerFamily() {
    String cleaned = providerName.toLowerCase(Locale.ROOT);
    return cleaned.isBlank() ? "deterministic" : cleaned;
  }

  private String modelFor(String usageFamily) {
    if (!"dashscope".equals(providerFamily())) {
      return providerFamily() + "-provider";
    }
    return switch (capabilityFor(usageFamily)) {
      case "llm" -> dashScopeProperties.getLlmModel();
      case "asr" -> dashScopeProperties.getAsrModel();
      case "tts" -> dashScopeProperties.getTtsModel();
      default -> "dashscope-unconfigured";
    };
  }

  private String capabilityFor(String usageFamily) {
    String cleaned = usageFamily == null ? "" : usageFamily.toLowerCase(Locale.ROOT).trim();
    return switch (cleaned) {
      case "ai" -> "llm";
      case "asr", "tts", "scoring" -> cleaned;
      default -> "llm";
    };
  }

  private String normalizeStatus(String providerStatus, String fallbackReason) {
    String status = providerStatus == null ? "" : providerStatus.toLowerCase(Locale.ROOT).trim();
    if ("available".equals(status) || "success".equals(status)) {
      return "available";
    }
    if ("rejected".equals(status)) {
      return "rejected";
    }
    if ("provider_unavailable".equals(status) || "unavailable".equals(status) || "timeout".equals(status)) {
      return "provider_unavailable";
    }
    String fallback = fallbackReason == null ? "" : fallbackReason.trim();
    return fallback.isBlank() ? "fallback" : "provider_unavailable".equals(fallback) ? "provider_unavailable" : "fallback";
  }

  private BigDecimal estimateCost(
      String status, boolean cacheHit, Integer tokenEstimate, Integer audioDurationSeconds) {
    if (cacheHit || "rejected".equals(status)) {
      return BigDecimal.ZERO.setScale(6, RoundingMode.HALF_UP);
    }
    BigDecimal tokenCost = BigDecimal.valueOf(Math.max(0, tokenEstimate == null ? 0 : tokenEstimate)).multiply(TOKEN_UNIT_COST);
    BigDecimal audioCost = BigDecimal.valueOf(Math.max(0, audioDurationSeconds == null ? 0 : audioDurationSeconds)).multiply(AUDIO_SECOND_COST);
    return tokenCost.add(audioCost).setScale(6, RoundingMode.HALF_UP);
  }

  private String marginRisk(String plan, String status, BigDecimal estimatedCost) {
    if ("provider_unavailable".equals(status)) {
      return "watch";
    }
    if ("free".equals(plan) && estimatedCost.compareTo(new BigDecimal("0.020000")) >= 0) {
      return "high";
    }
    if (estimatedCost.compareTo(new BigDecimal("0.005000")) >= 0) {
      return "watch";
    }
    return "low";
  }

  private String userHash(UUID userId) {
    return "user_sha256:" + sha256(userId == null ? "unknown" : userId.toString()).substring(0, 16);
  }

  private String safeReason(String value) {
    if (value == null || value.isBlank()) {
      return "";
    }
    return value.trim().replaceAll("[\\r\\n\\t ]+", "_");
  }

  private BigDecimal decimal(String value, String fallback) {
    try {
      return new BigDecimal(value == null || value.isBlank() ? fallback : value.trim());
    } catch (NumberFormatException e) {
      return new BigDecimal(fallback);
    }
  }

  private String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException("sha256 unavailable", e);
    }
  }

  private record MetricKey(
      String period,
      String plan,
      String userHash,
      String providerFamily,
      String model,
      String capability,
      String status,
      boolean cacheHit,
      String fallbackReason,
      String budgetBucket,
      String marginRisk) {}

  private static class MutableAggregate {
    int callCount;
    int tokenEstimate;
    int audioDurationSeconds;
    BigDecimal estimatedCost = BigDecimal.ZERO;

    void add(AiProviderInvocationMetric row) {
      callCount += 1;
      tokenEstimate += row.getTokenEstimate() == null ? 0 : row.getTokenEstimate();
      audioDurationSeconds += row.getAudioDurationSeconds() == null ? 0 : row.getAudioDurationSeconds();
      estimatedCost = estimatedCost.add(row.getEstimatedCost());
    }
  }

  public record CostMetrics(int schemaVersion, String status, List<CostMetric> metrics) {}

  public record CostMetric(
      String period,
      String plan,
      String userHash,
      String providerFamily,
      String model,
      String capability,
      String status,
      boolean cacheHit,
      int callCount,
      Integer audioDurationSeconds,
      Integer tokenEstimate,
      BigDecimal estimatedCost,
      String fallbackReason,
      String budgetBucket,
      String marginRisk) {}
}
