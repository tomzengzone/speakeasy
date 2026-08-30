package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.util.Arrays;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

class CoursePersistenceContractTest {
  @Test
  void migrationCreatesEmptySchemaAndCanonicalConstraints() throws Exception {
    String jdbcUrl = "jdbc:h2:mem:course_contract_" + System.nanoTime()
        + ";MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH;DB_CLOSE_DELAY=-1";
    Flyway flyway = Flyway.configure()
        .dataSource(jdbcUrl, "sa", "")
        .locations("classpath:db/migration")
        .load();

    assertThat(flyway.migrate().migrationsExecuted).isGreaterThan(0);
    assertThat(flyway.migrate().migrationsExecuted).isZero();

    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      assertThat(count(connection, "content_course")).isZero();
      assertThat(count(connection, "content_course_version")).isZero();
      assertThat(count(connection, "content_course_content_binding")).isZero();

      connection.createStatement().executeUpdate("""
          INSERT INTO content_course (
            course_id, scenario_id, slug, sort_order, created_at, updated_at
          ) VALUES (
            '40000000-0000-4000-8000-000000000001', 'job_interview', 'fixture-course', 10,
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """);

      assertThatThrownBy(() -> connection.createStatement().executeUpdate("""
          INSERT INTO content_course (
            course_id, scenario_id, slug, sort_order, created_at, updated_at
          ) VALUES (
            '40000000-0000-4000-8000-000000000097', 'job_interview', ' Fixture-Course ', 11,
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """)).isInstanceOf(Exception.class);

      assertThatThrownBy(() -> connection.createStatement().executeUpdate("""
          INSERT INTO content_course (
            course_id, scenario_id, slug, sort_order, created_at, updated_at
          ) VALUES (
            '40000000-0000-4000-8000-000000000099', 'job_interview', 'duplicate-order', 10,
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """)).isInstanceOf(Exception.class);

      connection.createStatement().executeUpdate("""
          INSERT INTO content_course_version (
            course_version_id, course_id, version_key, title_en, summary_zh, cefr_level,
            duration_value, duration_unit, publication_status, published_at,
            current_published_marker, created_at, updated_at
          ) VALUES (
            '41000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001',
            'fixture-v1', 'Fixture', '测试课程。', 'A2', 10, 'minutes', 'published',
            TIMESTAMP '2026-08-07 00:00:00', TRUE,
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """);

      assertThatThrownBy(() -> connection.createStatement().executeUpdate("""
          INSERT INTO content_course_version (
            course_version_id, course_id, version_key, title_en, summary_zh, cefr_level,
            duration_value, duration_unit, publication_status, published_at,
            current_published_marker, created_at, updated_at
          ) VALUES (
            '41000000-0000-4000-8000-000000000099', '40000000-0000-4000-8000-000000000001',
            'bad', 'Bad', 'Bad', 'L1', 0, ' ', 'published', TIMESTAMP '2026-08-07 00:00:00', TRUE,
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """)).isInstanceOf(Exception.class);

      connection.createStatement().executeUpdate("""
          INSERT INTO content_course_version (
            course_version_id, course_id, version_key, title_en, summary_zh, cefr_level,
            duration_value, duration_unit, publication_status, published_at, superseded_at,
            current_published_marker, created_at, updated_at
          ) VALUES (
            '41000000-0000-4000-8000-000000000098', '40000000-0000-4000-8000-000000000001',
            '2026.08-draft', 'Draft', '草稿。', 'A2', 10, 'minutes', 'draft', NULL, NULL, NULL,
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """);
      assertThatThrownBy(() -> connection.createStatement().executeUpdate("""
          UPDATE content_course_version
          SET publication_status = 'published', published_at = TIMESTAMP '2026-08-08 00:00:00',
              current_published_marker = TRUE
          WHERE course_version_id = '41000000-0000-4000-8000-000000000098'
          """)).isInstanceOf(Exception.class);

      connection.createStatement().executeUpdate("""
          INSERT INTO content_course_content_binding (
            course_content_binding_id, course_version_id, scenario_version_id, scenario_level_id, created_at, updated_at
          ) VALUES (
            '42000000-0000-4000-8000-000000000001', '41000000-0000-4000-8000-000000000001',
            '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """);

      assertThatThrownBy(() -> connection.createStatement().executeUpdate("""
          INSERT INTO content_course_content_binding (
            course_content_binding_id, course_version_id, scenario_version_id, scenario_level_id, created_at, updated_at
          ) VALUES (
            '42000000-0000-4000-8000-000000000098', '41000000-0000-4000-8000-000000000001',
            '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001',
            TIMESTAMP '2026-08-07 00:00:00', TIMESTAMP '2026-08-07 00:00:00'
          )
          """)).isInstanceOf(Exception.class);
    }

    assertThat(publicMethodNames(com.speakeasy.content.Course.class)).noneMatch(name -> name.startsWith("set"));
    assertThat(publicMethodNames(com.speakeasy.content.CourseVersion.class)).noneMatch(name -> name.startsWith("set"));
    assertThat(publicMethodNames(com.speakeasy.content.CourseContentBinding.class)).noneMatch(name -> name.startsWith("set"));
  }

  private java.util.List<String> publicMethodNames(Class<?> type) {
    return Arrays.stream(type.getDeclaredMethods())
        .filter(method -> java.lang.reflect.Modifier.isPublic(method.getModifiers()))
        .map(java.lang.reflect.Method::getName)
        .toList();
  }

  private long count(Connection connection, String table) throws Exception {
    try (ResultSet result = connection.createStatement().executeQuery("SELECT COUNT(*) FROM " + table)) {
      result.next();
      return result.getLong(1);
    }
  }

}
