package com.speakeasy.common;

import java.util.Set;
import org.springframework.http.HttpStatus;

public final class CefrLevel {
  public static final String DEFAULT = "A2";
  public static final String REGEXP = "A1|A2|B1|B2|C1|C2";

  private static final Set<String> VALUES = Set.of("A1", "A2", "B1", "B2", "C1", "C2");

  private CefrLevel() {}

  public static String require(String value, String fieldName) {
    String cleaned = value == null ? null : value.trim();
    if (cleaned == null || cleaned.isEmpty() || !VALUES.contains(cleaned)) {
      throw new ApiException(
          HttpStatus.UNPROCESSABLE_ENTITY,
          "SCHEMA_VALIDATION_FAILED",
          fieldName + " must be one of A1, A2, B1, B2, C1, or C2.");
    }
    return cleaned;
  }

  public static String requireIfPresent(String value, String fieldName) {
    return value == null ? null : require(value, fieldName);
  }

  public static String defaultIfBlank(String value, String fieldName) {
    return value == null || value.isBlank() ? DEFAULT : require(value, fieldName);
  }
}
