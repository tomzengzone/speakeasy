package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotQuotaDowngradeTest extends BackendIntegrationTestSupport {
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired GoalBackplanRepository backplans;

  @Test
  void tcP02Fud011QuotaExhaustionReturnsStableDowngradeAndClearsProjection() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140620");
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(userId, "pro", "active", "{\"ai\":1,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}", null);
    createSupportedGoal(tokens, "req_fud_s006_quota_goal")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("full"));
    generatePlan(tokens, "req_fud_s006_quota_plan_1", false, "initial_backplan")
        .andExpect(status().isOk());
    long backplansBeforeBlockedRetry = backplans.count();

    generatePlan(tokens, "req_fud_s006_quota_plan_2", true, "quota_retry")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"))
        .andExpect(jsonPath("$.error.details.usage_family").value("ai"))
        .andExpect(jsonPath("$.error.details.operation").value("plan_generate"))
        .andExpect(jsonPath("$.error.details.downgrade_state").value("QuotaDowngraded"))
        .andExpect(jsonPath("$.error.details.downgrade_reason").value("quota_exhausted"))
        .andExpect(jsonPath("$.error.details.blocked_full_depth").value(true));
    assertThat(backplans.count()).isEqualTo(backplansBeforeBlockedRetry);

    assertProjectionDowngraded(tokens, "quota_exhausted");
  }

  @Test
  void tcP02Fud011EntitlementBlockedUsesStableDowngradeReason() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140621");
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(userId, "pro", "revoked", "{\"ai\":5,\"asr\":100,\"tts\":100,\"scoring\":5,\"training\":50}", null);
    createSupportedGoal(tokens, "req_fud_s006_entitlement_goal")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("blocked"))
        .andExpect(jsonPath("$.entitlement_depth.limitation_reason").value("entitlement_blocked_revoked"))
        .andExpect(jsonPath("$.forecast.forecast_state").value("unavailable"))
        .andExpect(jsonPath("$.forecast.eta_unavailable_reason").value("entitlement_required"));

    generatePlan(tokens, "req_fud_s006_entitlement_plan", false, "blocked_entitlement")
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.error.code").value("ENTITLEMENT_DEPTH_BLOCKED"))
        .andExpect(jsonPath("$.error.details.reason_code").value("entitlement_required"))
        .andExpect(jsonPath("$.error.details.source_reason").value("entitlement_blocked_revoked"))
        .andExpect(jsonPath("$.error.details.downgrade_state").value("EntitlementBlocked"))
        .andExpect(jsonPath("$.error.details.downgrade_reason").value("entitlement_required"))
        .andExpect(jsonPath("$.error.details.blocked_full_depth").value(true));

    mvc.perform(get("/goal-autopilot/checkpoints/task")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint_task.checkpoint_state").value("CheckpointUnavailable"))
        .andExpect(jsonPath("$.checkpoint_task.limitation_reason").value("entitlement_required"))
        .andExpect(jsonPath("$.entitlement_depth.limitation_reason").value("entitlement_blocked_revoked"));
    assertProjectionDowngraded(tokens, "entitlement_required");
  }

  @Test
  void tcP02Fud011CostBudgetLimitedUsesStableDowngradeReasonWithoutFullDepthProjection() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140622");
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(
        userId,
        "pro",
        "active",
        "{\"ai\":5,\"asr\":100,\"tts\":100,\"scoring\":5,\"training\":50,\"cost_budget\":0}",
        null);
    createSupportedGoal(tokens, "req_fud_s006_cost_goal")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("limited"))
        .andExpect(jsonPath("$.entitlement_depth.limitation_reason").value("cost_budget_limited"))
        .andExpect(jsonPath("$.forecast.forecast_state").value("unavailable"))
        .andExpect(jsonPath("$.forecast.eta_unavailable_reason").value("cost_budget_limited"));

    generatePlan(tokens, "req_fud_s006_cost_plan", false, "cost_budget_limited")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("limited"))
        .andExpect(jsonPath("$.entitlement_depth.provider_candidate_allowed").value(false))
        .andExpect(jsonPath("$.entitlement_depth.limitation_reason").value("cost_budget_limited"));
    mvc.perform(get("/goal-autopilot/checkpoints/task")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint_task.limitation_reason").value("cost_budget_limited"));
    assertProjectionDowngraded(tokens, "cost_budget_limited");
  }

  private void assertProjectionDowngraded(AuthTokens tokens, String reason) throws Exception {
    MvcResult result = mvc.perform(get("/goal-autopilot/progress-projection")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.projection.projection_state").value("unavailable"))
        .andExpect(jsonPath("$.projection.downgrade_reason").value(reason))
        .andExpect(jsonPath("$.projection.goal").doesNotExist())
        .andExpect(jsonPath("$.projection.next_action").doesNotExist())
        .andExpect(jsonPath("$.projection.progress").doesNotExist())
        .andExpect(jsonPath("$.projection.latest_checkpoint").doesNotExist())
        .andExpect(jsonPath("$.projection.source_refs", hasSize(0)))
        .andExpect(jsonPath("$.projection.surface_fragments[?(@.eligible == false)]", hasSize(3)))
        .andExpect(jsonPath("$.projection.surface_fragments[?(@.downgrade_reason == '" + reason + "')]", hasSize(3)))
        .andReturn();
    String body = result.getResponse().getContentAsString();
    for (int index = 0; index < 3; index += 1) {
      List<String> safeFields = JsonPath.read(body, "$.projection.surface_fragments[" + index + "].safe_fields");
      assertThat(safeFields).isEmpty();
      assertThat(JsonPath.<String>read(body, "$.projection.surface_fragments[" + index + "].next_action_ref")).isNull();
      assertThat(JsonPath.<String>read(body, "$.projection.surface_fragments[" + index + "].forecast_ref")).isNull();
      assertThat(JsonPath.<String>read(body, "$.projection.surface_fragments[" + index + "].checkpoint_ref")).isNull();
    }
    assertThat(body).doesNotContain(
        "Fluency expansion drill",
        "Backend checkpoint conclusion only",
        "eta_date",
        "target_score",
        "target_ability",
        "official_score",
        "guaranteed",
        "goal achieved");
  }

  private void saveEntitlement(UUID userId, String plan, String status, String quotaLimits, Instant validUntil) {
    entitlements.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        userId,
        null,
        plan,
        "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
        quotaLimits,
        status,
        validUntil,
        Instant.now()));
  }

  private ResultActions createSupportedGoal(AuthTokens tokens, String requestId) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .header("Idempotency-Key", "quota-goal-" + requestId)
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
                  "sample_ref": "diag-s006-a",
                  "transcript": "I can explain a speaking answer with a direct point, one concrete example, and a short conclusion.",
                  "duration_seconds": 68
                },
                {
                  "sample_ref": "diag-s006-b",
                  "transcript": "I need a plan that keeps follow-up answers organized while improving fluency and example depth.",
                  "duration_seconds": 66
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
}
