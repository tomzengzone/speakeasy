package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.BackendIntegrationTestSupport;
import java.time.LocalDate;
import java.util.Set;
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
class GoalProgressProjectionServiceTest extends BackendIntegrationTestSupport {
  @Autowired GoalAutopilotService goalAutopilotService;

  @Test
  void tcP02Fuc010ProjectionAggregatesBackendFactsAndRedactsUnsafeInputs() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140310");
    createSupportedGoal(tokens);
    generatePlan(tokens, false, "initial_backplan");
    submitCheckpoint(tokens);
    generatePlan(tokens, true, "checkpoint_replan");

    GoalAutopilotService.GoalProgressProjectionView projection =
        goalAutopilotService.progressProjection(UUID.fromString(tokens.userId()));

    assertThat(projection.projectionState()).isEqualTo("ready");
    assertThat(projection.downgradeReason()).isNull();
    assertThat(projection.ruleVersion()).isEqualTo("fuc-progress-projection-v1");
    assertThat(projection.goal().supportStatus()).isEqualTo("supported");
    assertThat(projection.nextAction()).isNotNull();
    assertThat(projection.progress().forecastState()).isEqualTo("ready");
    assertThat(projection.progress().riskReasonCode()).isEqualTo("forecast_supported");
    assertThat(projection.progress().claimGuard().goalCompletionClaimAllowed()).isFalse();
    assertThat(projection.latestCheckpoint().resultStatus()).isEqualTo("recorded");
    assertThat(projection.latestCheckpoint().reasonCode()).isEqualTo("checkpoint_updated_gap");
    assertThat(projection.sourceRefs()).anySatisfy(ref -> assertThat(ref).startsWith("goal_profile:"));
    assertThat(projection.sourceRefs()).anySatisfy(ref -> assertThat(ref).startsWith("goal_revision:"));
    assertThat(projection.sourceRefs()).anySatisfy(ref -> assertThat(ref).startsWith("plan_item:"));
    assertThat(projection.sourceRefs()).anySatisfy(ref -> assertThat(ref).startsWith("forecast:"));
    assertThat(projection.sourceRefs()).anySatisfy(ref -> assertThat(ref).startsWith("checkpoint:"));
    assertThat(projection.surfaceFragments()).extracting(GoalAutopilotService.GoalProgressSurfaceFragmentView::surface)
        .containsExactlyInAnyOrder("home", "queue", "wiki");
    assertThat(projection.surfaceFragments()).allSatisfy(fragment -> {
      assertThat(fragment.displayState()).isEqualTo("ready");
      assertThat(fragment.eligible()).isTrue();
      assertThat(fragment.safeFields()).doesNotContain(
          "diagnostic", "rubric_scores", "target_ability", "target_score", "transcript", "audio_ref", "provider_payload");
    });
    assertThat(projection.surfaceFragments()).flatExtracting(GoalAutopilotService.GoalProgressSurfaceFragmentView::safeFields)
        .contains("next_action", "gap_summary", "risk_reason_code", "checkpoint_summary", "claim_guard");
    assertThat(Set.copyOf(projection.sourceRefs())).hasSameSizeAs(projection.sourceRefs());
    assertThat(projection.toString()).doesNotContain(
        "familiar questions",
        "concrete checkpoint response",
        "confident speaking under IELTS part 2 and part 3 pressure",
        "targetAbility",
        "rubricScores",
        "audioRef");
  }

  @Test
  void tcP02Fuc010ProjectionReturnsSafeUnavailableWhenGoalFactsAreMissing() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140311");

    GoalAutopilotService.GoalProgressProjectionView projection =
        goalAutopilotService.progressProjection(UUID.fromString(tokens.userId()));

    assertThat(projection.projectionState()).isEqualTo("unavailable");
    assertThat(projection.downgradeReason()).isEqualTo("no_active_goal");
    assertThat(projection.goal()).isNull();
    assertThat(projection.progress()).isNull();
    assertThat(projection.sourceRefs()).isEmpty();
    assertThat(projection.surfaceFragments()).hasSize(3);
    assertThat(projection.surfaceFragments()).allSatisfy(fragment -> {
      assertThat(fragment.eligible()).isFalse();
      assertThat(fragment.downgradeReason()).isEqualTo("no_active_goal");
      assertThat(fragment.safeFields()).isEmpty();
    });
  }

  private void createSupportedGoal(AuthTokens tokens) throws Exception {
    mvc.perform(post("/goal-autopilot/goals")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc010_goal")
            .header("Idempotency-Key", "projection-goal-" + tokens.userId())
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_type": "ielts_speaking",
                  "target_score": 8,
                  "target_ability": "confident speaking under IELTS part 2 and part 3 pressure",
                  "deadline": "%s",
                  "daily_minutes": 30,
                  "intensity_preference": "standard",
                  "diagnostic_samples": [
                    {
                      "sample_ref": "sample_1",
                      "transcript": "I can answer familiar questions, but I often stop when I need to add a clear example and connect it back to the topic.",
                      "duration_seconds": 50
                    },
                    {
                      "sample_ref": "sample_2",
                      "transcript": "When the examiner asks a follow-up question, I understand it, but my answer becomes short and I repeat simple words.",
                      "duration_seconds": 45
                    },
                    {
                      "sample_ref": "sample_3",
                      "transcript": "My goal is to speak with stronger structure, more natural transitions, and enough detail to sustain a longer answer.",
                      "duration_seconds": 48
                    }
                  ],
                  "autopilot_control": {
                    "paused": false,
                    "quiet_hours_start": "22:00",
                    "quiet_hours_end": "08:00",
                    "notification_consent": true,
                    "intensity_override": "standard"
                  }
                }
                """.formatted(LocalDate.now().plusDays(75))))
        .andExpect(status().isOk());
  }

  private void generatePlan(AuthTokens tokens, boolean forceReplan, String reasonCode) throws Exception {
    mvc.perform(post("/goal-autopilot/plans/generate")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc010_plan")
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

  private void submitCheckpoint(AuthTokens tokens) throws Exception {
    mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc010_checkpoint")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "weekly_mock",
                  "transcript": "I gave a concrete checkpoint response with a project example, follow-up answer, fluency reflection, and enough evidence to update the gap without claiming final completion.",
                  "score_hint": 6.5
                }
                """))
        .andExpect(status().isOk());
  }
}
