package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
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
            "goal_autopilot_control_idempotency",
            "goal_progress_forecasts",
            "goal_outcome_checkpoints");
  }
}
