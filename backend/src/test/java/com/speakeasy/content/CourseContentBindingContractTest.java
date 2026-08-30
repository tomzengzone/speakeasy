package com.speakeasy.content;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.boot.test.mock.mockito.SpyBean;
import java.util.List;
import static org.mockito.Mockito.doReturn;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@ExtendWith(OutputCaptureExtension.class)
class CourseContentBindingContractTest extends AbstractCourseContractTest {
  private static final String DETAIL =
      "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001";

  @SpyBean CourseContentBindingRepository bindingRepository;

  @Test
  void readProjectionIntegrity(CapturedOutput output) throws Exception {
    AuthTokens tokens = loginPhone("+8613910050201");

    mvc.perform(get(DETAIL)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_binding_valid"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.course.content_binding_ref.scenario_version_id")
            .value("10000000-0000-0000-0000-000000000001"))
        .andExpect(jsonPath("$.course.content_binding_ref.scenario_level_id")
            .value("20000000-0000-0000-0000-000000000001"));

    jdbc.update("""
        DELETE FROM content_course_content_binding
        WHERE course_content_binding_id = '42000000-0000-4000-8000-000000000001'
        """);
    assertUnavailable(tokens, "req_binding_missing");
    restoreCourseFixtures();

    jdbc.update("""
        UPDATE content_course_content_binding
        SET scenario_level_id = '20000000-0000-0000-0000-000000000004'
        WHERE course_content_binding_id = '42000000-0000-4000-8000-000000000001'
        """);
    assertUnavailable(tokens, "req_binding_scenario_mismatch");
    restoreCourseFixtures();

    jdbc.update("""
        UPDATE content_course_content_binding
        SET scenario_level_id = '20000000-0000-0000-0000-000000000002'
        WHERE course_content_binding_id = '42000000-0000-4000-8000-000000000001'
        """);
    assertUnavailable(tokens, "req_binding_cefr_mismatch");
    restoreCourseFixtures();

    jdbc.update("""
        UPDATE scenario_versions SET content_status = 'draft'
        WHERE scenario_version_id = '10000000-0000-0000-0000-000000000001'
        """);
    assertUnavailable(tokens, "req_binding_content_unavailable");

    restoreCourseFixtures();
    CourseContentBinding valid = bindingRepository
        .findByCourseVersionId(java.util.UUID.fromString(CourseTestFixture.JOB_A2_VERSION_ID))
        .get(0);
    doReturn(List.of(valid, valid))
        .when(bindingRepository)
        .findByCourseVersionId(java.util.UUID.fromString(CourseTestFixture.JOB_A2_VERSION_ID));
    assertUnavailable(tokens, "req_binding_duplicate");
    org.assertj.core.api.Assertions.assertThat(output)
        .contains(
            "outcome=binding_missing",
            "outcome=binding_cardinality_violation",
            "outcome=binding_scenario_mismatch",
            "outcome=binding_cefr_mismatch",
            "outcome=bound_content_unavailable");
  }

  private void assertUnavailable(AuthTokens tokens, String requestId) throws Exception {
    mvc.perform(get(DETAIL)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", requestId))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("CONTENT_READ_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.request_id").value(requestId))
        .andExpect(jsonPath("$.error.details.retryable").value(true))
        .andExpect(jsonPath("$.courses").doesNotExist());
  }
}
