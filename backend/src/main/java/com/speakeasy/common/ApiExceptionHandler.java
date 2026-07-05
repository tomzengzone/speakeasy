package com.speakeasy.common;

import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {
  @ExceptionHandler(ApiException.class)
  ResponseEntity<ErrorResponse> handleApiException(ApiException exception, HttpServletRequest request) {
    return ResponseEntity.status(exception.getStatus())
        .body(ErrorResponse.of(exception.getCode(), exception.getMessage(), requestId(request), exception.getDetails()));
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  ResponseEntity<ErrorResponse> handleValidation(MethodArgumentNotValidException exception, HttpServletRequest request) {
    FieldError firstError = exception.getBindingResult().getFieldErrors().stream().findFirst().orElse(null);
    Map<String, Object> details =
        firstError == null ? Map.of() : Map.of("field", firstError.getField(), "reason", firstError.getDefaultMessage());
    return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
        .body(ErrorResponse.of("SCHEMA_VALIDATION_FAILED", "Request validation failed.", requestId(request), details));
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  ResponseEntity<ErrorResponse> handleMalformedJson(HttpMessageNotReadableException exception, HttpServletRequest request) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
        .body(ErrorResponse.of(
            "SCHEMA_VALIDATION_FAILED",
            "Request body is malformed.",
            requestId(request),
            Map.of("reason", "malformed_json")));
  }

  private String requestId(HttpServletRequest request) {
    String header = request.getHeader("X-Request-Id");
    return header == null || header.isBlank() ? "unknown" : header;
  }
}
