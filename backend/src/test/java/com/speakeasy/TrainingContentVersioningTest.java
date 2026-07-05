package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.content.ScenarioVersionRepository;
import com.speakeasy.training.TrainingPlannerService;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class TrainingContentVersioningTest extends BackendIntegrationTestSupport {
  @Autowired ScenarioVersionRepository scenarioVersions;

  @Test
  void tcP01025TrainingContentMappingIsVersionedReviewedAndScenarioOwned() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138550");
    MvcResult result = mvc.perform(post("/training/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "scenario_id": "onboarding_introduction",
                  "level_code": "L2",
                  "resume_existing": false
                }
                """))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.action_chain[0].step_key").value("opening"))
        .andExpect(jsonPath("$.session.action_chain[5].step_key").value("closing"))
        .andExpect(jsonPath("$.session.action_chain[0].review_status").value("reviewed"))
        .andReturn();

    String scenarioVersionId = JsonPath.read(result.getResponse().getContentAsString(), "$.session.scenario_version_id");
    var published = scenarioVersions
        .findFirstByScenarioIdAndContentStatusOrderByPublishedAtDesc("onboarding_introduction", "published")
        .orElseThrow();

    assertThat(UUID.fromString(scenarioVersionId)).isEqualTo(published.getScenarioVersionId());
    assertThat(trainingSessions.findAll().get(0).getActionChainVersion())
        .isEqualTo(TrainingPlannerService.ACTION_CHAIN_VERSION);
    assertThat(trainingContentMappings.findByScenarioVersionIdAndLevelCodeAndReviewStatusOrderByOrderIndexAsc(
            published.getScenarioVersionId(), "L2", "reviewed"))
        .hasSize(6)
        .allSatisfy(mapping -> {
          assertThat(mapping.getScenarioId()).isEqualTo("onboarding_introduction");
          assertThat(mapping.getMappingVersion()).isEqualTo("training-map:" + published.getVersion());
          assertThat(mapping.getTargetExpressionId()).isNotNull();
        });
  }
}
