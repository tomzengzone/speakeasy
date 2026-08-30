package com.speakeasy.content;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.doReturn;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@ExtendWith(OutputCaptureExtension.class)
class CourseDetailApiContractTest extends AbstractCourseContractTest {
  @SpyBean CourseVersionRepository courseVersionRepository;

  @Test
  void courseDetail() throws Exception {
    AuthTokens tokens = loginPhone("+8613910050101");

    MvcResult list = mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_detail_source"))
        .andExpect(status().isOk())
        .andReturn();
    String listBody = list.getResponse().getContentAsString();
    String courseId = JsonPath.read(listBody, "$.courses[0].course_id");
    String versionId = JsonPath.read(listBody, "$.courses[0].course_version_id");
    String title = JsonPath.read(listBody, "$.courses[0].title_en");
    String summary = JsonPath.read(listBody, "$.courses[0].summary_zh");
    String level = JsonPath.read(listBody, "$.courses[0].level_code");
    String bindingId = JsonPath.read(listBody, "$.courses[0].content_binding_ref.course_content_binding_id");
    String scenarioVersionId = JsonPath.read(listBody, "$.courses[0].content_binding_ref.scenario_version_id");
    String scenarioLevelId = JsonPath.read(listBody, "$.courses[0].content_binding_ref.scenario_level_id");

    MvcResult detail = mvc.perform(get("/courses/" + courseId + "/versions/" + versionId)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_detail"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.schema_version").value(1))
        .andExpect(jsonPath("$.request_id").value("req_course_detail"))
        .andExpect(jsonPath("$.course.course_id").value("40000000-0000-4000-8000-000000000001"))
        .andExpect(jsonPath("$.course.course_version_id").value("41000000-0000-4000-8000-000000000001"))
        .andExpect(jsonPath("$.course.title_en").value("Job Interview Basics"))
        .andExpect(jsonPath("$.course.summary_zh").value("用简单句完成自我介绍并回答常见面试问题。"))
        .andExpect(jsonPath("$.course.level_code").value("A2"))
        .andExpect(jsonPath("$.course.content_binding_ref.course_content_binding_id")
            .value("42000000-0000-4000-8000-000000000001"))
        .andExpect(jsonPath("$.course.typical_duration.value").value(10))
        .andExpect(jsonPath("$.course.typical_duration.unit").value("minutes"))
        .andExpect(jsonPath("$.course.background_asset_ref").doesNotExist())
        .andReturn();
    String detailBody = detail.getResponse().getContentAsString();
    assertThat(JsonPath.<String>read(detailBody, "$.course.title_en")).isEqualTo(title);
    assertThat(JsonPath.<String>read(detailBody, "$.course.summary_zh")).isEqualTo(summary);
    assertThat(JsonPath.<String>read(detailBody, "$.course.level_code")).isEqualTo(level);
    assertThat(JsonPath.<String>read(
        detailBody, "$.course.content_binding_ref.course_content_binding_id")).isEqualTo(bindingId);
    assertThat(JsonPath.<String>read(
        detailBody, "$.course.content_binding_ref.scenario_version_id")).isEqualTo(scenarioVersionId);
    assertThat(JsonPath.<String>read(
        detailBody, "$.course.content_binding_ref.scenario_level_id")).isEqualTo(scenarioLevelId);

    jdbc.update("""
        UPDATE content_course_version
        SET background_asset_ref = 'asset://course/job-interview-a2'
        WHERE course_version_id = '41000000-0000-4000-8000-000000000001'
        """);
    mvc.perform(get("/courses/" + courseId + "/versions/" + versionId)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_detail_background"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.course.background_asset_ref")
            .value("asset://course/job-interview-a2"));

    assertInvalidPublishedSnapshotFailsWholeDetail();
  }

  private void assertInvalidPublishedSnapshotFailsWholeDetail() throws Exception {
    AuthTokens tokens = loginPhone("+8613910050103");
    UUID courseId = UUID.fromString(CourseTestFixture.JOB_A2_COURSE_ID);
    UUID versionId = UUID.fromString(CourseTestFixture.JOB_A2_VERSION_ID);
    CourseVersion invalid = courseVersionRepository.findById(versionId).orElseThrow();
    ReflectionTestUtils.setField(invalid, "durationValue", BigDecimal.ZERO);
    doReturn(Optional.of(invalid)).when(courseVersionRepository).findById(versionId);

    mvc.perform(get("/courses/" + courseId + "/versions/" + versionId)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_detail_invalid_snapshot"))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("CONTENT_READ_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));
  }

  @Test
  void exactVersion(CapturedOutput output) throws Exception {
    AuthTokens tokens = loginPhone("+8613910050102");

    assertNotFound(tokens, "40000000-0000-4000-8000-000000000001", "41000000-0000-4000-8000-000000000002");
    assertNotFound(tokens, "40000000-0000-4000-8000-000000000001", "41000000-0000-4000-8000-000000000099");
    assertNotFound(tokens, CourseTestFixture.JOB_A2_COURSE_ID, CourseTestFixture.JOB_DRAFT_VERSION_ID);
    assertNotFound(tokens, CourseTestFixture.JOB_A2_COURSE_ID, CourseTestFixture.JOB_SUPERSEDED_VERSION_ID);

    jdbc.update("""
        UPDATE content_course_version
        SET publication_status = 'draft', published_at = NULL, current_published_marker = NULL
        WHERE course_version_id = '41000000-0000-4000-8000-000000000001'
        """);
    assertNotFound(tokens, "40000000-0000-4000-8000-000000000001", "41000000-0000-4000-8000-000000000001");
    assertThat(output)
        .contains("outcome=course_version_not_found", "outcome=course_version_not_published");
  }

  private void assertNotFound(AuthTokens tokens, String courseId, String versionId) throws Exception {
    mvc.perform(get("/courses/" + courseId + "/versions/" + versionId)
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_course_exact_not_found"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"))
        .andExpect(jsonPath("$.error.message").value("Content resource was not found."));
  }
}
