package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;

import com.speakeasy.content.ScenarioLevelRepository;
import com.speakeasy.content.ScenarioRepository;
import com.speakeasy.content.ScenarioVersionRepository;
import com.speakeasy.content.TargetExpressionRepository;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ScenarioSeedVersioningTest extends BackendIntegrationTestSupport {
  @Autowired ScenarioRepository scenarios;
  @Autowired ScenarioVersionRepository versions;
  @Autowired ScenarioLevelRepository levels;
  @Autowired TargetExpressionRepository expressions;

  @Test
  void seedContainsOnlyTwoProductBaseOfficialScenarios() {
    assertThat(scenarios.findAll())
        .extracting(com.speakeasy.content.Scenario::getScenarioId)
        .containsExactlyInAnyOrder("job_interview", "onboarding_introduction");
    assertThat(scenarios.findById("daily_service")).isEmpty();
  }

  @Test
  void seedHasPublishedVersionLevelsAndReadableExpressions() {
    for (String scenarioId : Set.of("job_interview", "onboarding_introduction")) {
      var version = versions.findFirstByScenarioIdAndContentStatusOrderByPublishedAtDesc(scenarioId, "published");
      assertThat(version).isPresent();
      assertThat(version.orElseThrow().getVersion()).isEqualTo("2026.05-mvp-seed");
      assertThat(levels.findByScenarioIdOrderByLevelCodeAsc(scenarioId))
          .extracting(com.speakeasy.content.ScenarioLevel::getLevelCode)
          .containsExactly("L1", "L2", "L3");
      assertThat(expressions.findByScenarioVersionIdAndLevelCodeOrderByTextAsc(
              version.orElseThrow().getScenarioVersionId(), "L1"))
          .hasSize(2);
    }
  }
}
