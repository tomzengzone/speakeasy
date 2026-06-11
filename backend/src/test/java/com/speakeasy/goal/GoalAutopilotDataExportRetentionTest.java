package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.speakeasy.BackendIntegrationTestSupport;
import com.speakeasy.ai.AiCostMetricsService;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.commerce.EntitlementSnapshotRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotDataExportRetentionTest extends BackendIntegrationTestSupport {
  private static final String RAW_DIAGNOSTIC = "S007 RAW DIAGNOSTIC TRANSCRIPT SHOULD NOT EXPORT";
  private static final String RAW_CHECKPOINT = "S007 RAW CHECKPOINT TRANSCRIPT SHOULD NOT EXPORT";
  private static final String RAW_AUDIO_REF = "oss://s007/raw-audio-should-not-export";

  @Autowired GoalAutopilotService goalAutopilotService;
  @Autowired NotificationOutboxService notificationOutboxService;
  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired AiCostMetricsService aiCostMetricsService;
  @Autowired JdbcTemplate jdbcTemplate;
  private int mediaUploadSequence;

  @Test
  void tcP02Fud013ExportReturnsRedactedRecordsAndRetentionRulesForP02Families() throws Exception {
    Dataset dataset = createS007Dataset("+8613800140701");

    GoalAutopilotService.GoalAutopilotDataGovernanceExport export =
        goalAutopilotService.exportGoalAutopilotDataGovernance(dataset.userId());

    assertThat(export.exportFamily()).isEqualTo("goal_autopilot_p0_2");
    assertThat(export.ruleVersion()).isEqualTo("fud-data-governance-v1");
    assertThat(export.generatedAt()).isNotNull();
    assertThat(export.redactedExportOnly()).isTrue();
    assertThat(export.deletionProcessor()).isEqualTo("account_deletion_service_and_ai_retention_service");
    assertThat(export.userHash()).startsWith("user_sha256:");
    assertThat(export.omittedSensitiveFields()).contains(
        "raw_diagnostic_transcript",
        "raw_diagnostic_audio_ref",
        "raw_checkpoint_transcript",
        "raw_checkpoint_audio_ref",
        "raw_notification_payload",
        "raw_provider_payload",
        "raw_idempotency_key");

    Set<String> exportedFamilies = export.dataFamilies().stream()
        .map(GoalAutopilotService.DataFamilyExportRecord::dataClass)
        .collect(Collectors.toSet());
    assertThat(exportedFamilies).containsAll(expectedS007Families());
    assertThat(export.retentionRules().stream()
            .map(GoalAutopilotService.RetentionRuleView::dataClass)
            .collect(Collectors.toSet()))
        .containsAll(expectedS007Families())
        .contains("audit_logs");
    assertThat(export.deletionTables()).containsAll(expectedS007DeletionTables());
    assertThat(export.retainedRedactedTables()).contains("audit_logs", "account_deletion_jobs");

    assertThat(assertFamily(export, "goal_profiles", 1).safeFields()).contains("goal_type", "revision");
    assertThat(assertFamily(export, "goal_diagnostic_assessments", 1).omittedFields())
        .contains("raw_diagnostic_transcript", "raw_diagnostic_audio_ref", "provider_payload");
    assertThat(assertFamily(export, "goal_outcome_checkpoints", 1).omittedFields())
        .contains("raw_checkpoint_transcript", "raw_checkpoint_audio_ref", "provider_payload");
    assertThat(assertFamily(export, "goal_autopilot_goal_idempotency", 1).omittedFields())
        .contains("raw_idempotency_key", "response_json");
    assertThat(assertFamily(export, "goal_autopilot_control_idempotency", 1).omittedFields())
        .contains("raw_idempotency_key", "response_json");
    assertThat(assertFamily(export, "goal_notification_outbox_records", 1).safeFields())
        .contains("payload_hash", "input_snapshot_hash");
    assertThat(assertFamily(export, "goal_recovery_plan_decisions", 1).redactedFields())
        .contains("idempotency_key_hash");
    assertThat(assertFamily(export, "usage_reservations", 2).redactedFields())
        .contains("idempotency_key_ref");
    assertThat(assertFamily(export, "ai_provider_invocation_metrics", 2).omittedFields())
        .contains("raw_provider_payload", "raw_prompt", "raw_transcript", "raw_audio_ref");
    assertThat(assertFamily(export, "goal_autopilot_metric_events", 3).safeFields())
        .contains("user_hash", "event_type", "status", "reason_code", "source_path", "target_ref");
    assertThat(assertFamily(export, "goal_autopilot_metric_events", 3).omittedFields())
        .contains("raw_transcript", "raw_audio_ref", "raw_provider_payload", "raw_prompt", "raw_idempotency_key");

    String rendered = export.toString();
    assertThat(rendered)
        .doesNotContain(RAW_DIAGNOSTIC)
        .doesNotContain(RAW_CHECKPOINT)
        .doesNotContain(RAW_AUDIO_REF)
        .doesNotContain(dataset.audioRef())
        .doesNotContain("s007-control-idempotency-raw")
        .doesNotContain("s007-recovery-idempotency-raw")
        .doesNotContain("s007-reminder-slot-raw")
        .doesNotContain("provider-message-raw-id");
  }

  @Test
  void tcP02Fud014AccountDeletionPurgesP02DataFamiliesAndKeepsRedactedAuditProof() throws Exception {
    Dataset dataset = createS007Dataset("+8613800140702");

    assertThat(count("goal_profiles", dataset.userId())).isEqualTo(1);
    assertThat(count("goal_autopilot_goal_idempotency", dataset.userId())).isEqualTo(1);
    assertThat(count("goal_autopilot_control_idempotency", dataset.userId())).isEqualTo(1);
    assertThat(count("goal_notification_outbox_records", dataset.userId())).isEqualTo(1);
    assertThat(count("goal_recovery_plan_decisions", dataset.userId())).isEqualTo(1);
    assertThat(count("usage_reservations", dataset.userId())).isGreaterThanOrEqualTo(2);
    assertThat(count("usage_ledgers", dataset.userId())).isGreaterThanOrEqualTo(2);
    assertThat(countAiMetrics(dataset.userId())).isGreaterThanOrEqualTo(2);
    assertThat(countGoalMetrics(dataset.userId())).isGreaterThanOrEqualTo(3);

    mvc.perform(delete("/user/me")
            .header(HttpHeaders.AUTHORIZATION, bearer(dataset.tokens().accessToken()))
            .header("Idempotency-Key", "delete-s007-proof")
            .header("X-Request-Id", "req_delete_s007"))
        .andExpect(status().isAccepted())
        .andExpect(jsonPath("$.status").value("completed"));

    for (String table : expectedS007DeletionTables()) {
      if ("ai_provider_invocation_metrics".equals(table)) {
        assertThat(countAiMetrics(dataset.userId())).isZero();
      } else if ("goal_autopilot_metric_events".equals(table)) {
        assertThat(countGoalMetrics(dataset.userId())).isZero();
      } else {
        assertThat(count(table, dataset.userId())).as(table).isZero();
      }
    }
    assertThat(auditDetails(dataset.userId(), "account_deletion_completed"))
        .contains("\"p0_2_goal_autopilot_data\":\"deleted_or_anonymized\"")
        .contains("\"ai_retention_ref\":\"audit:ai_retention:");
  }

  private Dataset createS007Dataset(String phoneNumber) throws Exception {
    AuthTokens tokens = loginPhone(phoneNumber);
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(userId);
    String audioRef = createValidatedAudioRef(tokens, "s007-proof");

    MvcResult goalResult = mvc.perform(post("/goal-autopilot/goals")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_s007_goal")
            .header("Idempotency-Key", "s007-goal-create")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "goal_type": "ielts_speaking",
                  "target_score": 7.5,
                  "target_ability": "Band 7 speaking fluency",
                  "deadline": "%s",
                  "daily_minutes": 30,
                  "intensity_preference": "standard",
                  "diagnostic_samples": [
                    {
                      "sample_ref": "s007-diag-a",
                      "transcript": "%s with a structured answer, supporting example, and enough detail for high confidence.",
                      "audio_ref": "%s",
                      "duration_seconds": 72
                    },
                    {
                      "sample_ref": "s007-diag-b",
                      "transcript": "I can compare options, explain a tradeoff, and give a concise conclusion in a speaking response.",
                      "duration_seconds": 70
                    },
                    {
                      "sample_ref": "s007-diag-c",
                      "transcript": "I need recurring checkpoint practice and memory review without exporting raw diagnostic text.",
                      "duration_seconds": 69
                    }
                  ],
                  "autopilot_control": {
                    "quiet_hours_start": "00:00",
                    "quiet_hours_end": "00:00",
                    "notification_consent": true
                  }
                }
                """.formatted(LocalDate.now().plusDays(75), RAW_DIAGNOSTIC, audioRef)))
        .andExpect(status().isOk())
        .andReturn();
    String goalBody = goalResult.getResponse().getContentAsString();
    UUID goalProfileId = UUID.fromString(JsonPath.read(goalBody, "$.goal_profile.goal_profile_id"));
    int goalRevision = JsonPath.read(goalBody, "$.goal_profile.revision");

    mvc.perform(patch("/goal-autopilot/control")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "s007-control-idempotency-raw")
            .header("X-Request-Id", "req_s007_control")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "timezone": "Asia/Shanghai",
                  "quiet_hours_start": "00:00",
                  "quiet_hours_end": "00:00",
                  "notification_consent": true,
                  "intensity_override": "standard",
                  "missed_day_policy": "balanced"
                }
                """))
        .andExpect(status().isOk());

    MvcResult planResult = mvc.perform(post("/goal-autopilot/plans/generate")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_s007_plan")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "force_replan": false,
                  "reason_code": "initial_backplan"
                }
                """))
        .andExpect(status().isOk())
        .andReturn();
    UUID planItemId = UUID.fromString(JsonPath.read(
        planResult.getResponse().getContentAsString(),
        "$.daily_plan.items[0].plan_item_id"));

    notificationOutboxService.scheduleOrUpdate(new NotificationOutboxService.ScheduleReminderCommand(
        userId,
        goalProfileId,
        goalRevision,
        planItemId,
        "s007-reminder-slot-raw",
        true,
        "eligible",
        null,
        "reminder_allowed",
        Instant.parse("2026-06-07T02:00:00Z"),
        "fub-reminder-v1"));

    mvc.perform(post("/goal-autopilot/actions/%s/complete".formatted(planItemId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_s007_action")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "outcome": "skipped",
                  "evidence_ref": "training-turn-s007",
                  "learner_note": "S007 learner note should not export"
                }
                """))
        .andExpect(status().isOk());

    mvc.perform(post("/goal-autopilot/recovery/replan")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "s007-recovery-idempotency-raw")
            .header("X-Request-Id", "req_s007_recovery")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "source_event": "skipped",
                  "plan_item_id": "%s",
                  "preferred_policy": "balanced"
                }
                """.formatted(planItemId)))
        .andExpect(status().isOk());

    mvc.perform(post("/goal-autopilot/checkpoints")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("X-Request-Id", "req_s007_checkpoint")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checkpoint_type": "weekly_mock",
                  "transcript": "%s with concrete evidence, a follow-up answer, and enough language sample for scoring.",
                  "audio_ref": "%s",
                  "result_status": "recorded"
                }
                """.formatted(RAW_CHECKPOINT, audioRef)))
        .andExpect(status().isOk());

    return new Dataset(tokens, userId, goalProfileId, planItemId, audioRef);
  }

  private GoalAutopilotService.DataFamilyExportRecord assertFamily(
      GoalAutopilotService.GoalAutopilotDataGovernanceExport export,
      String dataClass,
      long minimumCount) {
    GoalAutopilotService.DataFamilyExportRecord family = export.dataFamilies().stream()
        .filter(candidate -> dataClass.equals(candidate.dataClass()))
        .findFirst()
        .orElseThrow();
    assertThat(family.recordCount()).as(dataClass).isGreaterThanOrEqualTo(minimumCount);
    assertThat(family.sourceRefs()).as(dataClass + " source refs").hasSize((int) family.recordCount());
    return family;
  }

  private Set<String> expectedS007Families() {
    return Set.of(
        "goal_profiles",
        "goal_diagnostic_assessments",
        "goal_mastery_initial_states",
        "goal_backplans",
        "goal_daily_plans",
        "goal_plan_items",
        "goal_progress_forecasts",
        "goal_outcome_checkpoints",
        "goal_autopilot_controls",
        "goal_autopilot_goal_idempotency",
        "goal_autopilot_control_idempotency",
        "goal_notification_outbox_records",
        "goal_planner_replay_audits",
        "goal_recovery_plan_decisions",
        "goal_mastery_transition_decisions",
        "usage_ledgers",
        "usage_reservations",
        "ai_provider_invocation_metrics",
        "goal_autopilot_metric_events");
  }

  private Set<String> expectedS007DeletionTables() {
    return expectedS007Families();
  }

  private long count(String tableName, UUID userId) {
    return jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM " + tableName + " WHERE user_id = ?",
        Long.class,
        userId);
  }

  private long countAiMetrics(UUID userId) {
    return jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM ai_provider_invocation_metrics WHERE user_hash = ?",
        Long.class,
        aiCostMetricsService.redactedUserHash(userId));
  }

  private long countGoalMetrics(UUID userId) {
    return jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM goal_autopilot_metric_events WHERE user_hash = ?",
        Long.class,
        aiCostMetricsService.redactedUserHash(userId));
  }

  private String auditDetails(UUID userId, String eventType) {
    return jdbcTemplate.queryForObject(
        "SELECT redacted_details FROM audit_logs WHERE actor_id = ? AND event_type = ?",
        String.class,
        userId.toString(),
        eventType);
  }

  private void saveEntitlement(UUID userId) {
    entitlements.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        userId,
        null,
        "pro",
        "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
        "{\"ai\":10,\"asr\":100,\"tts\":100,\"scoring\":10,\"training\":50}",
        "active",
        null,
        Instant.now()));
  }

  private String createValidatedAudioRef(AuthTokens tokens, String purposeSuffix) throws Exception {
    mediaUploadSequence += 1;
    String suffix = purposeSuffix + "-" + mediaUploadSequence;
    String checksum = "checksum-" + suffix;
    MvcResult create = mvc.perform(post("/media/audio/uploads")
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .header("Idempotency-Key", "audio-upload-" + suffix)
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "purpose": "asr_input",
                  "content_type": "audio/m4a",
                  "byte_size": 240000,
                  "duration_seconds": 12,
                  "checksum_sha256": "%s",
                  "client_upload_id": "client-%s"
                }
                """.formatted(checksum, suffix)))
        .andExpect(status().isCreated())
        .andReturn();
    String mediaId = JsonPath.read(create.getResponse().getContentAsString(), "$.media.media_id");
    String audioRef = JsonPath.read(create.getResponse().getContentAsString(), "$.media.audio_ref");
    mvc.perform(post("/media/audio/uploads/%s/complete".formatted(mediaId))
            .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
            .contentType(MediaType.APPLICATION_JSON)
            .content("""
                {
                  "schema_version": 1,
                  "checksum_sha256": "%s"
                }
                """.formatted(checksum)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.media.status").value("validated"));
    return audioRef;
  }

  private record Dataset(AuthTokens tokens, UUID userId, UUID goalProfileId, UUID planItemId, String audioRef) {}
}
