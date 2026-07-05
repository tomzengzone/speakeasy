package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.everyItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
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

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MemoryCurveReplayTest extends BackendIntegrationTestSupport {
  @Autowired PlannerReplayAuditRepository replayAudits;

  @Test
  void tcP02Fub012ItemPolicyDecisionsAreReplayDeterministicAndControlBlocked() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140240");
    UUID userId = UUID.fromString(tokens.userId());
    createSupportedGoal(tokens).andExpect(status().isOk());
    generatePlan(tokens).andExpect(status().isOk());

    String requestJson = itemPolicyRequestJson(21);
    MvcResult first = mvc.perform(post("/goal-autopilot/item-policy/decisions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fub012_memory_first")
            .contentType(MediaType.APPLICATION_JSON)
            .content(requestJson))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.decisions", hasSize(6)))
        .andExpect(jsonPath("$.decisions[0].item_ref").value("expr-high-risk"))
        .andExpect(jsonPath("$.decisions[0].due_decision").value("review_due"))
        .andExpect(jsonPath("$.decisions[0].reason_code").value("high_forgetting_risk"))
        .andExpect(jsonPath("$.decisions[1].due_decision").value("review_due"))
        .andExpect(jsonPath("$.decisions[1].reason_code").value("due_forgetting_risk"))
        .andExpect(jsonPath("$.decisions[2].due_decision").value("interleave_alternative"))
        .andExpect(jsonPath("$.decisions[2].reason_code").value("interleaving_cap_viable_alternative"))
        .andExpect(jsonPath("$.decisions[3].due_decision").value("review_due"))
        .andExpect(jsonPath("$.decisions[4].due_decision").value("defer_budget"))
        .andExpect(jsonPath("$.decisions[4].reason_code").value("daily_memory_budget_exhausted"))
        .andExpect(jsonPath("$.decisions[5].due_decision").value("skip_overlearning_cap"))
        .andExpect(jsonPath("$.decisions[5].reason_code").value("overlearning_cap_reached"))
        .andExpect(jsonPath("$.decisions[*].rule_version", everyItem(org.hamcrest.Matchers.is(MemoryCurvePolicy.RULE_VERSION))))
        .andExpect(jsonPath("$.replay_audit.decision_family").value("item_policy"))
        .andExpect(jsonPath("$.replay_audit.expected_decision").value("review_due"))
        .andExpect(jsonPath("$.replay_audit.reason_code").value("high_forgetting_risk"))
        .andExpect(jsonPath("$.replay_audit.rule_version").value(MemoryCurvePolicy.RULE_VERSION))
        .andExpect(jsonPath("$.replay_audit.input_snapshot_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.replay_audit.output_snapshot_hash").value(startsWith("sha256:")))
        .andExpect(jsonPath("$.replay_audit.replay_hash").value(startsWith("sha256:")))
        .andReturn();

    MvcResult replay = mvc.perform(post("/goal-autopilot/item-policy/decisions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fub012_memory_replay")
            .contentType(MediaType.APPLICATION_JSON)
            .content(requestJson))
        .andExpect(status().isOk())
        .andReturn();

    assertThat(JsonPath.read(first.getResponse().getContentAsString(), "$.decisions").toString())
        .isEqualTo(JsonPath.read(replay.getResponse().getContentAsString(), "$.decisions").toString());
    assertThat((String) JsonPath.read(first.getResponse().getContentAsString(), "$.replay_audit.input_snapshot_hash"))
        .isEqualTo(JsonPath.read(replay.getResponse().getContentAsString(), "$.replay_audit.input_snapshot_hash"));
    assertThat((String) JsonPath.read(first.getResponse().getContentAsString(), "$.replay_audit.output_snapshot_hash"))
        .isEqualTo(JsonPath.read(replay.getResponse().getContentAsString(), "$.replay_audit.output_snapshot_hash"));
    assertThat((String) JsonPath.read(first.getResponse().getContentAsString(), "$.replay_audit.replay_hash"))
        .isEqualTo(JsonPath.read(replay.getResponse().getContentAsString(), "$.replay_audit.replay_hash"));

    List<PlannerReplayAudit> audits =
        replayAudits.findByUserIdAndDecisionFamilyOrderByCreatedAtDesc(userId, "item_policy");
    assertThat(audits).hasSize(2);
    assertThat(audits).allSatisfy(audit -> {
      assertThat(audit.getExpectedDecision()).isEqualTo("review_due");
      assertThat(audit.getReasonCode()).isEqualTo("high_forgetting_risk");
      assertThat(audit.getRuleVersion()).isEqualTo(MemoryCurvePolicy.RULE_VERSION);
      assertThat(audit.getReplayHash()).startsWith("sha256:");
    });
    assertThat(audits.get(0).getReplayHash()).isEqualTo(audits.get(1).getReplayHash());

    mvc.perform(post("/goal-autopilot/control/pause")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "memory-fub012-pause")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "pause_reason": "user_requested_break"
                }
                """))
        .andExpect(status().isOk());

    mvc.perform(post("/goal-autopilot/item-policy/decisions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_fub012_memory_paused")
            .contentType(MediaType.APPLICATION_JSON)
            .content(requestJson))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.decisions", hasSize(6)))
        .andExpect(jsonPath("$.decisions[*].due_decision", everyItem(org.hamcrest.Matchers.is("blocked_by_control"))))
        .andExpect(jsonPath("$.decisions[*].reason_code", everyItem(org.hamcrest.Matchers.is("control_paused"))))
        .andExpect(jsonPath("$.replay_audit.expected_decision").value("blocked_by_control"))
        .andExpect(jsonPath("$.replay_audit.reason_code").value("control_paused"));
  }

  private org.springframework.test.web.servlet.ResultActions createSupportedGoal(AuthTokens tokens) throws Exception {
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_fub012_goal")
        .header("Idempotency-Key", "memory-curve-goal-" + tokens.userId())
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
                  "transcript": "I can answer familiar questions, but I need more detail and cleaner examples.",
                  "duration_seconds": 45
                },
                {
                  "sample_ref": "sample_2",
                  "transcript": "Follow-up questions are understandable, but my answers become short.",
                  "duration_seconds": 45
                },
                {
                  "sample_ref": "sample_3",
                  "transcript": "I want stronger structure, transitions, and enough extension for longer answers.",
                  "duration_seconds": 45
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

  private org.springframework.test.web.servlet.ResultActions generatePlan(AuthTokens tokens) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", "req_fub012_plan")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": false,
              "reason_code": "initial_backplan"
            }
            """));
  }

  private String itemPolicyRequestJson(int dailyBudgetMinutes) {
    return """
        {
          "schema_version": 1,
          "policy_version": "memory-curve-v1",
          "daily_time_budget_minutes": %d,
          "items": [
            {
              "item_type": "expression",
              "item_ref": "expr-high-risk",
              "interleaving_group": "fluency",
              "current_mastery_level": "L1",
              "evidence_refs": ["evidence-high"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 3,
              "overlearning_count": 2,
              "forgetting_risk": 0.72,
              "retrieval_success": false,
              "recent_failures": 2,
              "pressure_level": "high",
              "estimated_minutes": 5
            },
            {
              "item_type": "expression",
              "item_ref": "expr-fluency-1",
              "interleaving_group": "fluency",
              "current_mastery_level": "L2",
              "evidence_refs": ["evidence-fluency-1"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 2,
              "overlearning_count": 0,
              "forgetting_risk": 0.50,
              "retrieval_success": true,
              "recent_failures": 0,
              "pressure_level": "standard",
              "estimated_minutes": 5
            },
            {
              "item_type": "expression",
              "item_ref": "expr-fluency-2",
              "interleaving_group": "fluency",
              "current_mastery_level": "L2",
              "evidence_refs": ["evidence-fluency-2"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 2,
              "overlearning_count": 0,
              "forgetting_risk": 0.50,
              "retrieval_success": true,
              "recent_failures": 0,
              "pressure_level": "standard",
              "estimated_minutes": 5
            },
            {
              "item_type": "diagnostic_weakness",
              "item_ref": "weakness-grammar",
              "interleaving_group": "grammar",
              "current_mastery_level": "L2",
              "evidence_refs": ["evidence-grammar"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 2,
              "overlearning_count": 0,
              "forgetting_risk": 0.50,
              "retrieval_success": true,
              "recent_failures": 0,
              "pressure_level": "standard",
              "estimated_minutes": 10
            },
            {
              "item_type": "scenario",
              "item_ref": "scenario-budget",
              "interleaving_group": "scenario",
              "current_mastery_level": "L2",
              "evidence_refs": ["evidence-scenario"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 2,
              "overlearning_count": 0,
              "forgetting_risk": 0.50,
              "retrieval_success": true,
              "recent_failures": 0,
              "pressure_level": "standard",
              "estimated_minutes": 5
            },
            {
              "item_type": "expression",
              "item_ref": "expr-overlearned",
              "interleaving_group": "vocab",
              "current_mastery_level": "L2",
              "evidence_refs": ["evidence-overlearned"],
              "last_reviewed_at": "2026-06-03T09:00:00Z",
              "exposure_count": 4,
              "overlearning_count": 2,
              "forgetting_risk": 0.50,
              "retrieval_success": true,
              "recent_failures": 0,
              "pressure_level": "standard",
              "estimated_minutes": 5
            }
          ]
        }
        """.formatted(dailyBudgetMinutes);
  }
}
