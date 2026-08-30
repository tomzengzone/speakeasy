package com.speakeasy.identity.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.bind.Bindable;
import org.springframework.boot.context.properties.bind.Binder;
import org.springframework.boot.env.YamlPropertySourceLoader;
import org.springframework.core.env.PropertySource;
import org.springframework.core.env.StandardEnvironment;
import org.springframework.core.io.ClassPathResource;

class AuthRateLimitPropertiesTest {
  @Test
  void bindsTheApprovedEndpointThresholdMatrixFromApplicationConfiguration() throws Exception {
    StandardEnvironment environment = new StandardEnvironment();
    List<PropertySource<?>> sources =
        new YamlPropertySourceLoader().load("application", new ClassPathResource("application.yml"));
    sources.forEach(source -> environment.getPropertySources().addLast(source));

    AuthRateLimitProperties properties = Binder.get(environment)
        .bind("speakeasy.auth.rate-limit", Bindable.of(AuthRateLimitProperties.class))
        .orElseThrow(() -> new AssertionError("Authentication rate-limit configuration was not bound."));
    properties.validate();

    assertBucket(properties, "phone-login", "network", 30, 1, Duration.ofSeconds(2));
    assertBucket(properties, "phone-login", "device", 10, 1, Duration.ofSeconds(60));
    assertBucket(properties, "phone-login", "account", 5, 1, Duration.ofSeconds(120));
    for (String endpoint : List.of("apple-login", "wechat-login")) {
      assertBucket(properties, endpoint, "network", 60, 1, Duration.ofSeconds(1));
      assertBucket(properties, endpoint, "device", 15, 1, Duration.ofSeconds(30));
      assertBucket(properties, endpoint, "credential", 5, 1, Duration.ofSeconds(60));
      assertBucket(properties, endpoint, "account", 10, 1, Duration.ofSeconds(60));
    }
    assertBucket(properties, "refresh", "network", 120, 2, Duration.ofSeconds(1));
    assertBucket(properties, "refresh", "device", 12, 1, Duration.ofSeconds(10));
    assertBucket(properties, "refresh", "credential", 5, 1, Duration.ofSeconds(30));
    assertBucket(properties, "refresh", "account", 30, 1, Duration.ofSeconds(5));
    assertBucket(properties, "refresh", "family", 6, 1, Duration.ofSeconds(30));
    assertBucket(properties, "session-management", "network", 120, 2, Duration.ofSeconds(1));
    assertBucket(properties, "session-management", "session", 30, 1, Duration.ofSeconds(2));
    assertBucket(properties, "session-management", "account", 60, 1, Duration.ofSeconds(1));
    assertBucket(properties, "phone-code-request", "network", 20, 1, Duration.ofSeconds(3));
    assertBucket(properties, "phone-code-request", "device", 5, 1, Duration.ofSeconds(120));
    assertBucket(properties, "phone-code-request", "account", 3, 1, Duration.ofSeconds(300));
    assertBucket(properties, "phone-account-recovery-code-request", "network", 20, 1, Duration.ofSeconds(3));
    assertBucket(properties, "phone-account-recovery-code-request", "device", 5, 1, Duration.ofSeconds(120));
    assertBucket(properties, "phone-account-recovery-code-request", "account", 3, 1, Duration.ofSeconds(300));
    assertBucket(properties, "phone-account-recovery", "network", 30, 1, Duration.ofSeconds(2));
    assertBucket(properties, "phone-account-recovery", "device", 10, 1, Duration.ofSeconds(60));
    assertBucket(properties, "phone-account-recovery", "account", 5, 1, Duration.ofSeconds(120));
  }

  @Test
  void requiresAnHmacSecretWheneverRedisKeysCanBeWritten() {
    AuthRateLimitProperties properties = new AuthRateLimitProperties();
    properties.setMode(AuthRateLimitProperties.Mode.OBSERVE);

    assertThatThrownBy(properties::validate)
        .isInstanceOf(IllegalStateException.class)
        .hasMessageContaining("observe and enforce");
  }

  private void assertBucket(
      AuthRateLimitProperties properties,
      String endpoint,
      String dimension,
      int capacity,
      int refillTokens,
      Duration refillPeriod) {
    AuthRateLimitProperties.Bucket bucket = properties.bucket(endpoint, dimension);
    assertThat(bucket).isNotNull();
    assertThat(bucket.getCapacity()).isEqualTo(capacity);
    assertThat(bucket.getRefillTokens()).isEqualTo(refillTokens);
    assertThat(bucket.getRefillPeriod()).isEqualTo(refillPeriod);
  }
}
