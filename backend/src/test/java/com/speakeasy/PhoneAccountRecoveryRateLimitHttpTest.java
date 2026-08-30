package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.clearInvocations;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.identity.ratelimit.AuthRateLimitAudit;
import com.speakeasy.identity.ratelimit.AuthRateLimitStore;
import com.speakeasy.identity.ratelimit.AuthRateLimitStoreUnavailableException;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Duration;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = {
    "speakeasy.auth.account-recovery-enabled=true",
    "speakeasy.auth.rate-limit.mode=enforce",
    "speakeasy.auth.rate-limit.key-secret=recovery-rate-limit-test-secret"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
@ExtendWith(OutputCaptureExtension.class)
class PhoneAccountRecoveryRateLimitHttpTest {
  private static final String PHONE = "+8613800138670";
  private static final String DEVICE = "recovery-device-secret";
  private static final String NETWORK = "198.51.100.77";
  private static final String CODE = "887766";
  private static final String HEADER_SECRET = "opaque-header-secret";

  @Autowired MockMvc mvc;
  @Autowired MeterRegistry meterRegistry;
  @MockBean AuthRateLimitStore store;
  @MockBean AuthRateLimitAudit rateLimitAudit;

  @Test
  void requestCodeEndpointEnforcesNetworkDeviceAndAccountBuckets(CapturedOutput output)
      throws Exception {
    for (String dimension : List.of("network", "device", "account")) {
      assertRateLimited(
          "/auth/account-recovery/phone/verification-codes",
          requestCodeBody(),
          "phone-account-recovery-code-request",
          dimension,
          "req-recovery-code-rate-" + dimension);
    }
    assertNoSecretsInLogsOrMetricTags(output);
  }

  @Test
  void completionEndpointEnforcesNetworkDeviceAndAccountBuckets(CapturedOutput output)
      throws Exception {
    for (String dimension : List.of("network", "device", "account")) {
      assertRateLimited(
          "/auth/account-recovery/phone",
          completionBody(),
          "phone-account-recovery",
          dimension,
          "req-recovery-complete-rate-" + dimension);
    }
    assertNoSecretsInLogsOrMetricTags(output);
  }

  @Test
  void unavailableSharedLimiterReturnsRetryHeadersForBothRecoveryEndpoints()
      throws Exception {
    when(store.consume(anyList())).thenThrow(
        new AuthRateLimitStoreUnavailableException(new IllegalStateException("redis offline")));

    assertLimiterUnavailable(
        "/auth/account-recovery/phone/verification-codes",
        requestCodeBody(),
        "req-recovery-code-limiter-unavailable");
    assertLimiterUnavailable(
        "/auth/account-recovery/phone",
        completionBody(),
        "req-recovery-complete-limiter-unavailable");
  }

  private void assertRateLimited(
      String path, String body, String endpoint, String violatedDimension, String requestId)
      throws Exception {
    clearInvocations(store);
    clearInvocations(rateLimitAudit);
    when(store.consume(anyList())).thenReturn(
        new AuthRateLimitStore.Decision(false, Duration.ofSeconds(1), violatedDimension));

    mvc.perform(post(path)
            .with(request -> {
              request.setRemoteAddr(NETWORK);
              return request;
            })
            .header("X-Request-Id", requestId)
            .header("X-Arbitrary-Header", HEADER_SECRET)
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isTooManyRequests())
        .andExpect(header().string("Retry-After", "5"))
        .andExpect(header().string("Cache-Control", "no-store"))
        .andExpect(header().string("X-Request-Id", requestId))
        .andExpect(jsonPath("$.error.code").value("AUTH_RATE_LIMITED"))
        .andExpect(jsonPath("$.error.request_id").value(requestId))
        .andExpect(jsonPath("$.error.details.endpoint").value(endpoint))
        .andExpect(jsonPath("$.error.details.dimension").value(violatedDimension));

    @SuppressWarnings("unchecked")
    ArgumentCaptor<List<AuthRateLimitStore.BucketRequest>> captor =
        ArgumentCaptor.forClass(List.class);
    verify(store).consume(captor.capture());
    List<AuthRateLimitStore.BucketRequest> buckets = captor.getValue();
    assertThat(buckets).extracting(AuthRateLimitStore.BucketRequest::dimension)
        .containsExactly("network", "device", "account");
    assertThat(buckets).allSatisfy(bucket -> {
      assertThat(bucket.key()).startsWith("authrl:v1:" + endpoint + ":");
      assertThat(bucket.key()).doesNotContain(PHONE, DEVICE, NETWORK, CODE, HEADER_SECRET);
    });
    ArgumentCaptor<String> auditBucketKey = ArgumentCaptor.forClass(String.class);
    verify(rateLimitAudit).record(
        eq(endpoint), eq(violatedDimension), eq("blocked"), auditBucketKey.capture(), eq(requestId));
    assertThat(auditBucketKey.getValue())
        .doesNotContain(PHONE, DEVICE, NETWORK, CODE, HEADER_SECRET);
  }

  private void assertLimiterUnavailable(String path, String body, String requestId)
      throws Exception {
    mvc.perform(post(path)
            .with(request -> {
              request.setRemoteAddr(NETWORK);
              return request;
            })
            .header("X-Request-Id", requestId)
            .contentType(MediaType.APPLICATION_JSON)
            .content(body))
        .andExpect(status().isServiceUnavailable())
        .andExpect(header().string("Retry-After", "5"))
        .andExpect(header().string("Cache-Control", "no-store"))
        .andExpect(header().string("X-Request-Id", requestId))
        .andExpect(jsonPath("$.error.code").value("AUTH_SERVICE_UNAVAILABLE"));
  }

  private void assertNoSecretsInLogsOrMetricTags(CapturedOutput output) {
    assertThat(output.getAll()).doesNotContain(PHONE, DEVICE, NETWORK, CODE, HEADER_SECRET);
    Set<String> secrets = Set.of(PHONE, DEVICE, NETWORK, CODE, HEADER_SECRET);
    meterRegistry.getMeters().forEach(meter -> meter.getId().getTags().forEach(tag ->
        assertThat(secrets).noneMatch(secret -> tag.getValue().contains(secret))));
  }

  private String requestCodeBody() {
    return """
        {
          "schema_version": 1,
          "phone_number": "%s",
          "device_id": "%s"
        }
        """.formatted(PHONE, DEVICE);
  }

  private String completionBody() {
    return """
        {
          "schema_version": 1,
          "phone_number": "%s",
          "verification_code": "%s",
          "device_id": "%s"
        }
        """.formatted(PHONE, CODE, DEVICE);
  }
}
