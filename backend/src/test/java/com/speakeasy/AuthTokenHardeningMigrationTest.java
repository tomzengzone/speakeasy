package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

class AuthTokenHardeningMigrationTest {
  @Test
  void migrationBackfillsCanonicalTokensDropsSessionHashesAndCreatesIndexes() throws Exception {
    String database = "auth_token_hardening_" + System.nanoTime();
    String jdbcUrl = "jdbc:h2:mem:%s;MODE=PostgreSQL;DATABASE_TO_UPPER=false;DB_CLOSE_DELAY=-1".formatted(database);

    Flyway.configure()
        .dataSource(jdbcUrl, "sa", "")
        .locations("classpath:db/migration")
        .target("202608290001")
        .load()
        .migrate();

    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      connection.createStatement().executeUpdate("""
          INSERT INTO user_accounts (
            user_id, display_name, locale, account_status, onboarding_status, created_at, updated_at,
            security_epoch
          ) VALUES (
            '00000000-0000-0000-0000-000000000901', 'Legacy Auth User', 'zh-CN', 'active', 'complete',
            TIMESTAMP '2026-08-29 08:00:00', TIMESTAMP '2026-08-29 08:00:00', 0
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO auth_sessions (
            session_id, user_id, access_token_hash, refresh_token_hash, status, issued_at, expires_at,
            refresh_expires_at, refresh_token_family_id, device_name, platform, created_at, last_active_at,
            idle_expires_at, absolute_expires_at, security_epoch
          ) VALUES (
            '00000000-0000-0000-0000-000000000902', '00000000-0000-0000-0000-000000000901',
            'legacy-access-hash', 'legacy-refresh-hash', 'active', TIMESTAMP '2026-08-29 08:00:00',
            TIMESTAMP '2026-08-29 08:15:00', TIMESTAMP '2026-09-28 08:00:00',
            '00000000-0000-0000-0000-000000000902', 'Legacy device', 'android',
            TIMESTAMP '2026-08-29 08:00:00', TIMESTAMP '2026-08-29 08:00:00',
            TIMESTAMP '2026-09-28 08:00:00', TIMESTAMP '2026-11-27 08:00:00', 0
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO auth_refresh_token_families (
            family_id, session_id, user_id, status, created_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000902', '00000000-0000-0000-0000-000000000902',
            '00000000-0000-0000-0000-000000000901', 'active', TIMESTAMP '2026-08-29 08:00:00'
          )
          """);
      connection.createStatement().executeUpdate("""
          INSERT INTO auth_refresh_tokens (
            token_id, family_id, session_id, user_id, token_hash, status, issued_at, expires_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000902', '00000000-0000-0000-0000-000000000902',
            '00000000-0000-0000-0000-000000000902', '00000000-0000-0000-0000-000000000901',
            'legacy-refresh-hash', 'active', TIMESTAMP '2026-08-29 08:00:00', TIMESTAMP '2026-09-28 08:00:00'
          )
          """);
    }

    Flyway.configure().dataSource(jdbcUrl, "sa", "").locations("classpath:db/migration").load().migrate();

    try (Connection connection = DriverManager.getConnection(jdbcUrl, "sa", "")) {
      assertThat(value(connection,
          "SELECT token_hash FROM auth_access_tokens WHERE session_id = '00000000-0000-0000-0000-000000000902'"))
          .isEqualTo("legacy-access-hash");
      assertThat(value(connection,
          "SELECT client_id FROM auth_refresh_token_families WHERE family_id = '00000000-0000-0000-0000-000000000902'"))
          .isEqualTo("speakeasy-mobile");
      assertThat(value(connection,
          "SELECT audience FROM auth_refresh_token_families WHERE family_id = '00000000-0000-0000-0000-000000000902'"))
          .isEqualTo("speakeasy-api");
      assertThat(columnExists(connection, "auth_sessions", "access_token_hash")).isFalse();
      assertThat(columnExists(connection, "auth_sessions", "refresh_token_hash")).isFalse();
      assertThat(indexExists(connection, "idx_auth_access_tokens_session")).isTrue();
      assertThat(indexExists(connection, "idx_auth_access_tokens_status_expires")).isTrue();
      assertThatThrownBy(() -> connection.createStatement().executeUpdate("""
          INSERT INTO auth_access_tokens (
            token_id, token_hash, session_id, user_id, client_id, audience, scope, status, issued_at, expires_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000903', 'legacy-access-hash',
            '00000000-0000-0000-0000-000000000902', '00000000-0000-0000-0000-000000000901',
            'speakeasy-mobile', 'speakeasy-api', 'user:read', 'active',
            TIMESTAMP '2026-08-29 08:01:00', TIMESTAMP '2026-08-29 08:16:00'
          )
          """)).isInstanceOf(Exception.class);
    }
  }

  private String value(Connection connection, String sql) throws Exception {
    try (ResultSet result = connection.createStatement().executeQuery(sql)) {
      assertThat(result.next()).isTrue();
      return result.getString(1);
    }
  }

  private boolean columnExists(Connection connection, String table, String column) throws Exception {
    try (ResultSet result = connection.getMetaData().getColumns(null, null, table, column)) {
      return result.next();
    }
  }

  private boolean indexExists(Connection connection, String index) throws Exception {
    try (ResultSet result = connection.getMetaData().getIndexInfo(null, null, "auth_access_tokens", false, false)) {
      while (result.next()) {
        if (index.equalsIgnoreCase(result.getString("INDEX_NAME"))) return true;
      }
      return false;
    }
  }
}
