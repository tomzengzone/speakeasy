package com.speakeasy.identity.ratelimit;

public interface AuthRateLimitAudit {
  void record(
      String endpoint,
      String dimension,
      String outcome,
      String bucketKey,
      String requestId);
}
