package com.speakeasy.ops;

import com.speakeasy.common.ApiException;
import com.speakeasy.goal.GoalAutopilotTelemetryService;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AccountDeletionService {
  private static final Set<String> IN_PROGRESS_STATUSES = Set.of(
      "requested",
      "access_revoked",
      "deleting_learning_data",
      "anonymizing_audit_refs");

  private final UserAccountRepository users;
  private final AccountDeletionJobRepository deletionJobs;
  private final AccountDeletionRetryIdempotencyRepository retryIdempotency;
  private final AuditLogRepository auditLogs;
  private final AuthService authService;
  private final AccountDeletionRetentionRunner retentionRunner;
  private final GoalAutopilotTelemetryService goalAutopilotTelemetryService;
  private final JdbcTemplate jdbcTemplate;
  private final Clock clock;

  public AccountDeletionService(
      UserAccountRepository users,
      AccountDeletionJobRepository deletionJobs,
      AccountDeletionRetryIdempotencyRepository retryIdempotency,
      AuditLogRepository auditLogs,
      AuthService authService,
      AccountDeletionRetentionRunner retentionRunner,
      GoalAutopilotTelemetryService goalAutopilotTelemetryService,
      JdbcTemplate jdbcTemplate,
      Clock clock) {
    this.users = users;
    this.deletionJobs = deletionJobs;
    this.retryIdempotency = retryIdempotency;
    this.auditLogs = auditLogs;
    this.authService = authService;
    this.retentionRunner = retentionRunner;
    this.goalAutopilotTelemetryService = goalAutopilotTelemetryService;
    this.jdbcTemplate = jdbcTemplate;
    this.clock = clock;
  }

  @Transactional
  public AccountDeletionJob requestDeletion(UUID userId, String idempotencyKey, String requestId) {
    requireIdempotencyKey(idempotencyKey);
    AccountDeletionJob existingJob = deletionJobs.findByUserIdAndIdempotencyKey(userId, idempotencyKey).orElse(null);
    if (existingJob != null) {
      return existingJob;
    }
    Instant now = Instant.now(clock);
    UserAccount user = users.findById(userId)
        .filter(candidate -> "active".equals(candidate.getAccountStatus()) || "deletion_requested".equals(candidate.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
    AccountDeletionJob job = deletionJobs.save(new AccountDeletionJob(UUID.randomUUID(), userId, idempotencyKey, now));
    return runDeletionJob(job, user, requestId, null);
  }

  @Transactional(readOnly = true)
  public AccountDeletionJob latestDeletionJob(UUID userId) {
    return deletionJobs.findFirstByUserIdOrderByRequestedAtDesc(userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Deletion job was not found."));
  }

  @Transactional
  public AccountDeletionJob retryDeletionJob(String jobId, String idempotencyKey, String requestId) {
    requireIdempotencyKey(idempotencyKey);
    UUID deletionJobId = parseDeletionJobId(jobId);
    AccountDeletionJob job = deletionJobs.findByIdForUpdate(deletionJobId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Deletion job was not found."));

    AccountDeletionRetryIdempotency existingRetry =
        retryIdempotency.findByDeletionJobIdAndIdempotencyKey(deletionJobId, idempotencyKey).orElse(null);
    if (existingRetry != null || "completed".equals(job.getStatus())) {
      return job;
    }
    if (IN_PROGRESS_STATUSES.contains(job.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "DELETE_IN_PROGRESS", "Deletion job is already in progress.");
    }
    if (!"failed".equals(job.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Deletion job cannot be retried from its current state.");
    }

    Instant now = Instant.now(clock);
    AccountDeletionRetryIdempotency retry = retryIdempotency.save(new AccountDeletionRetryIdempotency(
        UUID.randomUUID(), deletionJobId, idempotencyKey, now));
    job.markRetryStarted();
    deletionJobs.save(job);
    auditRetryRequested(job, retry, requestId, now);

    UserAccount user = users.findById(job.getUserId())
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Deletion job user was not found."));
    return runDeletionJob(job, user, requestId, retry);
  }

  private AccountDeletionJob runDeletionJob(
      AccountDeletionJob job,
      UserAccount user,
      String requestId,
      AccountDeletionRetryIdempotency retry) {
    try {
      Instant accessRevokedAt = Instant.now(clock);
      if (!"deleted".equals(user.getAccountStatus())) {
        user.requestDeletion(accessRevokedAt);
      }
      job.markAccessRevoked();
      deletionJobs.save(job);
      authService.revokeUserSessions(job.getUserId());

      job.markDeletingLearningData();
      deletionJobs.save(job);
      var aiRetentionJob = retentionRunner.runAccountDeletion(
          job.getUserId(), aiRetentionIdempotencyKey(job, retry), requestId);
      purgeUserOwnedData(job.getUserId());

      job.markAnonymizingAuditRefs();
      deletionJobs.save(job);
      Instant completedAt = Instant.now(clock);
      user.markDeleted(completedAt);
      job.complete(completedAt);
      if (retry != null) {
        retry.complete(completedAt);
        retryIdempotency.save(retry);
      }
      auditCompleted(job, aiRetentionJob.getRedactedEvidenceRef(), requestId, completedAt, retry != null);
      return deletionJobs.save(job);
    } catch (RuntimeException exception) {
      Instant failedAt = Instant.now(clock);
      String reason = failureReason(exception);
      job.fail(reason);
      if (retry != null) {
        retry.fail(reason, failedAt);
        retryIdempotency.save(retry);
      }
      auditFailed(job, reason, requestId, failedAt, retry != null);
      return deletionJobs.save(job);
    }
  }

  private void purgeUserOwnedData(UUID userId) {
    delete("expression_practice_attempts", userId);
    delete("goal_outcome_checkpoints", userId);
    delete("goal_progress_forecasts", userId);
    goalAutopilotTelemetryService.deleteByUserHash(userId);
    delete("goal_planner_replay_audits", userId);
    delete("goal_notification_outbox_records", userId);
    delete("goal_mastery_transition_decisions", userId);
    delete("goal_recovery_plan_decisions", userId);
    delete("goal_autopilot_goal_idempotency", userId);
    delete("goal_autopilot_control_idempotency", userId);
    delete("goal_autopilot_controls", userId);
    delete("goal_plan_items", userId);
    delete("goal_daily_plans", userId);
    delete("goal_backplans", userId);
    delete("goal_mastery_initial_states", userId);
    delete("goal_diagnostic_assessments", userId);
    delete("goal_profiles", userId);
    delete("favorite_expressions", userId);
    delete("practice_queue_items", userId);
    delete("review_items", userId);
    delete("saved_expressions", userId);
    delete("mastery_records", userId);
    delete("learning_history_entries", userId);
    delete("training_metric_events", userId);
    delete("training_evidence_candidates", userId);
    delete("training_planner_decisions", userId);
    delete("training_turns", userId);
    delete("training_recaps", userId);
    delete("training_sessions", userId);
    delete("learning_evidences", userId);
    delete("session_summaries", userId);
    delete("practice_turns", userId);
    delete("practice_sessions", userId);
    delete("user_scenario_states", userId);
    delete("learning_routes", userId);
    delete("onboarding_assessments", userId);
    delete("entitlement_snapshots", userId);
    jdbcTemplate.update(
        "DELETE FROM payment_provider_events WHERE related_subscription_id IN (SELECT subscription_id FROM subscriptions WHERE user_id = ?)",
        userId);
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

  private void requireIdempotencyKey(String idempotencyKey) {
    if (idempotencyKey == null || idempotencyKey.length() < 8 || idempotencyKey.length() > 128) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
    }
  }

  private UUID parseDeletionJobId(String jobId) {
    try {
      return UUID.fromString(jobId);
    } catch (IllegalArgumentException exception) {
      throw new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Deletion job was not found.");
    }
  }

  private String aiRetentionIdempotencyKey(AccountDeletionJob job, AccountDeletionRetryIdempotency retry) {
    if (retry == null) {
      return "account-deletion-" + job.getDeletionJobId();
    }
    return "account-deletion-retry-" + retry.getRetryId();
  }

  private String failureReason(RuntimeException exception) {
    if (exception instanceof ApiException apiException) {
      return sanitizeFailureReason(apiException.getCode().toLowerCase(Locale.ROOT));
    }
    return "account_deletion_execution_failed";
  }

  private String sanitizeFailureReason(String reason) {
    String cleaned = reason == null ? "" : reason.trim().toLowerCase(Locale.ROOT);
    cleaned = cleaned.replaceAll("[^a-z0-9_\\-]+", "_");
    if (cleaned.isBlank()) {
      return "account_deletion_execution_failed";
    }
    return cleaned.length() > 120 ? cleaned.substring(0, 120) : cleaned;
  }

  private void auditRetryRequested(
      AccountDeletionJob job,
      AccountDeletionRetryIdempotency retry,
      String requestId,
      Instant createdAt) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "ops",
        "ops",
        "account_deletion_retry_requested",
        "account_deletion:" + job.getDeletionJobId(),
        "{\"schema_version\":1,\"retry_id\":\""
            + retry.getRetryId()
            + "\",\"retry_count\":"
            + job.getRetryCount()
            + "}",
        requestId,
        createdAt));
  }

  private void auditCompleted(
      AccountDeletionJob job,
      String aiRetentionRef,
      String requestId,
      Instant createdAt,
      boolean retry) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        retry ? "ops" : "user",
        retry ? "ops" : job.getUserId().toString(),
        retry ? "account_deletion_retry_completed" : "account_deletion_completed",
        retry ? "account_deletion:" + job.getDeletionJobId() : "user:" + job.getUserId(),
        "{\"schema_version\":1,\"learning_data\":\"deleted_or_anonymized\",\"p0_2_goal_autopilot_data\":\"deleted_or_anonymized\",\"sessions\":\"revoked\",\"retry_count\":"
            + job.getRetryCount()
            + ",\"ai_retention_ref\":\""
            + aiRetentionRef
            + "\"}",
        requestId,
        createdAt));
  }

  private void auditFailed(
      AccountDeletionJob job,
      String reason,
      String requestId,
      Instant createdAt,
      boolean retry) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        retry ? "ops" : "system",
        retry ? "ops" : job.getUserId().toString(),
        retry ? "account_deletion_retry_failed" : "account_deletion_failed",
        retry ? "account_deletion:" + job.getDeletionJobId() : "user:" + job.getUserId(),
        "{\"schema_version\":1,\"reason\":\""
            + sanitizeFailureReason(reason)
            + "\",\"retry_count\":"
            + job.getRetryCount()
            + "}",
        requestId,
        createdAt));
  }
}
