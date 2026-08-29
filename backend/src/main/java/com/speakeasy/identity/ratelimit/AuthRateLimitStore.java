package com.speakeasy.identity.ratelimit;

import java.time.Duration;
import java.util.List;

public interface AuthRateLimitStore {
  Decision consume(List<BucketRequest> buckets);

  record BucketRequest(
      String key, String dimension, int capacity, int refillTokens, Duration refillPeriod) {}

  record Decision(boolean allowed, Duration retryAfter, String violatedDimension) {
    public static Decision allow() { return new Decision(true, Duration.ZERO, null); }
  }
}
