package com.speakeasy.ops;

import com.speakeasy.common.ApiException;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountDeletionService {
  private final UserAccountRepository users;
  private final AccountDeletionJobRepository deletionJobs;
  private final AuditLogRepository auditLogs;
  private final AuthService authService;
  private final JdbcTemplate jdbcTemplate;
  private final Clock clock;

  public AccountDeletionService(
      UserAccountRepository users,
      AccountDeletionJobRepository deletionJobs,
      AuditLogRepository auditLogs,
      AuthService authService,
      JdbcTemplate jdbcTemplate,
      Clock clock) {
    this.users = users;
    this.deletionJobs = deletionJobs;
    this.auditLogs = auditLogs;
    this.authService = authService;
    this.jdbcTemplate = jdbcTemplate;
    this.clock = clock;
  }

  @Transactional
  public AccountDeletionJob requestDeletion(UUID userId, String idempotencyKey, String requestId) {
    if (idempotencyKey == null || idempotencyKey.length() < 8 || idempotencyKey.length() > 128) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
    }
    Instant now = Instant.now(clock);
    UserAccount user = users.findById(userId)
        .filter(candidate -> "active".equals(candidate.getAccountStatus()) || "deletion_requested".equals(candidate.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
    AccountDeletionJob job = deletionJobs.save(new AccountDeletionJob(UUID.randomUUID(), userId, now));
    user.requestDeletion(now);
    authService.revokeUserSessions(userId);
    purgeUserOwnedData(userId);
    user.markDeleted(now);
    job.complete(now);
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "user",
        userId.toString(),
        "account_deletion_completed",
        "user:" + userId,
        "{\"learning_data\":\"deleted_or_anonymized\",\"sessions\":\"revoked\"}",
        requestId,
        now));
    return deletionJobs.save(job);
  }

  @Transactional(readOnly = true)
  public AccountDeletionJob latestDeletionJob(UUID userId) {
    return deletionJobs.findFirstByUserIdOrderByRequestedAtDesc(userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Deletion job was not found."));
  }

  private void purgeUserOwnedData(UUID userId) {
    delete("expression_practice_attempts", userId);
    delete("favorite_expressions", userId);
    delete("practice_queue_items", userId);
    delete("review_items", userId);
    delete("saved_expressions", userId);
    delete("mastery_records", userId);
    delete("learning_history_entries", userId);
    delete("learning_evidences", userId);
    delete("session_summaries", userId);
    delete("practice_turns", userId);
    delete("practice_sessions", userId);
    delete("user_scenario_states", userId);
    delete("learning_routes", userId);
    delete("onboarding_assessments", userId);
    delete("entitlement_snapshots", userId);
    delete("subscriptions", userId);
    delete("purchases", userId);
    delete("usage_reservations", userId);
    delete("usage_ledgers", userId);
    delete("auth_identities", userId);
    delete("user_profiles", userId);
  }

  private void delete(String tableName, UUID userId) {
    jdbcTemplate.update("DELETE FROM " + tableName + " WHERE user_id = ?", userId);
  }
}
