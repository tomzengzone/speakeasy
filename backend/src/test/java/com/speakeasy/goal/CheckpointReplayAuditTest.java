package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CheckpointReplayAuditTest extends BackendIntegrationTestSupport {
  @Autowired JdbcTemplate jdbcTemplate;

  @Test
  void tcP02Fuc008CheckpointPlanSignalHasReplayAuditEvidence() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140294");
    createSupportedGoal(tokens);
    generatePlan(tokens, false, "initial_backplan");

    MvcResult checkpointResult = mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc008_checkpoint")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "weekly_mock",
                  "transcript": "I spoke for two minutes, gave a concrete project example, answered one follow-up question, and identified the same fluency issue without claiming final completion.",
                  "score_hint": 6.5
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.plan_update_signal.rule_version").value("fuc-checkpoint-plan-v1"))
        .andExpect(jsonPath("$.plan_update_signal.input_snapshot_hash", startsWith("sha256:")))
        .andExpect(jsonPath("$.plan_update_signal.replay_audit_id", not(blankOrNullString())))
        .andReturn();

    String body = checkpointResult.getResponse().getContentAsString();
    String checkpointId = JsonPath.read(body, "$.checkpoint.checkpoint_id");
    String inputSnapshotHash = JsonPath.read(body, "$.plan_update_signal.input_snapshot_hash");
    String replayAuditId = JsonPath.read(body, "$.plan_update_signal.replay_audit_id");
    assertThat(body).doesNotContain("concrete project example");

    MvcResult auditResult = mvc.perform(get("/goal-autopilot/replay-audits")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andReturn();
    String auditBody = auditResult.getResponse().getContentAsString();
    List<String> replayAuditIds = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].replay_audit_id");
    List<String> sourceRefs = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].source_entity_ref");
    List<String> inputHashes = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].input_snapshot_hash");
    List<String> outputHashes = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].output_snapshot_hash");
    List<String> expectedDecisions = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].expected_decision");
    List<String> reasonCodes = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].reason_code");
    List<String> ruleVersions = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].rule_version");
    List<String> replayHashes = JsonPath.read(
        auditBody, "$.audits[?(@.decision_family == 'checkpoint_plan_update')].replay_hash");

    assertThat(replayAuditIds).containsExactly(replayAuditId);
    assertThat(sourceRefs).containsExactly("checkpoint:" + checkpointId);
    assertThat(inputHashes).containsExactly(inputSnapshotHash);
    assertThat(outputHashes).hasSize(1);
    assertThat(outputHashes.get(0)).startsWith("sha256:");
    assertThat(expectedDecisions).containsExactly("checkpoint_replan");
    assertThat(reasonCodes).containsExactly("checkpoint_updated_gap");
    assertThat(ruleVersions).containsExactly("fuc-checkpoint-plan-v1");
    assertThat(replayHashes).hasSize(1);
    assertThat(replayHashes.get(0)).startsWith("sha256:");

    assertThat(jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_planner_replay_audits WHERE decision_family = 'checkpoint_plan_update'",
        Integer.class)).isEqualTo(1);
  }

  private void createSupportedGoal(AuthTokens tokens) throws Exception {
    mvc.perform(post("/goal-autopilot/goals")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_p02_fuc008_goal")
            .header("Idempotency-Key", "checkpoint-replay-goal-" + tokens.userId())
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
            .header("X-Request-Id", "req_p02_fuc008_plan")
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
}
