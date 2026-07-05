package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.util.List;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("test")
class FoundationMigrationTest {
  @Autowired JdbcTemplate jdbc;

  @Test
  void pbP0FoundationTablesExist() {
    List<String> tables = jdbc.queryForList(
        "select table_name from information_schema.tables where table_schema = 'public'",
        String.class);

    assertThat(tables)
        .contains(
            "user_accounts",
            "auth_identities",
            "auth_sessions",
            "user_profiles",
            "onboarding_assessments",
            "learning_routes",
            "user_scenario_states",
            "practice_sessions",
            "practice_turns",
            "coach_feedbacks",
            "session_summaries",
            "practice_queue_items",
            "expression_practice_attempts",
            "favorite_expressions",
            "learning_evidences",
            "mastery_records",
            "review_items",
            "saved_expressions",
            "learning_history_entries",
            "scenarios",
            "scenario_versions",
            "scenario_levels",
            "target_expressions",
            "subscription_plans",
            "purchases",
            "subscriptions",
            "entitlement_snapshots",
            "usage_ledgers",
            "usage_reservations",
            "payment_provider_events",
            "account_deletion_jobs",
            "audit_logs",
            "goal_profiles",
            "goal_diagnostic_assessments",
            "goal_mastery_initial_states",
            "goal_backplans",
            "goal_daily_plans",
            "goal_plan_items",
            "goal_autopilot_controls",
            "goal_autopilot_goal_idempotency",
            "goal_autopilot_control_idempotency",
            "goal_notification_outbox_records",
            "goal_planner_replay_audits",
            "goal_progress_forecasts",
            "goal_outcome_checkpoints");
  }

  @Test
  void xcb005GoalProfileUniqueMigrationPrunesLegacyDuplicateRows() throws Exception {
    String dbName = "xcb005_migration_" + System.nanoTime();
    String jdbcUrl = "jdbc:h2:mem:%s;MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1".formatted(dbName);

    Flyway.configure()
        .dataSource(jdbcUrl, "sa", "")
        .locations("classpath:db/migration")
        .target("202606100002")
        .load()
        .migrate();

    String userId = "00000000-0000-0000-0000-000000000501";
    String legacyProfileId = "00000000-0000-0000-0000-000000000601";
    String canonicalProfileId = "00000000-0000-0000-0000-000000000602";
    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      connection
          .createStatement()
          .executeUpdate(
              """
              INSERT INTO user_accounts (
                user_id, display_name, avatar_ref, locale, account_status, onboarding_status, created_at, updated_at
              ) VALUES (
                '%s', 'Migration User', NULL, 'zh-CN', 'active', 'completed',
                TIMESTAMP '2026-06-09 08:00:00', TIMESTAMP '2026-06-09 08:00:00'
              )
              """
                  .formatted(userId));
      insertGoalProfile(connection, legacyProfileId, userId, "2026-06-09 08:00:00");
      insertGoalProfile(connection, canonicalProfileId, userId, "2026-06-10 08:00:00");
      connection
          .createStatement()
          .executeUpdate(
              """
              INSERT INTO goal_diagnostic_assessments (
                diagnostic_assessment_id, goal_profile_id, user_id, status, confidence_band, sample_count,
                rubric_scores_json, weakness_tags_json, claim_guard_json, reason_code, created_at
              ) VALUES (
                '00000000-0000-0000-0000-000000000701', '%s', '%s', 'completed', 'low', 1,
                '{}', '[]', '{}', 'legacy_duplicate', TIMESTAMP '2026-06-09 08:05:00'
              )
              """
                  .formatted(legacyProfileId, userId));
    }

    Flyway.configure()
        .dataSource(jdbcUrl, "sa", "")
        .locations("classpath:db/migration")
        .load()
        .migrate();

    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      assertThat(countRows(connection, "goal_profiles", "user_id", userId)).isEqualTo(1);
      assertThat(singleValue(connection, "SELECT goal_profile_id FROM goal_profiles WHERE user_id = '%s'".formatted(userId)))
          .isEqualTo(canonicalProfileId);
      assertThat(countRows(connection, "goal_diagnostic_assessments", "goal_profile_id", legacyProfileId)).isZero();
    }
  }

  private void insertGoalProfile(Connection connection, String profileId, String userId, String updatedAt) throws Exception {
    connection
        .createStatement()
        .executeUpdate(
            """
            INSERT INTO goal_profiles (
              goal_profile_id, user_id, goal_type, target_score, target_ability, deadline,
              daily_minutes, intensity_preference, support_status, status, revision,
              limitation_message, quiet_hours_start, quiet_hours_end, notification_consent,
              created_at, updated_at
            ) VALUES (
              '%s', '%s', 'ielts_speaking', 7.5, 'speaking fluency', DATE '2026-08-31',
              30, 'standard', 'supported', 'active', 1,
              '', '22:00', '08:00', TRUE,
              TIMESTAMP '2026-06-09 08:00:00', TIMESTAMP '%s'
            )
            """
                .formatted(profileId, userId, updatedAt));
  }

  private long countRows(Connection connection, String tableName, String columnName, String value) throws Exception {
    try (ResultSet rs =
        connection.createStatement().executeQuery(
            "SELECT COUNT(*) FROM %s WHERE %s = '%s'".formatted(tableName, columnName, value))) {
      rs.next();
      return rs.getLong(1);
    }
  }

  private String singleValue(Connection connection, String query) throws Exception {
    try (ResultSet rs = connection.createStatement().executeQuery(query)) {
      rs.next();
      return rs.getString(1);
    }
  }
}
