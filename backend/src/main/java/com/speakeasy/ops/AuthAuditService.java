package com.speakeasy.ops;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.security.TokenHasher;
import com.speakeasy.identity.AuthMetrics;
import java.time.Clock;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthAuditService {
  private final AuditLogRepository auditLogs;
  private final ObjectMapper objectMapper;
  private final Clock clock;
  private final AuthMetrics metrics;

  public AuthAuditService(AuditLogRepository auditLogs, ObjectMapper objectMapper, Clock clock, AuthMetrics metrics) {
    this.auditLogs = auditLogs;
    this.objectMapper = objectMapper;
    this.clock = clock;
    this.metrics = metrics;
  }

  public void recordUserEvent(
      UUID actorUserId, String eventType, UUID targetUserId, UUID sessionId,
      String reasonCode, int affectedSessions, String requestId) {
    record("user", reference("user", actorUserId), eventType, targetUserId, sessionId,
        reasonCode, affectedSessions, null, requestId, Map.of());
  }

  public void recordOpsEvent(
      String principalId, String eventType, UUID targetUserId, String reasonCode,
      int affectedSessions, String caseReference, String requestId) {
    record("ops", reference("ops", principalId), eventType, targetUserId, null,
        reasonCode, affectedSessions, caseReference, requestId, Map.of());
  }

  public void recordSystemEvent(
      String eventType, UUID targetUserId, UUID sessionId, String reasonCode,
      int affectedSessions, String requestId) {
    record("system", "auth", eventType, targetUserId, sessionId,
        reasonCode, affectedSessions, null, requestId, Map.of());
  }

  @Transactional(propagation = Propagation.REQUIRES_NEW)
  public void recordRateLimitEvent(
      String endpoint, String dimension, String outcome, String requestId) {
    record(
        "system",
        "auth",
        "auth_rate_limit_" + safeCode(outcome),
        null,
        null,
        "rate_limit",
        0,
        null,
        requestId,
        Map.of(
            "endpoint", safeCode(endpoint),
            "dimension", safeCode(dimension),
            "outcome", safeCode(outcome)));
  }

  private void record(
      String actorType, String actorId, String eventType, UUID targetUserId, UUID sessionId,
      String reasonCode, int affectedSessions, String caseReference, String requestId,
      Map<String, Object> additionalDetails) {
    Map<String, Object> details = new LinkedHashMap<>();
    details.put("schema_version", 1);
    details.put("affected_session_count", affectedSessions);
    if (reasonCode != null && !reasonCode.isBlank()) details.put("reason_code", safeCode(reasonCode));
    if (sessionId != null) details.put("session_ref", reference("session", sessionId));
    if (caseReference != null && !caseReference.isBlank()) details.put("case_reference", safeCode(caseReference));
    if (additionalDetails != null) details.putAll(additionalDetails);
    try {
      auditLogs.saveAndFlush(new AuditLog(
          UUID.randomUUID(),
          actorType,
          actorId,
          eventType,
          reference("user", targetUserId),
          json(details),
          requestId,
          Instant.now(clock)));
      metrics.securityOperation("audit_write", "success");
    } catch (RuntimeException exception) {
      metrics.securityOperation("audit_write", "failure");
      throw exception;
    }
  }

  private String json(Map<String, Object> value) {
    try {
      return objectMapper.writeValueAsString(value);
    } catch (JsonProcessingException exception) {
      throw new IllegalStateException("Authentication audit serialization failed.", exception);
    }
  }

  private static String reference(String type, UUID id) {
    return reference(type, id == null ? "unknown" : id.toString());
  }

  private static String reference(String type, String value) {
    String hash = TokenHasher.hash(value == null ? "unknown" : value);
    return type + ":" + hash.substring(0, 24);
  }

  private static String safeCode(String value) {
    String cleaned = value.trim().replaceAll("[^A-Za-z0-9_.:-]", "_");
    return cleaned.substring(0, Math.min(cleaned.length(), 120));
  }
}
