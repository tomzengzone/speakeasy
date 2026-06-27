package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.learning.LearningEvidence;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TrainingEvidenceRuleTraceTest extends BackendIntegrationTestSupport {
  @Test
  void tcP01023AcceptedTrainingEvidenceWritesRuleTraceAndLearningMemory() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138530");
    String sessionId = startTraining(tokens);

    MvcResult turn = mvc.perform(post("/training/sessions/%s/turns".formatted(sessionId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "evidence-rule-trace")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "transcript": "I worked on a project that improved our workflow."
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.learning_evidence_candidates[0].status").value("accepted"))
        .andExpect(jsonPath("$.learning_evidence_candidates[0].rule_name").value("training_signal_v1"))
        .andExpect(jsonPath("$.learning_evidence_candidates[0].reason_code").value("target_and_task_met"))
        .andExpect(jsonPath("$.learning_evidence_candidates[0].schema_version").value(1))
        .andReturn();

    String evidenceId = JsonPath.read(
        turn.getResponse().getContentAsString(), "$.learning_evidence_candidates[0].learning_evidence_id");
    LearningEvidence evidence = learningEvidences.findById(UUID.fromString(evidenceId)).orElseThrow();

    assertThat(evidence.getAcceptedStatus()).isEqualTo("accepted");
    assertThat(evidence.getRuleName()).isEqualTo("training_signal_v1");
    assertThat(evidence.getReasonCode()).isEqualTo("target_and_task_met");
    assertThat(evidence.getSchemaVersion()).isEqualTo(1);
    assertThat(masteryRecords.findByUserId(UUID.fromString(tokens.userId()))).isNotEmpty();
    assertThat(reviewItems.findByUserIdAndStatusAndDueAtLessThanEqualOrderByDueAtAsc(
            UUID.fromString(tokens.userId()), "due", java.time.Instant.now().plusSeconds(5)))
        .isNotEmpty();
  }

  private String startTraining(AuthTokens tokens) throws Exception {
    MvcResult result = mvc.perform(post("/training/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "job_interview",
                  "level_code": "L1",
                  "resume_existing": true
                }
                """))
        .andExpect(status().isOk())
        .andReturn();
    return JsonPath.read(result.getResponse().getContentAsString(), "$.session.session_id");
  }
}
