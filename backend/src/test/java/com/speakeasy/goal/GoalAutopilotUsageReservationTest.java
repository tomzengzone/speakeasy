package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.BackendIntegrationTestSupport;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import com.speakeasy.usage.UsageLedger;
import com.speakeasy.usage.UsageLedgerRepository;
import com.speakeasy.usage.UsageReservation;
import com.speakeasy.usage.UsageReservationRepository;
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
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotUsageReservationTest extends BackendIntegrationTestSupport {
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired UsageReservationRepository usageReservations;
  @Autowired UsageLedgerRepository ledgers;
  @Autowired GoalBackplanRepository backplans;

  @Test
  void tcP02Fud007PlanUsageIsReservedCommittedAndIdempotent() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140320");
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(userId, "{\"ai\":2,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}");
    createSupportedGoal(tokens, "req_fud_s004_goal")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("full"));

    generatePlan(tokens, "req_fud_s004_plan", false, "initial_backplan")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("full"));

    assertUsage(userId, "ai", 1, 0);
    List<UsageReservation> aiReservations = usageReservations.findAll().stream()
        .filter(reservation -> userId.equals(reservation.getUserId()))
        .filter(reservation -> "ai".equals(reservation.getUsageFamily()))
        .toList();
    assertThat(aiReservations).hasSize(1);
    assertThat(aiReservations.get(0).getStatus()).isEqualTo("committed");
    assertThat(aiReservations.get(0).getSourceRef()).startsWith("goal_autopilot:plan_generate:");
    assertThat(aiReservations.get(0).getProviderUsageEventRef()).startsWith("goal_autopilot:plan_generate:committed:");

    generatePlan(tokens, "req_fud_s004_plan", false, "initial_backplan")
        .andExpect(status().isOk());
    assertUsage(userId, "ai", 1, 0);
    assertThat(usageReservations.findAll().stream()
        .filter(reservation -> userId.equals(reservation.getUserId()))
        .filter(reservation -> "ai".equals(reservation.getUsageFamily()))
        .count()).isEqualTo(1);

    long backplansBeforeConflict = backplans.count();
    generatePlan(tokens, "req_fud_s004_plan", true, "changed_payload")
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.error.code").value("IDEMPOTENCY_CONFLICT"));
    assertUsage(userId, "ai", 1, 0);
    assertThat(backplans.count()).isEqualTo(backplansBeforeConflict);
  }

  @Test
  void tcP02Fud007CheckpointUsageCommitsSuccessfulEvidenceAndReleasesLowConfidenceFallback() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140321");
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(userId, "{\"ai\":100,\"asr\":100,\"tts\":100,\"scoring\":2,\"training\":50}");
    createSupportedGoal(tokens, "req_fud_s004_checkpoint_goal").andExpect(status().isOk());
    generatePlan(tokens, "req_fud_s004_checkpoint_plan", false, "initial_backplan").andExpect(status().isOk());

    submitCheckpoint(tokens, "req_fud_s004_checkpoint_commit", "recorded", longTranscript())
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint.result_status").value("recorded"));
    assertUsage(userId, "scoring", 1, 0);

    submitCheckpoint(tokens, "req_fud_s004_checkpoint_release", "failed", "short evidence")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint.result_status").value("failed"));
    assertUsage(userId, "scoring", 1, 0);

    List<UsageReservation> scoringReservations = usageReservations.findAll().stream()
        .filter(reservation -> userId.equals(reservation.getUserId()))
        .filter(reservation -> "scoring".equals(reservation.getUsageFamily()))
        .toList();
    assertThat(scoringReservations).extracting(UsageReservation::getStatus)
        .containsExactlyInAnyOrder("committed", "released");
    assertThat(scoringReservations).allSatisfy(reservation -> {
      assertThat(reservation.getSourceRef()).startsWith("goal_autopilot:checkpoint_submit:");
      assertThat(reservation.getProviderUsageEventRef()).startsWith("goal_autopilot:checkpoint_submit:");
    });
  }

  @Test
  void tcP02Fud008QuotaBlocksBeforePlanWritesAndLimitedDepthDoesNotReserveUsage() throws Exception {
    AuthTokens paidTokens = loginPhone("+8613800140322");
    UUID paidUserId = UUID.fromString(paidTokens.userId());
    saveEntitlement(paidUserId, "{\"ai\":1,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}");
    createSupportedGoal(paidTokens, "req_fud_s004_quota_goal").andExpect(status().isOk());
    generatePlan(paidTokens, "req_fud_s004_quota_plan_1", false, "initial_backplan").andExpect(status().isOk());
    long backplansBeforeBlockedRetry = backplans.count();

    generatePlan(paidTokens, "req_fud_s004_quota_plan_2", true, "quota_retry")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.code").value("USAGE_LIMIT_EXCEEDED"))
        .andExpect(jsonPath("$.error.details.usage_family").value("ai"));
    assertUsage(paidUserId, "ai", 1, 0);
    assertThat(backplans.count()).isEqualTo(backplansBeforeBlockedRetry);

    AuthTokens freeTokens = loginPhone("+8613800140323");
    UUID freeUserId = UUID.fromString(freeTokens.userId());
    createSupportedGoal(freeTokens, "req_fud_s004_free_goal")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("limited"));
    generatePlan(freeTokens, "req_fud_s004_free_plan", false, "free_depth_plan")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.entitlement_depth.depth_state").value("limited"));
    assertThat(usageReservations.findAll().stream()
        .filter(reservation -> freeUserId.equals(reservation.getUserId()))
        .count()).isZero();
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

  private void assertUsage(UUID userId, String usageFamily, int committed, int reserved) {
    UsageLedger ledger = ledgers.findByUserId(userId).stream()
        .filter(candidate -> usageFamily.equals(candidate.getUsageFamily()))
        .findFirst()
        .orElseThrow();
    assertThat(ledger.getCommittedAmount()).isEqualTo(committed);
    assertThat(ledger.getReservedAmount()).isEqualTo(reserved);
  }

  private ResultActions createSupportedGoal(AuthTokens tokens, String requestId) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .header("Idempotency-Key", "usage-goal-" + requestId)
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
                  "sample_ref": "diag-s004-a",
                  "transcript": "I usually introduce a point, give one concrete example, and connect it back to the question with a clear reason.",
                  "duration_seconds": 68
                },
                {
                  "sample_ref": "diag-s004-b",
                  "transcript": "My biggest speaking gap is extending examples naturally while keeping the answer organized and relevant.",
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
    return "I would structure my response by introducing the situation, explaining the challenge, "
        + "giving a concrete example with enough detail, and ending with the result and what I learned from it.";
  }
}
