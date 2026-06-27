package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.net.ServerSocket;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.testcontainers.postgresql.PostgreSQLContainer;

class PostgresFoundationMigrationTest {
  @TempDir Path tempDir;

  @Test
  void pbP0FoundationMigrationAppliesOnPostgres() throws Exception {
    Optional<PostgresTarget> maybeTarget = startDockerPostgres().or(this::startLocalPostgres);
    Assumptions.assumeTrue(maybeTarget.isPresent(), "No Docker daemon or local PostgreSQL binary available.");

    try (PostgresTarget postgres = maybeTarget.orElseThrow()) {
      runMigrationAndAssertTables(postgres);
    }
  }

  private Optional<PostgresTarget> startDockerPostgres() {
    if (!isDockerLikelyAvailable()) {
      return Optional.empty();
    }

    try {
      PostgreSQLContainer postgres =
          new PostgreSQLContainer("postgres:15")
              .withDatabaseName("speakeasy_test")
              .withUsername("speakeasy")
              .withPassword("speakeasy");
      postgres.start();
      return Optional.of(new ContainerPostgresTarget(postgres));
    } catch (RuntimeException | Error ignored) {
      return Optional.empty();
    }
  }

  private Optional<PostgresTarget> startLocalPostgres() {
    Process process = null;
    Optional<Path> initdb = findExecutable("initdb");
    Optional<Path> postgres = findExecutable("postgres");
    if (initdb.isEmpty() || postgres.isEmpty()) {
      return Optional.empty();
    }

    try {
      Path dataDir = tempDir.resolve("pgdata");
      Path logFile = tempDir.resolve("postgres.log");
      runCommand(initdb.get().toString(), "-D", dataDir.toString(), "-A", "trust", "-U", "speakeasy");

      int port = freePort();
      process =
          new ProcessBuilder(
                  postgres.get().toString(),
                  "-D",
                  dataDir.toString(),
                  "-p",
                  String.valueOf(port),
                  "-h",
                  "127.0.0.1",
                  "-c",
                  "fsync=off",
                  "-c",
                  "full_page_writes=off")
              .redirectErrorStream(true)
              .redirectOutput(logFile.toFile())
              .start();
      String jdbcUrl = "jdbc:postgresql://127.0.0.1:%d/postgres".formatted(port);
      waitForPostgres(jdbcUrl, "speakeasy", "");
      return Optional.of(new ProcessPostgresTarget(process, jdbcUrl, "speakeasy", ""));
    } catch (Exception exception) {
      if (process != null) {
        stopProcess(process);
      }
      if (exception instanceof InterruptedException) {
        Thread.currentThread().interrupt();
      }
      return Optional.empty();
    }
  }

  private void runMigrationAndAssertTables(PostgresTarget postgres) throws SQLException {
    Flyway.configure()
        .dataSource(postgres.jdbcUrl(), postgres.username(), postgres.password())
        .locations("classpath:db/migration")
        .load()
        .migrate();

    try (Connection connection = DriverManager.getConnection(postgres.jdbcUrl(), postgres.username(), postgres.password())) {
      assertThat(publicTables(connection))
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
              "audit_logs");
    }
  }

  private boolean isDockerLikelyAvailable() {
    String dockerHost = System.getenv("DOCKER_HOST");
    return dockerHost != null && !dockerHost.isBlank()
        || Files.exists(Path.of("/var/run/docker.sock"))
        || Files.exists(Path.of(System.getProperty("user.home"), ".docker/run/docker.sock"))
        || findExecutable("docker").isPresent();
  }

  private Optional<Path> findExecutable(String name) {
    List<Path> candidates = new ArrayList<>();
    String path = System.getenv("PATH");
    if (path != null) {
      for (String entry : path.split(System.getProperty("path.separator"))) {
        candidates.add(Path.of(entry, name));
      }
    }
    candidates.add(Path.of("/opt/homebrew/opt/postgresql@15/bin", name));
    candidates.add(Path.of("/opt/homebrew/opt/postgresql@16/bin", name));
    candidates.add(Path.of("/usr/local/opt/postgresql@15/bin", name));
    candidates.add(Path.of("/usr/local/opt/postgresql@16/bin", name));
    return candidates.stream().filter(Files::isExecutable).findFirst();
  }

  private void runCommand(String... command) throws IOException, InterruptedException {
    Process process = new ProcessBuilder(command).redirectErrorStream(true).start();
    boolean exited = process.waitFor(30, TimeUnit.SECONDS);
    if (!exited || process.exitValue() != 0) {
      process.destroyForcibly();
      throw new IllegalStateException("Command failed: " + String.join(" ", command));
    }
  }

  private int freePort() throws IOException {
    try (ServerSocket socket = new ServerSocket(0)) {
      return socket.getLocalPort();
    }
  }

  private void waitForPostgres(String jdbcUrl, String username, String password) throws Exception {
    long deadline = System.nanoTime() + Duration.ofSeconds(20).toNanos();
    while (System.nanoTime() < deadline) {
      try (Connection ignored = DriverManager.getConnection(jdbcUrl, username, password)) {
        return;
      } catch (SQLException ignored) {
        Thread.sleep(250);
      }
    }
    throw new IllegalStateException("PostgreSQL did not become ready.");
  }

  private static void stopProcess(Process process) {
    process.destroy();
    try {
      if (!process.waitFor(5, TimeUnit.SECONDS)) {
        process.destroyForcibly();
      }
    } catch (InterruptedException interrupted) {
      process.destroyForcibly();
      Thread.currentThread().interrupt();
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

  private interface PostgresTarget extends AutoCloseable {
    String jdbcUrl();

    String username();

    String password();
  }

  private record ContainerPostgresTarget(PostgreSQLContainer container) implements PostgresTarget {
    @Override
    public String jdbcUrl() {
      return container.getJdbcUrl();
    }

    @Override
    public String username() {
      return container.getUsername();
    }

    @Override
    public String password() {
      return container.getPassword();
    }

    @Override
    public void close() {
      container.stop();
    }
  }

  private record ProcessPostgresTarget(Process process, String jdbcUrl, String username, String password)
      implements PostgresTarget {
    @Override
    public void close() throws Exception {
      stopProcess(process);
    }
  }
}
