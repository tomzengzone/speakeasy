package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.speakeasy.common.ApiException;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@ActiveProfiles("test")
@Transactional
class NotificationOutboxServiceTest {
  private static final Instant BASE_TIME = Instant.parse("2026-06-05T01:00:00Z");

  @Autowired UserAccountRepository users;
  @Autowired GoalAutopilotService goalAutopilotService;
  @Autowired NotificationOutboxService outboxService;
  @Autowired NotificationOutboxRecordRepository outboxRecords;

  @Test
  void tcP02Fub007SchedulesDedupesAndTransitionsOutboxLifecycle() {
    Fixture fixture = fixture("TC-P02-FUB-007");

    NotificationOutboxService.OutboxRecordView pending =
        outboxService.scheduleOrUpdate(command(fixture, "evening_review", true, "eligible", null, BASE_TIME));

    assertThat(pending.lifecycleStatus()).isEqualTo("pending");
    assertThat(pending.processingStatus()).isEqualTo("queued");
    assertThat(pending.reasonCode()).isEqualTo("eligible");
    assertThat(pending.dedupeKey())
        .isEqualTo(fixture.userId + ":" + fixture.goalRevision + ":" + fixture.planItemId + ":evening_review:fub-reminder-v1");
    assertThat(pending.inputSnapshotHash()).startsWith("sha256:");
    assertThat(pending.payloadHash()).startsWith("sha256:");
    assertThat(pending.failureReason()).isNull();

    NotificationOutboxService.OutboxRecordView duplicate =
        outboxService.scheduleOrUpdate(command(fixture, "evening_review", true, "eligible", null, BASE_TIME));
    assertThat(duplicate.outboxId()).isEqualTo(pending.outboxId());
    assertThat(outboxRecords.findByUserIdOrderByUpdatedAtDesc(fixture.userId)).hasSize(1);

    NotificationOutboxService.OutboxRecordView scheduled =
        outboxService.markScheduled(pending.outboxId(), BASE_TIME.plusSeconds(30));
    assertThat(scheduled.lifecycleStatus()).isEqualTo("scheduled");
    assertThat(scheduled.processingStatus()).isEqualTo("complete");
    assertThat(scheduled.nextAttemptAt()).isNull();

    NotificationOutboxService.OutboxRecordView failed =
        outboxService.recordFailure(scheduled.outboxId(), "provider_timeout", BASE_TIME.plusSeconds(120));
    assertThat(failed.lifecycleStatus()).isEqualTo("failed");
    assertThat(failed.processingStatus()).isEqualTo("retry_waiting");
    assertThat(failed.retryCount()).isEqualTo(1);
    assertThat(failed.nextAttemptAt()).isEqualTo(BASE_TIME.plusSeconds(120));
    assertThat(failed.failureReason()).isEqualTo("provider_timeout");

    NotificationOutboxService.OutboxRecordView retried =
        outboxService.retry(failed.outboxId(), BASE_TIME.plusSeconds(120));
    assertThat(retried.lifecycleStatus()).isEqualTo("scheduled");
    assertThat(retried.processingStatus()).isEqualTo("complete");
    assertThat(retried.failureReason()).isNull();

    NotificationOutboxService.OutboxRecordView sent =
        outboxService.recordSent(retried.outboxId(), "provider-message-raw-id", BASE_TIME.plusSeconds(150));
    assertThat(sent.lifecycleStatus()).isEqualTo("sent");
    assertThat(sent.processingStatus()).isEqualTo("complete");
    assertThat(sent.payloadHash()).startsWith("sha256:");
    assertThat(sent.payloadHash()).doesNotContain("provider-message-raw-id");

    NotificationOutboxService.OutboxRecordView quietBlocked =
        outboxService.scheduleOrUpdate(command(
            fixture, "morning_review", false, "quiet_hours", BASE_TIME.plusSeconds(3600), BASE_TIME.plusSeconds(60)));
    assertThat(quietBlocked.lifecycleStatus()).isEqualTo("blocked");
    assertThat(quietBlocked.processingStatus()).isEqualTo("complete");
    assertThat(quietBlocked.reasonCode()).isEqualTo("quiet_hours");
    assertThat(quietBlocked.nextAttemptAt()).isEqualTo(BASE_TIME.plusSeconds(3600));
    assertThatThrownBy(() -> outboxService.markScheduled(quietBlocked.outboxId(), BASE_TIME.plusSeconds(3700)))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("not schedulable");

    NotificationOutboxService.OutboxRecordView cancellable =
        outboxService.scheduleOrUpdate(command(fixture, "lunch_review", true, "eligible", null, BASE_TIME.plusSeconds(90)));
    outboxService.markScheduled(cancellable.outboxId(), BASE_TIME.plusSeconds(100));
    NotificationOutboxService.OutboxRecordView cancelled =
        outboxService.scheduleOrUpdate(command(fixture, "lunch_review", false, "paused", null, BASE_TIME.plusSeconds(110)));
    assertThat(cancelled.lifecycleStatus()).isEqualTo("cancelled");
    assertThat(cancelled.reasonCode()).isEqualTo("paused");
    NotificationOutboxService.OutboxRecordView rescheduled =
        outboxService.scheduleOrUpdate(command(fixture, "lunch_review", true, "eligible", null, BASE_TIME.plusSeconds(115)));
    assertThat(rescheduled.outboxId()).isEqualTo(cancelled.outboxId());
    assertThat(rescheduled.lifecycleStatus()).isEqualTo("pending");
    assertThat(rescheduled.processingStatus()).isEqualTo("queued");
    assertThat(rescheduled.reasonCode()).isEqualTo("eligible");

    NotificationOutboxService.OutboxRecordView pausedOnly =
        outboxService.scheduleOrUpdate(command(fixture, "paused_review", true, "eligible", null, BASE_TIME.plusSeconds(116)));
    outboxService.markScheduled(pausedOnly.outboxId(), BASE_TIME.plusSeconds(117));
    NotificationOutboxService.OutboxRecordView stillCancelled =
        outboxService.scheduleOrUpdate(command(fixture, "paused_review", false, "paused", null, BASE_TIME.plusSeconds(118)));
    assertThat(stillCancelled.lifecycleStatus()).isEqualTo("cancelled");
    assertThatThrownBy(() -> outboxService.markScheduled(stillCancelled.outboxId(), BASE_TIME.plusSeconds(119)))
        .isInstanceOf(ApiException.class)
        .hasMessageContaining("not schedulable");

    NotificationOutboxService.OutboxRecordView expiring =
        outboxService.scheduleOrUpdate(command(fixture, "late_review", true, "eligible", null, BASE_TIME.plusSeconds(120)));
    NotificationOutboxService.OutboxRecordView expired =
        outboxService.expire(expiring.outboxId(), "slot_expired_before_send", BASE_TIME.plusSeconds(600));
    assertThat(expired.lifecycleStatus()).isEqualTo("expired");
    assertThat(expired.reasonCode()).isEqualTo("slot_expired_before_send");
    assertThat(expired.processingStatus()).isEqualTo("complete");

    assertThat(outboxRecords.findByUserIdOrderByUpdatedAtDesc(fixture.userId))
        .extracting(NotificationOutboxRecord::getLifecycleStatus)
        .contains("sent", "blocked", "pending", "cancelled", "expired");
  }

  private NotificationOutboxService.ScheduleReminderCommand command(
      Fixture fixture,
      String slot,
      boolean eligible,
      String reasonCode,
      Instant nextAllowedAt,
      Instant evaluatedAt) {
    return new NotificationOutboxService.ScheduleReminderCommand(
        fixture.userId,
        fixture.goalProfileId,
        fixture.goalRevision,
        fixture.planItemId,
        slot,
        eligible,
        reasonCode,
        nextAllowedAt,
        "reminder_" + reasonCode,
        evaluatedAt,
        "fub-reminder-v1");
  }

  private Fixture fixture(String displayName) {
    UUID userId = UUID.randomUUID();
    users.save(new UserAccount(userId, displayName, BASE_TIME));
    GoalAutopilotService.SummaryView summary = goalAutopilotService.createGoal(
        userId,
        new GoalAutopilotService.GoalInput(
            "ielts_speaking",
            8.0,
            "confident speaking under IELTS part 2 and part 3 pressure",
            LocalDate.now().plusDays(75),
            30,
            "standard",
            List.of(
                new GoalAutopilotService.DiagnosticSampleInput(
                    "sample_1",
                    "I can answer familiar questions, but I need more detail and cleaner examples.",
                    null,
                    45),
                new GoalAutopilotService.DiagnosticSampleInput(
                    "sample_2",
                    "Follow-up questions are understandable, but my answers become short.",
                    null,
                    45),
                new GoalAutopilotService.DiagnosticSampleInput(
                    "sample_3",
                    "I want stronger structure, transitions, and enough extension for longer answers.",
                    null,
                    45)),
            "22:00",
            "08:00",
            true),
        "req_" + displayName,
        "outbox-service-goal-" + displayName.replace(" ", "-"));
    GoalAutopilotService.PlanResult plan = goalAutopilotService.generatePlan(userId, false, "initial_backplan", "req_plan");
    UUID planItemId = plan.dailyPlan().items().get(0).planItemId();
    return new Fixture(
        userId,
        summary.goalProfile().goalProfileId(),
        summary.goalProfile().revision(),
        planItemId);
  }

  private record Fixture(UUID userId, UUID goalProfileId, int goalRevision, UUID planItemId) {}
}
