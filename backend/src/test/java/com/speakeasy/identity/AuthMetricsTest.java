package com.speakeasy.identity;

import static org.assertj.core.api.Assertions.assertThat;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Meter;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import org.junit.jupiter.api.Test;

class AuthMetricsTest {
  @Test
  void authenticationHttpLabelsUseOnlyBoundedPlatformVersionAndApiFamilyValues() {
    SimpleMeterRegistry registry = new SimpleMeterRegistry();
    AuthMetrics metrics = new AuthMetrics(registry, "42.7, 43.0");

    metrics.accessHttp("ACCESS_TOKEN_EXPIRED", "android", "42.7.19-beta", "/ai/tts/private-value");
    metrics.accessHttp("arbitrary-reason", "custom-platform", "release-user-input", "/private/raw/path");
    metrics.accessHttp("authenticated", "ios", "999.998.7", "/user/me");

    Counter bounded = registry.find("speakeasy.auth.http")
        .tags(
            "outcome", "unauthorized",
            "reason", "access_token_expired",
            "platform", "android",
            "app_version", "42.7",
            "api_family", "ai")
        .counter();
    assertThat(bounded).isNotNull();
    assertThat(bounded.count()).isEqualTo(1.0);

    Counter unknown = registry.find("speakeasy.auth.http")
        .tags(
            "outcome", "unauthorized",
            "reason", "unknown",
            "platform", "unknown",
            "app_version", "unknown",
            "api_family", "other")
        .counter();
    assertThat(unknown).isNotNull();
    assertThat(unknown.count()).isEqualTo(1.0);
    Counter unsupportedNumericVersion = registry.find("speakeasy.auth.http")
        .tags(
            "outcome", "authenticated",
            "reason", "none",
            "platform", "ios",
            "app_version", "unknown",
            "api_family", "user")
        .counter();
    assertThat(unsupportedNumericVersion).isNotNull();
    assertThat(unsupportedNumericVersion.count()).isEqualTo(1.0);
    assertThat(registry.getMeters())
        .flatExtracting(meter -> meter.getId().getTags())
        .extracting(tag -> tag.getValue())
        .doesNotContain(
            "42.7.19-beta",
            "999.998",
            "999.998.7",
            "/ai/tts/private-value",
            "/private/raw/path",
            "custom-platform");
  }
}
