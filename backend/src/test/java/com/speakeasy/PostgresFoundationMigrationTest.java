package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.Set;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@Testcontainers
class PostgresFoundationMigrationTest {
  @Container
  static final PostgreSQLContainer postgres =
      new PostgreSQLContainer("postgres:15")
          .withDatabaseName("speakeasy_test")
          .withUsername("speakeasy")
          .withPassword("speakeasy");

  @Test
  void pbP0FoundationMigrationAppliesOnPostgres() throws SQLException {
    Flyway.configure()
        .dataSource(postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword())
        .locations("classpath:db/migration")
        .load()
        .migrate();

    try (Connection connection =
        DriverManager.getConnection(postgres.getJdbcUrl(), postgres.getUsername(), postgres.getPassword())) {
      assertThat(publicTables(connection))
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

  private Set<String> publicTables(Connection connection) throws SQLException {
    Set<String> tables = new HashSet<>();
    try (ResultSet rs =
        connection
            .createStatement()
            .executeQuery("select table_name from information_schema.tables where table_schema = 'public'")) {
      while (rs.next()) {
        tables.add(rs.getString("table_name"));
      }
    }
    return tables;
  }
}
