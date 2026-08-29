package com.speakeasy.identity.ratelimit;

public class AuthRateLimitStoreUnavailableException extends RuntimeException {
  public AuthRateLimitStoreUnavailableException(Throwable cause) {
    super("Authentication rate-limit store is unavailable.", cause);
  }
}
