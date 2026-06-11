package com.speakeasy.goal;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.util.TestPropertyValues;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest(properties = "speakeasy.ai.provider=deterministic")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class GoalAutopilotTelemetryTest extends BackendIntegrationTestSupport {
  private static final String RAW_DIAGNOSTIC = "raw s009 diagnostic transcript must not enter telemetry";
  private static final String RAW_CHECKPOINT = "raw s009 checkpoint transcript must not enter telemetry";
  private static final String RAW_AUDIO_REF = "s3://raw-s009-audio";

  @Autowired EntitlementSnapshotRepository entitlements;
  @Autowired GoalAutopilotMetricEventRepository metrics;
  @Autowired AiCostMetricsService aiCostMetricsService;
  @Autowired ConfigurableApplicationContext context;
  @Autowired JdbcTemplate jdbcTemplate;
  private final List<String> submittedAudioRefs = new ArrayList<>();
  private int mediaUploadSequence;

  @AfterEach
  void resetTelemetryProperties() {
    TestPropertyValues.of(
            "speakeasy.goal-autopilot.telemetry.force-write-failure=false",
            "speakeasy.goal-autopilot.runtime.kill-switch.enabled=false",
            "speakeasy.goal-autopilot.runtime.kill-switch.reason=operator_disabled")
        .applyTo(context.getEnvironment());
  }

  @Test
  void tcP02Fud016RecordsRedactedFunnelHealthAndBlockedReasonMetrics() throws Exception {
    AuthTokens tokens = loginPhone("+8613800140901");
    UUID userId = UUID.fromString(tokens.userId());
    saveEntitlement(userId, "{\"ai\":5,\"asr\":100,\"tts\":100,\"scoring\":5,\"training\":50}");

    createSupportedGoal(tokens, "req_fud_s009_goal").andExpect(status().isOk());
    MvcResult plan = generatePlan(tokens, "req_fud_s009_plan", false, "initial_backplan")
        .andExpect(status().isOk())
        .andReturn();
    String planItemId = JsonPath.read(plan.getResponse().getContentAsString(), "$.next_action.plan_item_id");
    nextAction(tokens).andExpect(status().isOk());
    updateControl(tokens, "req_fud_s009_control").andExpect(status().isOk());
    completeAction(tokens, planItemId, "req_fud_s009_action", "completed").andExpect(status().isOk());
    submitCheckpoint(tokens, "req_fud_s009_checkpoint", "recorded", RAW_CHECKPOINT)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.checkpoint.result_status").value("low_confidence"));
    progressProjection(tokens)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.projection.projection_state").value("low_confidence"))
        .andExpect(jsonPath("$.projection.downgrade_reason").value("low_confidence"));

    assertUserMetricTypes(
        userId,
        "goal_intake",
        "diagnostic_assessment",
        "plan_generation",
        "control_update",
        "next_action",
        "action_complete",
        "checkpoint",
        "projection_read",
        "provider_fallback");

    AuthTokens quotaTokens = loginPhone("+8613800140902");
    UUID quotaUserId = UUID.fromString(quotaTokens.userId());
    saveEntitlement(quotaUserId, "{\"ai\":1,\"asr\":100,\"tts\":100,\"scoring\":100,\"training\":50}");
    createSupportedGoal(quotaTokens, "req_fud_s009_quota_goal").andExpect(status().isOk());
    generatePlan(quotaTokens, "req_fud_s009_quota_plan_1", false, "initial_backplan").andExpect(status().isOk());
    generatePlan(quotaTokens, "req_fud_s009_quota_plan_2", true, "quota_retry")
        .andExpect(status().isTooManyRequests())
        .andExpect(jsonPath("$.error.details.downgrade_reason").value("quota_exhausted"));
    assertMetric(quotaUserId, "quota_error", "blocked", "quota_exhausted");

    TestPropertyValues.of(
            "speakeasy.goal-autopilot.runtime.kill-switch.enabled=true",
            "speakeasy.goal-autopilot.runtime.kill-switch.reason=release_hold")
        .applyTo(context.getEnvironment());
    generatePlan(tokens, "req_fud_s009_kill_plan", true, "kill_switch_probe")
        .andExpect(status().isServiceUnavailable())
        .andExpect(jsonPath("$.error.details.reason_code").value("kill_switch_active"));
    assertMetric(userId, "kill_switch_event", "blocked", "kill_switch_active");

    List<GoalAutopilotMetricEvent> allRows = metrics.findAll();
    assertThat(allRows).isNotEmpty();
    assertThat(allRows).allSatisfy(metric -> {
      assertThat(metric.getUserHash()).startsWith("user_sha256:");
      assertThat(metric.getUserHash()).doesNotContain(userId.toString()).doesNotContain(quotaUserId.toString());
      assertThat(metric.getSchemaVersion()).isEqualTo(1);
      String rendered = metric.getEventType()
          + " " + metric.getStatus()
          + " " + metric.getReasonCode()
          + " " + metric.getSourcePath()
          + " " + metric.getTargetRef()
          + " " + metric.getAuditRef();
      assertThat(rendered)
          .doesNotContain(RAW_DIAGNOSTIC)
          .doesNotContain(RAW_CHECKPOINT)
          .doesNotContain(RAW_AUDIO_REF)
          .doesNotContain("provider payload")
          .doesNotContain("idempotency");
      submittedAudioRefs.forEach(audioRef -> assertThat(rendered).doesNotContain(audioRef));
    });
  }

  @Test
  void tcP02Fud016TelemetryWriteFailureFallsBackToAuditWithoutBlockingUserPath() throws Exception {
    TestPropertyValues.of("speakeasy.goal-autopilot.telemetry.force-write-failure=true")
        .applyTo(context.getEnvironment());
    AuthTokens tokens = loginPhone("+8613800140903");
    UUID userId = UUID.fromString(tokens.userId());

    createSupportedGoal(tokens, "req_fud_s009_forced_telemetry_failure")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.goal_profile.status").value("active"));

    assertThat(metrics.findAll()).isEmpty();
    List<String> fallbackAudits = jdbcTemplate.queryForList(
        "SELECT redacted_details FROM audit_logs WHERE actor_id = ? AND event_type = 'goal_autopilot_telemetry_write_failed'",
        String.class,
        userId.toString());
    assertThat(fallbackAudits).isNotEmpty();
    assertThat(fallbackAudits).allSatisfy(details -> assertThat(details)
        .contains("\"data\":\"redacted\"")
        .contains("\"schema_version\":1")
        .doesNotContain(RAW_DIAGNOSTIC)
        .doesNotContain(RAW_AUDIO_REF));
    assertThat(fallbackAudits).allSatisfy(
        details -> submittedAudioRefs.forEach(audioRef -> assertThat(details).doesNotContain(audioRef)));
  }

  private void assertUserMetricTypes(UUID userId, String... eventTypes) {
    List<String> actual = metrics.findByUserHashOrderByCreatedAtAsc(aiCostMetricsService.redactedUserHash(userId)).stream()
        .map(GoalAutopilotMetricEvent::getEventType)
        .toList();
    assertThat(actual).contains(eventTypes);
  }

  private void assertMetric(UUID userId, String eventType, String status, String reasonCode) {
    assertThat(metrics.findByUserHashOrderByCreatedAtAsc(aiCostMetricsService.redactedUserHash(userId)))
        .anySatisfy(metric -> {
          assertThat(metric.getEventType()).isEqualTo(eventType);
          assertThat(metric.getStatus()).isEqualTo(status);
          assertThat(metric.getReasonCode()).isEqualTo(reasonCode);
          assertThat(metric.getSourcePath()).startsWith("goal_autopilot.");
          assertThat(metric.getAuditRef()).startsWith("request:");
        });
  }

  private void saveEntitlement(UUID userId, String quotaLimits) {
    entitlements.save(new EntitlementSnapshot(
        UUID.randomUUID(),
        userId,
        null,
        "pro",
        "{\"basic_scenarios\":true,\"advanced_scenarios\":true,\"ai_feedback\":true}",
        quotaLimits,
        "active",
        null,
        Instant.now()));
  }

  private ResultActions createSupportedGoal(AuthTokens tokens, String requestId) throws Exception {
    String audioRef = createValidatedAudioRef(tokens, "diag-" + requestId);
    return mvc.perform(post("/goal-autopilot/goals")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .header("Idempotency-Key", "telemetry-goal-" + requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "goal_type": "ielts_speaking",
              "target_score": 7.5,
              "deadline": "%s",
              "daily_minutes": 30,
              "intensity_preference": "standard",
              "diagnostic_samples": [
                {
                  "sample_ref": "diag-s009-a",
                  "transcript": "%s",
                  "audio_ref": "%s",
                  "duration_seconds": 66
                },
                {
                  "sample_ref": "diag-s009-b",
                  "transcript": "I need more practice extending answers naturally while keeping the organization easy to follow.",
                  "duration_seconds": 68
                }
              ],
              "autopilot_control": {
                "notification_consent": true
              }
            }
            """.formatted(LocalDate.now().plusDays(75), RAW_DIAGNOSTIC, audioRef)));
  }

  private ResultActions generatePlan(AuthTokens tokens, String requestId, boolean forceReplan, String reasonCode) throws Exception {
    return mvc.perform(post("/goal-autopilot/plans/generate")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "force_replan": %s,
              "reason_code": "%s"
            }
            """.formatted(forceReplan, reasonCode)));
  }

  private ResultActions nextAction(AuthTokens tokens) throws Exception {
    return mvc.perform(get("/goal-autopilot/actions/next")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())));
  }

  private ResultActions updateControl(AuthTokens tokens, String requestId) throws Exception {
    return mvc.perform(patch("/goal-autopilot/control")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .header("Idempotency-Key", "s009-control-update")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "notification_consent": true,
              "missed_day_policy": "balanced"
            }
            """));
  }

  private ResultActions completeAction(AuthTokens tokens, String planItemId, String requestId, String outcome) throws Exception {
    return mvc.perform(post("/goal-autopilot/actions/{plan_item_id}/complete", UUID.fromString(planItemId))
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "outcome": "%s"
            }
            """.formatted(outcome)));
  }

  private ResultActions submitCheckpoint(AuthTokens tokens, String requestId, String resultStatus, String transcript) throws Exception {
    String audioRef = createValidatedAudioRef(tokens, "checkpoint-" + requestId);
    return mvc.perform(post("/goal-autopilot/checkpoints")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .header("X-Request-Id", requestId)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "checkpoint_type": "weekly_mock",
              "transcript": "%s",
              "audio_ref": "%s",
              "score_hint": 7.0,
              "result_status": "%s"
            }
            """.formatted(transcript, audioRef, resultStatus)));
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
    submittedAudioRefs.add(audioRef);
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

  private ResultActions progressProjection(AuthTokens tokens) throws Exception {
    return mvc.perform(get("/goal-autopilot/progress-projection")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken())));
  }
}
