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
            "audit_logs");
  }
}
