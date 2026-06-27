package com.speakeasy.common;

import java.util.Map;

public record ErrorResponse(ErrorBody error) {
  public static ErrorResponse of(String code, String message, String requestId) {
    return new ErrorResponse(new ErrorBody(code, message, requestId, Map.of()));
  }

  public static ErrorResponse of(String code, String message, String requestId, Map<String, Object> details) {
    return new ErrorResponse(new ErrorBody(code, message, requestId, details == null ? Map.of() : details));
  }

  public record ErrorBody(String code, String message, String requestId, Map<String, Object> details) {}
}
