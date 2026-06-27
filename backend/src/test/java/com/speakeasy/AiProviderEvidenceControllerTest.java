package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.ai.AiProviderSandboxRun;
import java.math.BigDecimal;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AiProviderEvidenceControllerTest extends BackendIntegrationTestSupport {
  private static final String OPS_BEARER = "Bearer ops-test-token";

  @Test
  void tcComAi004ProviderEvidenceEndpointReturnsEmptyListWithoutClosingGate() throws Exception {
    mvc.perform(get("/admin/ai/provider-evidence").header(HttpHeaders.AUTHORIZATION, OPS_BEARER))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.evidence", hasSize(0)));
  }

  @Test
  void tcComAi004ProviderEvidenceEndpointRequiresOpsToken() throws Exception {
    AuthTokens tokens = loginPhone("+15550003001");

    mvc.perform(get("/admin/ai/provider-evidence"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));

    mvc.perform(get("/admin/ai/provider-evidence").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("FORBIDDEN"));
  }

  @Test
  void tcComAi004ProviderEvidenceEndpointReturnsContractFieldsAndRedactsSensitiveRefs() throws Exception {
    Instant now = Instant.parse("2026-06-03T12:00:00Z");
    aiProviderSandboxRuns.save(new AiProviderSandboxRun(
        "ev_dashscope_asr_20260601",
        "dashscope",
        "asr",
        "paraformer-v2",
        "tests/fixtures/asr-short.m4a",
        1800,
        3200,
        "executed",
        null,
        new BigDecimal("0.030000"),
        "approved",
        "tests/commercial/ai_provider_sandbox_matrix.md#dashscope-asr",
        now.plusSeconds(60),
        "reviewer_sha256:asr",
        now.minusSeconds(3600),
        now.minusSeconds(3000)));
    aiProviderSandboxRuns.save(new AiProviderSandboxRun(
        "ev_dashscope_tts_blocked_20260603",
        "dashscope",
        "tts",
        "qwen3-tts-flash-api_key-should-not-leak",
        "raw_payload={\"full_transcript\":\"should not leak\"}",
        null,
        null,
        "blocked",
        "InvalidApiKey",
        null,
        "pending",
        "https://media.test.local/signed.wav?token=secret-token&signature=should-not-leak&full_transcript=raw",
        null,
        "reviewer_sha256:tts",
        now,
        now.plusSeconds(10)));
    aiProviderSandboxRuns.save(new AiProviderSandboxRun(
        "ev_dashscope_llm_newer_20260602",
        "dashscope",
        "llm",
        "qwen-plus",
        "tests/fixtures/llm-safe.json",
        900,
        1500,
        "planned",
        null,
        BigDecimal.ZERO,
        "pending",
        "tests/commercial/ai_provider_sandbox_matrix.md#dashscope-llm",
        null,
        null,
        now.minusSeconds(1800),
        now.minusSeconds(900)));
    aiProviderSandboxRuns.save(new AiProviderSandboxRun(
        "ev_dashscope_llm_a_20260602",
        "dashscope",
        "llm",
        "qwen-plus",
        "tests/fixtures/llm-a-safe.json",
        850,
        1400,
        "planned",
        null,
        BigDecimal.ZERO,
        "pending",
        "tests/commercial/ai_provider_sandbox_matrix.md#dashscope-llm-a",
        null,
        null,
        now.minusSeconds(1800),
        now.minusSeconds(1000)));
    aiProviderSandboxRuns.save(new AiProviderSandboxRun(
        "ev_dashscope_llm_b_20260602",
        "dashscope",
        "llm",
        "qwen-plus",
        "tests/fixtures/llm-b-safe.json",
        875,
        1450,
        "planned",
        null,
        BigDecimal.ZERO,
        "pending",
        "tests/commercial/ai_provider_sandbox_matrix.md#dashscope-llm-b",
        null,
        null,
        now.minusSeconds(1800),
        now.minusSeconds(1000)));

    MvcResult result = mvc.perform(get("/admin/ai/provider-evidence")
            .header(HttpHeaders.AUTHORIZATION, OPS_BEARER))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.evidence", hasSize(5)))
        .andExpect(jsonPath("$.evidence[0].evidence_id").value("ev_dashscope_tts_blocked_20260603"))
        .andExpect(jsonPath("$.evidence[0].provider_family").value("dashscope"))
        .andExpect(jsonPath("$.evidence[0].capability").value("tts"))
        .andExpect(jsonPath("$.evidence[0].status").value("blocked"))
        .andExpect(jsonPath("$.evidence[0].reviewed_status").value("pending"))
        .andExpect(jsonPath("$.evidence[0].evidence_ref").value("redacted:evidence-ref"))
        .andExpect(jsonPath("$.evidence[1].evidence_id").value("ev_dashscope_llm_newer_20260602"))
        .andExpect(jsonPath("$.evidence[2].evidence_id").value("ev_dashscope_llm_a_20260602"))
        .andExpect(jsonPath("$.evidence[3].evidence_id").value("ev_dashscope_llm_b_20260602"))
        .andExpect(jsonPath("$.evidence[4].evidence_id").value("ev_dashscope_asr_20260601"))
        .andExpect(jsonPath("$.evidence[4].reviewed_status").value("approved"))
        .andExpect(jsonPath("$.evidence[4].latency_p50_ms").value(1800))
        .andExpect(jsonPath("$.evidence[4].latency_p95_ms").value(3200))
        .andExpect(jsonPath("$.evidence[4].estimated_cost").exists())
        .andReturn();

    String body = result.getResponse().getContentAsString();
    assertThat(body).doesNotContain("api_key");
    assertThat(body).doesNotContain("should-not-leak");
    assertThat(body).doesNotContain("secret-token");
    assertThat(body).doesNotContain("signature=");
    assertThat(body).doesNotContain("full_transcript");
    assertThat(body).doesNotContain("raw_payload");
    assertThat(body).doesNotContain("model");
    assertThat(body).doesNotContain("fixture_ref");
    assertThat(body).doesNotContain("error_code");
  }
}
