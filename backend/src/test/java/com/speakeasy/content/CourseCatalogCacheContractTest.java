package com.speakeasy.content;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import jakarta.persistence.EntityManagerFactory;
import java.util.UUID;
import org.hibernate.SessionFactory;
import org.hibernate.stat.Statistics;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CourseCatalogCacheContractTest extends AbstractCourseContractTest {
  private static final UUID NULL_PUBLISHED_AT_VERSION_ID =
      UUID.fromString("70000000-0000-4000-8000-000000000091");
  private static final UUID TIED_VERSION_ASC_ID =
      UUID.fromString("70000000-0000-4000-8000-000000000092");
  private static final UUID TIED_VERSION_DESC_ID =
      UUID.fromString("70000000-0000-4000-8000-000000000093");

  @Autowired CourseCatalogService courseCatalogService;
  @Autowired EntityManagerFactory entityManagerFactory;

  @Test
  void themeSelectionIgnoresPublishedVersionWithoutPublishedAt() {
    insertScenarioVersion(NULL_PUBLISHED_AT_VERSION_ID, "null-published-at", null);
    try {
      CourseCatalogService.ThemeView selected = courseCatalogService
          .listThemes(UUID.fromString("70000000-0000-4000-8000-000000000001"), null, null, "req_null_publish")
          .themes()
          .stream()
          .filter(theme -> "job_interview".equals(theme.scenarioId()))
          .findFirst()
          .orElseThrow();

      assertThat(selected.scenarioVersionId())
          .isEqualTo(UUID.fromString("10000000-0000-0000-0000-000000000001"));
    } finally {
      clearDeterministicScenarioVersions();
    }
  }

  @Test
  void tiedLatestThemeVersionsUseAscendingIdAndKeepRepresentationAndEtagStable() throws Exception {
    insertScenarioVersion(TIED_VERSION_DESC_ID, "same-time-desc", "2026-08-09 00:00:00");
    insertScenarioVersion(TIED_VERSION_ASC_ID, "same-time-asc", "2026-08-09 00:00:00");
    try {
      CourseCatalogService.ThemeView selected = courseCatalogService
          .listThemes(UUID.fromString("70000000-0000-4000-8000-000000000001"), null, null, "req_tie_selected")
          .themes()
          .stream()
          .filter(theme -> "job_interview".equals(theme.scenarioId()))
          .findFirst()
          .orElseThrow();
      assertThat(selected.scenarioVersionId()).isEqualTo(TIED_VERSION_ASC_ID);

      AuthTokens tokens = loginPhone("+8613910050599");
      MvcResult first = mvc.perform(get("/scenarios")
              .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
              .header("X-Request-Id", "req_tie_stable"))
          .andExpect(status().isOk())
          .andReturn();
      String representation = first.getResponse().getContentAsString();
      String etag = first.getResponse().getHeader(HttpHeaders.ETAG);
      assertThat(etag).isNotBlank();

      for (int request = 2; request <= 5; request++) {
        MvcResult repeated = mvc.perform(get("/scenarios")
                .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
                .header("X-Request-Id", "req_tie_stable"))
            .andExpect(status().isOk())
            .andReturn();
        assertThat(repeated.getResponse().getContentAsString()).isEqualTo(representation);
        assertThat(repeated.getResponse().getHeader(HttpHeaders.ETAG)).isEqualTo(etag);
      }
    } finally {
      clearDeterministicScenarioVersions();
    }
  }

  @Test
  void learnerPrivateEtag() throws Exception {
    AuthTokens first = loginPhone("+8613910050501");
    MvcResult initial = mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header("X-Request-Id", "req_cache_initial"))
        .andExpect(status().isOk())
        .andExpect(header().string(HttpHeaders.CACHE_CONTROL, "private, no-cache"))
        .andExpect(header().string(HttpHeaders.VARY, HttpHeaders.AUTHORIZATION))
        .andReturn();
    String etag = initial.getResponse().getHeader(HttpHeaders.ETAG);
    assertThat(etag).isNotBlank();

    MvcResult initialThemes = mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header("X-Request-Id", "req_cache_theme_initial"))
        .andExpect(status().isOk())
        .andReturn();
    String themeEtag = initialThemes.getResponse().getHeader(HttpHeaders.ETAG);

    MvcResult initialDetail = mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header("X-Request-Id", "req_cache_detail_initial"))
        .andExpect(status().isOk())
        .andReturn();
    String detailEtag = initialDetail.getResponse().getHeader(HttpHeaders.ETAG);

    mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header(HttpHeaders.IF_NONE_MATCH, etag)
            .header("X-Request-Id", "req_cache_revalidate"))
        .andExpect(status().isNotModified())
        .andExpect(header().string("X-Request-Id", "req_cache_revalidate"))
        .andExpect(header().string(HttpHeaders.ETAG, etag));

    saveContentEntitlement(first, true, false);
    MvcResult revisionChanged = mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header(HttpHeaders.IF_NONE_MATCH, etag)
            .header("X-Request-Id", "req_cache_revision_changed"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.courses.length()").value(2))
        .andReturn();
    String revisionEtag = revisionChanged.getResponse().getHeader(HttpHeaders.ETAG);
    assertThat(revisionEtag).isNotEqualTo(etag);

    MvcResult themeRevisionChanged = mvc.perform(get("/scenarios")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header(HttpHeaders.IF_NONE_MATCH, themeEtag)
            .header("X-Request-Id", "req_cache_theme_revision_changed"))
        .andExpect(status().isOk())
        .andReturn();
    assertThat(themeRevisionChanged.getResponse().getHeader(HttpHeaders.ETAG)).isNotEqualTo(themeEtag);

    MvcResult detailRevisionChanged = mvc.perform(get(
            "/courses/40000000-0000-4000-8000-000000000001/versions/41000000-0000-4000-8000-000000000001")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header(HttpHeaders.IF_NONE_MATCH, detailEtag)
            .header("X-Request-Id", "req_cache_detail_revision_changed"))
        .andExpect(status().isOk())
        .andReturn();
    assertThat(detailRevisionChanged.getResponse().getHeader(HttpHeaders.ETAG)).isNotEqualTo(detailEtag);

    AuthTokens second = loginPhone("+8613910050502");
    MvcResult otherLearner = mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(second.accessToken()))
            .header(HttpHeaders.IF_NONE_MATCH, etag)
            .header("X-Request-Id", "req_cache_other_learner"))
        .andExpect(status().isOk())
        .andReturn();
    assertThat(otherLearner.getResponse().getHeader(HttpHeaders.ETAG)).isNotEqualTo(etag);

    grantAdvanced(first);
    MvcResult changedVisibility = mvc.perform(get("/scenarios/job_interview/courses")
            .header(HttpHeaders.AUTHORIZATION, bearer(first.accessToken()))
            .header(HttpHeaders.IF_NONE_MATCH, revisionEtag)
            .header("X-Request-Id", "req_cache_visibility_changed"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.courses.length()").value(3))
        .andReturn();
    assertThat(changedVisibility.getResponse().getHeader(HttpHeaders.ETAG)).isNotEqualTo(etag);
  }

  @Test
  void collectionQueryCountsStayFixedAsThemeAndCourseCountsGrow() {
    Statistics statistics = entityManagerFactory.unwrap(SessionFactory.class).getStatistics();
    boolean initiallyEnabled = statistics.isStatisticsEnabled();
    statistics.setStatisticsEnabled(true);
    UUID userId = UUID.fromString("70000000-0000-4000-8000-000000000001");
    try {
      long baseThemeQueries = countThemeQueries(statistics, userId);
      try {
        insertSyntheticThemes(8);
        long scaledThemeQueries = countThemeQueries(statistics, userId);
        assertThat(scaledThemeQueries).isEqualTo(baseThemeQueries);
      } finally {
        clearSyntheticThemes();
      }

      long baseCourseQueries = countCourseQueries(statistics, userId);
      try {
        insertSyntheticCourses(8);
        long scaledCourseQueries = countCourseQueries(statistics, userId);
        assertThat(scaledCourseQueries).isEqualTo(baseCourseQueries);
      } finally {
        clearSyntheticCourses();
      }
    } finally {
      statistics.clear();
      statistics.setStatisticsEnabled(initiallyEnabled);
    }
  }

  private long countThemeQueries(Statistics statistics, UUID userId) {
    statistics.clear();
    courseCatalogService.listThemes(userId, null, null, "req_theme_query_count");
    return statistics.getPrepareStatementCount();
  }

  private long countCourseQueries(Statistics statistics, UUID userId) {
    statistics.clear();
    courseCatalogService.listCourses(userId, "job_interview", "req_course_query_count");
    return statistics.getPrepareStatementCount();
  }

  private void insertSyntheticThemes(int count) {
    for (int index = 1; index <= count; index++) {
      String scenarioId = "bulk_theme_%02d".formatted(index);
      jdbc.update(
          "INSERT INTO scenarios (scenario_id, slug, title, summary, category, status) VALUES (?, ?, ?, ?, 'official', 'available')",
          scenarioId,
          scenarioId.replace('_', '-'),
          "Bulk Theme " + index,
          "Query-count fixture");
      jdbc.update("""
          INSERT INTO scenario_versions (
            scenario_version_id, scenario_id, version, content_status, published_at
          ) VALUES (?, ?, 'query-count-v1', 'published', TIMESTAMP '2026-08-07 00:00:00')
          """, UUID.fromString("50000000-0000-4000-8000-%012d".formatted(index)), scenarioId);
      jdbc.update("""
          INSERT INTO scenario_levels (
            scenario_level_id, scenario_id, level_code, target_level, expression_count
          ) VALUES (?, ?, 'A2', 'A2', 0)
          """, UUID.fromString("51000000-0000-4000-8000-%012d".formatted(index)), scenarioId);
    }
  }

  private void clearSyntheticThemes() {
    jdbc.update("DELETE FROM scenario_levels WHERE scenario_id LIKE 'bulk_theme_%'");
    jdbc.update("DELETE FROM scenario_versions WHERE scenario_id LIKE 'bulk_theme_%'");
    jdbc.update("DELETE FROM scenarios WHERE scenario_id LIKE 'bulk_theme_%'");
  }

  private void insertScenarioVersion(UUID scenarioVersionId, String version, String publishedAt) {
    jdbc.update(
        "INSERT INTO scenario_versions (scenario_version_id, scenario_id, version, content_status, published_at) "
            + "VALUES (?, 'job_interview', ?, 'published', ?)",
        scenarioVersionId,
        version,
        publishedAt);
  }

  private void clearDeterministicScenarioVersions() {
    jdbc.update(
        "DELETE FROM scenario_versions WHERE scenario_version_id IN (?, ?, ?)",
        NULL_PUBLISHED_AT_VERSION_ID,
        TIED_VERSION_ASC_ID,
        TIED_VERSION_DESC_ID);
    CourseTestFixture.restoreScenarioFacts(jdbc);
  }

  private void insertSyntheticCourses(int count) {
    for (int index = 1; index <= count; index++) {
      UUID courseId = UUID.fromString("60000000-0000-4000-8000-%012d".formatted(index));
      UUID versionId = UUID.fromString("61000000-0000-4000-8000-%012d".formatted(index));
      UUID bindingId = UUID.fromString("62000000-0000-4000-8000-%012d".formatted(index));
      jdbc.update("""
          INSERT INTO content_course (
            course_id, scenario_id, slug, sort_order, created_at, updated_at
          ) VALUES (?, 'job_interview', ?, ?, TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00')
          """, courseId, "bulk-course-%02d".formatted(index), 100 + index);
      jdbc.update("""
          INSERT INTO content_course_version (
            course_version_id, course_id, version_key, title_en, summary_zh, cefr_level,
            duration_value, duration_unit, background_asset_ref, publication_status, published_at,
            superseded_at, current_published_marker, created_at, updated_at
          ) VALUES (?, ?, 'query-count-v1', ?, '查询数量测试数据。', 'A2', 5, 'minutes', NULL,
            'published', TIMESTAMP '2026-08-07 00:00:00', NULL, TRUE,
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00')
          """, versionId, courseId, "Bulk Course " + index);
      jdbc.update("""
          INSERT INTO content_course_content_binding (
            course_content_binding_id, course_version_id, scenario_version_id, scenario_level_id,
            created_at, updated_at
          ) VALUES (?, ?, '10000000-0000-0000-0000-000000000001',
            '20000000-0000-0000-0000-000000000001',
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00')
          """, bindingId, versionId);
    }
  }

  private void clearSyntheticCourses() {
    jdbc.update("""
        DELETE FROM content_course_content_binding
        WHERE course_version_id IN (
          SELECT version.course_version_id
          FROM content_course_version version
          JOIN content_course course ON course.course_id = version.course_id
          WHERE course.slug LIKE 'bulk-course-%'
        )
        """);
    jdbc.update("""
        DELETE FROM content_course_version
        WHERE course_id IN (SELECT course_id FROM content_course WHERE slug LIKE 'bulk-course-%')
        """);
    jdbc.update("DELETE FROM content_course WHERE slug LIKE 'bulk-course-%'");
  }
}
