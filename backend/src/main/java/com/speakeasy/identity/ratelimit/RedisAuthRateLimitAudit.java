package com.speakeasy.identity.ratelimit;

import com.speakeasy.identity.AuthMetrics;
import com.speakeasy.ops.AuthAuditService;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

@Component
public class RedisAuthRateLimitAudit implements AuthRateLimitAudit {
  private final StringRedisTemplate redis;
  private final AuthRateLimitProperties properties;
  private final AuthAuditService audit;
  private final AuthMetrics metrics;

  public RedisAuthRateLimitAudit(
      StringRedisTemplate redis,
      AuthRateLimitProperties properties,
      AuthAuditService audit,
      AuthMetrics metrics) {
    this.redis = redis;
    this.properties = properties;
    this.audit = audit;
    this.metrics = metrics;
  }

  @Override
  public void record(
      String endpoint,
      String dimension,
      String outcome,
      String bucketKey,
      String requestId) {
    if (bucketKey == null || bucketKey.isBlank()) return;
    String dedupKey = "authrl:audit:v1:" + outcome + ":" + bucketKey;
    try {
      Boolean first = redis.opsForValue().setIfAbsent(
          dedupKey, "1", properties.getAuditDedupWindow());
      if (!Boolean.TRUE.equals(first)) {
        metrics.securityOperation("rate_limit_audit", "deduplicated");
        return;
      }
      audit.recordRateLimitEvent(endpoint, dimension, outcome, requestId);
      metrics.securityOperation("rate_limit_audit", "success");
    } catch (RuntimeException exception) {
      // A telemetry failure must not replace the already-determined auth response.
      metrics.securityOperation("rate_limit_audit", "failure");
    }
  }
}
