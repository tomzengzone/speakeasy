package com.speakeasy.content;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import com.speakeasy.commerce.EntitlementGateService;
import java.util.UUID;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@ExtendWith(OutputCaptureExtension.class)
class CourseCatalogVisibilityContractTest extends AbstractCourseContractTest {
  private static final String B2_DETAIL =
      "/courses/40000000-0000-4000-8000-000000000003/versions/41000000-0000-4000-8000-000000000003";

  @Autowired EntitlementGateService entitlementGateService;

  @Test
  void privacyVisibility(CapturedOutput output) throws Exception {
    AuthTokens free = loginPhone("+8613910050401");
    EntitlementGateService.ContentVisibilityDecision freeDecision =
        entitlementGateService.contentVisibility(UUID.fromString(free.userId()));
    assertThat(freeDecision.theme("job_interview"))
        .isEqualTo(EntitlementGateService.ContentVisibilityOutcome.ALLOW);
    assertThat(freeDecision.course("job_interview", "A2"))
        .isEqualTo(EntitlementGateService.ContentVisibilityOutcome.ALLOW);
    assertThat(freeDecision.course("job_interview", "B2"))
        .isEqualTo(EntitlementGateService.ContentVisibilityOutcome.DENY);
    assertThat(freeDecision.visibilityRevision()).isNotBlank();

    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(free.accessToken()))
            .header("X-Request-Id", "req_visibility_free"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.courses.length()").value(2));
    mvc.perform(get(B2_DETAIL)
            .header(HttpHeaders.AUTHORIZATION, bearer(free.accessToken()))
            .header("X-Request-Id", "req_visibility_hidden"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"))
        .andExpect(jsonPath("$.error.message").value("Content resource was not found."));

    mvc.perform(get("/scenarios/missing/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(free.accessToken()))
            .header("X-Request-Id", "req_visibility_theme_missing"))
        .andExpect(status().isNotFound());
    jdbc.update("UPDATE scenarios SET status = 'unavailable' WHERE scenario_id = 'job_interview'");
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(free.accessToken()))
            .header("X-Request-Id", "req_visibility_theme_unpublished"))
        .andExpect(status().isNotFound());
    mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header(HttpHeaders.AUTHORIZATION, bearer(free.accessToken()))
            .header("X-Request-Id", "req_visibility_detail_theme_unpublished"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
    restoreCourseFixtures();

    AuthTokens denied = loginPhone("+8613910050404");
    saveContentEntitlement(denied, false, false);
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(denied.accessToken()))
            .header("X-Request-Id", "req_visibility_theme_hidden"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"));
    mvc.perform(get("/courses/40000000-0000-4000-8000-000000000099/versions/41000000-0000-4000-8000-000000000099")
            .header(HttpHeaders.AUTHORIZATION, bearer(free.accessToken()))
            .header("X-Request-Id", "req_visibility_missing"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.error.code").value("RESOURCE_NOT_FOUND"))
        .andExpect(jsonPath("$.error.message").value("Content resource was not found."));

    AuthTokens pro = loginPhone("+8613910050402");
    grantAdvanced(pro);
    EntitlementGateService.ContentVisibilityDecision proDecision =
        entitlementGateService.contentVisibility(UUID.fromString(pro.userId()));
    assertThat(proDecision.course("job_interview", "B2"))
        .isEqualTo(EntitlementGateService.ContentVisibilityOutcome.ALLOW);
    assertThat(proDecision.visibilityRevision()).isNotEqualTo(freeDecision.visibilityRevision());
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(pro.accessToken()))
            .header("X-Request-Id", "req_visibility_pro"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.courses.length()").value(3))
        .andExpect(jsonPath("$.courses[2].level_code").value("B2"));
    mvc.perform(get(B2_DETAIL)
            .header(HttpHeaders.AUTHORIZATION, bearer(pro.accessToken()))
            .header("X-Request-Id", "req_visibility_pro_detail"))
        .andExpect(status().isOk());

    AuthTokens malformed = loginPhone("+8613910050403");
    saveMalformedEntitlement(malformed);
    EntitlementGateService.ContentVisibilityDecision malformedDecision =
        entitlementGateService.contentVisibility(UUID.fromString(malformed.userId()));
    assertThat(malformedDecision.theme("job_interview"))
        .isEqualTo(EntitlementGateService.ContentVisibilityOutcome.DEPENDENCY_UNAVAILABLE);
    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(malformed.accessToken()))
            .header("X-Request-Id", "req_visibility_malformed"))
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.code").value("CONTENT_READ_UNAVAILABLE"))
        .andExpect(jsonPath("$.error.details.retryable").value(true));

    assertThat(jdbc.queryForObject(
        "SELECT COUNT(*) FROM content_course_version WHERE publication_status = 'published'", Long.class)).isEqualTo(6L);
    assertThat(output)
        .contains(
            "outcome=theme_not_found",
            "outcome=theme_not_published",
            "outcome=theme_not_visible",
            "outcome=course_not_found",
            "outcome=course_not_visible",
            "outcome=visibility_dependency_failure");
  }
}
