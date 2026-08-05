package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

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

  @Test
  void strictCefrMigrationRewritesEveryApiFacingLevelFactAndAddsConstraints() throws Exception {
    String dbName = "cefr_migration_" + System.nanoTime();
    String jdbcUrl = "jdbc:h2:mem:%s;MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1".formatted(dbName);

    Flyway.configure()
        .dataSource(jdbcUrl, "sa", "")
        .locations("classpath:db/migration")
        .target("202606110001")
        .load()
        .migrate();

    String userId = "00000000-0000-0000-0000-000000000801";
    String assessmentId = "00000000-0000-0000-0000-000000000802";
    String goalProfileId = "00000000-0000-0000-0000-000000000803";
    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      connection.createStatement().executeUpdate("""
          INSERT INTO user_accounts (
            user_id, display_name, avatar_ref, locale, account_status, onboarding_status, created_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000801', 'CEFR Migration User', NULL, 'zh-CN', 'active', 'complete',
            TIMESTAMP '2026-08-05 08:00:00', TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO user_profiles (user_id, nickname, target_level, daily_minutes, updated_at)
          VALUES ('00000000-0000-0000-0000-000000000801', 'CEFR', 'L1', 10, TIMESTAMP '2026-08-05 08:00:00')
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO onboarding_assessments (
            assessment_id, user_id, goal_direction, pain_points, output_level, daily_minutes, completed_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000802', '00000000-0000-0000-0000-000000000801',
            'job_interview', 'opening', 'L2', 10, TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO learning_routes (
            route_id, user_id, current_scenario_id, target_level, source_assessment_id, created_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000804', '00000000-0000-0000-0000-000000000801',
            'job_interview', 'L3', '00000000-0000-0000-0000-000000000802',
            TIMESTAMP '2026-08-05 08:00:00', TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO user_scenario_states (
            user_scenario_state_id, user_id, scenario_id, state, current_flag, target_level, joined_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000805', '00000000-0000-0000-0000-000000000801',
            'job_interview', 'joined', TRUE, 'L1', TIMESTAMP '2026-08-05 08:00:00', TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO practice_sessions (
            practice_session_id, user_id, scenario_id, level_code, status, current_turn_index, started_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000806', '00000000-0000-0000-0000-000000000801',
            'job_interview', 'L2', 'active', 0, TIMESTAMP '2026-08-05 08:00:00', TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO training_content_mappings (
            mapping_id, scenario_id, scenario_version_id, level_code, mapping_version, action_chain_version,
            step_key, micro_action, order_index, target_expression_id, prompt_text, review_status, created_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000807', 'job_interview',
            '10000000-0000-0000-0000-000000000001', 'L3', 'cefr-migration', 'v1',
            'opening', 'SayOne', 0, '30000000-0000-0000-0000-000000000005', 'prompt', 'reviewed',
            TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO training_sessions (
            training_session_id, user_id, scenario_id, scenario_version_id, level_code, mapping_version,
            action_chain_version, status, current_turn_index, current_step_key, current_micro_action, hint_level,
            failure_count, success_count, evidence_write_status, sync_status, started_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000808', '00000000-0000-0000-0000-000000000801',
            'job_interview', '10000000-0000-0000-0000-000000000001', 'L1', 'cefr-migration',
            'v1', 'ready', 0, 'opening', 'SayOne', 'sentence_frame', 0, 0, 'not_started', 'synced',
            TIMESTAMP '2026-08-05 08:00:00', TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      insertGoalProfile(connection, goalProfileId, userId, "2026-08-05 08:00:00");
      connection.createStatement().executeUpdate("""
          INSERT INTO goal_mastery_initial_states (
            state_id, goal_profile_id, user_id, dimension_key, initial_level, evidence_ref, source, created_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000809', '00000000-0000-0000-0000-000000000803',
            '00000000-0000-0000-0000-000000000801', 'speaking', 'L1', 'evidence-1', 'diagnostic',
            TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
    }

    Flyway.configure()
        .dataSource(jdbcUrl, "sa", "")
        .locations("classpath:db/migration")
        .load()
        .migrate();

    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      assertThat(singleValue(connection, "SELECT target_level FROM user_profiles WHERE user_id = '" + userId + "'"))
          .isEqualTo("A2");
      assertThat(singleValue(connection, "SELECT output_level FROM onboarding_assessments WHERE assessment_id = '" + assessmentId + "'"))
          .isEqualTo("B1");
      assertThat(singleValue(connection, "SELECT target_level FROM learning_routes WHERE user_id = '" + userId + "'"))
          .isEqualTo("B2");
      assertThat(singleValue(connection, "SELECT target_level FROM user_scenario_states WHERE user_id = '" + userId + "'"))
          .isEqualTo("A2");
      assertThat(singleValue(connection, "SELECT level_code FROM practice_sessions WHERE user_id = '" + userId + "'"))
          .isEqualTo("B1");
      assertThat(singleValue(connection, "SELECT level_code FROM training_content_mappings WHERE mapping_id = '00000000-0000-0000-0000-000000000807'"))
          .isEqualTo("B2");
      assertThat(singleValue(connection, "SELECT level_code FROM training_sessions WHERE user_id = '" + userId + "'"))
          .isEqualTo("A2");
      assertThat(singleValue(connection, "SELECT initial_level FROM goal_mastery_initial_states WHERE user_id = '" + userId + "'"))
          .isEqualTo("L1");
      assertThat(singleValue(connection, "SELECT COUNT(*) FROM scenario_levels WHERE level_code IN ('L1', 'L2', 'L3')"))
          .isEqualTo("0");
      assertThat(singleValue(connection, "SELECT COUNT(*) FROM target_expressions WHERE level_code IN ('L1', 'L2', 'L3')"))
          .isEqualTo("0");

      assertLegacyRejected(connection, "user_profiles", "target_level", "user_id = '" + userId + "'");
      assertLegacyRejected(connection, "onboarding_assessments", "output_level", "assessment_id = '" + assessmentId + "'");
      assertLegacyRejected(connection, "learning_routes", "target_level", "user_id = '" + userId + "'");
      assertLegacyRejected(connection, "user_scenario_states", "target_level", "user_id = '" + userId + "'");
      assertLegacyRejected(connection, "scenario_levels", "level_code", "scenario_level_id = '20000000-0000-0000-0000-000000000001'");
      assertLegacyRejected(connection, "target_expressions", "level_code", "target_expression_id = '30000000-0000-0000-0000-000000000001'");
      assertLegacyRejected(connection, "practice_sessions", "level_code", "user_id = '" + userId + "'");
      assertLegacyRejected(connection, "training_content_mappings", "level_code", "mapping_id = '00000000-0000-0000-0000-000000000807'");
      assertLegacyRejected(connection, "training_sessions", "level_code", "user_id = '" + userId + "'");
      assertThatThrownBy(() -> connection.createStatement().executeUpdate(
              "UPDATE scenario_levels SET target_level = 'C1' WHERE scenario_level_id = '20000000-0000-0000-0000-000000000001'"))
          .isInstanceOf(Exception.class);
    }
  }

  @Test
  void strictCefrMigrationFailsForUnexpectedAliasDataInsteadOfGuessingItsMeaning() throws Exception {
    String dbName = "cefr_alias_failure_" + System.nanoTime();
    String jdbcUrl = "jdbc:h2:mem:%s;MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1".formatted(dbName);

    Flyway.configure()
        .dataSource(jdbcUrl, "sa", "")
        .locations("classpath:db/migration")
        .target("202606110001")
        .load()
        .migrate();

    String userId = "00000000-0000-0000-0000-000000000811";
    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      connection.createStatement().executeUpdate("""
          INSERT INTO user_accounts (
            user_id, display_name, avatar_ref, locale, account_status, onboarding_status, created_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000811', 'Unexpected Alias User', NULL, 'zh-CN', 'active', 'complete',
            TIMESTAMP '2026-08-05 08:00:00', TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO user_profiles (user_id, nickname, target_level, daily_minutes, updated_at)
          VALUES (
            '00000000-0000-0000-0000-000000000811', 'Alias', 'beginner', 10, TIMESTAMP '2026-08-05 08:00:00'
          )
          """);
    }

    assertThatThrownBy(() -> Flyway.configure()
            .dataSource(jdbcUrl, "sa", "")
            .locations("classpath:db/migration")
            .load()
            .migrate())
        .hasMessageContaining("ck_user_profiles_target_level_cefr");

    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      assertThat(singleValue(connection, "SELECT target_level FROM user_profiles WHERE user_id = '" + userId + "'"))
          .isEqualTo("beginner");
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

  private void assertLegacyRejected(Connection connection, String tableName, String columnName, String whereClause) {
    assertThatThrownBy(() -> connection.createStatement().executeUpdate(
            "UPDATE %s SET %s = 'L1' WHERE %s".formatted(tableName, columnName, whereClause)))
        .isInstanceOf(Exception.class);
  }

  private String singleValue(Connection connection, String query) throws Exception {
    try (ResultSet rs = connection.createStatement().executeQuery(query)) {
      rs.next();
      return rs.getString(1);
    }
  }
}
