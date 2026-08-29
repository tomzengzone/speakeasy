package com.speakeasy.identity.ratelimit;

import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.HttpStatus;

public final class AuthRateLimitException extends RuntimeException {
  private final HttpStatus status;
  private final String code;
  private final Duration retryAfter;
  private final Map<String, Object> details;

  private AuthRateLimitException(
      HttpStatus status, String code, String message, Duration retryAfter, Map<String, Object> details) {
    super(message);
    this.status = status;
    this.code = code;
    this.retryAfter = retryAfter;
    this.details = details;
  }

  public static AuthRateLimitException rejected(String endpoint, String dimension, Duration retryAfter) {
    Map<String, Object> details = new LinkedHashMap<>();
    details.put("endpoint", endpoint);
    if (dimension != null) details.put("dimension", dimension);
    return new AuthRateLimitException(
        HttpStatus.TOO_MANY_REQUESTS,
        "AUTH_RATE_LIMITED",
        "Too many authentication requests. Try again later.",
        retryAfter,
        Map.copyOf(details));
  }

  public static AuthRateLimitException unavailable(Duration retryAfter) {
    return new AuthRateLimitException(
        HttpStatus.SERVICE_UNAVAILABLE,
        "AUTH_SERVICE_UNAVAILABLE",
        "Authentication service is temporarily unavailable. Try again later.",
        retryAfter,
        Map.of());
  }

  public HttpStatus getStatus() { return status; }
  public String getCode() { return code; }
  public Duration getRetryAfter() { return retryAfter; }
  public Map<String, Object> getDetails() { return details; }
}
