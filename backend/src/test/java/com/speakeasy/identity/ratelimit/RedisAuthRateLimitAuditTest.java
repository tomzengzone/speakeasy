package com.speakeasy.identity.ratelimit;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.speakeasy.identity.AuthMetrics;
import com.speakeasy.ops.AuthAuditService;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

class RedisAuthRateLimitAuditTest {
  @Test
  void writesOnlyTheFirstAuditEventWithinTheDeduplicationWindow() {
    StringRedisTemplate redis = mock(StringRedisTemplate.class);
    @SuppressWarnings("unchecked")
    ValueOperations<String, String> values = mock(ValueOperations.class);
    AuthAuditService audit = mock(AuthAuditService.class);
    AuthRateLimitProperties properties = new AuthRateLimitProperties();
    properties.setAuditDedupWindow(Duration.ofMinutes(15));
    when(redis.opsForValue()).thenReturn(values);
    when(values.setIfAbsent(any(), eq("1"), eq(Duration.ofMinutes(15))))
        .thenReturn(true, false);
    RedisAuthRateLimitAudit deduplicator = new RedisAuthRateLimitAudit(
        redis, properties, audit, new AuthMetrics(new SimpleMeterRegistry()));

    deduplicator.record(
        "phone-login", "account", "blocked", "authrl:v1:opaque", "request-1");
    deduplicator.record(
        "phone-login", "account", "blocked", "authrl:v1:opaque", "request-2");

    verify(audit).recordRateLimitEvent(
        "phone-login", "account", "blocked", "request-1");
  }

  @Test
  void auditFailureNeverChangesTheAuthenticationDecision() {
    StringRedisTemplate redis = mock(StringRedisTemplate.class);
    @SuppressWarnings("unchecked")
    ValueOperations<String, String> values = mock(ValueOperations.class);
    AuthAuditService audit = mock(AuthAuditService.class);
    when(redis.opsForValue()).thenReturn(values);
    when(values.setIfAbsent(any(), eq("1"), any(Duration.class)))
        .thenThrow(new IllegalStateException("offline"));
    RedisAuthRateLimitAudit deduplicator = new RedisAuthRateLimitAudit(
        redis, new AuthRateLimitProperties(), audit, new AuthMetrics(new SimpleMeterRegistry()));

    deduplicator.record(
        "refresh", "network", "blocked", "authrl:v1:opaque", "request-1");

    verify(audit, never()).recordRateLimitEvent(any(), any(), any(), any());
  }
}
