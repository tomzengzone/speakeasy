package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.BackendIntegrationTestSupport;
import com.speakeasy.ai.AiProviderInvocationMetric;
import com.speakeasy.ai.AiProviderInvocationMetricRepository;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotCostTelemetryTest extends BackendIntegrationTestSupport {
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired AiProviderInvocationMetricRepository metrics;

  @BeforeEach
  void cleanMetrics() {
    metrics.deleteAll();
  }

  @Test
  void tcP02Fud009DeterministicNoProviderMetricsAreRecordedForPlanAndCheckpoint() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140520");
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(userId, "{\"ai\":5,\"asr\":100,\"tts\":100,\"scoring\":5,\"training\":50}");

    createSupportedGoal(tokens, "req_fud_s005_goal").andExpect(status().isOk());
    generatePlan(tokens, "req_fud_s005_plan", false, "initial_backplan").andExpect(status().isOk());
    submitCheckpoint(tokens, "req_fud_s005_checkpoint", "recorded", longTranscript())
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint.result_status").value("recorded"));

    assertMetric(userId, "llm", "deterministic_no_provider", "deterministic_no_provider_call:plan_generate");
    assertMetric(userId, "scoring", "deterministic_no_provider", "deterministic_no_provider_call:checkpoint_submit");
    assertThat(metrics.findAll()).allSatisfy(metric -> {
      assertThat(metric.getUserHash()).startsWith("user_sha256:");
      assertThat(metric.getUserHash()).doesNotContain(userId.toString());
      assertThat(metric.getEstimatedCost()).isEqualByComparingTo(BigDecimal.ZERO);
      assertThat(metric.getFallbackReason()).doesNotContain("I would structure my response");
    });
  }

  @Test
  void tcP02Fud009PolicyRejectionAndQuotaMetricsDoNotCreateEntitlementFacts() throws Exception {
    AuthTokens freeTokens = loginPhone("+8613800140521");
    UUID freeUserId = UUID.fromString(freeTokens.userId());
    createSupportedGoal(freeTokens, "req_fud_s005_free_goal")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("limited"));
    generatePlan(freeTokens, "req_fud_s005_free_plan", false, "free_limited")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("limited"));

    assertMetric(freeUserId, "llm", "rejected", "missing_entitlement_free_fallback");
    assertThat(entitlements.findByUserIdOrderByGeneratedAtDesc(freeUserId)).isEmpty();

    AuthTokens paidTokens = loginPhone("+8613800140522");
    UUID paidUserId = UUID.fromString(paidTokens.userId());
    saveEntitlement(paidUserId, "{\"ai\":1,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}");
    createSupportedGoal(paidTokens, "req_fud_s005_quota_goal").andExpect(status().isOk());
    generatePlan(paidTokens, "req_fud_s005_quota_plan_1", false, "initial_backplan").andExpect(status().isOk());
    generatePlan(paidTokens, "req_fud_s005_quota_plan_2", true, "quota_retry")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"));

    assertMetric(paidUserId, "llm", "rejected", "quota_exhausted:plan_generate");
  }

  private void assertMetric(UUID userId, String capability, String status, String fallbackReason) {
    assertThat(metrics.findAll()).anySatisfy(metric -> {
      assertThat(metric.getUserHash()).startsWith("user_sha256:");
      assertThat(metric.getUserHash()).doesNotContain(userId.toString());
      assertThat(metric.getProviderFamily()).isIn("deterministic", "ai-gateway");
      assertThat(metric.getCapability()).isEqualTo(capability);
      assertThat(metric.getStatus()).isEqualTo(status);
      assertThat(metric.getFallbackReason()).isEqualTo(fallbackReason);
      assertThat(metric.getBudgetBucket()).isEqualTo("daily_user");
      assertThat(metric.getMarginRisk()).isIn("low", "watch");
    });
  }

  private void saveEntitlement(UUID userId, String quotaLimits) {
    entitlements.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        userId,
        null,
        "pro",
        "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
        quotaLimits,
        "active",
        null,
        Instant.now()));
  }

  private ResultActions createSupportedGoal(AuthTokens tokens, String requestId) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .header("Idempotency-Key", "cost-goal-" + requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "goal_type": "ielts_speaking",
              "target_score": 7.5,
              "deadline": "%s",
              "daily_minutes": 30,
              "intensity_preference": "standard",
              "diagnostic_samples": [
                {
                  "sample_ref": "diag-s005-a",
                  "transcript": "I can describe an experience with a clear reason, a specific example, and a short conclusion.",
                  "duration_seconds": 66
                },
                {
                  "sample_ref": "diag-s005-b",
                  "transcript": "I need more practice extending answers naturally while keeping the organization easy to follow.",
                  "duration_seconds": 68
                }
              ]
            }
            """.formatted(LocalDate.now().plusDays(75))));
  }

  private ResultActions generatePlan(AuthTokens tokens, String requestId, boolean forceReplan, String reasonCode) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": %s,
              "reason_code": "%s"
            }
            """.formatted(forceReplan, reasonCode)));
  }

  private ResultActions submitCheckpoint(
      AuthTokens tokens, String requestId, String resultStatus, String transcript) throws Exception {
    return mvc.perform(post("/goal-autopilot/checkpoints")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "checkpoint_type": "weekly_mock",
              "transcript": "%s",
              "score_hint": 7.0,
              "result_status": "%s"
            }
            """.formatted(transcript, resultStatus)));
  }

  private String longTranscript() {
    return "I would structure my response by giving context, naming the challenge, "
        + "adding a concrete example, and closing with the result and the lesson from the situation.";
  }
}
