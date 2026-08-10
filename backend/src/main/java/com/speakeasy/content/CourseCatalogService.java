package com.speakeasy.content;

import com.speakeasy.common.ApiException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CourseCatalogService {
  private static final Logger log = LoggerFactory.getLogger(CourseCatalogService.class);
  private static final Set<String> CEFR_LEVELS = Set.of("A1", "A2", "B1", "B2", "C1", "C2");
  private static final String PUBLISHED = "published";
  private static final String READ_UNAVAILABLE_MESSAGE = "Content is temporarily unavailable.";
  private static final String NOT_FOUND_MESSAGE = "Content resource was not found.";

  private final ScenarioRepository scenarios;
  private final ScenarioVersionRepository scenarioVersions;
  private final ScenarioLevelRepository scenarioLevels;
  private final CourseRepository courses;
  private final CourseVersionRepository courseVersions;
  private final CourseContentBindingRepository bindings;
  private final CourseVisibilityProjection visibility;

  public CourseCatalogService(
      ScenarioRepository scenarios,
      ScenarioVersionRepository scenarioVersions,
      ScenarioLevelRepository scenarioLevels,
      CourseRepository courses,
      CourseVersionRepository courseVersions,
      CourseContentBindingRepository bindings,
      CourseVisibilityProjection visibility) {
    this.scenarios = scenarios;
    this.scenarioVersions = scenarioVersions;
    this.scenarioLevels = scenarioLevels;
    this.courses = courses;
    this.courseVersions = courseVersions;
    this.bindings = bindings;
    this.visibility = visibility;
  }

  @Transactional(readOnly = true)
  public ThemeListView listThemes(UUID userId, String query, String category, String requestId) {
    try {
      String normalizedQuery = normalize(query);
      String normalizedCategory = normalize(category);
      CourseVisibilityProjection.VisibilityContext visibilityContext = visibility.current(userId);
      List<Scenario> candidates = scenarios.findAll(Sort.by(Sort.Direction.ASC, "scenarioId")).stream()
          .filter(scenario -> "official".equals(scenario.getCategory()))
          .filter(scenario -> "available".equals(scenario.getStatus()))
          .toList();
      List<String> scenarioIds = candidates.stream().map(Scenario::getScenarioId).toList();
      Map<String, ScenarioVersion> publishedVersions = scenarioIds.isEmpty()
          ? Map.of()
          : scenarioVersions
              .findByScenarioIdInAndContentStatusAndPublishedAtIsNotNullOrderByScenarioIdAscPublishedAtDescScenarioVersionIdAsc(
                  scenarioIds, PUBLISHED)
              .stream()
              .collect(Collectors.toMap(
                  ScenarioVersion::getScenarioId,
                  Function.identity(),
                  (latest, ignoredOlder) -> latest));
      Map<String, List<ScenarioLevel>> levelsByScenario = scenarioIds.isEmpty()
          ? Map.of()
          : scenarioLevels.findByScenarioIdInOrderByScenarioIdAscLevelCodeAsc(scenarioIds).stream()
              .collect(Collectors.groupingBy(ScenarioLevel::getScenarioId));
      List<ThemeView> result = candidates.stream()
          .filter(scenario -> publishedVersions.containsKey(scenario.getScenarioId()))
          .map(scenario -> themeView(
              scenario,
              publishedVersions.get(scenario.getScenarioId()),
              levelsByScenario.getOrDefault(scenario.getScenarioId(), List.of()),
              requestId))
          .filter(theme -> isThemeVisible(visibilityContext, theme, requestId))
          .filter(theme -> matchesQuery(theme, normalizedQuery))
          .filter(theme -> normalizedCategory == null || normalizedCategory.equals(normalize(theme.category())))
          .toList();
      observe(requestId, result.isEmpty() ? "theme_empty" : "theme_success", null);
      return new ThemeListView(result, visibilityContext.revision());
    } catch (ApiException exception) {
      throw exception;
    } catch (CourseVisibilityProjection.CourseVisibilityDependencyException exception) {
      throw unavailable(requestId, InternalOutcome.VISIBILITY_DEPENDENCY_FAILURE, null, exception);
    } catch (DataAccessException exception) {
      throw unavailable(requestId, InternalOutcome.THEME_QUERY_FAILURE, null, exception);
    }
  }

  @Transactional(readOnly = true)
  public CourseListView listCourses(UUID userId, String scenarioId, String requestId) {
    try {
      requirePublishedTheme(scenarioId, requestId);
      CourseVisibilityProjection.VisibilityContext visibilityContext = visibility.current(userId);
      if (!visibilityContext.isThemeVisible(scenarioId)) {
        throw notFound(requestId, InternalOutcome.THEME_NOT_VISIBLE, scenarioId);
      }
      List<CourseProjection> projections = currentPublishedProjections(
          courses.findByScenarioIdOrderBySortOrderAscCourseIdAsc(scenarioId), requestId);
      List<CourseSummaryView> result = projections.stream()
          .filter(projection -> isCourseVisible(visibilityContext, scenarioId, projection, requestId))
          .map(CourseProjection::summary)
          .toList();
      observe(requestId, result.isEmpty() ? "course_empty" : "course_success", scenarioId);
      return new CourseListView(scenarioId, result, visibilityContext.revision());
    } catch (ApiException exception) {
      throw exception;
    } catch (CourseVisibilityProjection.CourseVisibilityDependencyException exception) {
      throw unavailable(requestId, InternalOutcome.VISIBILITY_DEPENDENCY_FAILURE, scenarioId, exception);
    } catch (DataAccessException exception) {
      throw unavailable(requestId, InternalOutcome.COURSE_QUERY_FAILURE, scenarioId, exception);
    }
  }

  @Transactional(readOnly = true)
  public CourseDetailView getCourse(UUID userId, UUID courseId, UUID courseVersionId, String requestId) {
    String ref = courseId + ":" + courseVersionId;
    try {
      Course course = courses.findById(courseId)
          .orElseThrow(() -> notFound(requestId, InternalOutcome.COURSE_NOT_FOUND, ref));
      CourseVersion version = courseVersions.findById(courseVersionId)
          .filter(candidate -> courseId.equals(candidate.getCourseId()))
          .orElseThrow(() -> notFound(requestId, InternalOutcome.COURSE_VERSION_NOT_FOUND, ref));
      if (!PUBLISHED.equals(version.getPublicationStatus()) || version.getPublishedAt() == null) {
        throw notFound(requestId, InternalOutcome.COURSE_VERSION_NOT_PUBLISHED, ref);
      }
      CourseProjection projection = validateProjection(course, version, requestId);
      requirePublishedTheme(course.getScenarioId(), requestId);
      CourseVisibilityProjection.VisibilityContext visibilityContext = visibility.current(userId);
      if (!visibilityContext.isThemeVisible(course.getScenarioId())
          || !visibilityContext.isCourseVisible(course.getScenarioId(), version.getCefrLevel())) {
        throw notFound(requestId, InternalOutcome.COURSE_NOT_VISIBLE, ref);
      }
      observe(requestId, "course_detail_success", ref);
      return new CourseDetailView(
          projection.summary(),
          version.getDurationValue(),
          version.getDurationUnit(),
          version.getBackgroundAssetRef(),
          visibilityContext.revision());
    } catch (ApiException exception) {
      throw exception;
    } catch (CourseVisibilityProjection.CourseVisibilityDependencyException exception) {
      throw unavailable(requestId, InternalOutcome.VISIBILITY_DEPENDENCY_FAILURE, ref, exception);
    } catch (DataAccessException exception) {
      throw unavailable(requestId, InternalOutcome.COURSE_QUERY_FAILURE, ref, exception);
    }
  }

  private List<CourseProjection> currentPublishedProjections(
      List<Course> courseCandidates, String requestId) {
    if (courseCandidates.isEmpty()) {
      return List.of();
    }
    List<UUID> courseIds = courseCandidates.stream().map(Course::getCourseId).toList();
    Map<UUID, List<CourseVersion>> publishedByCourse = courseVersions
        .findByCourseIdInAndPublicationStatus(courseIds, PUBLISHED)
        .stream()
        .collect(Collectors.groupingBy(CourseVersion::getCourseId));
    List<CourseVersionCandidate> selected = new ArrayList<>();
    for (Course course : courseCandidates) {
      List<CourseVersion> published = publishedByCourse.getOrDefault(course.getCourseId(), List.of());
      if (published.size() > 1) {
        throw unavailable(
            requestId, InternalOutcome.CURRENT_PUBLISHED_VERSION_CONFLICT, course.getCourseId().toString(), null);
      }
      if (!published.isEmpty()) {
        CourseVersion version = published.get(0);
        validatePublishedSnapshot(course, version, requestId);
        selected.add(new CourseVersionCandidate(course, version));
      }
    }
    if (selected.isEmpty()) {
      return List.of();
    }

    List<UUID> versionIds = selected.stream()
        .map(candidate -> candidate.version().getCourseVersionId())
        .toList();
    List<CourseContentBinding> allBindings = bindings.findByCourseVersionIdIn(versionIds);
    Map<UUID, List<CourseContentBinding>> bindingsByVersion = allBindings.stream()
        .collect(Collectors.groupingBy(CourseContentBinding::getCourseVersionId));
    Set<UUID> scenarioVersionIds = allBindings.stream()
        .map(CourseContentBinding::getScenarioVersionId)
        .collect(Collectors.toSet());
    Set<UUID> scenarioLevelIds = allBindings.stream()
        .map(CourseContentBinding::getScenarioLevelId)
        .collect(Collectors.toSet());
    Map<UUID, ScenarioVersion> scenarioVersionsById = scenarioVersionIds.isEmpty()
        ? Map.of()
        : scenarioVersions.findAllById(scenarioVersionIds).stream()
            .collect(Collectors.toMap(ScenarioVersion::getScenarioVersionId, Function.identity()));
    Map<UUID, ScenarioLevel> scenarioLevelsById = scenarioLevelIds.isEmpty()
        ? Map.of()
        : scenarioLevels.findAllById(scenarioLevelIds).stream()
            .collect(Collectors.toMap(ScenarioLevel::getScenarioLevelId, Function.identity()));

    return selected.stream().map(candidate -> {
      Course course = candidate.course();
      CourseVersion version = candidate.version();
      String ref = course.getCourseId() + ":" + version.getCourseVersionId();
      CourseContentBinding binding = requireSingleBinding(
          bindingsByVersion.getOrDefault(version.getCourseVersionId(), List.of()), requestId, ref);
      ScenarioVersion scenarioVersion = scenarioVersionsById.get(binding.getScenarioVersionId());
      ScenarioLevel scenarioLevel = scenarioLevelsById.get(binding.getScenarioLevelId());
      if (scenarioVersion == null || scenarioLevel == null) {
        throw unavailable(requestId, InternalOutcome.BOUND_CONTENT_UNAVAILABLE, ref, null);
      }
      return validatedProjection(course, version, binding, scenarioVersion, scenarioLevel, requestId);
    }).toList();
  }

  private CourseProjection validateProjection(Course course, CourseVersion version, String requestId) {
    String ref = validatePublishedSnapshot(course, version, requestId);
    CourseContentBinding binding = requireSingleBinding(
        bindings.findByCourseVersionId(version.getCourseVersionId()), requestId, ref);
    ScenarioVersion scenarioVersion = scenarioVersions.findById(binding.getScenarioVersionId())
        .orElseThrow(() -> unavailable(requestId, InternalOutcome.BOUND_CONTENT_UNAVAILABLE, ref, null));
    ScenarioLevel scenarioLevel = scenarioLevels.findById(binding.getScenarioLevelId())
        .orElseThrow(() -> unavailable(requestId, InternalOutcome.BOUND_CONTENT_UNAVAILABLE, ref, null));
    return validatedProjection(course, version, binding, scenarioVersion, scenarioLevel, requestId);
  }

  private String validatePublishedSnapshot(Course course, CourseVersion version, String requestId) {
    String ref = course.getCourseId() + ":" + version.getCourseVersionId();
    if (!course.getCourseId().equals(version.getCourseId())
        || !PUBLISHED.equals(version.getPublicationStatus())
        || version.getPublishedAt() == null
        || isBlank(version.getVersionKey())
        || isBlank(version.getTitleEn())
        || isBlank(version.getSummaryZh())
        || !CEFR_LEVELS.contains(version.getCefrLevel())
        || version.getDurationValue() == null
        || version.getDurationValue().compareTo(BigDecimal.ZERO) <= 0
        || isBlank(version.getDurationUnit())) {
      throw unavailable(requestId, InternalOutcome.PUBLISHED_SNAPSHOT_INVALID, ref, null);
    }
    return ref;
  }

  private CourseContentBinding requireSingleBinding(
      List<CourseContentBinding> candidates, String requestId, String ref) {
    if (candidates.isEmpty()) {
      throw unavailable(requestId, InternalOutcome.BINDING_MISSING, ref, null);
    }
    if (candidates.size() != 1) {
      throw unavailable(requestId, InternalOutcome.BINDING_CARDINALITY_VIOLATION, ref, null);
    }
    return candidates.get(0);
  }

  private CourseProjection validatedProjection(
      Course course,
      CourseVersion version,
      CourseContentBinding binding,
      ScenarioVersion scenarioVersion,
      ScenarioLevel scenarioLevel,
      String requestId) {
    String ref = course.getCourseId() + ":" + version.getCourseVersionId();
    if (!course.getScenarioId().equals(scenarioVersion.getScenarioId())
        || !course.getScenarioId().equals(scenarioLevel.getScenarioId())) {
      throw unavailable(requestId, InternalOutcome.BINDING_SCENARIO_MISMATCH, ref, null);
    }
    if (!version.getCefrLevel().equals(scenarioLevel.getLevelCode())
        || !version.getCefrLevel().equals(scenarioLevel.getTargetLevel())) {
      throw unavailable(requestId, InternalOutcome.BINDING_CEFR_MISMATCH, ref, null);
    }
    if (!PUBLISHED.equals(scenarioVersion.getContentStatus()) || scenarioVersion.getPublishedAt() == null) {
      throw unavailable(requestId, InternalOutcome.BOUND_CONTENT_UNAVAILABLE, ref, null);
    }

    BindingRef bindingRef = new BindingRef(
        binding.getCourseContentBindingId(),
        binding.getScenarioVersionId(),
        binding.getScenarioLevelId());
    CourseSummaryView summary = new CourseSummaryView(
        course.getCourseId(),
        version.getCourseVersionId(),
        version.getTitleEn(),
        version.getSummaryZh(),
        version.getCefrLevel(),
        bindingRef,
        course.getSortOrder());
    return new CourseProjection(version, summary);
  }

  private ThemeView themeView(
      Scenario scenario,
      ScenarioVersion version,
      List<ScenarioLevel> scenarioLevelFacts,
      String requestId) {
    if (version.getPublishedAt() == null) {
      throw unavailable(requestId, InternalOutcome.THEME_VERSION_INCONSISTENT, scenario.getScenarioId(), null);
    }
    List<String> levels = scenarioLevelFacts.stream()
        .map(level -> {
          if (!CEFR_LEVELS.contains(level.getLevelCode()) || !level.getLevelCode().equals(level.getTargetLevel())) {
            throw unavailable(requestId, InternalOutcome.THEME_LEVEL_INCONSISTENT, scenario.getScenarioId(), null);
          }
          return level.getLevelCode();
        })
        .toList();
    return new ThemeView(
        scenario.getScenarioId(),
        scenario.getTitle(),
        scenario.getSummary(),
        List.of("official"),
        levels,
        scenario.getStatus(),
        true,
        null,
        scenario.getCategory(),
        version.getScenarioVersionId());
  }

  private Scenario requirePublishedTheme(String scenarioId, String requestId) {
    Scenario scenario = scenarios.findById(scenarioId)
        .orElseThrow(() -> notFound(requestId, InternalOutcome.THEME_NOT_FOUND, scenarioId));
    if (!"official".equals(scenario.getCategory())
        || !"available".equals(scenario.getStatus())
        || scenarioVersions
            .findFirstByScenarioIdAndContentStatusAndPublishedAtIsNotNullOrderByPublishedAtDescScenarioVersionIdAsc(
                scenarioId, PUBLISHED)
            .isEmpty()) {
      throw notFound(requestId, InternalOutcome.THEME_NOT_PUBLISHED, scenarioId);
    }
    return scenario;
  }

  private boolean matchesQuery(ThemeView theme, String query) {
    if (query == null) {
      return true;
    }
    return containsNormalized(theme.scenarioId(), query)
        || containsNormalized(theme.title(), query)
        || containsNormalized(theme.summary(), query);
  }

  private boolean containsNormalized(String value, String query) {
    String normalized = normalize(value);
    return normalized != null && normalized.contains(query);
  }

  private String normalize(String value) {
    return value == null || value.isBlank() ? null : value.trim().toLowerCase(Locale.ROOT);
  }

  private boolean isBlank(String value) {
    return value == null || value.isBlank();
  }

  private boolean isThemeVisible(
      CourseVisibilityProjection.VisibilityContext visibilityContext, ThemeView theme, String requestId) {
    boolean visible = visibilityContext.isThemeVisible(theme.scenarioId());
    if (!visible) {
      observe(requestId, InternalOutcome.THEME_NOT_VISIBLE.externalName(), theme.scenarioId());
    }
    return visible;
  }

  private boolean isCourseVisible(
      CourseVisibilityProjection.VisibilityContext visibilityContext,
      String scenarioId,
      CourseProjection projection,
      String requestId) {
    boolean visible = visibilityContext.isCourseVisible(scenarioId, projection.version().getCefrLevel());
    if (!visible) {
      observe(
          requestId,
          InternalOutcome.COURSE_NOT_VISIBLE.externalName(),
          projection.summary().courseId() + ":" + projection.summary().courseVersionId());
    }
    return visible;
  }

  private CourseReadException notFound(String requestId, InternalOutcome outcome, String ref) {
    observe(requestId, outcome.externalName(), ref);
    return new CourseReadException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", NOT_FOUND_MESSAGE, Map.of(), outcome);
  }

  private CourseReadException unavailable(
      String requestId, InternalOutcome outcome, String ref, Throwable cause) {
    observe(requestId, outcome.externalName(), ref);
    CourseReadException exception = new CourseReadException(
        HttpStatus.SERVICE_UNAVAILABLE,
        "CONTENT_READ_UNAVAILABLE",
        READ_UNAVAILABLE_MESSAGE,
        Map.of("retryable", true),
        outcome);
    if (cause != null) {
      exception.initCause(cause);
    }
    return exception;
  }

  private void observe(String requestId, String outcome, String ref) {
    log.info(
        "course_read request_id={} outcome={} ref_hash={}",
        requestId,
        outcome,
        ref == null ? "none" : hash(ref));
  }

  private String hash(String value) {
    try {
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(digest, 0, 8);
    } catch (Exception exception) {
      return "unavailable";
    }
  }

  public record ThemeView(
      String scenarioId,
      String title,
      String summary,
      List<String> tags,
      List<String> levels,
      String status,
      boolean accessAllowed,
      String accessReasonCode,
      String category,
      UUID scenarioVersionId) {
    public String fingerprint() {
      return String.join(
          "|",
          scenarioId,
          title,
          summary == null ? "" : summary,
          String.join(",", tags),
          String.join(",", levels),
          status,
          Boolean.toString(accessAllowed),
          accessReasonCode == null ? "" : accessReasonCode,
          scenarioVersionId.toString());
    }
  }

  public record ThemeListView(List<ThemeView> themes, String visibilityRevision) {}

  public record BindingRef(UUID courseContentBindingId, UUID scenarioVersionId, UUID scenarioLevelId) {
    public String fingerprint() {
      return courseContentBindingId + ":" + scenarioVersionId + ":" + scenarioLevelId;
    }
  }

  public record CourseSummaryView(
      UUID courseId,
      UUID courseVersionId,
      String titleEn,
      String summaryZh,
      String levelCode,
      BindingRef contentBindingRef,
      int sortOrder) {
    public String fingerprint() {
      return String.join(
          "|",
          courseId.toString(),
          courseVersionId.toString(),
          titleEn,
          summaryZh,
          levelCode,
          contentBindingRef.fingerprint(),
          Integer.toString(sortOrder));
    }
  }

  public record CourseListView(String scenarioId, List<CourseSummaryView> courses, String visibilityRevision) {
    public String fingerprint() {
      return scenarioId + "|" + courses.stream()
          .sorted(Comparator.comparingInt(CourseSummaryView::sortOrder))
          .map(CourseSummaryView::fingerprint)
          .reduce((left, right) -> left + ";" + right)
          .orElse("");
    }
  }

  public record CourseDetailView(
      CourseSummaryView summary,
      BigDecimal durationValue,
      String durationUnit,
      String backgroundAssetRef,
      String visibilityRevision) {
    public String fingerprint() {
      return summary.fingerprint()
          + "|" + durationValue.toPlainString()
          + "|" + durationUnit
          + "|" + (backgroundAssetRef == null ? "" : backgroundAssetRef);
    }
  }

  enum InternalOutcome {
    THEME_NOT_FOUND,
    THEME_NOT_PUBLISHED,
    THEME_NOT_VISIBLE,
    COURSE_NOT_FOUND,
    COURSE_VERSION_NOT_FOUND,
    COURSE_VERSION_NOT_PUBLISHED,
    COURSE_NOT_VISIBLE,
    BINDING_MISSING,
    BINDING_CARDINALITY_VIOLATION,
    BINDING_SCENARIO_MISMATCH,
    BINDING_CEFR_MISMATCH,
    BOUND_CONTENT_UNAVAILABLE,
    PUBLISHED_SNAPSHOT_INVALID,
    CURRENT_PUBLISHED_VERSION_CONFLICT,
    THEME_VERSION_INCONSISTENT,
    THEME_LEVEL_INCONSISTENT,
    VISIBILITY_DEPENDENCY_FAILURE,
    THEME_QUERY_FAILURE,
    COURSE_QUERY_FAILURE;

    String externalName() {
      return name().toLowerCase(Locale.ROOT);
    }
  }

  static final class CourseReadException extends ApiException {
    private final InternalOutcome internalOutcome;

    CourseReadException(
        HttpStatus status,
        String code,
        String message,
        Map<String, Object> details,
        InternalOutcome internalOutcome) {
      super(status, code, message, details);
      this.internalOutcome = internalOutcome;
    }

    InternalOutcome internalOutcome() {
      return internalOutcome;
    }
  }

  private record CourseProjection(CourseVersion version, CourseSummaryView summary) {}

  private record CourseVersionCandidate(Course course, CourseVersion version) {}
}
