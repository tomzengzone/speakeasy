package com.speakeasy.goal;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationOutboxService {
  private static final Set<String> TERMINAL_STATUSES = Set.of("sent", "expired");
  private static final Set<String> CANCELLATION_REASONS = Set.of("paused", "consent_missing", "permission_denied");

  private final NotificationOutboxRecordRepository outboxRecords;
  private final PlannerReplayAuditRepository replayAudits;
  private final ObjectMapper objectMapper;

  public NotificationOutboxService(
      NotificationOutboxRecordRepository outboxRecords,
      PlannerReplayAuditRepository replayAudits,
      ObjectMapper objectMapper) {
    this.outboxRecords = outboxRecords;
    this.replayAudits = replayAudits;
    this.objectMapper = objectMapper;
  }

  @Transactional
  public OutboxRecordView scheduleOrUpdate(ScheduleReminderCommand command) {
    String dedupeKey = dedupeKey(command);
    String inputHash = inputSnapshotHash(command);
    String payloadHash = sha256("payload:" + dedupeKey + ":" + command.explanationKey());
    NotificationOutboxRecord existing = outboxRecords.findByDedupeKey(dedupeKey).orElse(null);
    Instant now = command.evaluatedAt();

    if (existing == null) {
      String lifecycle = command.eligible() ? "pending" : "blocked";
      String processing = command.eligible() ? "queued" : "complete";
      NotificationOutboxRecord created = outboxRecords.save(new NotificationOutboxRecord(
          UUID.randomUUID(),
          command.userId(),
          command.goalProfileId(),
          command.goalRevision(),
          command.planItemId(),
          command.reminderSlot(),
          lifecycle,
          dedupeKey,
          inputHash,
          payloadHash,
          command.reasonCode(),
          processing,
          command.eligible() ? now : command.nextAllowedAt(),
          command.ruleVersion(),
          now));
      writeReplay(created, lifecycle, command.reasonCode(), now);
      return view(created);
    }

    if (TERMINAL_STATUSES.contains(existing.getLifecycleStatus())) {
      return view(existing);
    }
    if (command.eligible() && Set.of("blocked", "cancelled", "failed").contains(existing.getLifecycleStatus())) {
      existing.transition("pending", "queued", command.reasonCode(), now, null, now);
      existing = outboxRecords.save(existing);
      writeReplay(existing, "pending", command.reasonCode(), now);
      return view(existing);
    }
    if (command.eligible()) {
      return view(existing);
    }

    String lifecycle = CANCELLATION_REASONS.contains(command.reasonCode()) ? "cancelled" : "blocked";
    existing.transition(lifecycle, "complete", command.reasonCode(), command.nextAllowedAt(), null, now);
    existing = outboxRecords.save(existing);
    writeReplay(existing, lifecycle, command.reasonCode(), now);
    return view(existing);
  }

  @Transactional
  public OutboxRecordView markScheduled(UUID outboxId, Instant scheduledAt) {
    NotificationOutboxRecord record = requireOutbox(outboxId);
    if ("scheduled".equals(record.getLifecycleStatus()) || TERMINAL_STATUSES.contains(record.getLifecycleStatus())) {
      return view(record);
    }
    if (!"pending".equals(record.getLifecycleStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Notification outbox record is not schedulable.");
    }
    record.transition("scheduled", "complete", "scheduled", null, null, scheduledAt);
    record = outboxRecords.save(record);
    writeReplay(record, "scheduled", "scheduled", scheduledAt);
    return view(record);
  }

  @Transactional
  public OutboxRecordView recordFailure(UUID outboxId, String failureReason, Instant nextAttemptAt) {
    NotificationOutboxRecord record = requireMutableOutbox(outboxId);
    String reason = cleanOrDefault(failureReason, "provider_failure");
    record.markFailure(reason, nextAttemptAt, nextAttemptAt);
    record = outboxRecords.save(record);
    writeReplay(record, "failed", reason, nextAttemptAt);
    return view(record);
  }

  @Transactional
  public OutboxRecordView retry(UUID outboxId, Instant retryAt) {
    NotificationOutboxRecord record = requireMutableOutbox(outboxId);
    record.transition("scheduled", "complete", "retry_scheduled", null, null, retryAt);
    record = outboxRecords.save(record);
    writeReplay(record, "scheduled", "retry_scheduled", retryAt);
    return view(record);
  }

  @Transactional
  public OutboxRecordView recordSent(UUID outboxId, String providerMessageRef, Instant sentAt) {
    NotificationOutboxRecord record = requireMutableOutbox(outboxId);
    record.markSent(sha256("provider-message:" + cleanOrDefault(providerMessageRef, "redacted")), sentAt);
    record = outboxRecords.save(record);
    writeReplay(record, "sent", "sent", sentAt);
    return view(record);
  }

  @Transactional
  public OutboxRecordView expire(UUID outboxId, String reasonCode, Instant expiredAt) {
    NotificationOutboxRecord record = requireMutableOutbox(outboxId);
    String reason = cleanOrDefault(reasonCode, "slot_expired_before_send");
    record.transition("expired", "complete", reason, null, null, expiredAt);
    record = outboxRecords.save(record);
    writeReplay(record, "expired", reason, expiredAt);
    return view(record);
  }

  @Transactional(readOnly = true)
  public java.util.List<OutboxRecordView> outboxRecords(UUID userId) {
    return outboxRecords.findByUserIdOrderByUpdatedAtDesc(userId).stream().map(this::view).toList();
  }

  @Transactional(readOnly = true)
  public java.util.List<PlannerReplayAuditView> replayAudits(UUID userId) {
    return replayAudits.findByUserIdOrderByCreatedAtDesc(userId).stream().map(this::view).toList();
  }

  private NotificationOutboxRecord requireOutbox(UUID outboxId) {
    return outboxRecords.findByOutboxId(outboxId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Notification outbox record was not found."));
  }

  private NotificationOutboxRecord requireMutableOutbox(UUID outboxId) {
    NotificationOutboxRecord record = requireOutbox(outboxId);
    if (TERMINAL_STATUSES.contains(record.getLifecycleStatus()) || "cancelled".equals(record.getLifecycleStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Notification outbox record is terminal.");
    }
    return record;
  }

  private String dedupeKey(ScheduleReminderCommand command) {
    return command.userId()
        + ":"
        + command.goalRevision()
        + ":"
        + command.planItemId()
        + ":"
        + command.reminderSlot()
        + ":"
        + command.ruleVersion();
  }

  private String inputSnapshotHash(ScheduleReminderCommand command) {
    return sha256(Map.of(
        "user_id", command.userId().toString(),
        "goal_profile_id", command.goalProfileId().toString(),
        "goal_revision", Integer.toString(command.goalRevision()),
        "plan_item_id", command.planItemId().toString(),
        "reminder_slot", command.reminderSlot(),
        "eligible", Boolean.toString(command.eligible()),
        "reason_code", command.reasonCode(),
        "next_allowed_at", command.nextAllowedAt() == null ? "<null>" : command.nextAllowedAt().toString(),
        "rule_version", command.ruleVersion()));
  }

  private void writeReplay(NotificationOutboxRecord record, String expectedDecision, String reasonCode, Instant createdAt) {
    String outputHash = sha256(Map.of(
        "outbox_id", record.getOutboxId().toString(),
        "lifecycle_status", record.getLifecycleStatus(),
        "processing_status", record.getProcessingStatus(),
        "reason_code", record.getReasonCode(),
        "next_attempt_at", record.getNextAttemptAt() == null ? "<null>" : record.getNextAttemptAt().toString(),
        "retry_count", Integer.toString(record.getRetryCount()),
        "rule_version", record.getRuleVersion()));
    String replayHash = sha256(Map.of(
        "input", record.getInputSnapshotHash(),
        "output", outputHash,
        "expected_decision", expectedDecision,
        "reason_code", reasonCode,
        "rule_version", record.getRuleVersion()));
    replayAudits.save(new PlannerReplayAudit(
        UUID.randomUUID(),
        record.getUserId(),
        "notification_outbox",
        "outbox:" + record.getOutboxId(),
        record.getInputSnapshotHash(),
        outputHash,
        expectedDecision,
        reasonCode,
        record.getRuleVersion(),
        replayHash,
        createdAt));
  }

  private OutboxRecordView view(NotificationOutboxRecord record) {
    return new OutboxRecordView(
        record.getOutboxId(),
        record.getUserId(),
        record.getGoalProfileId(),
        record.getGoalRevision(),
        record.getPlanItemId(),
        record.getReminderSlot(),
        record.getLifecycleStatus(),
        record.getDedupeKey(),
        record.getInputSnapshotHash(),
        record.getPayloadHash(),
        record.getReasonCode(),
        record.getProcessingStatus(),
        record.getNextAttemptAt(),
        record.getFailureReason(),
        record.getRetryCount(),
        record.getSentAt(),
        record.getRuleVersion(),
        record.getCreatedAt(),
        record.getUpdatedAt());
  }

  private PlannerReplayAuditView view(PlannerReplayAudit audit) {
    return new PlannerReplayAuditView(
        audit.getReplayAuditId(),
        audit.getDecisionFamily(),
        audit.getSourceEntityRef(),
        audit.getInputSnapshotHash(),
        audit.getOutputSnapshotHash(),
        audit.getExpectedDecision(),
        audit.getReasonCode(),
        audit.getRuleVersion(),
        audit.getReplayHash(),
        audit.getCreatedAt());
  }

  private String cleanOrDefault(String value, String fallback) {
    return value == null || value.isBlank() ? fallback : value.trim();
  }

  private String sha256(Object value) {
    try {
      String payload = value instanceof Map<?, ?> map ? toJson(new TreeMap<>(map)) : value.toString();
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(payload.getBytes(StandardCharsets.UTF_8));
      return "sha256:" + HexFormat.of().formatHex(digest);
    } catch (Exception e) {
      throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "CONFLICT", "Could not hash notification outbox payload.");
    }
  }

  private String toJson(Object value) {
    try {
      return objectMapper.writeValueAsString(value);
    } catch (Exception e) {
      throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "CONFLICT", "Could not serialize notification outbox payload.");
    }
  }

  public record ScheduleReminderCommand(
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      UUID planItemId,
      String reminderSlot,
      boolean eligible,
      String reasonCode,
      Instant nextAllowedAt,
      String explanationKey,
      Instant evaluatedAt,
      String ruleVersion) {}

  public record OutboxRecordView(
      UUID outboxId,
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      UUID planItemId,
      String reminderSlot,
      String lifecycleStatus,
      String dedupeKey,
      String inputSnapshotHash,
      String payloadHash,
      String reasonCode,
      String processingStatus,
      Instant nextAttemptAt,
      String failureReason,
      int retryCount,
      Instant sentAt,
      String ruleVersion,
      Instant createdAt,
      Instant updatedAt) {}

  public record PlannerReplayAuditView(
      UUID replayAuditId,
      String decisionFamily,
      String sourceEntityRef,
      String inputSnapshotHash,
      String outputSnapshotHash,
      String expectedDecision,
      String reasonCode,
      String ruleVersion,
      String replayHash,
      Instant createdAt) {}
}
