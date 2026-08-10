package com.speakeasy.content;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(properties = {
    "speakeasy.content.course-read.enabled=false",
    "speakeasy.ai.provider=deterministic"
})
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CourseCompatibilityRollbackContractTest extends BackendIntegrationTestSupport {
  @Autowired JdbcTemplate jdbc;

  @BeforeEach
  void createCourseFixtures() {
    CourseTestFixture.restore(jdbc);
  }

  @AfterEach
  void clearCourseFixtures() {
    try {
      CourseTestFixture.clear(jdbc);
    } finally {
      CourseTestFixture.restoreScenarioFacts(jdbc);
    }
  }

  @Test
  void routeOffPreservesLegacyScenarioAndAuthoredFacts() throws Exception {
    AuthTokens tokens = loginPhone("+8613910050601");
    long coursesBefore = jdbc.queryForObject("SELECT COUNT(*) FROM content_course", Long.class);
    long versionsBefore = jdbc.queryForObject("SELECT COUNT(*) FROM content_course_version", Long.class);
    long bindingsBefore = jdbc.queryForObject("SELECT COUNT(*) FROM content_course_content_binding", Long.class);
    assertThat(coursesBefore).isPositive();
    assertThat(versionsBefore).isPositive();
    assertThat(bindingsBefore).isPositive();

    mvc.perform(get("/scenarios").header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.scenarios.length()").value(2));
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound());
    mvc.perform(get("/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound());

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "delete-course-rollback-user")
            .header("X-Request-Id", "req_course_rollback_delete"))
        .andExpect(status().isAccepted());

    assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM content_course", Long.class)).isEqualTo(coursesBefore);
    assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM content_course_version", Long.class)).isEqualTo(versionsBefore);
    assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM content_course_content_binding", Long.class)).isEqualTo(bindingsBefore);
  }

  @Test
  void routeOffWithEmptyCourseInventoryKeepsLegacyLearningPathsIndependent() throws Exception {
    CourseTestFixture.clear(jdbc);
    assertEmptyCourseInventory();
    AuthTokens tokens = loginPhone("+8613910050602");

    mvc.perform(get("/scenarios/job_interview/levels/A2")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.level_code").value("A2"));

    mvc.perform(post("/practice/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content(sessionRequest()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.scenario_id").value("job_interview"));

    MvcResult training = mvc.perform(post("/training/sessions")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content(sessionRequest()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.scenario_id").value("job_interview"))
        .andReturn();
    String trainingSessionId = JsonPath.read(
        training.getResponse().getContentAsString(), "$.session.session_id");

    mvc.perform(post("/training/sessions/" + trainingSessionId + "/hints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"schema_version\":1}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.session.hint_level").value("sentence_frame"));

    mvc.perform(get("/learning/mastery")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.mastery_records").isArray());

    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound());
    mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound());
    assertEmptyCourseInventory();
  }

  private void assertEmptyCourseInventory() {
    assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM content_course", Long.class)).isZero();
    assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM content_course_version", Long.class)).isZero();
    assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM content_course_content_binding", Long.class)).isZero();
  }

  private String sessionRequest() {
    return """
        {
          "schema_version": 1,
          "scenario_id": "job_interview",
          "level_code": "A2",
          "resume_existing": false
        }
        """;
  }
}
