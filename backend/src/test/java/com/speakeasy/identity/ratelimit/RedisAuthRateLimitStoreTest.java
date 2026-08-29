package com.speakeasy.identity.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

@Testcontainers(disabledWithoutDocker = true)
class RedisAuthRateLimitStoreTest {
  @Container
  static final GenericContainer<?> REDIS = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
      .withExposedPorts(6379);

  private static LettuceConnectionFactory connectionFactory;
  private static StringRedisTemplate redis;

  @BeforeAll
  static void connect() {
    RedisStandaloneConfiguration configuration =
        new RedisStandaloneConfiguration(REDIS.getHost(), REDIS.getMappedPort(6379));
    connectionFactory = new LettuceConnectionFactory(configuration);
    connectionFactory.afterPropertiesSet();
    redis = new StringRedisTemplate(connectionFactory);
    redis.afterPropertiesSet();
  }

  @AfterAll
  static void disconnect() {
    connectionFactory.destroy();
  }

  @Test
  void sharesOneAtomicBucketAcrossServiceInstances() {
    MutableClock clock = new MutableClock(Instant.parse("2026-08-29T00:00:00Z"));
    RedisAuthRateLimitStore first = new RedisAuthRateLimitStore(redis, clock);
    RedisAuthRateLimitStore second = new RedisAuthRateLimitStore(redis, clock);
    AuthRateLimitStore.BucketRequest bucket = bucket("shared", 3, Duration.ofMinutes(1));

    assertThat(first.consume(List.of(bucket)).allowed()).isTrue();
    assertThat(second.consume(List.of(bucket)).allowed()).isTrue();
    assertThat(first.consume(List.of(bucket)).allowed()).isTrue();
    AuthRateLimitStore.Decision denied = second.consume(List.of(bucket));

    assertThat(denied.allowed()).isFalse();
    assertThat(denied.retryAfter()).isEqualTo(Duration.ofSeconds(60));
    assertThat(denied.violatedDimension()).isEqualTo("network");
  }

  @Test
  void refillsTokensAccordingToTheConfiguredPeriod() {
    MutableClock clock = new MutableClock(Instant.parse("2026-08-29T00:00:00Z"));
    RedisAuthRateLimitStore store = new RedisAuthRateLimitStore(redis, clock);
    AuthRateLimitStore.BucketRequest bucket = bucket("refill", 1, Duration.ofSeconds(10));

    assertThat(store.consume(List.of(bucket)).allowed()).isTrue();
    assertThat(store.consume(List.of(bucket)).allowed()).isFalse();
    clock.advance(Duration.ofSeconds(10));

    assertThat(store.consume(List.of(bucket)).allowed()).isTrue();
  }

  @Test
  void neverOverspendsTheCapacityUnderConcurrentLoad() throws Exception {
    MutableClock clock = new MutableClock(Instant.parse("2026-08-29T00:00:00Z"));
    RedisAuthRateLimitStore store = new RedisAuthRateLimitStore(redis, clock);
    AuthRateLimitStore.BucketRequest bucket = bucket("concurrent", 10, Duration.ofMinutes(1));
    ExecutorService executor = Executors.newFixedThreadPool(20);
    CountDownLatch ready = new CountDownLatch(20);
    CountDownLatch start = new CountDownLatch(1);
    AtomicInteger allowed = new AtomicInteger();

    try {
      for (int index = 0; index < 20; index++) {
        executor.submit(() -> {
          ready.countDown();
          try {
            start.await();
            if (store.consume(List.of(bucket)).allowed()) allowed.incrementAndGet();
          } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
          }
        });
      }
      assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
      start.countDown();
      executor.shutdown();
      assertThat(executor.awaitTermination(10, TimeUnit.SECONDS)).isTrue();
    } finally {
      executor.shutdownNow();
    }

    assertThat(allowed).hasValue(10);
  }

  private AuthRateLimitStore.BucketRequest bucket(String suffix, int capacity, Duration period) {
    return new AuthRateLimitStore.BucketRequest(
        "authrl:test:" + suffix + ":" + UUID.randomUUID(), "network", capacity, 1, period);
  }

  private static final class MutableClock extends Clock {
    private Instant instant;

    private MutableClock(Instant instant) {
      this.instant = instant;
    }

    void advance(Duration duration) {
      instant = instant.plus(duration);
    }

    @Override
    public ZoneId getZone() {
      return ZoneOffset.UTC;
    }

    @Override
    public Clock withZone(ZoneId zone) {
      return this;
    }

    @Override
    public Instant instant() {
      return instant;
    }
  }
}
