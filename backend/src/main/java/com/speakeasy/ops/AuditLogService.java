package com.speakeasy.ops;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import jakarta.persistence.criteria.Predicate;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditLogService {
  private static final int DEFAULT_LIMIT = 50;
  private static final int MAX_LIMIT = 100;
  private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {};
  private static final List<String> SENSITIVE_KEY_TOKENS = List.of(
      "api_key",
      "audio",
      "authorization",
      "credential",
      "idempotency",
      "payload",
      "provider_key",
      "raw",
      "receipt",
      "secret",
      "signature",
      "signed",
      "token",
      "transcript",
      "url");

  private final AuditLogRepository auditLogs;
  private final ObjectMapper objectMapper;
  private final Clock clock;

  public AuditLogService(AuditLogRepository auditLogs, ObjectMapper objectMapper, Clock clock) {
    this.auditLogs = auditLogs;
    this.objectMapper = objectMapper;
    this.clock = clock;
  }

  @Transactional
  public AuditEventPage listAuditEvents(AuditQuery query, String requestId) {
    List<AuditLog> rows = auditLogs.findAll(
        specification(query),
        PageRequest.of(
            0,
            query.limit() + 1,
            Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("auditLogId"))))
        .getContent();

    boolean hasMore = rows.size() > query.limit();
    List<AuditLog> pageRows = hasMore ? rows.subList(0, query.limit()) : rows;
    String nextCursor = hasMore && !pageRows.isEmpty() ? encodeCursor(pageRows.get(pageRows.size() - 1)) : null;
    List<AuditEventView> events = pageRows.stream().map(this::view).toList();
    auditAccess(events.size(), query, requestId);
    return new AuditEventPage(1, query.limit(), nextCursor, events);
  }

  private Specification<AuditLog> specification(AuditQuery query) {
    return (root, criteriaQuery, criteriaBuilder) -> {
      List<Predicate> predicates = new ArrayList<>();
      if (query.eventType() != null) {
        predicates.add(criteriaBuilder.equal(root.get("eventType"), query.eventType()));
      }
      if (query.actorType() != null) {
        predicates.add(criteriaBuilder.equal(root.get("actorType"), query.actorType()));
      }
      if (query.targetRef() != null) {
        predicates.add(criteriaBuilder.equal(root.get("targetRef"), query.targetRef()));
      }
      if (query.createdAfter() != null) {
        predicates.add(criteriaBuilder.greaterThanOrEqualTo(root.get("createdAt"), query.createdAfter()));
      }
      if (query.createdBefore() != null) {
        predicates.add(criteriaBuilder.lessThan(root.get("createdAt"), query.createdBefore()));
      }
      if (query.cursor() != null) {
        Cursor cursor = decodeCursor(query.cursor());
        predicates.add(criteriaBuilder.or(
            criteriaBuilder.lessThan(root.get("createdAt"), cursor.createdAt()),
            criteriaBuilder.and(
                criteriaBuilder.equal(root.get("createdAt"), cursor.createdAt()),
                criteriaBuilder.lessThan(root.<UUID>get("auditLogId"), cursor.auditLogId()))));
      }
      return criteriaBuilder.and(predicates.toArray(Predicate[]::new));
    };
  }

  private AuditEventView view(AuditLog audit) {
    return new AuditEventView(
        audit.getAuditLogId().toString(),
        safeValue(audit.getActorType(), "unknown"),
        safeValue(audit.getEventType(), "unknown"),
        safeTargetRef(audit.getTargetRef()),
        safeRequestId(audit.getRequestId()),
        sanitizedDetails(audit.getRedactedDetails()),
        audit.getCreatedAt());
  }

  private Map<String, Object> sanitizedDetails(String raw) {
    if (raw == null || raw.isBlank()) {
      return Map.of();
    }
    try {
      Map<String, Object> parsed = objectMapper.readValue(raw, MAP_TYPE);
      return sanitizeMap(parsed);
    } catch (Exception ignored) {
      return Map.of("format", "legacy_text", "summary", "redacted");
    }
  }

  private Map<String, Object> sanitizeMap(Map<String, Object> input) {
    Map<String, Object> sanitized = new LinkedHashMap<>();
    for (Map.Entry<String, Object> entry : input.entrySet()) {
      String key = safeKey(entry.getKey());
      if (isSensitiveKey(key)) {
        sanitized.put("redacted_field_" + sanitized.size(), "redacted");
      } else {
        sanitized.put(key, sanitizeValue(entry.getValue()));
      }
    }
    return sanitized;
  }

  @SuppressWarnings("unchecked")
  private Object sanitizeValue(Object value) {
    if (value instanceof Map<?, ?> map) {
      Map<String, Object> converted = new LinkedHashMap<>();
      for (Map.Entry<?, ?> entry : map.entrySet()) {
        converted.put(String.valueOf(entry.getKey()), entry.getValue());
      }
      return sanitizeMap(converted);
    }
    if (value instanceof List<?> list) {
      return list.stream().map(this::sanitizeValue).toList();
    }
    if (value instanceof String text) {
      return containsSensitiveValue(text) ? "redacted" : text;
    }
    return value;
  }

  private boolean isSensitiveKey(String key) {
    String normalized = key.toLowerCase(Locale.ROOT);
    return SENSITIVE_KEY_TOKENS.stream().anyMatch(normalized::contains);
  }

  private boolean containsSensitiveValue(String value) {
    String normalized = value.toLowerCase(Locale.ROOT);
    return normalized.contains("signature=")
        || normalized.contains("token=")
        || normalized.contains("secret")
        || normalized.contains("api_key")
        || normalized.contains("raw_payload")
        || normalized.contains("full_transcript")
        || normalized.startsWith("http://")
        || normalized.startsWith("https://");
  }

  private String safeKey(String key) {
    String cleaned = key == null ? "unknown" : key.trim();
    return cleaned.isBlank() ? "unknown" : cleaned;
  }

  private String safeTargetRef(String targetRef) {
    String cleaned = safeValue(targetRef, "unknown");
    return containsSensitiveValue(cleaned) ? "redacted:target_ref" : cleaned;
  }

  private String safeRequestId(String requestId) {
    String cleaned = requestId == null ? "" : requestId.trim();
    if (cleaned.isBlank() || isSensitiveKey(cleaned) || containsSensitiveValue(cleaned)) {
      return "unknown";
    }
    return cleaned.length() > 120 ? cleaned.substring(0, 120) : cleaned;
  }

  private String safeValue(String value, String fallback) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? fallback : cleaned;
  }

  private void auditAccess(int eventCount, AuditQuery query, String requestId) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "ops",
        "ops",
        "admin_audit_events_listed",
        "admin_audit",
        """
            {"schema_version":1,"event_count":%d,"limit":%d,"has_filters":%s}
            """.formatted(eventCount, query.limit(), query.hasFilters()).trim(),
        safeRequestId(requestId),
        Instant.now(clock)));
  }

  private String encodeCursor(AuditLog audit) {
    String payload = audit.getCreatedAt() + "|" + audit.getAuditLogId();
    return Base64.getUrlEncoder().withoutPadding().encodeToString(payload.getBytes(StandardCharsets.UTF_8));
  }

  private Cursor decodeCursor(String value) {
    try {
      String decoded = new String(Base64.getUrlDecoder().decode(value), StandardCharsets.UTF_8);
      String[] parts = decoded.split("\\|", 2);
      if (parts.length != 2) {
        throw validation("cursor is invalid.");
      }
      return new Cursor(Instant.parse(parts[0]), UUID.fromString(parts[1]));
    } catch (IllegalArgumentException | DateTimeParseException exception) {
      throw validation("cursor is invalid.");
    }
  }

  private static ApiException validation(String message) {
    return new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", message);
  }

  private static Instant parseInstant(String value, String field) {
    String cleaned = clean(value, 64, field);
    if (cleaned == null) {
      return null;
    }
    try {
      return Instant.parse(cleaned);
    } catch (DateTimeParseException exception) {
      throw validation(field + " is invalid.");
    }
  }

  private static String clean(String value, int maxLength, String field) {
    String cleaned = value == null ? "" : value.trim();
    if (cleaned.isBlank()) {
      return null;
    }
    if (cleaned.length() > maxLength) {
      throw validation(field + " is invalid.");
    }
    return cleaned;
  }

  public record AuditQuery(
      Integer limit,
      String cursor,
      String eventType,
      String actorType,
      String targetRef,
      Instant createdAfter,
      Instant createdBefore) {
    public static AuditQuery fromRaw(
        Integer limit,
        String cursor,
        String eventType,
        String actorType,
        String targetRef,
        String createdAfter,
        String createdBefore) {
      int normalizedLimit = limit == null ? DEFAULT_LIMIT : limit;
      if (normalizedLimit < 1 || normalizedLimit > MAX_LIMIT) {
        throw validation("limit must be between 1 and 100.");
      }
      return new AuditQuery(
          normalizedLimit,
          clean(cursor, 512, "cursor"),
          clean(eventType, 120, "event_type"),
          clean(actorType, 40, "actor_type"),
          clean(targetRef, 160, "target_ref"),
          parseInstant(createdAfter, "created_after"),
          parseInstant(createdBefore, "created_before"));
    }

    boolean hasFilters() {
      return cursor != null || eventType != null || actorType != null || targetRef != null || createdAfter != null || createdBefore != null;
    }
  }

  public record AuditEventPage(int schemaVersion, int limit, String nextCursor, List<AuditEventView> events) {}

  public record AuditEventView(
      String auditLogId,
      String actorType,
      String eventType,
      String targetRef,
      String requestId,
      Map<String, Object> redactedDetails,
      Instant createdAt) {}

  private record Cursor(Instant createdAt, UUID auditLogId) {}
}
