package com.speakeasy.content;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.hasItem;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CourseCatalogSchemaContractTest extends AbstractCourseContractTest {
  @Test
  void schemaAndErrors() throws Exception {
    assertSchemaAndRequestIdentityOnSuccessfulReads();
    for (String levelCode : new String[] {"A1", "A2", "B1", "B2", "C1", "C2"}) {
      assertCourseCefrValueRoundTripsAcrossThreeReads(levelCode);
    }
    for (String invalidLevel : new String[] {"L1", "L2", "L3", "beginner", "advanced", "A0", "C3", "unknown"}) {
      assertCoursePersistenceRejectsNonCefrValue(invalidLevel);
    }
    assertThemeAndCourseCollectionsUseEmptyWhileDetailEmptyIsNotApplicable();
    assertPrivacySafe404IsNotApplicableToThemeCollectionButAppliesToScopedListAndDetail();
    assertUnauthenticatedIs401ForAllThreeReads();
    assertDependencyOrIntegrityFailureIs503ForAllThreeReads();
  }

  private void assertSchemaAndRequestIdentityOnSuccessfulReads() throws Exception {
    AuthTokens tokens = loginPhone("+8613910050301");

    mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_schema_scenarios"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.request_id").value("req_schema_scenarios"));
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_schema_courses"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.request_id").value("req_schema_courses"));
    mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_schema_detail"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.request_id").value("req_schema_detail"));

    MvcResult generated = mvc.perform(get("/scenarios/job_interview/courses"))
        .andExpect(status().isUnauthorized())
        .andReturn();
    String generatedHeader = generated.getResponse().getHeader("X-Request-Id");
    assertThat(generatedHeader).matches("[0-9a-f]{8}-[0-9a-f-]{27}");
    assertThat(JsonPath.<String>read(generated.getResponse().getContentAsString(), "$.error.request_id"))
        .isEqualTo(generatedHeader);

    MvcResult sanitized = mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "unsafe request id"))
        .andExpect(status().isOk())
        .andReturn();
    String sanitizedHeader = sanitized.getResponse().getHeader("X-Request-Id");
    assertThat(sanitizedHeader).matches("[0-9a-f]{8}-[0-9a-f-]{27}");
    assertThat(JsonPath.<String>read(sanitized.getResponse().getContentAsString(), "$.request_id"))
        .isEqualTo(sanitizedHeader);
  }

  private void assertCourseCefrValueRoundTripsAcrossThreeReads(String levelCode) throws Exception {
    AuthTokens tokens = loginPhone("+861391006" + Math.abs(levelCode.hashCode()));
    grantAdvanced(tokens);
    int fixtureIndex = switch (levelCode) {
      case "B1" -> 2;
      case "B2" -> 3;
      default -> 1;
    };
    String courseId = "40000000-0000-4000-8000-%012d".formatted(fixtureIndex);
    String versionId = "41000000-0000-4000-8000-%012d".formatted(fixtureIndex);
    String scenarioLevelId = "20000000-0000-0000-0000-%012d".formatted(fixtureIndex);
    jdbc.update("""
        UPDATE content_course_version SET cefr_level = ?
        WHERE course_version_id = ?
        """, levelCode, versionId);
    jdbc.update("""
        UPDATE scenario_levels SET level_code = ?, target_level = ?
        WHERE scenario_level_id = ?
        """, levelCode, levelCode, scenarioLevelId);

    mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_cefr_theme_" + levelCode))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.scenarios[0].levels", hasItem(levelCode)));
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_cefr_list_" + levelCode))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.courses[*].level_code", hasItem(levelCode)));
    mvc.perform(get("/courses/" + courseId + "/versions/" + versionId)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_cefr_detail_" + levelCode))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.course.level_code").value(levelCode));
  }

  private void assertCoursePersistenceRejectsNonCefrValue(String invalidLevel) {
    assertThatThrownBy(() -> jdbc.update("""
        UPDATE content_course_version SET cefr_level = ?
        WHERE course_version_id = '41000000-0000-4000-8000-000000000001'
        """, invalidLevel)).isInstanceOf(Exception.class);
    assertThatThrownBy(() -> jdbc.update("""
        UPDATE scenario_levels SET level_code = ?, target_level = ?
        WHERE scenario_level_id = '20000000-0000-0000-0000-000000000001'
        """, invalidLevel, invalidLevel)).isInstanceOf(Exception.class);
  }

  private void assertThemeAndCourseCollectionsUseEmptyWhileDetailEmptyIsNotApplicable() throws Exception {
    AuthTokens tokens = loginPhone("+8613910050302");
    mvc.perform(get("/scenarios")
            .queryParam("query", "no-such-theme")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.scenarios.length()").value(0));

    CourseTestFixture.clearScenario(jdbc, "onboarding_introduction");
    mvc.perform(get("/scenarios/onboarding_introduction/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.courses.length()").value(0));

    mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000099/versions/41000000-0000-4000-8000-000000000099")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
  }

  private void assertPrivacySafe404IsNotApplicableToThemeCollectionButAppliesToScopedListAndDetail()
      throws Exception {
    AuthTokens tokens = loginPhone("+8613910050303");
    mvc.perform(get("/scenarios")
            .queryParam("query", "no-such-theme")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.scenarios.length()").value(0));
    mvc.perform(get("/scenarios/missing/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
    mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000099/versions/41000000-0000-4000-8000-000000000099")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
  }

  private void assertUnauthenticatedIs401ForAllThreeReads() throws Exception {
    mvc.perform(get("/scenarios").header("X-Request-Id", "req_schema_unauth_theme"))
        .andExpect(status().isUnauthorized())
        .andExpect(header().string("X-Request-Id", "req_schema_unauth_theme"))
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
    mvc.perform(get("/scenarios/job_interview/courses")
            .header("X-Request-Id", "req_schema_unauth_list"))
        .andExpect(status().isUnauthorized())
        .andExpect(header().string("X-Request-Id", "req_schema_unauth_list"))
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
    mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header("X-Request-Id", "req_schema_unauth_detail"))
        .andExpect(status().isUnauthorized())
        .andExpect(header().string("X-Request-Id", "req_schema_unauth_detail"))
        .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"));
  }

  private void assertDependencyOrIntegrityFailureIs503ForAllThreeReads() throws Exception {
    AuthTokens malformed = loginPhone("+8613910050304");
    saveMalformedEntitlement(malformed);
    mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(malformed.accessToken()))
            .header("X-Request-Id", "req_schema_theme_unavailable"))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("CONTENT_READ_UNAVAILABLE"));

    AuthTokens tokens = loginPhone("+8613910050305");
    jdbc.update("""
        DELETE FROM content_course_content_binding
        WHERE course_content_binding_id = '42000000-0000-4000-8000-000000000001'
        """);
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_schema_unavailable"))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("CONTENT_READ_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.request_id").value("req_schema_unavailable"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));
    mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_schema_detail_unavailable"))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("CONTENT_READ_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));
  }
}
