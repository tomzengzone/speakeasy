package com.speakeasy.identity.ratelimit;

import java.time.Clock;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import org.springframework.core.io.ClassPathResource;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;

public class RedisAuthRateLimitStore implements AuthRateLimitStore {
  private final StringRedisTemplate redis;
  private final Clock clock;
  private final DefaultRedisScript<List> script;

  public RedisAuthRateLimitStore(StringRedisTemplate redis, Clock clock) {
    this.redis = redis;
    this.clock = clock;
    this.script = new DefaultRedisScript<>();
    this.script.setLocation(new ClassPathResource("redis/auth_rate_limit_token_bucket.lua"));
    this.script.setResultType(List.class);
  }

  @Override
  public Decision consume(List<BucketRequest> buckets) {
    if (buckets == null || buckets.isEmpty()) return Decision.allow();
    List<String> keys = buckets.stream().map(BucketRequest::key).toList();
    List<String> arguments = new ArrayList<>();
    arguments.add(Long.toString(clock.millis()));
    for (BucketRequest bucket : buckets) {
      arguments.add(Integer.toString(bucket.capacity()));
      arguments.add(Integer.toString(bucket.refillTokens()));
      arguments.add(Long.toString(bucket.refillPeriod().toMillis()));
    }
    try {
      List<?> result = redis.execute(script, keys, arguments.toArray());
      if (result == null || result.size() < 3) throw new IllegalStateException("Unexpected Redis rate-limit result.");
      boolean allowed = number(result.get(0)) == 1L;
      long retrySeconds = Math.max(0L, number(result.get(1)));
      int violatedIndex = Math.toIntExact(number(result.get(2)));
      String dimension = violatedIndex <= 0 || violatedIndex > buckets.size()
          ? null : buckets.get(violatedIndex - 1).dimension();
      return new Decision(allowed, Duration.ofSeconds(retrySeconds), dimension);
    } catch (RuntimeException exception) {
      throw new AuthRateLimitStoreUnavailableException(exception);
    }
  }

  private long number(Object value) {
    if (value instanceof Number number) return number.longValue();
    return Long.parseLong(String.valueOf(value));
  }
}
