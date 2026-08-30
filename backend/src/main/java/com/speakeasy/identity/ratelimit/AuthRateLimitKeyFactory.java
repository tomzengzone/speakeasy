package com.speakeasy.identity.ratelimit;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.util.Base64;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public final class AuthRateLimitKeyFactory {
  private static final String HMAC_ALGORITHM = "HmacSHA256";
  private final byte[] secret;

  public AuthRateLimitKeyFactory(String secret) {
    if (secret == null || secret.isBlank()) {
      throw new IllegalArgumentException("Authentication rate-limit key secret is required.");
    }
    this.secret = secret.getBytes(StandardCharsets.UTF_8);
  }

  public String key(String endpoint, String dimension, String identifier) {
    String normalizedEndpoint = safeSegment(endpoint);
    String normalizedDimension = safeSegment(dimension);
    String value = identifier == null ? "unknown" : identifier.trim();
    try {
      Mac mac = Mac.getInstance(HMAC_ALGORITHM);
      mac.init(new SecretKeySpec(secret, HMAC_ALGORITHM));
      String digest = Base64.getUrlEncoder().withoutPadding()
          .encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
      return "authrl:v1:" + normalizedEndpoint + ":" + normalizedDimension + ":" + digest;
    } catch (GeneralSecurityException exception) {
      throw new IllegalStateException("HMAC-SHA256 is unavailable.", exception);
    }
  }

  private String safeSegment(String value) {
    if (value == null || !value.matches("[a-z0-9-]{1,40}")) {
      throw new IllegalArgumentException("Rate-limit key segment is invalid.");
    }
    return value;
  }
}
