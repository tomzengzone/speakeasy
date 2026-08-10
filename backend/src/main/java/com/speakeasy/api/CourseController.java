package com.speakeasy.api;

import com.speakeasy.content.CourseCatalogService;
import com.speakeasy.security.CurrentUser;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
@ConditionalOnProperty(prefix = "speakeasy.content.course-read", name = "enabled", havingValue = "true", matchIfMissing = true)
public class CourseController {
  private final CourseCatalogService service;

  public CourseController(CourseCatalogService service) {
    this.service = service;
  }

  @GetMapping("/scenarios/{scenarioId}/courses")
  public ResponseEntity<CourseListResponse> listCourses(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable String scenarioId,
      @RequestHeader(name = "X-Request-Id", required = false) String suppliedRequestId,
      @RequestHeader(name = "If-None-Match", required = false) String ifNoneMatch) {
    String requestId = suppliedRequestId;
    CourseCatalogService.CourseListView result = service.listCourses(currentUser.userId(), scenarioId, requestId);
    CourseListResponse body = new CourseListResponse(
        1,
        requestId,
        result.scenarioId(),
        result.courses().stream().map(CourseSummaryDto::from).toList());
    String etag = CourseReadHttpSupport.etag(
        currentUser,
        "GET|/scenarios/" + scenarioId + "/courses",
        result.visibilityRevision(),
        result.fingerprint());
    return CourseReadHttpSupport.response(etag, ifNoneMatch, body);
  }

  @GetMapping("/courses/{courseId}/versions/{courseVersionId}")
  public ResponseEntity<CourseDetailResponse> getCourseVersion(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable UUID courseId,
      @PathVariable UUID courseVersionId,
      @RequestHeader(name = "X-Request-Id", required = false) String suppliedRequestId,
      @RequestHeader(name = "If-None-Match", required = false) String ifNoneMatch) {
    String requestId = suppliedRequestId;
    CourseCatalogService.CourseDetailView result =
        service.getCourse(currentUser.userId(), courseId, courseVersionId, requestId);
    CourseDetailResponse body = new CourseDetailResponse(1, requestId, CourseDetailDto.from(result));
    String etag = CourseReadHttpSupport.etag(
        currentUser,
        "GET|/courses/" + courseId + "/versions/" + courseVersionId,
        result.visibilityRevision(),
        result.fingerprint());
    return CourseReadHttpSupport.response(etag, ifNoneMatch, body);
  }

  public record CourseListResponse(
      int schemaVersion, String requestId, String scenarioId, List<CourseSummaryDto> courses) {}

  public record CourseDetailResponse(int schemaVersion, String requestId, CourseDetailDto course) {}

  public record CourseContentBindingRefDto(
      UUID courseContentBindingId, UUID scenarioVersionId, UUID scenarioLevelId) {
    static CourseContentBindingRefDto from(CourseCatalogService.BindingRef binding) {
      return new CourseContentBindingRefDto(
          binding.courseContentBindingId(), binding.scenarioVersionId(), binding.scenarioLevelId());
    }
  }

  public record CourseSummaryDto(
      UUID courseId,
      UUID courseVersionId,
      String titleEn,
      String summaryZh,
      String levelCode,
      CourseContentBindingRefDto contentBindingRef) {
    static CourseSummaryDto from(CourseCatalogService.CourseSummaryView course) {
      return new CourseSummaryDto(
          course.courseId(),
          course.courseVersionId(),
          course.titleEn(),
          course.summaryZh(),
          course.levelCode(),
          CourseContentBindingRefDto.from(course.contentBindingRef()));
    }
  }

  public record TypicalDurationDto(BigDecimal value, String unit) {}

  public record CourseDetailDto(
      UUID courseId,
      UUID courseVersionId,
      String titleEn,
      String summaryZh,
      String levelCode,
      CourseContentBindingRefDto contentBindingRef,
      TypicalDurationDto typicalDuration,
      String backgroundAssetRef) {
    static CourseDetailDto from(CourseCatalogService.CourseDetailView course) {
      CourseCatalogService.CourseSummaryView summary = course.summary();
      return new CourseDetailDto(
          summary.courseId(),
          summary.courseVersionId(),
          summary.titleEn(),
          summary.summaryZh(),
          summary.levelCode(),
          CourseContentBindingRefDto.from(summary.contentBindingRef()),
          new TypicalDurationDto(course.durationValue(), course.durationUnit()),
          course.backgroundAssetRef());
    }
  }
}
