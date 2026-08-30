package com.speakeasy.identity;

import io.micrometer.core.instrument.MeterRegistry;
import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class AuthMetrics {
  private static final Set<String> ACCESS_REASONS = Set.of(
      "none",
      "access_token_invalid",
      "access_token_expired",
      "session_revoked",
      "account_disabled",
      "unauthenticated");
  private static final Set<String> PLATFORMS = Set.of("android", "ios", "unknown");
  private static final Pattern APP_VERSION = Pattern.compile("^(\\d{1,3})\\.(\\d{1,3})(?:\\..*)?$");
  private final MeterRegistry registry;
  private final Set<String> supportedAppVersions;

  public AuthMetrics(
      MeterRegistry registry,
      @Value("${speakeasy.auth.metrics-supported-app-versions:}")
      String supportedAppVersions) {
    this.registry = registry;
    this.supportedAppVersions = Arrays.stream(supportedAppVersions.split(","))
        .map(String::trim)
        .map(AuthMetrics::majorMinorVersion)
        .filter(version -> !"unknown".equals(version))
        .collect(Collectors.toUnmodifiableSet());
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
    String reason = normalizeAccessReason(success ? "none" : outcome);
    registry.counter("speakeasy.auth.access",
        "outcome", success ? "success" : "unauthorized",
        "reason", reason).increment();
  }

  public void accessHttp(
      String outcome, String platform, String appVersion, String requestPath) {
    boolean success = "AUTHENTICATED".equals(outcome) || "authenticated".equals(outcome);
    registry.counter("speakeasy.auth.http",
        "outcome", success ? "authenticated" : "unauthorized",
        "reason", normalizeAccessReason(success ? "none" : outcome),
        "platform", normalizePlatform(platform),
        "app_version", normalizeAppVersion(appVersion),
        "api_family", apiFamily(requestPath)).increment();
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

  private static String normalizeAccessReason(String reason) {
    String normalized = reason == null ? "unknown" : reason.trim().toLowerCase();
    return ACCESS_REASONS.contains(normalized) ? normalized : "unknown";
  }

  private static String normalizePlatform(String platform) {
    String normalized = platform == null ? "unknown" : platform.trim().toLowerCase();
    return PLATFORMS.contains(normalized) ? normalized : "unknown";
  }

  private String normalizeAppVersion(String appVersion) {
    String version = majorMinorVersion(appVersion);
    return supportedAppVersions.contains(version) ? version : "unknown";
  }

  private static String majorMinorVersion(String appVersion) {
    String normalized = appVersion == null ? "" : appVersion.trim();
    Matcher matcher = APP_VERSION.matcher(normalized);
    return matcher.matches() ? matcher.group(1) + "." + matcher.group(2) : "unknown";
  }

  private static String apiFamily(String requestPath) {
    String path = requestPath == null ? "" : requestPath.toLowerCase();
    if (startsWithAny(path, "/auth")) return "auth";
    if (startsWithAny(path, "/user")) return "user";
    if (startsWithAny(path, "/scenarios", "/courses", "/home")) return "content";
    if (startsWithAny(path, "/ai", "/media")) return "ai";
    if (startsWithAny(path, "/practice")) return "practice";
    if (startsWithAny(path, "/training")) return "training";
    if (startsWithAny(path, "/learning", "/review", "/favorites", "/expressions")) return "learning";
    if (startsWithAny(path, "/subscription", "/subscriptions", "/entitlements", "/membership")) return "commerce";
    if (startsWithAny(path, "/goal-autopilot")) return "goal";
    if (startsWithAny(path, "/admin", "/actuator")) return "ops";
    return "other";
  }

  private static boolean startsWithAny(String path, String... prefixes) {
    for (String prefix : prefixes) {
      if (path.equals(prefix) || path.startsWith(prefix + "/")) return true;
    }
    return false;
  }
}
