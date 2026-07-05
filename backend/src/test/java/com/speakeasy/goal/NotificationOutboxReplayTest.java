package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;

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
class NotificationOutboxReplayTest {
  private static final Instant BASE_TIME = Instant.parse("2026-06-05T02:00:00Z");

  @Autowired UserAccountRepository users;
  @Autowired GoalAutopilotService goalAutopilotService;
  @Autowired NotificationOutboxService outboxService;
  @Autowired PlannerReplayAuditRepository replayAudits;

  @Test
  void tcP02Fub008WritesDeterministicReplayAuditForOutboxDecisions() {
    Fixture fixture = fixture();
    NotificationOutboxService.ScheduleReminderCommand command = command(fixture, "evening_review", true, "eligible", null);

    NotificationOutboxService.OutboxRecordView first = outboxService.scheduleOrUpdate(command);
    NotificationOutboxService.OutboxRecordView duplicate = outboxService.scheduleOrUpdate(command);

    assertThat(duplicate.outboxId()).isEqualTo(first.outboxId());
    assertThat(replayAudits.findByUserIdAndDecisionFamilyOrderByCreatedAtDesc(fixture.userId, "notification_outbox"))
        .hasSize(1);

    NotificationOutboxService.OutboxRecordView scheduled = outboxService.markScheduled(first.outboxId(), BASE_TIME.plusSeconds(30));
    NotificationOutboxService.OutboxRecordView failed =
        outboxService.recordFailure(scheduled.outboxId(), "provider_timeout", BASE_TIME.plusSeconds(120));

    List<PlannerReplayAudit> audits =
        replayAudits.findByUserIdAndDecisionFamilyOrderByCreatedAtDesc(fixture.userId, "notification_outbox");
    assertThat(audits).hasSize(3);
    assertThat(audits)
        .extracting(PlannerReplayAudit::getExpectedDecision)
        .contains("pending", "scheduled", "failed");
    assertThat(audits)
        .allSatisfy(audit -> {
          assertThat(audit.getSourceEntityRef()).isEqualTo("outbox:" + first.outboxId());
          assertThat(audit.getInputSnapshotHash()).startsWith("sha256:");
          assertThat(audit.getOutputSnapshotHash()).startsWith("sha256:");
          assertThat(audit.getRuleVersion()).isEqualTo("fub-reminder-v1");
          assertThat(audit.getReplayHash()).startsWith("sha256:");
        });
    assertThat(audits.get(0).getReasonCode()).isEqualTo("provider_timeout");
    assertThat(failed.inputSnapshotHash()).isEqualTo(first.inputSnapshotHash());

    List<NotificationOutboxService.PlannerReplayAuditView> projection = outboxService.replayAudits(fixture.userId);
    assertThat(projection).hasSize(3);
    assertThat(projection.get(0).decisionFamily()).isEqualTo("notification_outbox");
    assertThat(projection.get(0).replayHash()).startsWith("sha256:");
  }

  private NotificationOutboxService.ScheduleReminderCommand command(
      Fixture fixture,
      String slot,
      boolean eligible,
      String reasonCode,
      Instant nextAllowedAt) {
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
        BASE_TIME,
        "fub-reminder-v1");
  }

  private Fixture fixture() {
    UUID userId = UUID.randomUUID();
    users.save(new UserAccount(userId, "TC-P02-FUB-008", BASE_TIME));
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
        "req_fub_008",
        "outbox-replay-goal");
    GoalAutopilotService.PlanResult plan = goalAutopilotService.generatePlan(userId, false, "initial_backplan", "req_plan");
    return new Fixture(
        userId,
        summary.goalProfile().goalProfileId(),
        summary.goalProfile().revision(),
        plan.dailyPlan().items().get(0).planItemId());
  }

  private record Fixture(UUID userId, UUID goalProfileId, int goalRevision, UUID planItemId) {}
}
