package com.speakeasy.identity.ratelimit;

import com.speakeasy.identity.AuthMetrics;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;

@Service
public class AuthRateLimitService {
  private final AuthRateLimitProperties properties;
  private final AuthRateLimitKeyFactory keys;
  private final ClientNetworkResolver networks;
  private final AuthRateLimitStore store;
  private final AuthMetrics metrics;
  private final AuthRateLimitAudit audit;

  public AuthRateLimitService(
      AuthRateLimitProperties properties,
      AuthRateLimitKeyFactory keys,
      ClientNetworkResolver networks,
      AuthRateLimitStore store,
      AuthMetrics metrics,
      AuthRateLimitAudit audit) {
    this.properties = properties;
    this.keys = keys;
    this.networks = networks;
    this.store = store;
    this.metrics = metrics;
    this.audit = audit;
  }

  public void check(String endpoint, HttpServletRequest request, Map<String, String> dimensions) {
    Map<String, String> identifiers = new LinkedHashMap<>();
    identifiers.put("network", networks.resolve(request));
    if (dimensions != null) identifiers.putAll(dimensions);
    checkDimensions(endpoint, identifiers, request.getHeader("X-Request-Id"));
  }

  public void checkAdditional(
      String endpoint, Map<String, String> dimensions, String requestId) {
    checkDimensions(endpoint, dimensions == null ? Map.of() : dimensions, requestId);
  }

  private void checkDimensions(
      String endpoint, Map<String, String> identifiers, String requestId) {
    if (properties.getMode() == AuthRateLimitProperties.Mode.DISABLED) return;

    Map<String, AuthRateLimitProperties.Bucket> policy = properties.getPolicies().get(endpoint);
    if (policy == null || policy.isEmpty()) return;
    List<AuthRateLimitStore.BucketRequest> buckets = new ArrayList<>();
    policy.forEach((dimension, bucket) -> {
      String identifier = identifiers.get(dimension);
      if (identifier == null || identifier.isBlank()) return;
      buckets.add(new AuthRateLimitStore.BucketRequest(
          keys.key(endpoint, dimension, identifier),
          dimension,
          bucket.getCapacity(),
          bucket.getRefillTokens(),
          bucket.getRefillPeriod()));
    });
    if (buckets.isEmpty()) return;

    try {
      AuthRateLimitStore.Decision decision = store.consume(List.copyOf(buckets));
      if (decision.allowed()) {
        metrics.rateLimit(endpoint, "none", "allowed");
        return;
      }
      Duration retryAfter = normalizeRetryAfter(decision.retryAfter());
      if (properties.getMode() == AuthRateLimitProperties.Mode.OBSERVE) {
        metrics.rateLimit(endpoint, safeDimension(decision.violatedDimension()), "observed");
        recordAudit(endpoint, decision.violatedDimension(), "observed", buckets, requestId);
        return;
      }
      metrics.rateLimit(endpoint, safeDimension(decision.violatedDimension()), "blocked");
      recordAudit(endpoint, decision.violatedDimension(), "blocked", buckets, requestId);
      throw AuthRateLimitException.rejected(endpoint, decision.violatedDimension(), retryAfter);
    } catch (AuthRateLimitStoreUnavailableException exception) {
      metrics.rateLimit(endpoint, "store", "unavailable");
      if (properties.getMode() == AuthRateLimitProperties.Mode.ENFORCE) {
        throw AuthRateLimitException.unavailable(properties.getUnavailableRetryAfter());
      }
    }
  }

  private void recordAudit(
      String endpoint,
      String dimension,
      String outcome,
      List<AuthRateLimitStore.BucketRequest> buckets,
      String requestId) {
    String bucketKey = buckets.stream()
        .filter(bucket -> bucket.dimension().equals(dimension))
        .map(AuthRateLimitStore.BucketRequest::key)
        .findFirst()
        .orElseGet(() -> buckets.get(0).key());
    audit.record(endpoint, safeDimension(dimension), outcome, bucketKey, requestId);
  }

  private Duration normalizeRetryAfter(Duration raw) {
    long seconds = raw == null ? 0 : Math.max(0, raw.toSeconds());
    long rounded = Math.max(5, ((seconds + 4) / 5) * 5);
    return Duration.ofSeconds(Math.min(rounded, properties.getMaxRetryAfter().toSeconds()));
  }

  private String safeDimension(String value) {
    return value == null || value.isBlank() ? "unknown" : value;
  }
}
