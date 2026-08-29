package com.speakeasy.identity;

import io.micrometer.core.instrument.MeterRegistry;
import org.springframework.stereotype.Component;

@Component
public class AuthMetrics {
  private final MeterRegistry registry;

  public AuthMetrics(MeterRegistry registry) {
    this.registry = registry;
  }

  public void login(String provider, String outcome) {
    registry.counter("speakeasy.auth.login", "provider", provider, "outcome", outcome).increment();
  }

  public void refresh(String outcome) {
    String normalizedOutcome = "success".equals(outcome) ? "success" : "failure";
    String reason = "success".equals(outcome) ? "none" : outcome;
    registry.counter("speakeasy.auth.refresh", "outcome", normalizedOutcome, "reason", reason).increment();
    if ("token_reuse".equals(outcome)) registry.counter("speakeasy.auth.token.reuse").increment();
  }

  public void access(String outcome) {
    boolean success = "authenticated".equals(outcome);
    registry.counter("speakeasy.auth.access",
        "outcome", success ? "success" : "unauthorized",
        "reason", success ? "none" : outcome).increment();
    registry.counter("speakeasy.auth.http",
        "outcome", success ? "authenticated" : "unauthorized",
        "api_family", "bearer").increment();
  }

  public void revocation(String action) {
    registry.counter("speakeasy.auth.session.revocation", "action", action).increment();
    securityOperation("session_revoke", "success");
  }

  public void securityEvent(String event) {
    registry.counter("speakeasy.auth.security.event", "event", event).increment();
  }

  public void securityOperation(String operation, String outcome) {
    registry.counter("speakeasy.auth.security.operation", "operation", operation, "outcome", outcome).increment();
  }

  public void rateLimit(String endpoint, String dimension, String outcome) {
    registry.counter(
        "speakeasy.auth.rate.limit",
        "endpoint", endpoint,
        "dimension", dimension,
        "outcome", outcome).increment();
  }
}
