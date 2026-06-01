package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.AiProviderInvocationMetric;
import com.speakeasy.ai.AiProviderInvocationMetricRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AiCostDashboardTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";

  @Autowired AiProviderInvocationMetricRepository metrics;

  @Test
  void tcComAi005ProviderCallsProduceSanitizedCostDashboard() throws Exception {
    AuthTokens tokens = loginPhone("+15550001001");

    mvc.perform(post("/ai/tts")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "text": "Cost dashboard sample",
                  "voice": "Cherry"
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"));

    MvcResult dashboard = mvc.perform(get("/admin/ai/cost-metrics")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.status").value("normal"))
        .andExpect(jsonPath("$.metrics", hasSize(1)))
        .andExpect(jsonPath("$.metrics[0].plan").value("free"))
        .andExpect(jsonPath("$.metrics[0].provider_family").value("deterministic"))
        .andExpect(jsonPath("$.metrics[0].capability").value("tts"))
        .andExpect(jsonPath("$.metrics[0].status").value("available"))
        .andExpect(jsonPath("$.metrics[0].cache_hit").value(false))
        .andExpect(jsonPath("$.metrics[0].call_count").value(1))
        .andExpect(jsonPath("$.metrics[0].budget_bucket").value("daily_user"))
        .andReturn();

    String body = dashboard.getResponse().getContentAsString();
    Double estimatedCost = JsonPath.read(body, "$.metrics[0].estimated_cost");
    String userHash = JsonPath.read(body, "$.metrics[0].user_hash");
    assertThat(estimatedCost).isGreaterThan(0.0);
    assertThat(userHash).startsWith("user_sha256:");
    assertThat(body).doesNotContain(tokens.userId());
    assertThat(body).doesNotContain("Cost dashboard sample");
  }

  @Test
  void tcComAi005BudgetWarningAndProviderAnomalyAreVisibleToOps() throws Exception {
    Instant now = Instant.now();
    metrics.save(metric("user_sha256:budget00000001", "free", "dashscope", "qwen-plus", "llm", "available", false, 900, null, "0.030000", "watch", now));
    metrics.save(metric("user_sha256:budget00000001", "free", "dashscope", "qwen-plus", "llm", "available", false, 600, null, "0.030000", "watch", now));

    mvc.perform(get("/admin/ai/cost-metrics").header(HttpHeaders.AUTHORIZATION, OPS_BEARER))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("budget_warning"))
        .andExpect(jsonPath("$.metrics[0].call_count").value(2))
        .andExpect(jsonPath("$.metrics[0].token_estimate").value(1500))
        .andExpect(jsonPath("$.metrics[0].margin_risk").value("watch"));

    metrics.deleteAll();
    metrics.save(metric("user_sha256:error00000001", "pro", "dashscope", "paraformer-v2", "asr", "provider_unavailable", false, null, 12, "0.001000", "watch", now));
    metrics.save(metric("user_sha256:error00000002", "pro", "dashscope", "paraformer-v2", "asr", "provider_unavailable", false, null, 10, "0.001000", "watch", now));
    metrics.save(metric("user_sha256:error00000003", "pro", "dashscope", "paraformer-v2", "asr", "provider_unavailable", false, null, 9, "0.001000", "watch", now));

    mvc.perform(get("/admin/ai/cost-metrics").header(HttpHeaders.AUTHORIZATION, OPS_BEARER))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("provider_anomaly"));
  }

  @Test
  void tcComAi005CostDashboardRequiresOpsToken() throws Exception {
    AuthTokens tokens = loginPhone("+15550001002");

    mvc.perform(get("/admin/ai/cost-metrics"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));

    mvc.perform(get("/admin/ai/cost-metrics").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
  }

  private AiProviderInvocationMetric metric(
      String userHash,
      String plan,
      String providerFamily,
      String model,
      String capability,
      String status,
      boolean cacheHit,
      Integer tokenEstimate,
      Integer audioDurationSeconds,
      String estimatedCost,
      String marginRisk,
      Instant createdAt) {
    return new AiProviderInvocationMetric(
        UUID.randomUUID(),
        userHash,
        plan,
        providerFamily,
        model,
        capability,
        status,
        cacheHit,
        tokenEstimate,
        audioDurationSeconds,
        new BigDecimal(estimatedCost),
        "daily_user",
        marginRisk,
        "",
        createdAt);
  }
}
