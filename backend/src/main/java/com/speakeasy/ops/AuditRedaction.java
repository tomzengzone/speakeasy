package com.speakeasy.ops;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

final class AuditRedaction {
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

  private AuditRedaction() {}

  static String sanitizeDetailsForStorage(String raw, ObjectMapper objectMapper) {
    if (raw == null || raw.isBlank()) {
      return raw;
    }
    try {
      Map<String, Object> parsed = objectMapper.readValue(raw, MAP_TYPE);
      return objectMapper.writeValueAsString(sanitizeMap(parsed));
    } catch (Exception ignored) {
      if (containsSensitiveKey(raw) || containsSensitiveValue(raw)) {
        return "{\"schema_version\":1,\"summary\":\"redacted\"}";
      }
      return raw;
    }
  }

  static Map<String, Object> sanitizedDetailsForView(String raw, ObjectMapper objectMapper) {
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

  static Map<String, Object> sanitizeMap(Map<String, Object> input) {
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

  static Object sanitizeValue(Object value) {
    if (value instanceof Map<?, ?> map) {
      Map<String, Object> converted = new LinkedHashMap<>();
      for (Map.Entry<?, ?> entry : map.entrySet()) {
        converted.put(String.valueOf(entry.getKey()), entry.getValue());
      }
      return sanitizeMap(converted);
    }
    if (value instanceof List<?> list) {
      List<Object> sanitized = new ArrayList<>();
      for (Object item : list) {
        sanitized.add(sanitizeValue(item));
      }
      return sanitized;
    }
    if (value instanceof String text) {
      return containsSensitiveValue(text) ? "redacted" : text;
    }
    return value;
  }

  static boolean containsSensitiveKey(String text) {
    String normalized = text == null ? "" : text.toLowerCase(Locale.ROOT);
    return SENSITIVE_KEY_TOKENS.stream().anyMatch(normalized::contains);
  }

  static boolean isSensitiveKey(String key) {
    String normalized = key == null ? "" : key.toLowerCase(Locale.ROOT);
    if (normalized.endsWith("_deleted_count") || normalized.endsWith("_redacted_count")) {
      return false;
    }
    return containsSensitiveKey(key);
  }

  static boolean containsSensitiveValue(String value) {
    String normalized = value == null ? "" : value.toLowerCase(Locale.ROOT);
    return normalized.contains("signature=")
        || normalized.contains("token=")
        || normalized.contains("secret")
        || normalized.contains("api_key")
        || normalized.contains("raw_payload")
        || normalized.contains("full_transcript")
        || normalized.contains("http://")
        || normalized.contains("https://");
  }

  static String safeTargetRef(String targetRef) {
    String cleaned = safeValue(targetRef, "unknown");
    return containsSensitiveKey(cleaned) || containsSensitiveValue(cleaned) ? "redacted:target_ref" : cleaned;
  }

  static String safeRequestId(String requestId) {
    String cleaned = requestId == null ? "" : requestId.trim();
    if (cleaned.isBlank() || containsSensitiveKey(cleaned) || containsSensitiveValue(cleaned)) {
      return "unknown";
    }
    return cleaned.length() > 120 ? cleaned.substring(0, 120) : cleaned;
  }

  static String safeValue(String value, String fallback) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? fallback : cleaned;
  }

  private static String safeKey(String key) {
    String cleaned = key == null ? "unknown" : key.trim();
    return cleaned.isBlank() ? "unknown" : cleaned;
  }
}
