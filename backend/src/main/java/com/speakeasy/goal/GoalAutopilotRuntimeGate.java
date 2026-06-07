package com.speakeasy.goal;

import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.support.TransactionTemplate;

@Service
public class GoalAutopilotRuntimeGate {
  static final String RULE_VERSION = "fud-runtime-gate-v1";

  private static final String ENABLED_PROPERTY = "speakeasy.goal-autopilot.runtime.enabled";
  private static final String KILL_SWITCH_PROPERTY = "speakeasy.goal-autopilot.runtime.kill-switch.enabled";
  private static final String KILL_SWITCH_REASON_PROPERTY = "speakeasy.goal-autopilot.runtime.kill-switch.reason";

  private final Environment environment;
  private final AuditLogRepository auditLogs;
  private final Clock clock;
  private final TransactionTemplate auditTransaction;

  public GoalAutopilotRuntimeGate(
      Environment environment, AuditLogRepository auditLogs, Clock clock, PlatformTransactionManager transactionManager) {
    this.environment = environment;
    this.auditLogs = auditLogs;
    this.clock = clock;
    this.auditTransaction = new TransactionTemplate(transactionManager);
    this.auditTransaction.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
  }

  public RuntimeGateDecision currentDecision() {
    boolean enabled = environment.getProperty(ENABLED_PROPERTY, Boolean.class, true);
    if (!enabled) {
      return new RuntimeGateDecision(false, "RuntimeDisabled", "feature_disabled", "feature_disabled", RULE_VERSION);
    }
    boolean killSwitchEnabled = environment.getProperty(KILL_SWITCH_PROPERTY, Boolean.class, false);
    if (killSwitchEnabled) {
      return new RuntimeGateDecision(
          false,
          "KillSwitchActive",
          "kill_switch_active",
          cleanOrDefault(environment.getProperty(KILL_SWITCH_REASON_PROPERTY), "operator_disabled"),
          RULE_VERSION);
    }
    return new RuntimeGateDecision(true, "RuntimeEnabled", "runtime_enabled", "runtime_enabled", RULE_VERSION);
  }

  public void requireMutationAllowed(UUID userId, String operation, String requestId) {
    RuntimeGateDecision decision = currentDecision();
    if (decision.allowed()) {
      return;
    }
    UUID auditLogId = writeBlockedAudit(userId, operation, "mutation", decision, requestId);
    throw disabledException(decision, auditLogId);
  }

  public void requireReadAllowed(UUID userId, String operation) {
    RuntimeGateDecision decision = currentDecision();
    if (decision.allowed()) {
      return;
    }
    throw disabledException(decision, null);
  }

  private ApiException disabledException(RuntimeGateDecision decision, UUID auditLogId) {
    Map<String, Object> details = new LinkedHashMap<>();
    details.put("reason_code", decision.reasonCode());
    details.put("runtime_state", decision.runtimeState());
    details.put("kill_switch_reason", decision.operatorReason());
    details.put("runtime_rule_version", decision.ruleVersion());
    if (auditLogId != null) {
      details.put("audit_log_id", auditLogId.toString());
    }
    return new ApiException(
        HttpStatus.SERVICE_UNAVAILABLE,
        "GOAL_AUTOPILOT_RUNTIME_DISABLED",
        "Goal autopilot runtime is disabled.",
        Map.copyOf(details));
  }

  private UUID writeBlockedAudit(
      UUID userId, String operation, String accessMode, RuntimeGateDecision decision, String requestId) {
    Instant now = Instant.now(clock);
    UUID auditLogId = UUID.randomUUID();
    auditTransaction.executeWithoutResult(status -> auditLogs.save(new AuditLog(
        auditLogId,
        "user",
        userId == null ? null : userId.toString(),
        "goal_autopilot_runtime_blocked",
        "goal_autopilot_runtime:" + cleanOrDefault(operation, "unknown_operation"),
        redactedDetails(operation, accessMode, decision),
        cleanOrDefault(requestId, "unknown"),
        now)));
    return auditLogId;
  }

  private String redactedDetails(String operation, String accessMode, RuntimeGateDecision decision) {
    return "{"
        + "\"data\":\"redacted\","
        + "\"schema_version\":1,"
        + "\"operation\":\"" + cleanOrDefault(operation, "unknown_operation") + "\","
        + "\"access_mode\":\"" + cleanOrDefault(accessMode, "unknown") + "\","
        + "\"runtime_state\":\"" + decision.runtimeState() + "\","
        + "\"reason_code\":\"" + decision.reasonCode() + "\","
        + "\"kill_switch_reason\":\"" + decision.operatorReason() + "\","
        + "\"rule_version\":\"" + decision.ruleVersion() + "\""
        + "}";
  }

  private static String cleanOrDefault(String value, String fallback) {
    if (value == null || value.isBlank()) {
      return fallback;
    }
    String cleaned = value.trim().toLowerCase().replaceAll("[^a-z0-9_-]", "_");
    return cleaned.isBlank() ? fallback : cleaned;
  }

  public record RuntimeGateDecision(
      boolean allowed, String runtimeState, String reasonCode, String operatorReason, String ruleVersion) {}
}
