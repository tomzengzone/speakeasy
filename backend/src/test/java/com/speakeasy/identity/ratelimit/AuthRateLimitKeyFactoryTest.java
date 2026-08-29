package com.speakeasy.identity.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AuthRateLimitKeyFactoryTest {
  @Test
  void createsDeterministicOpaqueKeysWithoutRawIdentifiers() {
    AuthRateLimitKeyFactory keys = new AuthRateLimitKeyFactory("test-rate-limit-secret");

    String first = keys.key("phone-login", "account", "+8613800138000");
    String second = keys.key("phone-login", "account", "+8613800138000");
    String other = keys.key("phone-login", "account", "+8613800138001");

    assertThat(first).isEqualTo(second).isNotEqualTo(other);
    assertThat(first).startsWith("authrl:v1:phone-login:account:");
    assertThat(first).doesNotContain("13800138000").doesNotContain("+86");
  }

  @Test
  void separatesEndpointAndDimensionNamespaces() {
    AuthRateLimitKeyFactory keys = new AuthRateLimitKeyFactory("test-rate-limit-secret");

    assertThat(keys.key("refresh", "device", "install-1"))
        .isNotEqualTo(keys.key("refresh", "account", "install-1"))
        .isNotEqualTo(keys.key("phone-login", "device", "install-1"));
  }
}
