package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.speakeasy.BackendIntegrationTestSupport;
import java.time.Duration;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalProgressProjectionPerformanceTest extends BackendIntegrationTestSupport {
  @Test
  void tcP02Fuc020FollowupCLocalP95BudgetsStayUnderTargets() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140340");
    createSupportedGoal(tokens).andExpect(status().isOk());
    generatePlan(tokens, false, "performance_initial_plan").andExpect(status().isOk());
    warmUp(tokens);

    List<Long> forecastDurations = new ArrayList<>();
    for (int i = 0; i < 24; i++) {
      forecastDurations.add(timed(() -> mvc.perform(get("/goal-autopilot/forecast")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
          .andExpect(status().isOk())));
    }

    List<Long> checkpointTaskDurations = new ArrayList<>();
    for (int i = 0; i < 24; i++) {
      checkpointTaskDurations.add(timed(() -> mvc.perform(get("/goal-autopilot/checkpoints/task")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
          .andExpect(status().isOk())));
    }

    List<Long> checkpointSubmitDurations = new ArrayList<>();
    for (int i = 0; i < 8; i++) {
      int index = i;
      checkpointSubmitDurations.add(timed(() -> submitCheckpoint(tokens, index).andExpect(status().isOk())));
    }

    List<Long> projectionDurations = new ArrayList<>();
    for (int i = 0; i < 24; i++) {
      projectionDurations.add(timed(() -> mvc.perform(get("/goal-autopilot/progress-projection")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
          .andExpect(status().isOk())));
    }

    assertThat(p95(forecastDurations))
        .as("TC-P02-FUC-020 forecast recompute p95")
        .isLessThan(Duration.ofSeconds(1).toNanos());
    assertThat(p95(checkpointTaskDurations))
        .as("TC-P02-FUC-020 checkpoint task lookup p95")
        .isLessThan(Duration.ofMillis(300).toNanos());
    assertThat(p95(checkpointSubmitDurations))
        .as("TC-P02-FUC-020 checkpoint submit accepted/queued p95")
        .isLessThan(Duration.ofSeconds(2).toNanos());
    assertThat(p95(projectionDurations))
        .as("TC-P02-FUC-020 backend projection load p95")
        .isLessThan(Duration.ofMillis(500).toNanos());
  }

  private void warmUp(AuthTokens tokens) throws Exception {
    mvc.perform(get("/goal-autopilot/forecast")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk());
    mvc.perform(get("/goal-autopilot/checkpoints/task")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk());
    mvc.perform(get("/goal-autopilot/progress-projection")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk());
  }

  private org.springframework.test.web.servlet.ResultActions createSupportedGoal(AuthTokens tokens) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_p02_fuc020_goal")
        .header("Idempotency-Key", "projection-perf-goal-" + tokens.userId())
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "goal_type": "ielts_speaking",
              "target_score": 8,
              "target_ability": "confident speaking with checkpoint-backed progress projection",
              "deadline": "%s",
              "daily_minutes": 30,
              "intensity_preference": "standard",
              "diagnostic_samples": [
                {
                  "sample_ref": "perf_sample_1",
                  "transcript": "I can answer familiar speaking questions, but my examples are sometimes short and I need stronger follow-up responses.",
                  "duration_seconds": 48
                },
                {
                  "sample_ref": "perf_sample_2",
                  "transcript": "I want to improve fluency, add clearer transitions, and handle pressure without repeating the same simple words.",
                  "duration_seconds": 44
                },
                {
                  "sample_ref": "perf_sample_3",
                  "transcript": "A weekly checkpoint should show whether my gap is shrinking without claiming an official score.",
                  "duration_seconds": 38
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
            """.formatted(LocalDate.now().plusDays(75))));
  }

  private org.springframework.test.web.servlet.ResultActions generatePlan(
      AuthTokens tokens, boolean forceReplan, String reasonCode) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_p02_fuc020_plan_" + reasonCode)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": %s,
              "reason_code": "%s"
            }
            """.formatted(forceReplan, reasonCode)));
  }

  private org.springframework.test.web.servlet.ResultActions submitCheckpoint(AuthTokens tokens, int index) throws Exception {
    return mvc.perform(post("/goal-autopilot/checkpoints")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_p02_fuc020_checkpoint_" + index)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "checkpoint_type": "weekly_mock",
              "transcript": "This checkpoint response gives a clear example, explains a tradeoff, answers a follow-up question, and records enough product-internal evidence for forecast and projection performance checks.",
              "score_hint": 6.5
            }
            """));
  }

  private long timed(ThrowingAction action) throws Exception {
    long start = System.nanoTime();
    action.run();
    return System.nanoTime() - start;
  }

  private long p95(List<Long> values) {
    List<Long> sorted = new ArrayList<>(values);
    Collections.sort(sorted);
    return sorted.get((int) Math.ceil(sorted.size() * 0.95) - 1);
  }

  @FunctionalInterface
  private interface ThrowingAction {
    void run() throws Exception;
  }
}
