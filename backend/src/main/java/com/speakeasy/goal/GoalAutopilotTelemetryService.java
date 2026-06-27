package com.speakeasy.goal;

import com.speakeasy.ai.AiCostMetricsService;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class GoalAutopilotTelemetryService {
  private static final int SCHEMA_VERSION = 1;
  private static final String FORCE_FAILURE_PROPERTY = "speakeasy.goal-autopilot.telemetry.force-write-failure";

  private final GoalAutopilotMetricEventRepository metrics;
  private final AiCostMetricsService aiCostMetricsService;
  private final AuditLogRepository auditLogs;
  private final Environment environment;
  private final Clock clock;
  private final TransactionTemplate telemetryTransaction;
  private final TransactionTemplate fallbackAuditTransaction;

  public GoalAutopilotTelemetryService(
      GoalAutopilotMetricEventRepository metrics,
      AiCostMetricsService aiCostMetricsService,
      AuditLogRepository auditLogs,
      Environment environment,
      Clock clock,
      PlatformTransactionManager transactionManager) {
    this.metrics = metrics;
    this.aiCostMetricsService = aiCostMetricsService;
    this.auditLogs = auditLogs;
    this.environment = environment;
    this.clock = clock;
    this.telemetryTransaction = new TransactionTemplate(transactionManager);
    this.telemetryTransaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
    this.fallbackAuditTransaction = new TransactionTemplate(transactionManager);
    this.fallbackAuditTransaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
  }

  public void record(
      UUID userId,
      String eventType,
      String status,
      String reasonCode,
      String sourcePath,
      String targetRef,
      String requestId) {
    try {
      if (environment.getProperty(FORCE_FAILURE_PROPERTY, Boolean.class, false)) {
        throw new IllegalStateException("forced telemetry failure");
      }
      Instant now = Instant.now(clock);
      telemetryTransaction.executeWithoutResult(ignored -> metrics.save(new GoalAutopilotMetricEvent(
          UUID.randomUUID(),
          aiCostMetricsService.redactedUserHash(userId),
          safeToken(eventType, "unknown_event", 120),
          safeToken(status, "unknown", 80),
          safeToken(reasonCode, "none", 120),
          safeToken(sourcePath, "goal_autopilot.unknown", 120),
          safeTargetRef(targetRef),
          auditRef(requestId),
          SCHEMA_VERSION,
          now)));
    } catch (RuntimeException failure) {
      writeFallbackAudit(userId, eventType, status, reasonCode, sourcePath, requestId, failure);
    }
  }

  public List<GoalAutopilotMetricEvent> userMetrics(UUID userId) {
    return metrics.findByUserHashOrderByCreatedAtAsc(aiCostMetricsService.redactedUserHash(userId));
  }

  public long deleteByUserHash(UUID userId) {
    return metrics.deleteByUserHash(aiCostMetricsService.redactedUserHash(userId));
  }

  private void writeFallbackAudit(
      UUID userId,
      String eventType,
      String status,
      String reasonCode,
      String sourcePath,
      String requestId,
      RuntimeException failure) {
    try {
      Instant now = Instant.now(clock);
      fallbackAuditTransaction.executeWithoutResult(ignored -> auditLogs.save(new AuditLog(
          UUID.randomUUID(),
          "system",
          userId == null ? null : userId.toString(),
          "goal_autopilot_telemetry_write_failed",
          "goal_autopilot_metric:" + safeToken(eventType, "unknown_event", 80),
          fallbackDetails(eventType, status, reasonCode, sourcePath, failure),
          auditRef(requestId),
          now)));
    } catch (RuntimeException ignored) {
      // Telemetry must never block the user path, including fallback audit failure.
    }
  }

  private String fallbackDetails(
      String eventType,
      String status,
      String reasonCode,
      String sourcePath,
      RuntimeException failure) {
    return "{"
        + "\"data\":\"redacted\","
        + "\"schema_version\":" + SCHEMA_VERSION + ","
        + "\"event_type\":\"" + safeToken(eventType, "unknown_event", 120) + "\","
        + "\"status\":\"" + safeToken(status, "unknown", 80) + "\","
        + "\"reason_code\":\"" + safeToken(reasonCode, "none", 120) + "\","
        + "\"source_path\":\"" + safeToken(sourcePath, "goal_autopilot.unknown", 120) + "\","
        + "\"error_class\":\"" + failure.getClass().getSimpleName() + "\""
        + "}";
  }

  private String auditRef(String requestId) {
    String cleaned = safeToken(requestId, "unknown", 120);
    return "request:" + cleaned;
  }

  private String safeTargetRef(String targetRef) {
    String cleaned = safeToken(targetRef, "goal_autopilot:none", 140);
    return cleaned.contains(":") ? cleaned : "goal_autopilot:" + cleaned;
  }

  private String safeToken(String value, String fallback, int maxLength) {
    String cleaned = value == null ? "" : value.trim().toLowerCase(Locale.ROOT).replaceAll("[^a-z0-9_.:-]", "_");
    if (cleaned.isBlank()) {
      cleaned = fallback;
    }
    if (cleaned.length() > maxLength) {
      return cleaned.substring(0, maxLength);
    }
    return cleaned;
  }
}
