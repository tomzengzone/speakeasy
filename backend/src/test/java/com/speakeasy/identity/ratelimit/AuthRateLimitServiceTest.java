package com.speakeasy.identity.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.identity.AuthMetrics;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

class AuthRateLimitServiceTest {
  @Test
  void disabledModeDoesNotTouchRedis() {
    RecordingStore store = new RecordingStore(AuthRateLimitStore.Decision.allow());
    AuthRateLimitService service = service(AuthRateLimitProperties.Mode.DISABLED, store);

    service.check("phone-login", request("198.51.100.4"), Map.of("account", "+8613800138000"));

    assertThat(store.calls).isZero();
  }

  @Test
  void enforceModeRejectsWithRoundedAndBoundedRetryAfter() {
    RecordingStore store = new RecordingStore(new AuthRateLimitStore.Decision(
        false, Duration.ofSeconds(1), "account"));
    AuthRateLimitService service = service(AuthRateLimitProperties.Mode.ENFORCE, store);

    assertThatThrownBy(() -> service.check(
        "phone-login", request("198.51.100.4"), Map.of("account", "+8613800138000")))
        .isInstanceOfSatisfying(AuthRateLimitException.class, exception -> {
          assertThat(exception.getCode()).isEqualTo("AUTH_RATE_LIMITED");
          assertThat(exception.getRetryAfter()).isEqualTo(Duration.ofSeconds(5));
          assertThat(exception.getDetails()).containsEntry("endpoint", "phone-login")
              .containsEntry("dimension", "account");
        });

    assertThat(store.requests).hasSize(2);
    assertThat(store.requests).allSatisfy(request -> {
      assertThat(request.key()).startsWith("authrl:v1:phone-login:");
      assertThat(request.key()).doesNotContain("198.51.100.4", "+8613800138000");
    });
  }

  @Test
  void observeModeRecordsTheDecisionButAllowsTheRequest() {
    RecordingStore store = new RecordingStore(new AuthRateLimitStore.Decision(
        false, Duration.ofMinutes(2), "network"));
    AuthRateLimitService service = service(AuthRateLimitProperties.Mode.OBSERVE, store);

    assertThatCode(() -> service.check("phone-login", request("198.51.100.4"), Map.of()))
        .doesNotThrowAnyException();
    assertThat(store.calls).isOne();
  }

  @Test
  void enforceFailsClosedAndObserveFailsOpenWhenRedisIsUnavailable() {
    RecordingStore unavailable = new RecordingStore(null);
    unavailable.failure = true;

    assertThatThrownBy(() -> service(AuthRateLimitProperties.Mode.ENFORCE, unavailable)
        .check("phone-login", request("198.51.100.4"), Map.of()))
        .isInstanceOfSatisfying(AuthRateLimitException.class, exception -> {
          assertThat(exception.getCode()).isEqualTo("AUTH_SERVICE_UNAVAILABLE");
          assertThat(exception.getRetryAfter()).isEqualTo(Duration.ofSeconds(5));
        });
    assertThatCode(() -> service(AuthRateLimitProperties.Mode.OBSERVE, unavailable)
        .check("phone-login", request("198.51.100.4"), Map.of()))
        .doesNotThrowAnyException();
  }

  private AuthRateLimitService service(AuthRateLimitProperties.Mode mode, RecordingStore store) {
    AuthRateLimitProperties properties = new AuthRateLimitProperties();
    properties.setMode(mode);
    properties.setKeySecret("test-secret");
    Map<String, AuthRateLimitProperties.Bucket> dimensions = new LinkedHashMap<>();
    dimensions.put("network", bucket(30, Duration.ofSeconds(2)));
    dimensions.put("account", bucket(5, Duration.ofMinutes(2)));
    properties.setPolicies(Map.of("phone-login", dimensions));
    properties.validate();
    return new AuthRateLimitService(
        properties,
        new AuthRateLimitKeyFactory("test-secret"),
        new ClientNetworkResolver(List.of()),
        store,
        new AuthMetrics(new SimpleMeterRegistry(), ""),
        (endpoint, dimension, outcome, bucketKey, requestId) -> {});
  }

  private AuthRateLimitProperties.Bucket bucket(int capacity, Duration period) {
    AuthRateLimitProperties.Bucket bucket = new AuthRateLimitProperties.Bucket();
    bucket.setCapacity(capacity);
    bucket.setRefillTokens(1);
    bucket.setRefillPeriod(period);
    return bucket;
  }

  private MockHttpServletRequest request(String remoteAddress) {
    MockHttpServletRequest request = new MockHttpServletRequest();
    request.setRemoteAddr(remoteAddress);
    return request;
  }

  private static final class RecordingStore implements AuthRateLimitStore {
    private final Decision decision;
    private int calls;
    private boolean failure;
    private List<BucketRequest> requests = List.of();

    private RecordingStore(Decision decision) {
      this.decision = decision;
    }

    @Override
    public Decision consume(List<BucketRequest> buckets) {
      calls++;
      requests = buckets;
      if (failure) throw new AuthRateLimitStoreUnavailableException(new IllegalStateException("offline"));
      return decision;
    }
  }
}
