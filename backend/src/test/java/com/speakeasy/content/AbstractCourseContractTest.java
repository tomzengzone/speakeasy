package com.speakeasy.content;

import com.speakeasy.BackendIntegrationTestSupport;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

abstract class AbstractCourseContractTest extends BackendIntegrationTestSupport {
  @Autowired protected JdbcTemplate jdbc;
  @Autowired private EntitlementSnapshotRepository entitlementSnapshots;

  @BeforeEach
  void restoreCourseFixtures() {
    CourseTestFixture.restore(jdbc);
  }

  @AfterEach
  void clearCourseFixtures() {
    try {
      CourseTestFixture.clear(jdbc);
    } finally {
      CourseTestFixture.restoreScenarioFacts(jdbc);
    }
  }

  protected void grantAdvanced(AuthTokens tokens) {
    entitlementSnapshots.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        UUID.fromString(tokens.userId()),
        "pro",
        "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
        "{\"ai\":100,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}",
        Instant.now().plusSeconds(30)));
  }

  protected void saveMalformedEntitlement(AuthTokens tokens) {
    entitlementSnapshots.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        UUID.fromString(tokens.userId()),
        "pro",
        "{malformed",
        "{}",
        Instant.now().plusSeconds(30)));
  }

  protected void saveContentEntitlement(AuthTokens tokens, boolean basic, boolean advanced) {
    entitlementSnapshots.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        UUID.fromString(tokens.userId()),
        "fixture",
        "{\"basic_scenarios\":" + basic + ",\"advanced_scenarios\":" + advanced + "}",
        "{}",
        Instant.now().plusSeconds(30)));
  }
}
