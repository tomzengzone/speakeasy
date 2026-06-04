package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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
class GoalAutopilotPerformanceTest extends BackendIntegrationTestSupport {
  @Test
  void tcP02Perf001GoalAutopilotLocalBudgetsStayUnderP95Targets() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140206");

    List<Long> goalIntakeDurations = new ArrayList<>();
    goalIntakeDurations.add(timed(() -> createGoal(tokens, 1).andExpect(status().isOk())));
    timed(() -> generatePlan(tokens).andExpect(status().isOk()));

    List<Long> dailyPlanDurations = new ArrayList<>();
    List<Long> nextActionDurations = new ArrayList<>();
    List<Long> forecastDurations = new ArrayList<>();
    for (int i = 0; i < 24; i++) {
      dailyPlanDurations.add(timed(() -> mvc.perform(get("/goal-autopilot/daily-plan")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
          .andExpect(status().isOk())));
      nextActionDurations.add(timed(() -> mvc.perform(get("/goal-autopilot/actions/next")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
          .andExpect(status().isOk())));
      forecastDurations.add(timed(() -> mvc.perform(get("/goal-autopilot/forecast")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
          .andExpect(status().isOk())));
    }

    assertThat(p95(goalIntakeDurations)).isLessThan(Duration.ofMillis(500).toNanos());
    assertThat(p95(dailyPlanDurations)).isLessThan(Duration.ofMillis(300).toNanos());
    assertThat(p95(nextActionDurations)).isLessThan(Duration.ofMillis(500).toNanos());
    assertThat(p95(forecastDurations)).isLessThan(Duration.ofSeconds(1).toNanos());
  }

  private org.springframework.test.web.servlet.ResultActions createGoal(AuthTokens tokens, int revision) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "goal_type": "business_meeting",
              "target_ability": "lead a concise business update and handle follow-up questions",
              "deadline": "%s",
              "daily_minutes": 25,
              "intensity_preference": "standard",
              "diagnostic_samples": [
                {
                  "sample_ref": "perf_sample_%s",
                  "transcript": "I can give a short update, but I need more practice expanding reasons, adding evidence, and responding naturally when colleagues ask follow-up questions.",
                  "duration_seconds": 45
                },
                {
                  "sample_ref": "perf_sample_%s_b",
                  "transcript": "My business English goal is to speak with clearer structure, better transitions, and fewer pauses during weekly meetings.",
                  "duration_seconds": 40
                },
                {
                  "sample_ref": "perf_sample_%s_c",
                  "transcript": "I also want to summarize risks and next steps without sounding too memorized or too vague.",
                  "duration_seconds": 35
                }
              ]
            }
            """.formatted(LocalDate.now().plusDays(60), revision, revision, revision)));
  }

  private org.springframework.test.web.servlet.ResultActions generatePlan(AuthTokens tokens) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": false,
              "reason_code": "performance_budget_fixture"
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
