package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.BackendIntegrationTestSupport;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalProgressProjectionDataGovernanceTest extends BackendIntegrationTestSupport {
  @Autowired GoalAutopilotService goalAutopilotService;
  @Autowired GoalProgressForecastRepository goalProgressForecasts;

  @Test
  void tcP02Fuc017DowngradesUnavailableUnsupportedStaleAndControlBlockedSurfaces() throws Exception {
    AuthTokens noGoalTokens = loginPhone("+8613800140410");
    GoalAutopilotService.GoalProgressProjectionView noGoal =
        goalAutopilotService.progressProjection(UUID.fromString(noGoalTokens.userId()));
    assertIneligibleProjection(noGoal, "unavailable", "no_active_goal");
    assertThat(noGoal.goal()).isNull();
    assertThat(noGoal.progress()).isNull();
    assertThat(noGoal.sourceRefs()).isEmpty();

    AuthTokens unavailableTokens = loginPhone("+8613800140411");
    UUID unavailableUserId = UUID.fromString(unavailableTokens.userId());
    createGoal(unavailableTokens, "ielts_speaking", "8", "lead a structured interview answer", 30, 3);
    generatePlan(unavailableTokens, false, "initial_backplan");
    goalProgressForecasts.deleteByUserId(unavailableUserId);
    GoalAutopilotService.GoalProgressProjectionView unavailable =
        goalAutopilotService.progressProjection(unavailableUserId);
    assertIneligibleProjection(unavailable, "unavailable", "forecast_unavailable");

    AuthTokens unsupportedTokens = loginPhone("+8613800140412");
    createGoal(unsupportedTokens, "opera_singing", null, "perform an aria", 30, 1);
    GoalAutopilotService.GoalProgressProjectionView unsupported =
        goalAutopilotService.progressProjection(UUID.fromString(unsupportedTokens.userId()));
    assertIneligibleProjection(unsupported, "unsupported", "unsupported_goal");
    assertThat(unsupported.toString()).doesNotContain("perform an aria");

    AuthTokens staleTokens = loginPhone("+8613800140413");
    createGoal(staleTokens, "ielts_speaking", "8", "answer follow-up questions with evidence", 30, 3);
    generatePlan(staleTokens, false, "initial_backplan");
    createGoal(staleTokens, "ielts_speaking", "8", "revise the goal without retaining stale surface facts", 30, 3);
    GoalAutopilotService.GoalProgressProjectionView stale =
        goalAutopilotService.progressProjection(UUID.fromString(staleTokens.userId()));
    assertIneligibleProjection(stale, "stale_plan", "stale_plan");

    AuthTokens pausedTokens = loginPhone("+8613800140414");
    createGoal(pausedTokens, "ielts_speaking", "8", "lead a client update", 30, 3);
    generatePlan(pausedTokens, false, "initial_backplan");
    pause(pausedTokens);
    GoalAutopilotService.GoalProgressProjectionView paused =
        goalAutopilotService.progressProjection(UUID.fromString(pausedTokens.userId()));
    assertIneligibleProjection(paused, "control_blocked", "paused");
  }

  @Test
  void tcP02Fuc017KeepsLimitedAndLowConfidenceDowngradeTraceableWithoutEtaOrCompletion() throws Exception {
    AuthTokens partialTokens = loginPhone("+8613800140415");
    createGoal(partialTokens, "ielts_speaking", "8", "sustain structured speaking", 10, 3);
    generatePlan(partialTokens, false, "partial_plan");
    GoalAutopilotService.GoalProgressProjectionView partial =
        goalAutopilotService.progressProjection(UUID.fromString(partialTokens.userId()));
    assertEligibleDowngradedProjection(partial, "limited", "partial_goal_limited");
    assertThat(partial.progress().etaDate()).isNull();
    assertThat(partial.progress().claimGuard().goalCompletionClaimAllowed()).isFalse();

    AuthTokens lowConfidenceTokens = loginPhone("+8613800140416");
    createGoal(lowConfidenceTokens, "ielts_speaking", "8", "answer interview follow-ups", 30, 0);
    generatePlan(lowConfidenceTokens, false, "low_confidence_plan");
    GoalAutopilotService.GoalProgressProjectionView lowConfidence =
        goalAutopilotService.progressProjection(UUID.fromString(lowConfidenceTokens.userId()));
    assertEligibleDowngradedProjection(lowConfidence, "low_confidence", "low_confidence");
    assertThat(lowConfidence.progress().etaDate()).isNull();
    assertThat(lowConfidence.progress().claimGuard().goalCompletionClaimAllowed()).isFalse();
  }

  private void assertIneligibleProjection(
      GoalAutopilotService.GoalProgressProjectionView projection,
      String state,
      String reason) {
    assertThat(projection.projectionState()).isEqualTo(state);
    assertThat(projection.downgradeReason()).isEqualTo(reason);
    assertThat(projection.surfaceFragments()).hasSize(3);
    assertThat(projection.surfaceFragments()).allSatisfy(fragment -> {
      assertThat(fragment.displayState()).isEqualTo(state);
      assertThat(fragment.eligible()).isFalse();
      assertThat(fragment.downgradeReason()).isEqualTo(reason);
      assertThat(fragment.nextActionRef()).isNull();
      assertThat(fragment.forecastRef()).isNull();
      assertThat(fragment.checkpointRef()).isNull();
      assertThat(fragment.safeFields()).isEmpty();
    });
  }

  private void assertEligibleDowngradedProjection(
      GoalAutopilotService.GoalProgressProjectionView projection,
      String state,
      String reason) {
    assertThat(projection.projectionState()).isEqualTo(state);
    assertThat(projection.downgradeReason()).isEqualTo(reason);
    assertThat(projection.surfaceFragments()).hasSize(3);
    assertThat(projection.surfaceFragments()).allSatisfy(fragment -> {
      assertThat(fragment.displayState()).isEqualTo(state);
      assertThat(fragment.eligible()).isTrue();
      assertThat(fragment.downgradeReason()).isEqualTo(reason);
      assertThat(fragment.safeFields()).doesNotContain(
          "eta_date",
          "eta_range",
          "goal_completion",
          "goal_completion_claim_allowed",
          "official_score_equivalence",
          "target_score",
          "target_ability",
          "transcript",
          "audio_ref",
          "provider_payload");
    });
  }

  private void createGoal(
      AuthTokens tokens,
      String goalType,
      String targetScore,
      String targetAbility,
      int dailyMinutes,
      int sampleCount) throws Exception {
    mvc.perform(post("/goal-autopilot/goals")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc017_goal")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_type": "%s",
                  "target_score": %s,
                  "target_ability": "%s",
                  "deadline": "%s",
                  "daily_minutes": %d,
                  "intensity_preference": "standard",
                  "diagnostic_samples": %s,
                  "autopilot_control": {
                    "paused": false,
                    "quiet_hours_start": "22:00",
                    "quiet_hours_end": "08:00",
                    "notification_consent": true,
                    "intensity_override": "standard"
                  }
                }
                """.formatted(
                    goalType,
                    targetScore == null ? "null" : targetScore,
                    targetAbility,
                    LocalDate.now().plusDays(75),
                    dailyMinutes,
                    diagnosticSamples(sampleCount))))
        .andExpect(status().isOk());
  }

  private String diagnosticSamples(int count) {
    if (count <= 0) {
      return "[]";
    }
    String sample = """
        {
          "sample_ref": "sample_%d",
          "transcript": "I can answer familiar questions, but I need stronger examples, clearer transitions, and more stable follow-up answers under pressure.",
          "duration_seconds": 48
        }
        """;
    StringBuilder builder = new StringBuilder("[");
    for (int i = 1; i <= count; i += 1) {
      if (i > 1) {
        builder.append(",");
      }
      builder.append(sample.formatted(i));
    }
    return builder.append("]").toString();
  }

  private void generatePlan(AuthTokens tokens, boolean forceReplan, String reasonCode) throws Exception {
    mvc.perform(post("/goal-autopilot/plans/generate")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc017_plan")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "force_replan": %s,
                  "reason_code": "%s"
                }
                """.formatted(forceReplan, reasonCode)))
        .andExpect(status().isOk());
  }

  private void pause(AuthTokens tokens) throws Exception {
    mvc.perform(post("/goal-autopilot/control/pause")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "pause-p02-fuc017")
            .header("X-Request-Id", "req_p02_fuc017_pause")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "pause_reason": "user_requested_break"
                }
                """))
        .andExpect(status().isOk());
  }
}
