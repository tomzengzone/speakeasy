package com.speakeasy.content;

import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CourseCatalogApiContractTest extends AbstractCourseContractTest {
  @Test
  void scenarioAll() throws Exception {
    AuthTokens tokens = loginPhone("+8613910050001");
    CourseTestFixture.clearScenario(jdbc, "onboarding_introduction");

    mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_scenario_all"))
        .andExpect(status().isOk())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "private, no-cache"))
        .andExpect(header().string(HttpHeaders.VARY, HttpHeaders.AUTHORIZATION))
        .andExpect(header().string("X-Request-Id", "req_course_scenario_all"))
        .andExpect(header().string(HttpHeaders.ETAG, not(blankOrNullString())))
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.request_id").value("req_course_scenario_all"))
        .andExpect(jsonPath("$.scenarios.length()").value(2))
        .andExpect(jsonPath("$.scenarios[0].scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.scenarios[1].scenario_id").value("onboarding_introduction"));

    mvc.perform(get("/scenarios")
            .queryParam("query", "入职")
            .queryParam("category", "official")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_scenario_filter"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.scenarios.length()").value(1))
        .andExpect(jsonPath("$.scenarios[0].scenario_id").value("onboarding_introduction"));

    mvc.perform(get("/scenarios")
            .queryParam("query", "no-match")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_scenario_empty"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.scenarios.length()").value(0));

    assertScenarioAllExcludesUnpublishedAndInvisibleThemesAndFailsOnVisibilityDependency();
  }

  private void assertScenarioAllExcludesUnpublishedAndInvisibleThemesAndFailsOnVisibilityDependency()
      throws Exception {
    AuthTokens publishedReader = loginPhone("+8613910050003");
    try {
      jdbc.update("""
          UPDATE scenario_versions SET content_status = 'draft', published_at = NULL
          WHERE scenario_version_id = '10000000-0000-0000-0000-000000000002'
          """);
      mvc.perform(get("/scenarios")
              .header(HttpHeaders.AUTHORIZATION, bearer(publishedReader.accessToken()))
              .header("X-Request-Id", "req_course_scenario_unpublished"))
          .andExpect(status().isOk())
          .andExpect(jsonPath("$.scenarios.length()").value(1))
          .andExpect(jsonPath("$.scenarios[0].scenario_id").value("job_interview"));
    } finally {
      CourseTestFixture.restoreScenarioFacts(jdbc);
    }

    AuthTokens invisibleReader = loginPhone("+8613910050004");
    saveContentEntitlement(invisibleReader, false, false);
    mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(invisibleReader.accessToken()))
            .header("X-Request-Id", "req_course_scenario_invisible"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.scenarios.length()").value(0));

    AuthTokens dependencyFailure = loginPhone("+8613910050005");
    saveMalformedEntitlement(dependencyFailure);
    mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(dependencyFailure.accessToken()))
            .header("X-Request-Id", "req_course_scenario_dependency"))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("CONTENT_READ_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));
  }

  @Test
  void courseList() throws Exception {
    AuthTokens tokens = loginPhone("+8613910050002");

    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_list"))
        .andExpect(status().isOk())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "private, no-cache"))
        .andExpect(header().string(HttpHeaders.VARY, HttpHeaders.AUTHORIZATION))
        .andExpect(header().string("X-Request-Id", "req_course_list"))
        .andExpect(header().string(HttpHeaders.ETAG, not(blankOrNullString())))
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.request_id").value("req_course_list"))
        .andExpect(jsonPath("$.scenario_id").value("job_interview"))
        .andExpect(jsonPath("$.courses.length()").value(2))
        .andExpect(jsonPath("$.courses[0].course_id").value("40000000-0000-4000-8000-000000000001"))
        .andExpect(jsonPath("$.courses[0].course_version_id").value("41000000-0000-4000-8000-000000000001"))
        .andExpect(jsonPath("$.courses[0].title_en").value("Job Interview Basics"))
        .andExpect(jsonPath("$.courses[0].summary_zh").value("用简单句完成自我介绍并回答常见面试问题。"))
        .andExpect(jsonPath("$.courses[0].level_code").value("A2"))
        .andExpect(jsonPath("$.courses[1].level_code").value("B1"));

    CourseTestFixture.clearScenario(jdbc, "onboarding_introduction");
    mvc.perform(get("/scenarios/onboarding_introduction/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_list_empty"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.scenario_id").value("onboarding_introduction"))
        .andExpect(jsonPath("$.courses.length()").value(0));
  }
}
