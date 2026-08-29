package com.speakeasy.identity.ratelimit;

import jakarta.annotation.PostConstruct;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("speakeasy.auth.rate-limit")
public class AuthRateLimitProperties {
  public enum Mode { DISABLED, OBSERVE, ENFORCE }

  private Mode mode = Mode.DISABLED;
  private String keySecret = "";
  private List<String> trustedProxyCidrs = List.of();
  private Duration maxRetryAfter = Duration.ofSeconds(300);
  private Duration unavailableRetryAfter = Duration.ofSeconds(5);
  private Duration auditDedupWindow = Duration.ofMinutes(15);
  private Map<String, Map<String, Bucket>> policies = new LinkedHashMap<>();

  @PostConstruct
  void validate() {
    if (mode != Mode.DISABLED && keySecret.isBlank()) {
      throw new IllegalStateException(
          "SPEAKEASY_AUTH_RATE_LIMIT_KEY_SECRET is required in observe and enforce modes.");
    }
    policies.forEach((endpoint, dimensions) -> dimensions.forEach((dimension, bucket) -> bucket.validate(endpoint, dimension)));
  }

  public Bucket bucket(String endpoint, String dimension) {
    Map<String, Bucket> dimensions = policies.get(endpoint);
    return dimensions == null ? null : dimensions.get(dimension);
  }

  public Mode getMode() { return mode; }
  public void setMode(Mode mode) { this.mode = mode; }
  public String getKeySecret() { return keySecret; }
  public void setKeySecret(String keySecret) { this.keySecret = keySecret == null ? "" : keySecret.trim(); }
  public List<String> getTrustedProxyCidrs() { return trustedProxyCidrs; }
  public void setTrustedProxyCidrs(List<String> trustedProxyCidrs) {
    this.trustedProxyCidrs = trustedProxyCidrs == null ? List.of() : trustedProxyCidrs;
  }
  public Duration getMaxRetryAfter() { return maxRetryAfter; }
  public void setMaxRetryAfter(Duration maxRetryAfter) { this.maxRetryAfter = maxRetryAfter; }
  public Duration getUnavailableRetryAfter() { return unavailableRetryAfter; }
  public void setUnavailableRetryAfter(Duration unavailableRetryAfter) { this.unavailableRetryAfter = unavailableRetryAfter; }
  public Duration getAuditDedupWindow() { return auditDedupWindow; }
  public void setAuditDedupWindow(Duration auditDedupWindow) { this.auditDedupWindow = auditDedupWindow; }
  public Map<String, Map<String, Bucket>> getPolicies() { return policies; }
  public void setPolicies(Map<String, Map<String, Bucket>> policies) {
    this.policies = policies == null ? new LinkedHashMap<>() : policies;
  }

  public static class Bucket {
    private int capacity;
    private int refillTokens;
    private Duration refillPeriod;

    void validate(String endpoint, String dimension) {
      if (capacity <= 0 || refillTokens <= 0 || refillPeriod == null || refillPeriod.isZero() || refillPeriod.isNegative()) {
        throw new IllegalStateException("Invalid authentication rate-limit bucket: " + endpoint + "/" + dimension);
      }
    }

    public int getCapacity() { return capacity; }
    public void setCapacity(int capacity) { this.capacity = capacity; }
    public int getRefillTokens() { return refillTokens; }
    public void setRefillTokens(int refillTokens) { this.refillTokens = refillTokens; }
    public Duration getRefillPeriod() { return refillPeriod; }
    public void setRefillPeriod(Duration refillPeriod) { this.refillPeriod = refillPeriod; }
  }
}
