package com.speakeasy.goal;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.ai.AiCostMetricsService;
import com.speakeasy.ai.AiGatewayService;
import com.speakeasy.ai.AiProviderInvocationMetric;
import com.speakeasy.commerce.CommercialFoundationService;
import com.speakeasy.commerce.EntitlementSnapshot;
import com.speakeasy.common.ApiException;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import com.speakeasy.usage.UsageLedger;
import com.speakeasy.usage.UsageReservation;
import com.speakeasy.usage.UsageLedgerRepository;
import com.speakeasy.usage.UsageReservationRepository;
import com.speakeasy.usage.UsageService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.DateTimeException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.UUID;
import java.util.function.Function;
import java.util.function.Supplier;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GoalAutopilotService {
  private static final String CONTROL_RULE_VERSION = "fub-control-v1";
  private static final String NOTIFICATION_RULE_VERSION = NotificationEligibilityPolicy.RULE_VERSION;
  private static final String RECOVERY_RULE_VERSION = MissedDayRecoveryPlanner.RULE_VERSION;
  private static final String MEMORY_RULE_VERSION = MemoryCurvePolicy.RULE_VERSION;
  private static final String CHECKPOINT_PLAN_RULE_VERSION = "fuc-checkpoint-plan-v1";
  private static final String PROGRESS_PROJECTION_RULE_VERSION = "fuc-progress-projection-v1";
  private static final String DEFAULT_TIMEZONE = "Asia/Shanghai";
  private static final String TIME_PATTERN = "^([01][0-9]|2[0-3]):[0-5][0-9]$";
  private static final String REMINDER_SLOT_PATTERN = "^[a-z0-9][a-z0-9_-]{1,63}$";
  private static final Collection<String> ACTIVE_GOAL_STATUSES =
      List.of("active", "partial", "unsupported", "needs_more_diagnostic");
  private static final Collection<String> ACTIVE_PLAN_STATUSES = List.of("active", "partial");
  private static final Collection<String> ACTIVE_DAILY_STATUSES = List.of("ready", "partial", "recovery_required");
  private static final Collection<String> REMINDER_ITEM_STATUSES = List.of("active", "pending");
  private static final Set<String> SUPPORTED_GOALS =
      Set.of("ielts_speaking", "toefl_speaking", "business_meeting", "job_interview", "onboarding_introduction");
  private static final Set<String> VALID_INTENSITIES = Set.of("gentle", "standard", "intensive");
  private static final Set<String> VALID_MISSED_DAY_POLICIES = Set.of("balanced", "compress", "defer", "replace");
  private static final Set<String> VALID_PLATFORM_PERMISSIONS = Set.of("granted", "denied", "unknown");
  private static final TypeReference<List<RubricScoreView>> RUBRIC_LIST = new TypeReference<>() {};
  private static final TypeReference<List<WeaknessTagView>> WEAKNESS_LIST = new TypeReference<>() {};
  private static final TypeReference<List<String>> STRING_LIST = new TypeReference<>() {};
  private static final TypeReference<Map<String, Object>> OBJECT_MAP = new TypeReference<>() {};
  private static final TypeReference<ClaimGuardView> CLAIM_GUARD = new TypeReference<>() {};
  private static final TypeReference<ControlResult> CONTROL_RESULT = new TypeReference<>() {};
  private static final TypeReference<SummaryView> SUMMARY_VIEW = new TypeReference<>() {};

  private final UserAccountRepository users;
  private final GoalProfileRepository goalProfiles;
  private final GoalAutopilotControlRepository controls;
  private final GoalAutopilotControlIdempotencyRepository controlIdempotency;
  private final GoalAutopilotGoalIdempotencyRepository goalIdempotency;
  private final GoalDiagnosticAssessmentRepository diagnostics;
  private final GoalMasteryInitialStateRepository masteryInitialStates;
  private final GoalMasteryTransitionDecisionRepository masteryTransitions;
  private final GoalBackplanRepository backplans;
  private final GoalDailyPlanRepository dailyPlans;
  private final GoalPlanItemRepository planItems;
  private final GoalProgressForecastRepository forecasts;
  private final GoalOutcomeCheckpointRepository checkpoints;
  private final GoalRecoveryPlanDecisionRepository recoveryDecisions;
  private final NotificationOutboxService notificationOutboxService;
  private final PlannerReplayAuditRepository replayAudits;
  private final AuditLogRepository auditLogs;
  private final GoalAutopilotRuntimeGate runtimeGate;
  private final CommercialFoundationService commercialFoundationService;
  private final UsageLedgerRepository usageLedgers;
  private final UsageReservationRepository usageReservations;
  private final UsageService usageService;
  private final AiCostMetricsService aiCostMetricsService;
  private final AiGatewayService aiGatewayService;
  private final GoalAutopilotTelemetryService telemetryService;
  private final ObjectMapper objectMapper;
  private final Clock clock;
  private final NotificationEligibilityPolicy notificationEligibilityPolicy = new NotificationEligibilityPolicy();
  private final MissedDayRecoveryPlanner missedDayRecoveryPlanner = new MissedDayRecoveryPlanner();
  private final MemoryCurvePolicy memoryCurvePolicy = new MemoryCurvePolicy();
  private final MasteryTransitionPolicy masteryTransitionPolicy = new MasteryTransitionPolicy();
  private final ProgressForecastPolicy progressForecastPolicy = new ProgressForecastPolicy();
  private final CheckpointCadencePolicy checkpointCadencePolicy = new CheckpointCadencePolicy();
  private final GoalAutopilotEntitlementPolicy entitlementPolicy = new GoalAutopilotEntitlementPolicy();

  public GoalAutopilotService(
      UserAccountRepository users,
      GoalProfileRepository goalProfiles,
      GoalAutopilotControlRepository controls,
      GoalAutopilotControlIdempotencyRepository controlIdempotency,
      GoalAutopilotGoalIdempotencyRepository goalIdempotency,
      GoalDiagnosticAssessmentRepository diagnostics,
      GoalMasteryInitialStateRepository masteryInitialStates,
      GoalMasteryTransitionDecisionRepository masteryTransitions,
      GoalBackplanRepository backplans,
      GoalDailyPlanRepository dailyPlans,
      GoalPlanItemRepository planItems,
      GoalProgressForecastRepository forecasts,
      GoalOutcomeCheckpointRepository checkpoints,
      GoalRecoveryPlanDecisionRepository recoveryDecisions,
      NotificationOutboxService notificationOutboxService,
      PlannerReplayAuditRepository replayAudits,
      AuditLogRepository auditLogs,
      GoalAutopilotRuntimeGate runtimeGate,
      CommercialFoundationService commercialFoundationService,
      UsageLedgerRepository usageLedgers,
      UsageReservationRepository usageReservations,
      UsageService usageService,
      AiCostMetricsService aiCostMetricsService,
      AiGatewayService aiGatewayService,
      GoalAutopilotTelemetryService telemetryService,
      ObjectMapper objectMapper,
      Clock clock) {
    this.users = users;
    this.goalProfiles = goalProfiles;
    this.controls = controls;
    this.controlIdempotency = controlIdempotency;
    this.goalIdempotency = goalIdempotency;
    this.diagnostics = diagnostics;
    this.masteryInitialStates = masteryInitialStates;
    this.masteryTransitions = masteryTransitions;
    this.backplans = backplans;
    this.dailyPlans = dailyPlans;
    this.planItems = planItems;
    this.forecasts = forecasts;
    this.checkpoints = checkpoints;
    this.recoveryDecisions = recoveryDecisions;
    this.notificationOutboxService = notificationOutboxService;
    this.replayAudits = replayAudits;
    this.auditLogs = auditLogs;
    this.runtimeGate = runtimeGate;
    this.commercialFoundationService = commercialFoundationService;
    this.usageLedgers = usageLedgers;
    this.usageReservations = usageReservations;
    this.usageService = usageService;
    this.aiCostMetricsService = aiCostMetricsService;
    this.aiGatewayService = aiGatewayService;
    this.telemetryService = telemetryService;
    this.objectMapper = objectMapper;
    this.clock = clock;
  }

  @Transactional
  public SummaryView createGoal(UUID userId, GoalInput input, String requestId, String idempotencyKey) {
    runtimeGate.requireMutationAllowed(userId, "goal_create_or_update", requestId);
    requireIdempotencyKey(idempotencyKey);
    requireUserForUpdate(userId);
    String requestHash = goalCreateRequestHash(input);
    GoalAutopilotGoalIdempotency existing = goalIdempotency.findByUserIdAndIdempotencyKey(userId, idempotencyKey).orElse(null);
    if (existing != null) {
      if (!existing.getRequestHash().equals(requestHash)) {
        throw new ApiException(HttpStatus.CONFLICT, "IDEMPOTENCY_CONFLICT", "Idempotency key reused with different goal payload.");
      }
      return fromJson(existing.getResponseJson(), SUMMARY_VIEW);
    }
    SummaryView result = createGoalMutation(userId, input, requestId);
    goalIdempotency.save(new GoalAutopilotGoalIdempotency(
        UUID.randomUUID(),
        userId,
        idempotencyKey,
        requestHash,
        result.goalProfile().goalProfileId(),
        result.goalProfile().revision(),
        toJson(result),
        Instant.now(clock)));
    return result;
  }

  private SummaryView createGoalMutation(UUID userId, GoalInput input, String requestId) {
    LocalDate today = LocalDate.now(clock);
    String goalType = cleanRequired(input.goalType(), "goal_type");
    if (input.deadline() == null || !input.deadline().isAfter(today)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "deadline must be in the future.");
    }
    int dailyMinutes = input.dailyMinutes() == null ? 0 : input.dailyMinutes();
    if (dailyMinutes < 5 || dailyMinutes > 240) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "daily_minutes must be between 5 and 240.");
    }
    String intensity = clean(input.intensityPreference());
    if (!VALID_INTENSITIES.contains(intensity)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "intensity_preference is invalid.");
    }

    SupportDecision support = decideSupport(goalType, input.targetScore(), input.targetAbility(), input.deadline(), dailyMinutes);
    Instant now = Instant.now(clock);
    String status = switch (support.supportStatus()) {
      case "supported" -> "active";
      case "partial" -> "partial";
      default -> "unsupported";
    };
    var existing = goalProfiles.findFirstByUserIdAndStatusInOrderByUpdatedAtDesc(userId, ACTIVE_GOAL_STATUSES);
    GoalProfile profile = existing.orElseGet(() -> new GoalProfile(
        UUID.randomUUID(),
        userId,
        goalType,
        input.targetScore(),
        clean(input.targetAbility()),
        input.deadline(),
        dailyMinutes,
        intensity,
        support.supportStatus(),
        status,
        support.limitationMessage(),
        input.quietHoursStart(),
        input.quietHoursEnd(),
        input.notificationConsent(),
        now));
    if (existing.isPresent()) {
      profile.revise(
          goalType,
          input.targetScore(),
          clean(input.targetAbility()),
          input.deadline(),
          dailyMinutes,
          intensity,
          support.supportStatus(),
          status,
          support.limitationMessage(),
          input.quietHoursStart(),
          input.quietHoursEnd(),
          input.notificationConsent(),
          now);
      markPlansStale(profile.getGoalProfileId(), "goal_revision_changed", now);
    }
    profile = goalProfiles.save(profile);
    ensureControl(profile, now);
    validateDiagnosticAudioRefs(userId, input.diagnosticSamples());
    GoalDiagnosticAssessment diagnostic = diagnostics.save(buildDiagnostic(profile, input.diagnosticSamples(), support, now));
    saveInitialMasteryStates(profile, diagnostic, now);
    GoalProgressForecast forecast = upsertForecast(profile, diagnostic, "goal_intake", null, now);
    audit(userId, "goal_autopilot_goal_saved", "goal_profile:" + profile.getGoalProfileId(), requestId, now);
    recordGoalMetric(
        profile,
        "goal_intake",
        "success",
        support.reasonCode(),
        "goal_autopilot.goals.create",
        "goal_profile:" + profile.getGoalProfileId(),
        requestId);
    recordGoalMetric(
        profile,
        "diagnostic_assessment",
        "success",
        diagnostic.getReasonCode(),
        "goal_autopilot.diagnostic.assess",
        "diagnostic:" + diagnostic.getDiagnosticAssessmentId(),
        requestId);
    return summaryView(
        profile, support, diagnostic, latestBackplan(profile), latestDailyPlanOrNull(profile), nextActionOrNull(profile), forecast, latestCheckpoint(profile));
  }

  @Transactional(readOnly = true)
  public SummaryView summary(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "summary");
    GoalProfile profile = requireActiveGoal(userId);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    GoalProgressForecast forecast = requireForecast(profile);
    return summaryView(
        profile,
        supportDecisionFrom(profile),
        diagnostic,
        latestBackplan(profile),
        latestDailyPlanOrNull(profile),
        nextActionOrNull(profile),
        forecast,
        latestCheckpoint(profile));
  }

  @Transactional(readOnly = true)
  public GoalProgressProjectionView progressProjection(UUID userId) {
    requireUser(userId);
    Instant now = Instant.now(clock);
    GoalAutopilotRuntimeGate.RuntimeGateDecision runtimeDecision = runtimeGate.currentDecision();
    if (!runtimeDecision.allowed()) {
      recordGoalMetric(
          userId,
          "projection_read",
          "downgraded",
          runtimeDecision.reasonCode(),
          "goal_autopilot.progress_projection",
          "runtime_gate:progress_projection",
          null);
      return unavailableProgressProjection(userId, "unavailable", runtimeDecision.reasonCode(), now);
    }
    GoalProfile profile = goalProfiles.findFirstByUserIdAndStatusInOrderByUpdatedAtDesc(userId, ACTIVE_GOAL_STATUSES).orElse(null);
    if (profile == null) {
      recordGoalMetric(
          userId,
          "projection_read",
          "downgraded",
          "no_active_goal",
          "goal_autopilot.progress_projection",
          "goal_profile:none",
          null);
      return unavailableProgressProjection(userId, "unavailable", "no_active_goal", now);
    }
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    EntitlementDepthView entitlementDepth = entitlementDepthView(profile, diagnostic);
    String depthDowngradeReason = fullDepthDowngradeReason(profile.getUserId(), entitlementDepth);
    if (depthDowngradeReason != null) {
      recordGoalMetric(
          profile,
          "projection_read",
          "downgraded",
          depthDowngradeReason,
          "goal_autopilot.progress_projection",
          "goal_profile:" + profile.getGoalProfileId(),
          null);
      return unavailableProgressProjection(userId, "unavailable", depthDowngradeReason, now);
    }

    GoalAutopilotControl control = controls.findFirstByGoalProfileIdOrderByUpdatedAtDesc(profile.getGoalProfileId()).orElse(null);
    GoalProgressForecast forecast = forecasts.findFirstByGoalProfileIdOrderByUpdatedAtDesc(profile.getGoalProfileId()).orElse(null);
    GoalOutcomeCheckpoint checkpoint = latestCheckpoint(profile);
    AutopilotActionView nextAction = nextActionOrNull(profile);
    PlanFacts facts = planFacts(profile);
    String controlReason = control == null ? policyReason(profile) : controlReason(profile, control);
    String controlStatus = control == null ? policyStatus(profile) : controlView(control, controlReason).controlStatus();
    String state = progressProjectionState(profile, controlStatus, controlReason, forecast, facts);
    String downgradeReason = progressProjectionDowngradeReason(profile, controlReason, forecast, facts, state);
    List<String> sourceRefs = progressProjectionSourceRefs(profile, control, nextAction, forecast, checkpoint);
    Instant updatedAt = progressProjectionUpdatedAt(control, forecast, now);
    recordGoalMetric(
        profile,
        "projection_read",
        "ready".equals(state) ? "success" : "downgraded",
        downgradeReason == null ? state : downgradeReason,
        "goal_autopilot.progress_projection",
        "goal_profile:" + profile.getGoalProfileId(),
        null);

    return new GoalProgressProjectionView(
        progressProjectionId(userId, profile, control, nextAction, forecast, checkpoint, state, downgradeReason),
        state,
        downgradeReason,
        new GoalProgressGoalFragmentView(
            profile.getGoalProfileId(),
            profile.getGoalType(),
            profile.getSupportStatus(),
            profile.getStatus(),
            profile.getRevision()),
        nextAction == null ? null : progressNextActionFragment(nextAction),
        forecast == null ? null : progressForecastFragment(forecast),
        checkpoint == null ? null : progressCheckpointFragment(checkpoint),
        progressSurfaceFragments(state, downgradeReason, nextAction, forecast, checkpoint),
        sourceRefs,
        PROGRESS_PROJECTION_RULE_VERSION,
        updatedAt);
  }

  @Transactional
  public ControlResult control(UUID userId) {
    GoalAutopilotRuntimeGate.RuntimeGateDecision runtimeDecision = runtimeGate.currentDecision();
    if (!runtimeDecision.allowed()) {
      GoalProfile profile = requireActiveGoal(userId);
      return disabledControlResult(profile, runtimeDecision);
    }
    GoalProfile profile = requireActiveGoal(userId);
    Instant now = Instant.now(clock);
    GoalAutopilotControl control = ensureControl(profile, now);
    return controlResult(profile, control, controlReason(profile, control), "none");
  }

  @Transactional
  public ControlResult updateControl(UUID userId, ControlSettingsInput input, String requestId, String idempotencyKey) {
    runtimeGate.requireMutationAllowed(userId, "control_update", requestId);
    GoalProfile profile = requireActiveGoal(userId);
    ControlSettingsInput validated = new ControlSettingsInput(
        input.quietHoursStart() == null ? null : validateClockTime(input.quietHoursStart(), "quiet_hours_start"),
        input.quietHoursEnd() == null ? null : validateClockTime(input.quietHoursEnd(), "quiet_hours_end"),
        input.timezone() == null ? null : validateTimezone(input.timezone()),
        input.notificationConsent(),
        input.intensityOverride() == null ? null : validateOneOf(input.intensityOverride(), VALID_INTENSITIES, "intensity_override"),
        input.missedDayPolicy() == null ? null : validateOneOf(input.missedDayPolicy(), VALID_MISSED_DAY_POLICIES, "missed_day_policy"));
    String requestHash = controlRequestHash(
        "update",
        profile,
        Map.of(
            "quiet_hours_start", nullableHashValue(validated.quietHoursStart()),
            "quiet_hours_end", nullableHashValue(validated.quietHoursEnd()),
            "timezone", nullableHashValue(validated.timezone()),
            "notification_consent", nullableHashValue(validated.notificationConsent()),
            "intensity_override", nullableHashValue(validated.intensityOverride()),
            "missed_day_policy", nullableHashValue(validated.missedDayPolicy())));
    return withControlIdempotency(profile, "update", idempotencyKey, requestHash, () -> {
      Instant now = Instant.now(clock);
      GoalAutopilotControl control = ensureControl(profile, now);
      String quietStart = validated.quietHoursStart() == null ? control.getQuietHoursStart() : validated.quietHoursStart();
      String quietEnd = validated.quietHoursEnd() == null ? control.getQuietHoursEnd() : validated.quietHoursEnd();
      String timezone = validated.timezone() == null ? control.getTimezone() : validated.timezone();
      boolean consent = validated.notificationConsent() == null ? control.isNotificationConsent() : validated.notificationConsent();
      String intensity = validated.intensityOverride() == null ? control.getIntensityOverride() : validated.intensityOverride();
      String missedDayPolicy = validated.missedDayPolicy() == null ? control.getMissedDayPolicy() : validated.missedDayPolicy();
      String status = "paused".equals(control.getControlStatus()) ? "paused" : policyStatus(profile);
      control.updateSettings(status, quietStart, quietEnd, timezone, consent, intensity, missedDayPolicy, now);
      control = controls.save(control);
      audit(userId, "goal_autopilot_control_updated", "control:" + control.getControlId(), requestId, now);
      recordGoalMetric(
          profile,
          "control_update",
          "success",
          "control_updated",
          "goal_autopilot.control.update",
          "control:" + control.getControlId(),
          requestId);
      return controlResult(profile, control, "control_updated", "no_replan_needed");
    });
  }

  @Transactional
  public ControlResult pauseControl(UUID userId, String pauseReason, String requestId, String idempotencyKey) {
    runtimeGate.requireMutationAllowed(userId, "control_pause", requestId);
    GoalProfile profile = requireActiveGoal(userId);
    String normalizedReason = cleanOrDefault(pauseReason, "user_requested_break");
    String requestHash = controlRequestHash("pause", profile, Map.of("pause_reason", normalizedReason));
    return withControlIdempotency(profile, "pause", idempotencyKey, requestHash, () -> {
      Instant now = Instant.now(clock);
      GoalAutopilotControl control = ensureControl(profile, now);
      boolean changed = control.pause(normalizedReason, now);
      control = controls.save(control);
      if (changed) {
        audit(userId, "goal_autopilot_control_paused", "control:" + control.getControlId(), requestId, now);
      }
      recordGoalMetric(
          profile,
          "control_update",
          "success",
          "paused",
          "goal_autopilot.control.pause",
          "control:" + control.getControlId(),
          requestId);
      return controlResult(profile, control, "paused", "paused_without_plan_change");
    });
  }

  @Transactional
  public ControlResult resumeControl(UUID userId, String sourceEvent, String requestId, String idempotencyKey) {
    runtimeGate.requireMutationAllowed(userId, "control_resume", requestId);
    String source = cleanOrDefault(sourceEvent, "manual_resume");
    if (!Set.of("manual_resume", "pause_gap_recovery").contains(source)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "source_event is invalid.");
    }
    GoalProfile profile = requireActiveGoal(userId);
    String requestHash = controlRequestHash("resume", profile, Map.of("source_event", source));
    return withControlIdempotency(profile, "resume", idempotencyKey, requestHash, () -> {
      Instant now = Instant.now(clock);
      GoalAutopilotControl control = ensureControl(profile, now);
      String policyStatus = policyStatus(profile);
      boolean changed = control.resume(policyStatus, now);
      control = controls.save(control);
      if (changed) {
        audit(userId, "goal_autopilot_control_resumed", "control:" + control.getControlId(), requestId, now);
      }
      String reason = controlReason(profile, control);
      String signalReason = "missing_plan".equals(reason) || "stale_plan".equals(reason)
          ? "resume_requires_replan"
          : "no_replan_needed";
      recordGoalMetric(
          profile,
          "control_update",
          "success",
          reason,
          "goal_autopilot.control.resume",
          "control:" + control.getControlId(),
          requestId);
      return controlResult(profile, control, reason, signalReason);
    });
  }

  @Transactional
  public NotificationEligibilityDecisionView evaluateReminderEligibility(
      UUID userId, ReminderEligibilityInput input, String requestId) {
    runtimeGate.requireMutationAllowed(userId, "reminder_eligibility", requestId);
    if (input == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "notification eligibility request is required.");
    }
    GoalProfile profile = requireActiveGoal(userId);
    Instant serverNow = Instant.now(clock);
    GoalAutopilotControl control = ensureControl(profile, serverNow);
    Instant evaluatedAt = parseOptionalInstant(input.currentTime(), "current_time");
    if (evaluatedAt == null) {
      evaluatedAt = serverNow;
    }
    UUID requestedPlanItemId = parseOptionalUuid(input.planItemId(), "plan_item_id");
    String reminderSlot = validateReminderSlot(input.reminderSlot());
    String platformPermission = validatePlatformPermission(input.platformPermission());
    NotificationEligibilityDecisionView decision = reminderEligibilityDecision(
        profile, control, requestedPlanItemId, reminderSlot, platformPermission, evaluatedAt);
    recordGoalMetric(
        profile,
        "notification_eligibility",
        decision.eligible() ? "allowed" : "blocked",
        decision.reasonCode(),
        "goal_autopilot.reminders.eligibility",
        decision.planItemId() == null ? "plan_item:none" : "plan_item:" + decision.planItemId(),
        requestId);
    return decision;
  }

  @Transactional(readOnly = true)
  public ControlDataGovernanceExport exportControlDataGovernance(UUID userId) {
    requireUser(userId);
    List<ControlExportRecord> controlRecords = controls.findByUserIdOrderByUpdatedAtDesc(userId).stream()
        .map(control -> new ControlExportRecord(
            control.getControlId(),
            control.getUserId(),
            control.getGoalProfileId(),
            control.getControlStatus(),
            control.getPausedAt(),
            control.getPauseReason(),
            control.getResumedAt(),
            control.getQuietHoursStart(),
            control.getQuietHoursEnd(),
            control.getTimezone(),
            control.isNotificationConsent(),
            control.getIntensityOverride(),
            control.getMissedDayPolicy(),
            control.getRuleVersion(),
            control.getCreatedAt(),
            control.getUpdatedAt()))
        .toList();
    List<ControlIdempotencyExportRecord> idempotencyRecords = controlIdempotency.findByUserIdOrderByCreatedAtDesc(userId).stream()
        .map(replay -> new ControlIdempotencyExportRecord(
            replay.getReplayId(),
            replay.getGoalProfileId(),
            replay.getGoalRevision(),
            replay.getOperation(),
            replay.getRequestHash(),
            replay.getCreatedAt(),
            true,
            true))
        .toList();
    return new ControlDataGovernanceExport(
        "goal_autopilot_control",
        CONTROL_RULE_VERSION,
        controlRecords,
        idempotencyRecords,
        List.of(
            new RetentionRuleView(
                "goal_autopilot_controls",
                "hard_delete_on_account_deletion",
                "account_deletion_or_user_export",
                "exports control state; deletes user-owned row on account deletion"),
            new RetentionRuleView(
                "goal_autopilot_control_idempotency",
                "hard_delete_on_account_deletion",
                "account_deletion_or_replay_window_expiry",
                "exports replay metadata only; idempotency key and response body remain redacted"),
            new RetentionRuleView(
                "goal_notification_outbox_records",
                "hard_delete_on_account_deletion",
                "account_deletion_or_reminder_expiry",
                "exports redacted reminder lifecycle only; raw notification payload is represented by hashes"),
            new RetentionRuleView(
                "goal_planner_replay_audits",
                "hard_delete_on_account_deletion",
                "account_deletion_or_replay_window_expiry",
                "exports deterministic replay hashes without raw diagnostic or notification payload"),
            new RetentionRuleView(
                "goal_recovery_plan_decisions",
                "hard_delete_on_account_deletion",
                "account_deletion_or_replay_window_expiry",
                "exports recovery mode, source event and hashed planner input only"),
            new RetentionRuleView(
                "goal_mastery_transition_decisions",
                "hard_delete_on_account_deletion",
                "account_deletion_or_replay_window_expiry",
                "exports product-internal mastery transition metadata and redacted evidence refs only"),
            new RetentionRuleView(
                "audit_logs",
                "retain_redacted_minimal_audit",
                "ops_audit_policy",
                "retains redacted proof without raw control payload or idempotency key")),
        List.of(
            "goal_autopilot_controls",
            "goal_autopilot_control_idempotency",
            "goal_notification_outbox_records",
            "goal_recovery_plan_decisions",
            "goal_mastery_transition_decisions",
            "goal_planner_replay_audits"),
        true,
        "implemented_through_s005_mastery");
  }

  @Transactional(readOnly = true)
  public GoalAutopilotDataGovernanceExport exportGoalAutopilotDataGovernance(UUID userId) {
    requireUser(userId);
    List<GoalProfile> profileRows = goalProfiles.findByUserIdOrderByUpdatedAtDesc(userId);
    List<GoalDiagnosticAssessment> diagnosticRows = diagnostics.findByUserIdOrderByCreatedAtDesc(userId);
    List<GoalMasteryInitialState> masteryInitialRows = profileRows.stream()
        .flatMap(profile -> masteryInitialStates.findByGoalProfileId(profile.getGoalProfileId()).stream())
        .toList();
    List<GoalBackplan> backplanRows = backplans.findByUserIdOrderByCreatedAtDesc(userId);
    List<GoalDailyPlan> dailyPlanRows = dailyPlans.findByUserIdOrderByPlanDateDesc(userId);
    List<GoalPlanItem> planItemRows = planItems.findByUserIdOrderByCreatedAtDesc(userId);
    List<GoalProgressForecast> forecastRows = forecasts.findByUserIdOrderByUpdatedAtDesc(userId);
    List<GoalOutcomeCheckpoint> checkpointRows = checkpoints.findByUserIdOrderByCreatedAtDesc(userId);
    List<GoalAutopilotControl> controlRows = controls.findByUserIdOrderByUpdatedAtDesc(userId);
    List<GoalAutopilotGoalIdempotency> goalReplayRows = goalIdempotency.findByUserIdOrderByCreatedAtDesc(userId);
    List<GoalAutopilotControlIdempotency> controlReplayRows = controlIdempotency.findByUserIdOrderByCreatedAtDesc(userId);
    List<NotificationOutboxService.OutboxRecordView> outboxRows = notificationOutboxService.outboxRecords(userId);
    List<PlannerReplayAudit> replayRows = replayAudits.findByUserIdOrderByCreatedAtDesc(userId);
    List<GoalRecoveryPlanDecision> recoveryRows = recoveryDecisions.findByUserIdOrderByCreatedAtDesc(userId);
    List<GoalMasteryTransitionDecision> transitionRows = masteryTransitions.findByUserIdOrderByCreatedAtDesc(userId);
    List<UsageLedger> usageLedgerRows = usageLedgers.findByUserId(userId);
    List<UsageReservation> usageReservationRows = usageReservations.findByUserIdOrderByReservedAtDesc(userId);
    List<AiProviderInvocationMetric> metricRows = aiCostMetricsService.userMetrics(userId);
    List<GoalAutopilotMetricEvent> goalMetricRows = telemetryService.userMetrics(userId);

    List<DataFamilyExportRecord> families = List.of(
        dataFamily(
            "goal_profiles",
            profileRows.size(),
            sourceRefs(profileRows, "goal_profile", GoalProfile::getGoalProfileId),
            List.of("goal_type", "deadline", "daily_minutes", "intensity_preference", "support_status", "status", "revision"),
            List.of("target_score", "target_ability", "limitation_message"),
            List.of("raw_goal_statement"),
            "redacted_goal_metadata"),
        dataFamily(
            "goal_diagnostic_assessments",
            diagnosticRows.size(),
            sourceRefs(diagnosticRows, "diagnostic", GoalDiagnosticAssessment::getDiagnosticAssessmentId),
            List.of("status", "confidence_band", "sample_count", "reason_code", "rubric_scores_summary", "weakness_tags_summary"),
            List.of("claim_guard_json"),
            List.of("raw_diagnostic_transcript", "raw_diagnostic_audio_ref", "provider_payload"),
            "redacted_diagnostic_summary"),
        dataFamily(
            "goal_mastery_initial_states",
            masteryInitialRows.size(),
            sourceRefs(masteryInitialRows, "mastery_initial_state", GoalMasteryInitialState::getInitialStateId),
            List.of("skill_code", "mastery_level", "evidence_ref", "rule_version"),
            List.of(),
            List.of("raw_diagnostic_transcript", "raw_diagnostic_audio_ref"),
            "initial_mastery_metadata"),
        dataFamily(
            "goal_backplans",
            backplanRows.size(),
            sourceRefs(backplanRows, "backplan", GoalBackplan::getWeeklyBackplanId),
            List.of("plan_version", "start_date", "end_date", "session_count", "checkpoint_due_date", "status"),
            List.of("milestone", "review_windows"),
            List.of("provider_payload"),
            "redacted_backplan_metadata"),
        dataFamily(
            "goal_daily_plans",
            dailyPlanRows.size(),
            sourceRefs(dailyPlanRows, "daily_plan", GoalDailyPlan::getDailyPlanId),
            List.of("plan_date", "total_minutes", "status", "memory_policy_version", "forgetting_risk"),
            List.of("limitation_message", "interleaving_rule"),
            List.of("provider_payload"),
            "redacted_daily_plan_metadata"),
        dataFamily(
            "goal_plan_items",
            planItemRows.size(),
            sourceRefs(planItemRows, "plan_item", GoalPlanItem::getPlanItemId),
            List.of("item_type", "reason_code", "duration_minutes", "status", "memory_risk", "pressure_level", "order_index"),
            List.of("title"),
            List.of("learner_note", "raw_training_turn"),
            "redacted_action_metadata"),
        dataFamily(
            "goal_progress_forecasts",
            forecastRows.size(),
            sourceRefs(forecastRows, "forecast", GoalProgressForecast::getForecastId),
            List.of("forecast_state", "risk_level", "risk_reason_code", "eta_unavailable_reason", "rule_version"),
            List.of("gap_summary", "eta_date", "eta_range_start", "eta_range_end", "claim_guard_json"),
            List.of("provider_payload", "official_score_claim"),
            "redacted_forecast_metadata"),
        dataFamily(
            "goal_outcome_checkpoints",
            checkpointRows.size(),
            sourceRefs(checkpointRows, "checkpoint", GoalOutcomeCheckpoint::getCheckpointId),
            List.of("checkpoint_type", "cadence", "result_status", "confidence_band", "plan_update_signal", "reason_code"),
            List.of("summary"),
            List.of("raw_checkpoint_transcript", "raw_checkpoint_audio_ref", "provider_payload"),
            "redacted_checkpoint_metadata"),
        dataFamily(
            "goal_autopilot_controls",
            controlRows.size(),
            sourceRefs(controlRows, "control", GoalAutopilotControl::getControlId),
            List.of("control_status", "quiet_hours_start", "quiet_hours_end", "timezone", "notification_consent", "rule_version"),
            List.of("pause_reason", "intensity_override", "missed_day_policy"),
            List.of("raw_control_payload"),
            "control_state_export"),
        dataFamily(
            "goal_autopilot_goal_idempotency",
            goalReplayRows.size(),
            sourceRefs(goalReplayRows, "goal_replay", GoalAutopilotGoalIdempotency::getReplayId),
            List.of("request_hash", "goal_profile_id", "goal_revision", "created_at"),
            List.of("idempotency_key_hash", "response_json_redacted"),
            List.of("raw_idempotency_key", "response_json", "raw_goal_payload"),
            "redacted_goal_intake_replay"),
        dataFamily(
            "goal_autopilot_control_idempotency",
            controlReplayRows.size(),
            sourceRefs(controlReplayRows, "control_replay", GoalAutopilotControlIdempotency::getReplayId),
            List.of("operation", "request_hash", "created_at"),
            List.of("idempotency_key_hash", "response_json_redacted"),
            List.of("raw_idempotency_key", "response_json"),
            "redacted_idempotency_replay"),
        dataFamily(
            "goal_notification_outbox_records",
            outboxRows.size(),
            sourceRefs(outboxRows, "outbox", NotificationOutboxService.OutboxRecordView::outboxId),
            List.of("lifecycle_status", "processing_status", "payload_hash", "input_snapshot_hash", "reason_code", "retry_count", "rule_version"),
            List.of("dedupe_key_hash", "failure_reason"),
            List.of("raw_notification_payload", "provider_message_id"),
            "redacted_notification_lifecycle"),
        dataFamily(
            "goal_planner_replay_audits",
            replayRows.size(),
            sourceRefs(replayRows, "planner_replay", PlannerReplayAudit::getReplayAuditId),
            List.of("decision_family", "input_snapshot_hash", "output_snapshot_hash", "expected_decision", "reason_code", "replay_hash"),
            List.of("source_entity_ref"),
            List.of("raw_planner_input", "raw_notification_payload", "raw_diagnostic_transcript"),
            "deterministic_replay_hash_export"),
        dataFamily(
            "goal_recovery_plan_decisions",
            recoveryRows.size(),
            sourceRefs(recoveryRows, "recovery_decision", GoalRecoveryPlanDecision::getDecisionId),
            List.of("source_event", "recovery_mode", "input_snapshot_hash", "reason_code", "rule_version"),
            List.of("affected_plan_item_refs", "idempotency_key_hash"),
            List.of("raw_idempotency_key", "raw_recovery_payload"),
            "redacted_recovery_decision"),
        dataFamily(
            "goal_mastery_transition_decisions",
            transitionRows.size(),
            sourceRefs(transitionRows, "mastery_transition", GoalMasteryTransitionDecision::getTransitionId),
            List.of("item_type", "previous_level", "proposed_level", "accepted_level", "direction", "confidence", "reason_code", "rule_version"),
            List.of("memory_item_state_id", "item_ref", "evidence_refs_json", "input_snapshot_hash"),
            List.of("raw_training_turn", "raw_checkpoint_transcript", "provider_payload"),
            "redacted_mastery_transition"),
        dataFamily(
            "usage_ledgers",
            usageLedgerRows.size(),
            sourceRefs(usageLedgerRows, "usage_ledger", UsageLedger::getLedgerId),
            List.of("usage_family", "period", "reserved_amount", "committed_amount", "limit_amount", "status"),
            List.of(),
            List.of("provider_payload"),
            "usage_ledger_summary"),
        dataFamily(
            "usage_reservations",
            usageReservationRows.size(),
            sourceRefs(usageReservationRows, "usage_reservation", UsageReservation::getReservationId),
            List.of("usage_family", "amount", "status", "source_ref", "provider_usage_event_ref", "expires_at"),
            List.of("idempotency_key_ref"),
            List.of("raw_idempotency_key", "raw_provider_payload"),
            "redacted_usage_reservation"),
        dataFamily(
            "ai_provider_invocation_metrics",
            metricRows.size(),
            sourceRefs(metricRows, "ai_metric", AiProviderInvocationMetric::getMetricId),
            List.of("user_hash", "plan", "provider_family", "model", "capability", "status", "estimated_cost", "fallback_reason"),
            List.of("token_estimate", "audio_duration_seconds"),
            List.of("raw_provider_payload", "raw_prompt", "raw_transcript", "raw_audio_ref"),
            "redacted_cost_metric"),
        dataFamily(
            "goal_autopilot_metric_events",
            goalMetricRows.size(),
            sourceRefs(goalMetricRows, "goal_metric", GoalAutopilotMetricEvent::getMetricEventId),
            List.of("user_hash", "event_type", "status", "reason_code", "source_path", "target_ref", "audit_ref", "schema_version"),
            List.of(),
            List.of("raw_transcript", "raw_audio_ref", "raw_provider_payload", "raw_prompt", "raw_idempotency_key", "notification_payload"),
            "redacted_rollout_health_metric"));

    return new GoalAutopilotDataGovernanceExport(
        "goal_autopilot_p0_2",
        "fud-data-governance-v1",
        Instant.now(clock),
        families,
        goalAutopilotRetentionRules(),
        goalAutopilotDeletionTables(),
        List.of("audit_logs", "account_deletion_jobs"),
        s007OmittedSensitiveFields(),
        aiCostMetricsService.redactedUserHash(userId),
        true,
        "account_deletion_service_and_ai_retention_service");
  }

  private DataFamilyExportRecord dataFamily(
      String dataClass,
      long recordCount,
      List<String> sourceRefs,
      List<String> safeFields,
      List<String> redactedFields,
      List<String> omittedFields,
      String exportBehavior) {
    return new DataFamilyExportRecord(
        dataClass,
        recordCount,
        sourceRefs,
        safeFields,
        redactedFields,
        omittedFields,
        exportBehavior);
  }

  private <T> List<String> sourceRefs(List<T> rows, String prefix, Function<T, UUID> idExtractor) {
    return rows.stream()
        .map(row -> prefix + ":" + idExtractor.apply(row))
        .toList();
  }

  private List<RetentionRuleView> goalAutopilotRetentionRules() {
    return List.of(
        new RetentionRuleView("goal_profiles", "hard_delete_on_account_deletion", "account_deletion_or_user_export", "exports redacted goal metadata and source refs"),
        new RetentionRuleView("goal_diagnostic_assessments", "hard_delete_on_account_deletion", "account_deletion_or_user_export", "exports rubric/confidence summary; raw transcripts and audio refs are omitted"),
        new RetentionRuleView("goal_mastery_initial_states", "hard_delete_on_account_deletion", "account_deletion_or_user_export", "exports initial mastery metadata without raw diagnostic samples"),
        new RetentionRuleView("goal_backplans", "hard_delete_on_account_deletion", "account_deletion_or_plan_expiry", "exports plan metadata with milestone/review text redacted"),
        new RetentionRuleView("goal_daily_plans", "hard_delete_on_account_deletion", "account_deletion_or_plan_expiry", "exports daily plan metadata with limitation copy redacted"),
        new RetentionRuleView("goal_plan_items", "hard_delete_on_account_deletion", "account_deletion_or_plan_expiry", "exports action metadata with learner notes omitted"),
        new RetentionRuleView("goal_progress_forecasts", "hard_delete_on_account_deletion", "account_deletion_or_forecast_stale", "exports forecast state and reason codes with ETA/gap details redacted"),
        new RetentionRuleView("goal_outcome_checkpoints", "hard_delete_on_account_deletion", "account_deletion_or_checkpoint_expiry", "exports checkpoint status metadata; raw transcript/audio/provider payload omitted"),
        new RetentionRuleView("goal_autopilot_controls", "hard_delete_on_account_deletion", "account_deletion_or_user_export", "exports control state; raw control payload omitted"),
        new RetentionRuleView("goal_autopilot_goal_idempotency", "hard_delete_on_account_deletion", "account_deletion_or_replay_window_expiry", "exports request hash only; raw idempotency key and response body omitted"),
        new RetentionRuleView("goal_autopilot_control_idempotency", "hard_delete_on_account_deletion", "account_deletion_or_replay_window_expiry", "exports request hash only; raw idempotency key and response body omitted"),
        new RetentionRuleView("goal_notification_outbox_records", "hard_delete_on_account_deletion", "account_deletion_or_reminder_expiry", "exports lifecycle and hashes only; raw notification payload omitted"),
        new RetentionRuleView("goal_planner_replay_audits", "hard_delete_on_account_deletion", "account_deletion_or_replay_window_expiry", "exports deterministic replay hashes only"),
        new RetentionRuleView("goal_recovery_plan_decisions", "hard_delete_on_account_deletion", "account_deletion_or_replay_window_expiry", "exports recovery metadata and hashed planner input only"),
        new RetentionRuleView("goal_mastery_transition_decisions", "hard_delete_on_account_deletion", "account_deletion_or_replay_window_expiry", "exports mastery transition metadata and hashed evidence refs only"),
        new RetentionRuleView("usage_ledgers", "hard_delete_on_account_deletion", "account_deletion_or_period_rolloff", "exports usage counters by family and period"),
        new RetentionRuleView("usage_reservations", "hard_delete_on_account_deletion", "account_deletion_or_reservation_expiry", "exports source refs and idempotency hash refs only"),
        new RetentionRuleView("ai_provider_invocation_metrics", "hard_delete_by_user_hash_on_account_deletion", "account_deletion_or_ops_rollup", "exports redacted cost metric rows without prompts, transcripts, audio refs or provider payloads"),
        new RetentionRuleView("goal_autopilot_metric_events", "hard_delete_by_user_hash_on_account_deletion", "account_deletion_or_ops_rollup", "exports redacted rollout health metrics without prompts, transcripts, audio refs or provider payloads"),
        new RetentionRuleView("audit_logs", "retain_redacted_minimal_audit", "ops_audit_policy", "retains redacted proof without raw payloads or idempotency keys"));
  }

  private List<String> goalAutopilotDeletionTables() {
    return List.of(
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

  private List<String> s007OmittedSensitiveFields() {
    return List.of(
        "raw_diagnostic_transcript",
        "raw_diagnostic_audio_ref",
        "raw_checkpoint_transcript",
        "raw_checkpoint_audio_ref",
        "raw_notification_payload",
        "raw_provider_payload",
        "raw_prompt",
        "raw_idempotency_key",
        "goal_create_response_json",
        "control_response_json",
        "learner_note");
  }

  @Transactional(readOnly = true)
  public List<NotificationOutboxService.OutboxRecordView> reminderOutbox(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "reminder_outbox");
    requireUser(userId);
    return notificationOutboxService.outboxRecords(userId);
  }

  @Transactional(readOnly = true)
  public List<NotificationOutboxService.PlannerReplayAuditView> replayAudits(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "replay_audits");
    requireUser(userId);
    return notificationOutboxService.replayAudits(userId);
  }

  @Transactional(readOnly = true)
  public List<MasteryTransitionDecisionView> masteryTransitions(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "mastery_transitions");
    requireUser(userId);
    return masteryTransitions.findByUserIdOrderByCreatedAtDesc(userId).stream()
        .map(this::masteryTransitionView)
        .toList();
  }

  @Transactional
  public PlanResult generatePlan(UUID userId, boolean forceReplan, String reasonCode, String requestId) {
    runtimeGate.requireMutationAllowed(userId, "plan_generate", requestId);
    GoalProfile profile = requireActiveGoal(userId);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    if ("unsupported".equals(profile.getSupportStatus())) {
      recordGoalMetric(
          profile,
          "plan_generation",
          "blocked",
          "unsupported_goal",
          "goal_autopilot.plans.generate",
          "goal_profile:" + profile.getGoalProfileId(),
          requestId);
      throw new ApiException(
          HttpStatus.CONFLICT,
          "CONFLICT",
          "Unsupported goals cannot generate a full goal autopilot plan.",
          Map.of("support_status", profile.getSupportStatus(), "reason_code", "unsupported_goal"));
    }
    EntitlementDepthView entitlementDepth = entitlementDepthView(profile, diagnostic);
    int costTokenEstimate = goalAutopilotTokenEstimate(profile, diagnostic, "plan_generate");
    if ("blocked".equals(entitlementDepth.depthState())) {
      String downgradeReason = stableDowngradeReason(entitlementDepth);
      recordGoalCostPolicyRejection(
          profile,
          "ai",
          "entitlement_depth_blocked:" + entitlementDepth.limitationReason(),
          costTokenEstimate);
      recordGoalMetric(
          profile,
          "plan_generation",
          "blocked",
          downgradeReason,
          "goal_autopilot.plans.generate",
          "goal_profile:" + profile.getGoalProfileId(),
          requestId);
      throw new ApiException(
          HttpStatus.FORBIDDEN,
          "ENTITLEMENT_DEPTH_BLOCKED",
          "Current entitlement blocks goal autopilot plan generation.",
          Map.of(
              "depth_state", entitlementDepth.depthState(),
              "allowed_depth", entitlementDepth.allowedDepth(),
              "reason_code", downgradeReason,
              "source_reason", entitlementDepth.limitationReason(),
              "downgrade_state", "EntitlementBlocked",
              "downgrade_reason", downgradeReason,
              "blocked_full_depth", true));
    }
    String usagePayloadHash = usagePayloadHash("plan_generate", profile, Map.of(
        "force_replan", Boolean.toString(forceReplan),
        "reason_code", cleanOrDefault(reasonCode, "manual_replan")));
    if (!entitlementDepth.providerCandidateAllowed()) {
      recordGoalCostPolicyRejection(profile, "ai", entitlementDepth.limitationReason(), costTokenEstimate);
    }
    UsageReservation usageReservation = reserveGoalUsageWithCostTelemetry(
        profile, entitlementDepth, "plan_generate", "ai", requestId, usagePayloadHash, costTokenEstimate);
    Instant now = Instant.now(clock);
    try {
      if (forceReplan || latestBackplan(profile) != null) {
        markPlansStale(profile.getGoalProfileId(), cleanOrDefault(reasonCode, "manual_replan"), now);
      }
      LocalDate today = LocalDate.now(clock);
      boolean partial = "partial".equals(profile.getSupportStatus()) || "low".equals(diagnostic.getConfidenceBand());
      String risk = riskFor(diagnostic, partial);
      GoalBackplan backplan = backplans.save(new GoalBackplan(
          UUID.randomUUID(),
          profile.getGoalProfileId(),
          userId,
          "goal-plan-v1",
          today,
          today.plusDays(6),
          milestoneFor(diagnostic, profile),
          sessionCount(profile, partial),
          "D1,D3,D7",
          today.plusDays(partial ? 14 : 7),
          partial ? "partial" : "active",
          now));
      GoalDailyPlan dailyPlan = dailyPlans.save(new GoalDailyPlan(
          UUID.randomUUID(),
          backplan.getWeeklyBackplanId(),
          profile.getGoalProfileId(),
          userId,
          today,
          Math.max(5, profile.getDailyMinutes()),
          partial ? "partial" : "ready",
          partial
              ? "Conservative plan because goal support or diagnostic confidence is limited."
              : "full".equals(entitlementDepth.allowedDepth()) ? "" : "Entitlement depth limits AI explanation and checkpoint depth.",
          risk,
          "high".equals(risk) ? 1 : 3,
          now));
      createDefaultPlanItems(profile, dailyPlan, risk, partial, now);
      activateControlAfterPlan(profile, now);
      GoalProgressForecast forecast = upsertForecast(profile, diagnostic, "plan_generated", null, now);
      audit(userId, "goal_autopilot_plan_generated", "goal_profile:" + profile.getGoalProfileId(), requestId, now);
      recordGoalMetric(
          profile,
          "plan_generation",
          "success",
          "plan_generated",
          "goal_autopilot.plans.generate",
          "goal_profile:" + profile.getGoalProfileId(),
          requestId);
      if (entitlementDepth.providerCandidateAllowed()) {
        recordGoalCostDeterministicNoProvider(profile, "ai", "deterministic_no_provider_call:plan_generate", costTokenEstimate);
      }
      closeGoalUsageReservation(profile, usageReservation, "plan_generate", usagePayloadHash, true);
      return new PlanResult(
          backplanView(backplan),
          dailyPlanView(dailyPlan),
          actionView(requireNextItem(dailyPlan), "ready"),
          forecastView(forecast),
          entitlementDepth);
    } catch (RuntimeException e) {
      closeGoalUsageReservation(profile, usageReservation, "plan_generate", usagePayloadHash, false);
      recordGoalMetric(
          profile,
          "plan_generation",
          "error",
          exceptionReason(e),
          "goal_autopilot.plans.generate",
          "goal_profile:" + profile.getGoalProfileId(),
          requestId);
      throw e;
    }
  }

  @Transactional(readOnly = true)
  public DailyPlanView dailyPlan(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "daily_plan");
    GoalProfile profile = requireActiveGoal(userId);
    GoalDailyPlan dailyPlan = requireDailyPlan(profile);
    return dailyPlanView(dailyPlan);
  }

  @Transactional
  public RecoveryPlanResult replanRecovery(
      UUID userId, RecoveryReplanInput input, String requestId, String idempotencyKey) {
    runtimeGate.requireMutationAllowed(userId, "recovery_replan", requestId);
    requireIdempotencyKey(idempotencyKey);
    String sourceEvent = validateOneOf(
        input.sourceEvent(),
        Set.of("missed_day", "skipped", "deferred", "resume_after_pause_gap", "stale_plan", "expired_item"),
        "source_event");
    GoalProfile profile = requireActiveGoal(userId);
    GoalAutopilotControl control = ensureControl(profile, Instant.now(clock));
    String preferredPolicy = input.preferredPolicy() == null
        ? control.getMissedDayPolicy()
        : validateOneOf(input.preferredPolicy(), VALID_MISSED_DAY_POLICIES, "preferred_policy");
    GoalRecoveryPlanDecision existing = recoveryDecisions
        .findByUserIdAndGoalProfileIdAndGoalRevisionAndSourceEventAndRuleVersionAndIdempotencyKey(
            userId, profile.getGoalProfileId(), profile.getRevision(), sourceEvent, RECOVERY_RULE_VERSION, idempotencyKey)
        .orElse(null);
    if (existing != null) {
      return recoveryPlanResult(existing);
    }

    Instant now = Instant.now(clock);
    GoalDailyPlan sourceDailyPlan = recoverySourceDailyPlan(profile, input.planItemId());
    List<GoalPlanItem> sourceItems = planItems.findByDailyPlanIdOrderByOrderIndexAsc(sourceDailyPlan.getDailyPlanId());
    MissedDayRecoveryPlanner.Decision plannerDecision = missedDayRecoveryPlanner.plan(new MissedDayRecoveryPlanner.Input(
        sourceEvent,
        preferredPolicy,
        profile.getSupportStatus(),
        !"unsupported".equals(profile.getSupportStatus()) && !sourceItems.isEmpty(),
        LocalDate.now(clock),
        profile.getDeadline(),
        profile.getDailyMinutes(),
        control.getIntensityOverride(),
        sourceDailyPlan.getForgettingRisk(),
        sourceItems.stream().map(this::recoveryPlannerItem).toList()));
    String inputSnapshotHash = recoveryInputSnapshotHash(
        profile, sourceDailyPlan, sourceEvent, preferredPolicy, plannerDecision.affectedPlanItemRefs());
    GoalDailyPlan recoveryDailyPlan = applyRecoveryPlan(profile, sourceDailyPlan, plannerDecision, control.getIntensityOverride(), now);
    GoalRecoveryPlanDecision decision = recoveryDecisions.save(new GoalRecoveryPlanDecision(
        UUID.randomUUID(),
        userId,
        profile.getGoalProfileId(),
        profile.getRevision(),
        recoveryDailyPlan.getDailyPlanId(),
        sourceEvent,
        plannerDecision.recoveryMode(),
        toJson(plannerDecision.affectedPlanItemRefs()),
        inputSnapshotHash,
        plannerDecision.reasonCode(),
        plannerDecision.ruleVersion(),
        idempotencyKey,
        now));
    writeRecoveryReplay(decision, recoveryDailyPlan, now);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    upsertForecast(profile, diagnostic, "skipped", null, now);
    audit(userId, "goal_autopilot_recovery_replanned", "recovery_decision:" + decision.getDecisionId(), requestId, now);
    return recoveryPlanResult(decision);
  }

  @Transactional
  public ItemPolicyDecisionResult itemPolicyDecisions(UUID userId, ItemPolicyDecisionInput input, String requestId) {
    runtimeGate.requireMutationAllowed(userId, "item_policy_decisions", requestId);
    if (input == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "item policy request is required.");
    }
    GoalProfile profile = requireActiveGoal(userId);
    Instant now = Instant.now(clock);
    Instant policyEvaluatedAt = now.truncatedTo(ChronoUnit.DAYS);
    GoalAutopilotControl control = ensureControl(profile, now);
    String policyVersion = cleanOrDefault(input.policyVersion(), MEMORY_RULE_VERSION);
    if (!MEMORY_RULE_VERSION.equals(policyVersion)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "policy_version is invalid.");
    }
    int dailyBudget = input.dailyTimeBudgetMinutes() == null
        ? profile.getDailyMinutes()
        : input.dailyTimeBudgetMinutes();
    String policyControlStatus = memoryPolicyControlStatus(profile, control);
    List<MemoryCurvePolicy.ItemInput> itemInputs = memoryPolicyItems(profile, input);
    MemoryCurvePolicy.Result policyResult = memoryCurvePolicy.evaluate(new MemoryCurvePolicy.Input(
        policyVersion,
        policyControlStatus,
        policyEvaluatedAt,
        dailyBudget,
        itemInputs));
    List<MemoryItemPolicyStateView> decisions = policyResult.decisions().stream()
        .map(decision -> memoryItemPolicyStateView(profile, decision))
        .toList();
    PlannerReplayAudit replayAudit =
        writeMemoryPolicyReplay(profile, policyControlStatus, policyEvaluatedAt, dailyBudget, itemInputs, decisions, now);
    audit(userId, "goal_autopilot_item_policy_evaluated", "item_policy:" + profile.getGoalProfileId(), requestId, now);
    return new ItemPolicyDecisionResult(decisions, replayAuditView(replayAudit));
  }

  @Transactional(readOnly = true)
  public ActionResult nextAction(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "next_action");
    GoalProfile profile = requireActiveGoal(userId);
    requireControlNotPaused(profile);
    GoalDailyPlan dailyPlan = requireDailyPlan(profile);
    GoalProgressForecast forecast = requireForecast(profile);
    GoalPlanItem nextItem = requireNextItem(dailyPlan);
    recordGoalMetric(
        profile,
        "next_action",
        "success",
        nextItem.getReasonCode(),
        "goal_autopilot.actions.next",
        "plan_item:" + nextItem.getPlanItemId(),
        null);
    return new ActionResult(actionView(nextItem, "ready"), forecastView(forecast), new PlanUpdateSignalView("none", "no_replan_needed"));
  }

  @Transactional
  public ActionResult completeAction(UUID userId, UUID planItemId, String outcome, String requestId) {
    runtimeGate.requireMutationAllowed(userId, "action_complete", requestId);
    GoalPlanItem item = planItems.findByPlanItemIdAndUserId(planItemId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Plan item was not found."));
    String normalizedOutcome = clean(outcome);
    if (!Set.of("completed", "skipped", "deferred").contains(normalizedOutcome)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "outcome is invalid.");
    }
    GoalProfile profile = requireActiveGoal(userId);
    requireControlNotPaused(profile);
    GoalDailyPlan dailyPlan = requireDailyPlan(profile);
    Instant now = Instant.now(clock);
    item.markOutcome(normalizedOutcome, now);
    planItems.save(item);
    PlanUpdateSignalView signal = new PlanUpdateSignalView("none", "no_replan_needed");
    if ("skipped".equals(normalizedOutcome) || "deferred".equals(normalizedOutcome)) {
      dailyPlan.markRecoveryRequired(now);
      dailyPlans.save(dailyPlan);
      signal = new PlanUpdateSignalView("recovery_replan", "learner_" + normalizedOutcome);
    } else {
      planItems.findFirstByDailyPlanIdAndStatusInOrderByOrderIndexAsc(dailyPlan.getDailyPlanId(), List.of("pending"))
          .ifPresent(next -> {
            next.activate(now);
            planItems.save(next);
          });
    }
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    GoalProgressForecast forecast = upsertForecast(profile, diagnostic, normalizedOutcome, null, now);
    applyMasteryTransition(profile, item, diagnostic, normalizedOutcome, now);
    audit(userId, "goal_autopilot_action_" + normalizedOutcome, "plan_item:" + planItemId, requestId, now);
    recordGoalMetric(
        profile,
        "action_complete",
        "success",
        normalizedOutcome,
        "goal_autopilot.actions.complete",
        "plan_item:" + planItemId,
        requestId);
    GoalPlanItem current = planItems.findFirstByDailyPlanIdAndStatusInOrderByOrderIndexAsc(
            dailyPlan.getDailyPlanId(), List.of("active", "pending"))
        .orElse(item);
    return new ActionResult(actionView(current, current.getStatus()), forecastView(forecast), signal);
  }

  @Transactional(readOnly = true)
  public ForecastResult forecast(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "forecast");
    GoalProfile profile = requireActiveGoal(userId);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    EntitlementDepthView entitlementDepth = entitlementDepthView(profile, diagnostic);
    return new ForecastResult(forecastView(requireForecast(profile), entitlementDepth, userId), entitlementDepth);
  }

  @Transactional(readOnly = true)
  public CheckpointTaskDecisionView checkpointTask(UUID userId) {
    runtimeGate.requireReadAllowed(userId, "checkpoint_task");
    GoalProfile profile = requireActiveGoal(userId);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    return checkpointTaskView(checkpointTaskDecision(profile), entitlementDepthView(profile, diagnostic));
  }

  @Transactional
  public CheckpointResult submitCheckpoint(UUID userId, CheckpointInput input, String requestId) {
    runtimeGate.requireMutationAllowed(userId, "checkpoint_submit", requestId);
    GoalProfile profile = requireActiveGoal(userId);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    EntitlementDepthView entitlementDepth = entitlementDepthView(profile, diagnostic);
    Instant now = Instant.now(clock);
    GoalAutopilotControl control = ensureControl(profile, now);
    if ("paused".equals(control.getControlStatus())) {
      recordGoalMetric(
          profile,
          "checkpoint",
          "blocked",
          "paused",
          "goal_autopilot.checkpoints.submit",
          "control:" + control.getControlId(),
          requestId);
      throw new ApiException(
          HttpStatus.CONFLICT,
          "CONFLICT",
          "Goal autopilot is paused.",
          Map.of("reason_code", "paused", "control_id", control.getControlId().toString()));
    }
    String checkpointType = cleanOrDefault(input.checkpointType(), "weekly_mock");
    String requestedStatus = cleanOrDefault(input.resultStatus(), "recorded");
    if (!Set.of("recorded", "failed", "skipped").contains(requestedStatus)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "result_status is invalid.");
    }
    CheckpointCadencePolicy.Decision taskDecision = checkpointTaskDecision(profile, entitlementDepth);
    if ("CheckpointUnavailable".equals(taskDecision.checkpointState())) {
      String downgradeReason = stableDowngradeReason(taskDecision.limitationReason());
      recordGoalMetric(
          profile,
          "checkpoint",
          "blocked",
          downgradeReason,
          "goal_autopilot.checkpoints.submit",
          "goal_profile:" + profile.getGoalProfileId(),
          requestId);
      throw new ApiException(
          HttpStatus.CONFLICT,
          "CONFLICT",
          "Checkpoint task is unavailable for the active goal.",
          Map.of(
              "reason_code", downgradeReason,
              "source_reason", taskDecision.limitationReason(),
              "downgrade_state", "CheckpointUnavailable",
              "downgrade_reason", downgradeReason,
              "blocked_full_depth", true));
    }
    if (!allowedCheckpointTypes(profile).contains(checkpointType)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "checkpoint_type is invalid.");
    }
    validateCheckpointAudioRef(userId, input.audioRef());
    String usagePayloadHash = usagePayloadHash("checkpoint_submit", profile, Map.of(
        "checkpoint_type", checkpointType,
        "result_status", requestedStatus,
        "transcript_hash", clean(input.transcript()) == null ? "<none>" : sha256(clean(input.transcript())),
        "audio_ref_hash", clean(input.audioRef()) == null ? "<none>" : sha256(clean(input.audioRef()))));
    int costTokenEstimate = goalAutopilotTokenEstimate(profile, diagnostic, "checkpoint_submit", clean(input.transcript()));
    if (!entitlementDepth.providerCandidateAllowed()) {
      recordGoalCostPolicyRejection(profile, "scoring", entitlementDepth.limitationReason(), costTokenEstimate);
    }
    UsageReservation usageReservation = reserveGoalUsageWithCostTelemetry(
        profile, entitlementDepth, "checkpoint_submit", "scoring", requestId, usagePayloadHash, costTokenEstimate);
    try {
      String confidence = "recorded".equals(requestedStatus) ? confidenceAfterCheckpoint(input, diagnostic) : "low";
      String resultStatus = checkpointResultStatus(requestedStatus, confidence);
      String reasonCode = checkpointReasonCode(resultStatus);
      String summary = checkpointSummary(input, diagnostic);
      PlanFacts planFactsBefore = planFacts(profile);
      PlanUpdateSignalView baseSignal = checkpointPlanSignal(resultStatus, planFactsBefore, control);
      GoalOutcomeCheckpoint checkpoint = checkpoints.save(new GoalOutcomeCheckpoint(
          UUID.randomUUID(),
          profile.getGoalProfileId(),
          userId,
          checkpointType,
          "biweekly_mock".equals(checkpointType) ? "biweekly" : taskDecision.cadence(),
          resultStatus,
          confidence,
          summary,
          baseSignal.signalType(),
          baseSignal.reasonCode(),
          now));
      if ("checkpoint_replan".equals(baseSignal.signalType())) {
        markPlansStale(profile.getGoalProfileId(), baseSignal.reasonCode(), now);
        ensureControl(profile, now);
      }
      GoalProgressForecast forecast = upsertForecast(profile, diagnostic, checkpointForecastSource(resultStatus), confidence, now);
      applyCheckpointMasteryTransition(profile, checkpoint, confidence, now);
      PlannerReplayAudit replayAudit = writeCheckpointPlanReplay(
          profile, checkpoint, input, taskDecision, control, planFactsBefore, forecast, baseSignal, now);
      audit(userId, "goal_autopilot_checkpoint_recorded", "checkpoint:" + checkpoint.getCheckpointId(), requestId, now);
      recordGoalMetric(
          profile,
          "checkpoint",
          "success",
          checkpoint.getReasonCode(),
          "goal_autopilot.checkpoints.submit",
          "checkpoint:" + checkpoint.getCheckpointId(),
          requestId);
      if (entitlementDepth.providerCandidateAllowed()) {
        if ("recorded".equals(resultStatus)) {
          recordGoalCostDeterministicNoProvider(
              profile,
              "scoring",
              "deterministic_no_provider_call:checkpoint_submit",
              costTokenEstimate);
        } else {
          recordGoalCostPolicyRejection(
              profile,
              "scoring",
              "checkpoint_no_charge:" + resultStatus,
              costTokenEstimate);
        }
      }
      closeGoalUsageReservation(profile, usageReservation, "checkpoint_submit", usagePayloadHash, "recorded".equals(resultStatus));
      return new CheckpointResult(
          checkpointView(checkpoint),
          forecastView(forecast, entitlementDepth, userId),
          entitlementDepth,
          new PlanUpdateSignalView(
              baseSignal.signalType(),
              baseSignal.reasonCode(),
              checkpoint.getCheckpointId(),
              CHECKPOINT_PLAN_RULE_VERSION,
              replayAudit.getInputSnapshotHash(),
              replayAudit.getReplayAuditId()));
    } catch (RuntimeException e) {
      closeGoalUsageReservation(profile, usageReservation, "checkpoint_submit", usagePayloadHash, false);
      recordGoalMetric(
          profile,
          "checkpoint",
          "error",
          exceptionReason(e),
          "goal_autopilot.checkpoints.submit",
          "goal_profile:" + profile.getGoalProfileId(),
          requestId);
      throw e;
    }
  }

  private String checkpointResultStatus(String requestedStatus, String confidence) {
    if ("failed".equals(requestedStatus) || "skipped".equals(requestedStatus)) {
      return requestedStatus;
    }
    return "low".equals(confidence) ? "low_confidence" : "recorded";
  }

  private String checkpointReasonCode(String resultStatus) {
    return switch (resultStatus) {
      case "recorded" -> "checkpoint_updated_gap";
      case "low_confidence" -> "low_confidence";
      case "failed" -> "checkpoint_failed";
      case "skipped" -> "checkpoint_skipped";
      default -> "unsupported_goal";
    };
  }

  private String checkpointForecastSource(String resultStatus) {
    return switch (resultStatus) {
      case "skipped" -> "skipped";
      case "failed" -> "checkpoint_failed";
      default -> "checkpoint";
    };
  }

  private PlanUpdateSignalView checkpointPlanSignal(
      String resultStatus, PlanFacts planFactsBefore, GoalAutopilotControl control) {
    if (!"recorded".equals(resultStatus)) {
      return new PlanUpdateSignalView("none", checkpointReasonCode(resultStatus));
    }
    if ("blocked_by_policy".equals(control.getControlStatus())) {
      return new PlanUpdateSignalView("stale_plan", "control_blocked");
    }
    if (planFactsBefore.recoveryRequired()) {
      return new PlanUpdateSignalView("recovery_replan", "recovery_required");
    }
    if (planFactsBefore.stalePlan()) {
      return new PlanUpdateSignalView("stale_plan", "stale_plan");
    }
    return new PlanUpdateSignalView("checkpoint_replan", "checkpoint_updated_gap");
  }

  private GoalAutopilotControl ensureControl(GoalProfile profile, Instant now) {
    GoalAutopilotControl control = controls.findFirstByGoalProfileIdOrderByUpdatedAtDesc(profile.getGoalProfileId())
        .orElseGet(() -> new GoalAutopilotControl(
            UUID.randomUUID(),
            profile.getUserId(),
            profile.getGoalProfileId(),
            policyStatus(profile),
            profile.getQuietHoursStart(),
            profile.getQuietHoursEnd(),
            DEFAULT_TIMEZONE,
            profile.isNotificationConsent(),
            profile.getIntensityPreference(),
            "balanced",
            CONTROL_RULE_VERSION,
            now));
    control.setPolicyStatus(policyStatus(profile), now);
    return controls.save(control);
  }

  private void activateControlAfterPlan(GoalProfile profile, Instant now) {
    GoalAutopilotControl control = ensureControl(profile, now);
    if (!"paused".equals(control.getControlStatus())) {
      control.setPolicyStatus(policyStatus(profile), now);
      controls.save(control);
    }
  }

  private void requireControlNotPaused(GoalProfile profile) {
    GoalAutopilotControl control = ensureControl(profile, Instant.now(clock));
    if ("paused".equals(control.getControlStatus())) {
      throw new ApiException(
          HttpStatus.CONFLICT,
          "CONFLICT",
          "Goal autopilot is paused.",
          Map.of("reason_code", "paused", "control_id", control.getControlId().toString()));
    }
  }

  private ControlResult withControlIdempotency(
      GoalProfile profile,
      String operation,
      String idempotencyKey,
      String requestHash,
      Supplier<ControlResult> mutation) {
    requireIdempotencyKey(idempotencyKey);
    GoalAutopilotControlIdempotency existing = controlIdempotency
        .findByUserIdAndGoalProfileIdAndGoalRevisionAndOperationAndIdempotencyKey(
            profile.getUserId(), profile.getGoalProfileId(), profile.getRevision(), operation, idempotencyKey)
        .orElse(null);
    if (existing != null) {
      if (!existing.getRequestHash().equals(requestHash)) {
        throw new ApiException(HttpStatus.CONFLICT, "IDEMPOTENCY_CONFLICT", "Idempotency key reused with different control payload.");
      }
      return fromJson(existing.getResponseJson(), CONTROL_RESULT);
    }

    ControlResult result = mutation.get();
    controlIdempotency.save(new GoalAutopilotControlIdempotency(
        UUID.randomUUID(),
        profile.getUserId(),
        profile.getGoalProfileId(),
        profile.getRevision(),
        operation,
        idempotencyKey,
        requestHash,
        toJson(result),
        Instant.now(clock)));
    return result;
  }

  private void requireIdempotencyKey(String idempotencyKey) {
    if (idempotencyKey == null || idempotencyKey.length() < 8 || idempotencyKey.length() > 128) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
    }
  }

  private String controlRequestHash(String operation, GoalProfile profile, Map<String, String> requestValues) {
    TreeMap<String, String> payload = new TreeMap<>();
    payload.put("operation", operation);
    payload.put("goal_profile_id", profile.getGoalProfileId().toString());
    payload.put("goal_revision", Integer.toString(profile.getRevision()));
    payload.putAll(requestValues);
    return sha256(toJson(payload));
  }

  private String goalCreateRequestHash(GoalInput input) {
    TreeMap<String, Object> payload = new TreeMap<>();
    payload.put("operation", "goal_create_or_update");
    payload.put("goal_type", nullableHashValue(clean(input.goalType())));
    payload.put("target_score", nullableHashValue(input.targetScore()));
    payload.put("target_ability", nullableHashValue(clean(input.targetAbility())));
    payload.put("deadline", nullableHashValue(input.deadline()));
    payload.put("daily_minutes", nullableHashValue(input.dailyMinutes()));
    payload.put("intensity_preference", nullableHashValue(clean(input.intensityPreference())));
    payload.put("quiet_hours_start", nullableHashValue(clean(input.quietHoursStart())));
    payload.put("quiet_hours_end", nullableHashValue(clean(input.quietHoursEnd())));
    payload.put("notification_consent", Boolean.toString(input.notificationConsent()));
    List<Map<String, String>> samples = input.diagnosticSamples() == null
        ? List.of()
        : input.diagnosticSamples().stream()
            .map(sample -> {
              Map<String, String> samplePayload = new TreeMap<>();
              samplePayload.put("sample_ref", nullableHashValue(clean(sample.sampleRef())));
              samplePayload.put("transcript", nullableHashValue(clean(sample.transcript())));
              samplePayload.put("audio_ref", nullableHashValue(clean(sample.audioRef())));
              samplePayload.put("duration_seconds", nullableHashValue(sample.durationSeconds()));
              return samplePayload;
            })
            .toList();
    payload.put("diagnostic_samples", samples);
    return sha256(toJson(payload));
  }

  private UsageReservation reserveGoalUsageIfRequired(
      GoalProfile profile,
      EntitlementDepthView entitlementDepth,
      String operation,
      String usageFamily,
      String requestId,
      String payloadHash) {
    if (!entitlementDepth.providerCandidateAllowed()) {
      return null;
    }
    String requestRef = clean(requestId);
    String idempotencySeed = requestRef == null ? "payload:" + payloadHash : "request:" + requestRef;
    String idempotencyKey = "goal-autopilot-" + operation.replace('_', '-') + "-" + sha256(idempotencySeed).substring(0, 32);
    String sourceRef = "goal_autopilot:" + operation + ":" + payloadHash.substring(0, 24);
    return usageService.reserve(profile.getUserId(), usageFamily, 1, idempotencyKey, sourceRef);
  }

  private UsageReservation reserveGoalUsageWithCostTelemetry(
      GoalProfile profile,
      EntitlementDepthView entitlementDepth,
      String operation,
      String usageFamily,
      String requestId,
      String payloadHash,
      int tokenEstimate) {
    try {
      return reserveGoalUsageIfRequired(profile, entitlementDepth, operation, usageFamily, requestId, payloadHash);
    } catch (ApiException e) {
      if ("USAGE_LIMIT_EXCEEDED".equals(e.getCode())) {
        recordGoalCostPolicyRejection(profile, usageFamily, "quota_exhausted:" + operation, tokenEstimate);
        recordGoalMetric(
            profile,
            "quota_error",
            "blocked",
            "quota_exhausted",
            "goal_autopilot." + operation,
            "goal_profile:" + profile.getGoalProfileId(),
            requestId);
        throw quotaDowngradeException(e, operation, usageFamily);
      }
      throw e;
    }
  }

  private ApiException quotaDowngradeException(ApiException exception, String operation, String usageFamily) {
    Map<String, Object> details = new LinkedHashMap<>(exception.getDetails());
    details.put("usage_family", usageFamily);
    details.put("operation", operation);
    details.put("downgrade_state", "QuotaDowngraded");
    details.put("downgrade_reason", "quota_exhausted");
    details.put("blocked_full_depth", true);
    return new ApiException(
        exception.getStatus(),
        exception.getCode(),
        exception.getMessage(),
        Map.copyOf(details));
  }

  private void recordGoalCostDeterministicNoProvider(
      GoalProfile profile,
      String usageFamily,
      String fallbackReason,
      int tokenEstimate) {
    aiCostMetricsService.recordDeterministicNoProvider(
        profile.getUserId(),
        usageFamily,
        costMetricPlan(profile.getUserId()),
        tokenEstimate,
        fallbackReason);
    recordGoalMetric(
        profile,
        "provider_fallback",
        "fallback",
        fallbackReason,
        "goal_autopilot.cost_metric",
        "goal_profile:" + profile.getGoalProfileId(),
        null);
  }

  private void recordGoalCostPolicyRejection(
      GoalProfile profile,
      String usageFamily,
      String fallbackReason,
      int tokenEstimate) {
    aiCostMetricsService.recordPolicyRejection(
        profile.getUserId(),
        usageFamily,
        costMetricPlan(profile.getUserId()),
        tokenEstimate,
        null,
        fallbackReason);
    recordGoalMetric(
        profile,
        "quota_error",
        "blocked",
        fallbackReason,
        "goal_autopilot.cost_metric",
        "goal_profile:" + profile.getGoalProfileId(),
        null);
  }

  private String costMetricPlan(UUID userId) {
    return commercialFoundationService.latestEntitlement(userId)
        .orElseGet(() -> commercialFoundationService.defaultFreeEntitlement(userId))
        .getPlan();
  }

  private int goalAutopilotTokenEstimate(
      GoalProfile profile,
      GoalDiagnosticAssessment diagnostic,
      String operation,
      String extraText) {
    int chars = 0;
    chars += nullableLength(operation);
    chars += nullableLength(profile.getGoalType());
    chars += nullableLength(profile.getTargetAbility());
    chars += nullableLength(profile.getSupportStatus());
    chars += nullableLength(profile.getIntensityPreference());
    chars += nullableLength(profile.getLimitationMessage());
    chars += nullableLength(diagnostic.getRubricScoresJson());
    chars += nullableLength(diagnostic.getWeaknessTagsJson());
    chars += nullableLength(diagnostic.getReasonCode());
    chars += nullableLength(extraText);
    return Math.max(1, Math.min(4000, chars / 4));
  }

  private int goalAutopilotTokenEstimate(
      GoalProfile profile,
      GoalDiagnosticAssessment diagnostic,
      String operation) {
    return goalAutopilotTokenEstimate(profile, diagnostic, operation, null);
  }

  private int nullableLength(String value) {
    return value == null ? 0 : value.length();
  }

  private void closeGoalUsageReservation(
      GoalProfile profile,
      UsageReservation reservation,
      String operation,
      String payloadHash,
      boolean success) {
    if (reservation == null) {
      return;
    }
    String eventRef = "goal_autopilot:" + operation + ":" + (success ? "committed:" : "released:") + payloadHash.substring(0, 16);
    if (success) {
      usageService.commit(profile.getUserId(), reservation.getReservationId(), eventRef);
    } else {
      usageService.release(profile.getUserId(), reservation.getReservationId(), eventRef);
    }
  }

  private String usagePayloadHash(String operation, GoalProfile profile, Map<String, String> requestValues) {
    TreeMap<String, String> payload = new TreeMap<>();
    payload.put("operation", operation);
    payload.put("goal_profile_id", profile.getGoalProfileId().toString());
    payload.put("goal_revision", Integer.toString(profile.getRevision()));
    payload.putAll(requestValues);
    return sha256(toJson(payload));
  }

  private String nullableHashValue(Object value) {
    return value == null ? "<null>" : value.toString();
  }

  private String sha256(String value) {
    try {
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(digest);
    } catch (Exception e) {
      throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "CONFLICT", "Could not hash control idempotency payload.");
    }
  }

  private String sha256Prefixed(Object value) {
    try {
      String payload = value instanceof Map<?, ?> map ? toJson(new TreeMap<>(map)) : value.toString();
      byte[] digest = MessageDigest.getInstance("SHA-256").digest(payload.getBytes(StandardCharsets.UTF_8));
      return "sha256:" + HexFormat.of().formatHex(digest);
    } catch (Exception e) {
      throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "CONFLICT", "Could not hash recovery planner payload.");
    }
  }

  private ControlResult controlResult(
      GoalProfile profile, GoalAutopilotControl control, String reasonCode, String planSignalReason) {
    Instant now = Instant.now(clock);
    NotificationEligibilityDecisionView eligibility = reminderEligibilityDecision(profile, control, null, "control_response", "granted", now);
    boolean replanRequired = "resume_requires_replan".equals(planSignalReason);
    return new ControlResult(
        controlView(control, reasonCode),
        true,
        true,
        replanRequired,
        reasonCode,
        eligibility,
        new PlanUpdateSignalView(replanRequired ? "recovery_replan" : "none", planSignalReason));
  }

  private ControlResult disabledControlResult(
      GoalProfile profile, GoalAutopilotRuntimeGate.RuntimeGateDecision runtimeDecision) {
    Instant now = Instant.now(clock);
    UUID controlId = UUID.nameUUIDFromBytes((
            "goal-autopilot-disabled-control:"
                + profile.getGoalProfileId()
                + ":"
                + profile.getRevision()
                + ":"
                + runtimeDecision.reasonCode()
                + ":"
                + runtimeDecision.ruleVersion())
        .getBytes(StandardCharsets.UTF_8));
    String decisionId = UUID.nameUUIDFromBytes((
            controlId
                + ":"
                + runtimeDecision.reasonCode()
                + ":"
                + runtimeDecision.ruleVersion())
        .getBytes(StandardCharsets.UTF_8)).toString();
    return new ControlResult(
        new ControlView(
            controlId,
            profile.getUserId(),
            profile.getGoalProfileId(),
            "blocked_by_policy",
            null,
            runtimeDecision.reasonCode(),
            null,
            profile.getQuietHoursStart(),
            profile.getQuietHoursEnd(),
            DEFAULT_TIMEZONE,
            false,
            profile.getIntensityPreference(),
            "balanced",
            now,
            runtimeDecision.ruleVersion()),
        true,
        true,
        false,
        runtimeDecision.reasonCode(),
        new NotificationEligibilityDecisionView(
            decisionId,
            controlId,
            profile.getUserId(),
            profile.getGoalProfileId(),
            null,
            false,
            runtimeDecision.reasonCode(),
            null,
            runtimeDecision.reasonCode(),
            now,
            runtimeDecision.ruleVersion()),
        new PlanUpdateSignalView("none", runtimeDecision.reasonCode()));
  }

  private ControlView controlView(GoalAutopilotControl control, String reasonCode) {
    String status = "paused".equals(control.getControlStatus()) ? "paused" : switch (reasonCode) {
      case "unsupported_goal", "missing_plan", "stale_plan" -> "blocked_by_policy";
      default -> control.getControlStatus();
    };
    return new ControlView(
        control.getControlId(),
        control.getUserId(),
        control.getGoalProfileId(),
        status,
        control.getPausedAt(),
        control.getPauseReason(),
        control.getResumedAt(),
        control.getQuietHoursStart(),
        control.getQuietHoursEnd(),
        control.getTimezone(),
        control.isNotificationConsent(),
        control.getIntensityOverride(),
        control.getMissedDayPolicy(),
        control.getUpdatedAt(),
        control.getRuleVersion());
  }

  private String policyStatus(GoalProfile profile) {
    return switch (policyReason(profile)) {
      case "unsupported_goal", "missing_plan", "stale_plan" -> "blocked_by_policy";
      default -> "active";
    };
  }

  private String controlReason(GoalProfile profile, GoalAutopilotControl control) {
    if ("paused".equals(control.getControlStatus())) {
      return "paused";
    }
    return policyReason(profile);
  }

  private String policyReason(GoalProfile profile) {
    if ("unsupported".equals(profile.getSupportStatus()) || "unsupported".equals(profile.getStatus())) {
      return "unsupported_goal";
    }
    PlanFacts facts = planFacts(profile);
    if (facts.stalePlan()) {
      return "stale_plan";
    }
    if (facts.missingPlan()) {
      return "missing_plan";
    }
    return "eligible";
  }

  private NotificationEligibilityDecisionView reminderEligibilityDecision(
      GoalProfile profile,
      GoalAutopilotControl control,
      UUID requestedPlanItemId,
      String reminderSlot,
      String platformPermission,
      Instant evaluatedAt) {
    PlanFacts facts = planFacts(profile);
    GoalPlanItem targetItem = reminderPlanItem(profile, requestedPlanItemId);
    boolean missingReminderTarget = targetItem == null;
    ReminderCommercialGate commercialGate = reminderCommercialGate(profile);
    boolean unsupportedGoal = "unsupported".equals(profile.getSupportStatus()) || "unsupported".equals(profile.getStatus());
    boolean partialGoalLimited = "partial".equals(profile.getSupportStatus());
    boolean genericPolicyBlocked = "blocked_by_policy".equals(control.getControlStatus())
        && !unsupportedGoal
        && !partialGoalLimited
        && !facts.stalePlan()
        && !facts.missingPlan();
    String eligibilityControlStatus = "paused".equals(control.getControlStatus()) ? "paused" : "active";
    NotificationEligibilityPolicy.Decision decision = notificationEligibilityPolicy.evaluate(new NotificationEligibilityPolicy.Input(
        eligibilityControlStatus,
        genericPolicyBlocked,
        unsupportedGoal,
        partialGoalLimited,
        facts.stalePlan() || facts.recoveryRequired(),
        facts.missingPlan() || missingReminderTarget,
        control.isNotificationConsent(),
        "granted".equals(platformPermission),
        commercialGate.entitlementAllowed(),
        commercialGate.quotaAvailable(),
        control.getQuietHoursStart(),
        control.getQuietHoursEnd(),
        control.getTimezone(),
        evaluatedAt));
    UUID planItemId = targetItem == null ? null : targetItem.getPlanItemId();
    return new NotificationEligibilityDecisionView(
        notificationEligibilityDecisionId(
            profile, control, planItemId, reminderSlot, platformPermission, decision),
        control.getControlId(),
        profile.getUserId(),
        profile.getGoalProfileId(),
        planItemId,
        decision.eligible(),
        decision.reasonCode(),
        decision.nextAllowedAt(),
        decision.explanationKey(),
        decision.evaluatedAt(),
        decision.ruleVersion());
  }

  private GoalPlanItem reminderPlanItem(GoalProfile profile, UUID requestedPlanItemId) {
    if (requestedPlanItemId == null) {
      try {
        return requireNextItem(latestDailyPlan(profile));
      } catch (ApiException ignored) {
        return null;
      }
    }
    GoalPlanItem item = planItems.findByPlanItemIdAndUserId(requestedPlanItemId, profile.getUserId())
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Plan item was not found."));
    if (!item.getGoalProfileId().equals(profile.getGoalProfileId())) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Plan item does not belong to the active goal.");
    }
    GoalDailyPlan dailyPlan = dailyPlans.findById(item.getDailyPlanId())
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Daily plan was not found."));
    if (!dailyPlan.getGoalProfileId().equals(profile.getGoalProfileId()) || !ACTIVE_DAILY_STATUSES.contains(dailyPlan.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Plan item is not part of the current active plan.");
    }
    if (!REMINDER_ITEM_STATUSES.contains(item.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Plan item is not eligible for reminders.");
    }
    return item;
  }

  private ReminderCommercialGate reminderCommercialGate(GoalProfile profile) {
    EntitlementDepthView entitlementDepth = entitlementDepthView(profile, requireDiagnostic(profile));
    String downgradeReason = fullDepthDowngradeReason(profile.getUserId(), entitlementDepth);
    if ("quota_exhausted".equals(downgradeReason) || "cost_budget_limited".equals(downgradeReason)) {
      return new ReminderCommercialGate(true, false);
    }
    if ("entitlement_required".equals(downgradeReason) || "blocked".equals(entitlementDepth.depthState())) {
      return new ReminderCommercialGate(false, true);
    }
    return new ReminderCommercialGate(true, true);
  }

  private String notificationEligibilityDecisionId(
      GoalProfile profile,
      GoalAutopilotControl control,
      UUID planItemId,
      String reminderSlot,
      String platformPermission,
      NotificationEligibilityPolicy.Decision decision) {
    return UUID.nameUUIDFromBytes((
            profile.getUserId()
                + ":" + profile.getGoalProfileId()
                + ":" + profile.getRevision()
                + ":" + control.getControlId()
                + ":" + nullableHashValue(planItemId)
                + ":" + nullableHashValue(reminderSlot)
                + ":" + nullableHashValue(platformPermission)
                + ":" + decision.reasonCode()
                + ":" + nullableHashValue(decision.nextAllowedAt())
                + ":" + decision.evaluatedAt()
                + ":" + decision.ruleVersion())
        .getBytes(StandardCharsets.UTF_8)).toString();
  }

  private PlanFacts planFacts(GoalProfile profile) {
    GoalBackplan activeBackplan = latestBackplan(profile);
    GoalBackplan staleBackplan = activeBackplan == null
        ? backplans.findByGoalProfileIdAndStatusIn(profile.getGoalProfileId(), List.of("stale")).stream().findFirst().orElse(null)
        : null;
    GoalDailyPlan activeDailyPlan = latestDailyPlanOrNull(profile);
    GoalDailyPlan staleDailyPlan = activeDailyPlan == null
        ? dailyPlans.findFirstByGoalProfileIdAndStatusInOrderByPlanDateDesc(profile.getGoalProfileId(), List.of("stale")).orElse(null)
        : null;
    boolean missing = activeBackplan == null && staleBackplan == null
        || activeDailyPlan == null && staleDailyPlan == null;
    boolean recoveryRequired = activeDailyPlan != null && "recovery_required".equals(activeDailyPlan.getStatus());
    return new PlanFacts(missing, staleBackplan != null || staleDailyPlan != null, recoveryRequired);
  }

  private UUID nextPlanItemIdOrNull(GoalProfile profile) {
    try {
      return requireNextItem(latestDailyPlan(profile)).getPlanItemId();
    } catch (ApiException ignored) {
      return null;
    }
  }

  private String validateClockTime(String value, String field) {
    String cleaned = clean(value);
    if (cleaned == null || !cleaned.matches(TIME_PATTERN)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", field + " is invalid.");
    }
    return cleaned;
  }

  private String validateTimezone(String value) {
    String cleaned = cleanRequired(value, "timezone");
    try {
      ZoneId.of(cleaned);
      return cleaned;
    } catch (DateTimeException e) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "timezone is invalid.");
    }
  }

  private String validateOneOf(String value, Set<String> allowed, String field) {
    String cleaned = cleanRequired(value, field);
    if (!allowed.contains(cleaned)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", field + " is invalid.");
    }
    return cleaned;
  }

  private void validateDiagnosticAudioRefs(UUID userId, List<DiagnosticSampleInput> samples) {
    if (samples == null) {
      return;
    }
    samples.stream()
        .map(DiagnosticSampleInput::audioRef)
        .map(this::clean)
        .filter(value -> value != null)
        .forEach(audioRef -> aiGatewayService.validateTrustedAudioRef(userId, "goal_diagnostic", audioRef));
  }

  private void validateCheckpointAudioRef(UUID userId, String audioRef) {
    String cleaned = clean(audioRef);
    if (cleaned != null) {
      aiGatewayService.validateTrustedAudioRef(userId, "goal_checkpoint", cleaned);
    }
  }

  private String validateReminderSlot(String value) {
    String cleaned = cleanRequired(value, "reminder_slot");
    if (!cleaned.matches(REMINDER_SLOT_PATTERN)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "reminder_slot is invalid.");
    }
    return cleaned;
  }

  private String validatePlatformPermission(String value) {
    String cleaned = cleanOrDefault(value, "unknown");
    if (!VALID_PLATFORM_PERMISSIONS.contains(cleaned)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "platform_permission is invalid.");
    }
    return cleaned;
  }

  private UUID parseOptionalUuid(String value, String field) {
    String cleaned = clean(value);
    if (cleaned == null) {
      return null;
    }
    try {
      return UUID.fromString(cleaned);
    } catch (IllegalArgumentException e) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", field + " is invalid.");
    }
  }

  private Instant parseOptionalInstant(String value, String field) {
    String cleaned = clean(value);
    if (cleaned == null) {
      return null;
    }
    try {
      return Instant.parse(cleaned);
    } catch (DateTimeException e) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", field + " is invalid.");
    }
  }

  private GoalDiagnosticAssessment buildDiagnostic(
      GoalProfile profile, List<DiagnosticSampleInput> samples, SupportDecision support, Instant now) {
    int sampleCount = samples == null ? 0 : samples.size();
    int transcriptChars = samples == null
        ? 0
        : samples.stream().map(DiagnosticSampleInput::transcript).filter(value -> value != null).mapToInt(String::length).sum();
    String confidence = "unsupported".equals(support.supportStatus())
        ? "low"
        : sampleCount >= 3 && transcriptChars >= 180 ? "high" : sampleCount >= 1 ? "medium" : "low";
    String status = "unsupported".equals(support.supportStatus())
        ? "unsupported"
        : "low".equals(confidence) ? "low_confidence" : "complete";
    double baseScore = "high".equals(confidence) ? 6.0 : "medium".equals(confidence) ? 5.0 : 4.0;
    List<RubricScoreView> scores = List.of(
        new RubricScoreView("fluency", baseScore, 0.72, "diagnostic_sample_1"),
        new RubricScoreView("grammar_vocabulary", Math.max(1.0, baseScore - 0.5), 0.68, "diagnostic_sample_1"),
        new RubricScoreView("pronunciation", Math.min(9.0, baseScore + 0.3), 0.65, "diagnostic_sample_1"),
        new RubricScoreView("scenario_fit", Math.max(1.0, baseScore - 0.2), 0.7, "diagnostic_sample_1"));
    List<WeaknessTagView> weaknesses = List.of(
        new WeaknessTagView("limited_extension", "high", "fluency", "longer turn expansion", "diagnostic_sample_1"),
        new WeaknessTagView("example_depth", "medium", "scenario_fit", "answer with concrete examples", "diagnostic_sample_1"));
    ClaimGuardView guard = claimGuard(false);
    return new GoalDiagnosticAssessment(
        UUID.randomUUID(),
        profile.getGoalProfileId(),
        profile.getUserId(),
        status,
        confidence,
        sampleCount,
        toJson(scores),
        toJson(weaknesses),
        toJson(guard),
        "unsupported".equals(support.supportStatus()) ? support.reasonCode() : "deterministic_diagnostic_v1",
        now);
  }

  private void saveInitialMasteryStates(GoalProfile profile, GoalDiagnosticAssessment diagnostic, Instant now) {
    masteryInitialStates.deleteByGoalProfileId(profile.getGoalProfileId());
    List<RubricScoreView> scores = fromJson(diagnostic.getRubricScoresJson(), RUBRIC_LIST);
    scores.forEach(score -> masteryInitialStates.save(new GoalMasteryInitialState(
        UUID.randomUUID(),
        profile.getGoalProfileId(),
        profile.getUserId(),
        score.dimension(),
        initialLevelFor(score.score()),
        score.evidenceRef() == null || score.evidenceRef().isBlank() ? diagnostic.getDiagnosticAssessmentId().toString() : score.evidenceRef(),
        now)));
  }

  private String initialLevelFor(double score) {
    if (score >= 7.5) {
      return "L4";
    }
    if (score >= 6.0) {
      return "L3";
    }
    if (score >= 4.5) {
      return "L2";
    }
    if (score >= 3.0) {
      return "L1";
    }
    return "L0";
  }

  private SupportDecision decideSupport(
      String goalType, Double targetScore, String targetAbility, LocalDate deadline, int dailyMinutes) {
    if (!SUPPORTED_GOALS.contains(goalType)) {
      return new SupportDecision(
          UUID.randomUUID().toString(),
          "unsupported",
          "goal_type_not_supported",
          "This target is outside the current supported goal matrix.",
          false,
          "none");
    }
    boolean scoreOutOfRange =
        ("ielts_speaking".equals(goalType) && targetScore != null && (targetScore < 4.0 || targetScore > 9.0))
            || ("toefl_speaking".equals(goalType) && targetScore != null && (targetScore < 10.0 || targetScore > 30.0));
    if (scoreOutOfRange) {
      return new SupportDecision(
          UUID.randomUUID().toString(),
          "unsupported",
          "target_score_out_of_supported_range",
          "The requested score is outside the current product-internal rubric range.",
          true,
          "rubric_only");
    }
    long days = ChronoUnit.DAYS.between(LocalDate.now(clock), deadline);
    boolean partial = dailyMinutes < 15 || days < 21 || (targetScore == null && (targetAbility == null || targetAbility.isBlank()));
    if (partial) {
      return new SupportDecision(
          UUID.randomUUID().toString(),
          "partial",
          "limited_time_or_target_precision",
          "The system can create a conservative plan, but ETA and claim precision are limited.",
          true,
          "partial_content_and_time");
    }
    return new SupportDecision(
        UUID.randomUUID().toString(),
        "supported",
        "rubric_and_content_available",
        "Product-internal rubric only; no official score certification.",
        true,
        "sufficient_for_local_plan");
  }

  private void createDefaultPlanItems(GoalProfile profile, GoalDailyPlan dailyPlan, String risk, boolean partial, Instant now) {
    int trainingMinutes = Math.min(Math.max(8, profile.getDailyMinutes() / 2), 20);
    int reviewMinutes = Math.min(Math.max(5, profile.getDailyMinutes() / 3), 12);
    planItems.save(new GoalPlanItem(
        UUID.randomUUID(),
        dailyPlan.getDailyPlanId(),
        profile.getGoalProfileId(),
        profile.getUserId(),
        "training",
        "Fluency expansion drill",
        "highest_weakness_and_memory_risk",
        trainingMinutes,
        "active",
        risk,
        partial ? "low" : "standard",
        1,
        now));
    planItems.save(new GoalPlanItem(
        UUID.randomUUID(),
        dailyPlan.getDailyPlanId(),
        profile.getGoalProfileId(),
        profile.getUserId(),
        "review",
        "Spaced retrieval review",
        "memory_curve_due_review",
        reviewMinutes,
        "pending",
        risk,
        "low",
        2,
        now));
  }

  private GoalProgressForecast upsertForecast(
      GoalProfile profile, GoalDiagnosticAssessment diagnostic, String source, String overrideConfidence, Instant now) {
    String confidence = overrideConfidence == null ? diagnostic.getConfidenceBand() : overrideConfidence;
    LocalDate today = LocalDate.now(clock);
    PlanFacts facts = planFacts(profile);
    boolean recoveryRequired = facts.recoveryRequired() || "skipped".equals(source) || "deferred".equals(source);
    ProgressForecastPolicy.Decision decision = progressForecastPolicy.evaluate(new ProgressForecastPolicy.Input(
        ProgressForecastPolicy.RULE_VERSION,
        profile.getSupportStatus(),
        profile.getStatus(),
        confidence,
        profile.getDailyMinutes(),
        profile.getDeadline(),
        today,
        profile.getRevision(),
        source,
        latestCheckpoint(profile) != null,
        facts.stalePlan(),
        recoveryRequired,
        false,
        false,
        "deterministic_no_provider_path"));
    GoalProgressForecast forecast = forecasts.findFirstByGoalProfileIdOrderByUpdatedAtDesc(profile.getGoalProfileId())
        .orElseGet(() -> new GoalProgressForecast(
            UUID.randomUUID(),
            profile.getGoalProfileId(),
            profile.getUserId(),
            profile.getRevision(),
            "limited",
            "",
            null,
            null,
            null,
            "",
            null,
            "low",
            "high",
            "",
            "checkpoint_evidence_missing",
            today.plusDays(7),
            toJson(claimGuard(false)),
            "checkpoint_evidence_missing",
            "deterministic_policy",
            "deterministic_no_provider_path",
            ProgressForecastPolicy.RULE_VERSION,
            now));
    forecast.update(
        decision.sourceGoalRevision(),
        decision.forecastState(),
        decision.gapSummary(),
        decision.etaDate(),
        decision.etaRangeStart(),
        decision.etaRangeEnd(),
        decision.etaWindow(),
        decision.etaUnavailableReason(),
        decision.confidenceBand(),
        decision.riskLevel(),
        decision.riskReason(),
        decision.riskReasonCode(),
        decision.nextCheckpointDate(),
        toJson(claimGuard(decision.goalCompletionClaimAllowed())),
        decision.explanationKey(),
        decision.explanationSource(),
        decision.aiExplanationUnavailableReason(),
        decision.ruleVersion(),
        now);
    return forecasts.save(forecast);
  }

  private void markPlansStale(UUID goalProfileId, String reasonCode, Instant now) {
    backplans.findByGoalProfileIdAndStatusIn(goalProfileId, ACTIVE_PLAN_STATUSES)
        .forEach(plan -> {
          plan.markStale(reasonCode, now);
          backplans.save(plan);
        });
    dailyPlans.findByGoalProfileIdAndStatusIn(goalProfileId, ACTIVE_DAILY_STATUSES)
        .forEach(plan -> {
          plan.markStale(now);
          dailyPlans.save(plan);
        });
  }

  private GoalProfile requireActiveGoal(UUID userId) {
    requireUser(userId);
    return goalProfiles.findFirstByUserIdAndStatusInOrderByUpdatedAtDesc(userId, ACTIVE_GOAL_STATUSES)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Active goal profile was not found."));
  }

  private void requireUser(UUID userId) {
    users.findById(userId)
        .filter(user -> "active".equals(user.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
  }

  private void requireUserForUpdate(UUID userId) {
    users.findByIdForUpdate(userId)
        .filter(user -> "active".equals(user.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
  }

  private GoalDiagnosticAssessment requireDiagnostic(GoalProfile profile) {
    return diagnostics.findFirstByGoalProfileIdOrderByCreatedAtDesc(profile.getGoalProfileId())
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Diagnostic assessment was not found."));
  }

  private GoalProgressForecast requireForecast(GoalProfile profile) {
    return forecasts.findFirstByGoalProfileIdOrderByUpdatedAtDesc(profile.getGoalProfileId())
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Progress forecast was not found."));
  }

  private GoalDailyPlan requireDailyPlan(GoalProfile profile) {
    return latestDailyPlan(profile);
  }

  private GoalDailyPlan latestDailyPlan(GoalProfile profile) {
    LocalDate today = LocalDate.now(clock);
    return dailyPlans.findFirstByGoalProfileIdAndPlanDateAndStatusInOrderByCreatedAtDesc(
            profile.getGoalProfileId(), today, ACTIVE_DAILY_STATUSES)
        .or(() -> dailyPlans.findFirstByGoalProfileIdAndStatusInOrderByPlanDateDesc(profile.getGoalProfileId(), ACTIVE_DAILY_STATUSES))
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Daily plan was not found."));
  }

  private GoalDailyPlan latestDailyPlanOrNull(GoalProfile profile) {
    try {
      return latestDailyPlan(profile);
    } catch (ApiException ignored) {
      return null;
    }
  }

  private GoalBackplan latestBackplan(GoalProfile profile) {
    return backplans.findFirstByGoalProfileIdAndStatusInOrderByStartDateDesc(profile.getGoalProfileId(), ACTIVE_PLAN_STATUSES)
        .orElse(null);
  }

  private GoalOutcomeCheckpoint latestCheckpoint(GoalProfile profile) {
    return checkpoints.findFirstByGoalProfileIdOrderByCreatedAtDesc(profile.getGoalProfileId()).orElse(null);
  }

  private CheckpointCadencePolicy.Decision checkpointTaskDecision(GoalProfile profile) {
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    EntitlementDepthView entitlementDepth = entitlementDepthView(profile, diagnostic);
    return checkpointTaskDecision(profile, entitlementDepth);
  }

  private CheckpointCadencePolicy.Decision checkpointTaskDecision(
      GoalProfile profile, EntitlementDepthView entitlementDepth) {
    GoalBackplan backplan = latestBackplan(profile);
    GoalOutcomeCheckpoint checkpoint = latestCheckpoint(profile);
    LocalDate latestCheckpointDate = checkpoint == null
        ? null
        : LocalDate.ofInstant(checkpoint.getCreatedAt(), clock.getZone());
    if ("blocked".equals(entitlementDepth.depthState())) {
      LocalDate dueDate = backplan == null ? LocalDate.now(clock) : backplan.getCheckpointDueDate();
      return new CheckpointCadencePolicy.Decision(
          "CheckpointUnavailable",
          "unavailable",
          dueDate,
          null,
          entitlementDepth.checkpointCadence(),
          stableDowngradeReason(entitlementDepth),
          profile.getSupportStatus(),
          contentCoverageFor(profile),
          null,
          CheckpointCadencePolicy.RULE_VERSION);
    }
    return checkpointCadencePolicy.evaluate(new CheckpointCadencePolicy.Input(
        CheckpointCadencePolicy.RULE_VERSION,
        profile.getGoalType(),
        profile.getSupportStatus(),
        contentCoverageFor(profile),
        LocalDate.now(clock),
        backplan == null ? null : backplan.getCheckpointDueDate(),
        latestCheckpointDate,
        entitlementDepth.providerCandidateAllowed(),
        !"quota_exhausted".equals(entitlementDepth.limitationReason()),
        !"cost_budget_limited".equals(entitlementDepth.limitationReason())));
  }

  private Set<String> allowedCheckpointTypes(GoalProfile profile) {
    return switch (profile.getGoalType()) {
      case "business_meeting", "job_interview", "onboarding_introduction" -> Set.of("business_task");
      default -> "partial".equals(profile.getSupportStatus())
          ? Set.of("biweekly_mock")
          : Set.of("weekly_mock", "biweekly_mock");
    };
  }

  private String contentCoverageFor(GoalProfile profile) {
    if ("unsupported".equals(profile.getSupportStatus())) {
      return "none";
    }
    if ("partial".equals(profile.getSupportStatus())) {
      return "partial_content_and_time";
    }
    return "sufficient_for_local_plan";
  }

  private GoalPlanItem requireNextItem(GoalDailyPlan dailyPlan) {
    return planItems.findFirstByDailyPlanIdAndStatusInOrderByOrderIndexAsc(dailyPlan.getDailyPlanId(), List.of("active", "pending"))
        .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "CONFLICT", "No active plan item is available."));
  }

  private GoalDailyPlan recoverySourceDailyPlan(GoalProfile profile, UUID planItemId) {
    if (planItemId != null) {
      GoalPlanItem item = planItems.findByPlanItemIdAndUserId(planItemId, profile.getUserId())
          .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Plan item was not found."));
      if (!item.getGoalProfileId().equals(profile.getGoalProfileId())) {
        throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Plan item does not belong to the active goal.");
      }
      return dailyPlans.findById(item.getDailyPlanId())
          .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Daily plan was not found."));
    }
    LocalDate today = LocalDate.now(clock);
    return dailyPlans.findFirstByGoalProfileIdAndPlanDateAndStatusInOrderByCreatedAtDesc(
            profile.getGoalProfileId(), today, List.of("ready", "partial", "recovery_required", "stale"))
        .or(() -> dailyPlans.findFirstByGoalProfileIdAndStatusInOrderByPlanDateDesc(
            profile.getGoalProfileId(), List.of("ready", "partial", "recovery_required", "stale")))
        .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Daily plan is required before recovery replan."));
  }

  private MissedDayRecoveryPlanner.RecoveryPlanItem recoveryPlannerItem(GoalPlanItem item) {
    return new MissedDayRecoveryPlanner.RecoveryPlanItem(
        item.getPlanItemId().toString(),
        item.getItemType(),
        item.getReasonCode(),
        item.getDurationMinutes(),
        item.getStatus(),
        item.getMemoryRisk(),
        item.getOrderIndex());
  }

  private GoalDailyPlan applyRecoveryPlan(
      GoalProfile profile,
      GoalDailyPlan sourceDailyPlan,
      MissedDayRecoveryPlanner.Decision decision,
      String intensity,
      Instant now) {
    backplans.findByGoalProfileIdAndStatusIn(profile.getGoalProfileId(), ACTIVE_PLAN_STATUSES)
        .forEach(plan -> {
          plan.markStale(decision.reasonCode(), now);
          backplans.save(plan);
        });
    if (!"stale".equals(sourceDailyPlan.getStatus())) {
      sourceDailyPlan.markStale(now);
      dailyPlans.save(sourceDailyPlan);
    }

    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    boolean partial = "partial".equals(profile.getSupportStatus()) || "low".equals(diagnostic.getConfidenceBand());
    LocalDate today = LocalDate.now(clock);
    GoalBackplan recoveryBackplan = backplans.save(new GoalBackplan(
        UUID.randomUUID(),
        profile.getGoalProfileId(),
        profile.getUserId(),
        "goal-plan-v1",
        today,
        today.plusDays(6),
        "recover missed work without overdue stacking",
        sessionCount(profile, partial),
        "D1,D3,D7",
        today.plusDays(partial ? 14 : 7),
        partial ? "partial" : "active",
        now));
    int totalMinutes = Math.min(recoveryDailyCap(profile.getDailyMinutes(), intensity), Math.max(5, decision.plannedMinutes()));
    GoalDailyPlan recoveryDailyPlan = dailyPlans.save(new GoalDailyPlan(
        UUID.randomUUID(),
        recoveryBackplan.getWeeklyBackplanId(),
        profile.getGoalProfileId(),
        profile.getUserId(),
        today,
        totalMinutes,
        partial ? "partial" : "ready",
        recoveryLimitationMessage(decision.recoveryMode()),
        "replace".equals(decision.recoveryMode()) ? "high" : riskFor(diagnostic, partial),
        "replace".equals(decision.recoveryMode()) ? 1 : 3,
        now));
    planItems.save(new GoalPlanItem(
        UUID.randomUUID(),
        recoveryDailyPlan.getDailyPlanId(),
        profile.getGoalProfileId(),
        profile.getUserId(),
        recoveryItemType(decision.recoveryMode()),
        recoveryTitle(decision.recoveryMode()),
        recoveryItemReason(decision.recoveryMode()),
        totalMinutes,
        "active",
        "replace".equals(decision.recoveryMode()) ? "high" : riskFor(diagnostic, partial),
        "replace".equals(decision.recoveryMode()) || partial ? "low" : "standard",
        1,
        now));
    return recoveryDailyPlan;
  }

  private int recoveryDailyCap(int dailyMinutes, String intensity) {
    int allowance = "intensive".equals(intensity)
        ? Math.min(10, Math.max(5, dailyMinutes / 4))
        : 0;
    return dailyMinutes + allowance;
  }

  private String recoveryLimitationMessage(String recoveryMode) {
    return switch (recoveryMode) {
      case "defer" -> "Missed work was deferred without stacking all overdue tasks.";
      case "compress" -> "Recovery work was compressed into a smaller feasible block.";
      default -> "Impossible overdue work was replaced with a smaller recovery block.";
    };
  }

  private String recoveryItemType(String recoveryMode) {
    return "compress".equals(recoveryMode) ? "training" : "review";
  }

  private String recoveryTitle(String recoveryMode) {
    return switch (recoveryMode) {
      case "defer" -> "Short fluency risk review";
      case "compress" -> "Compressed recovery training block";
      default -> "Small recovery review block";
    };
  }

  private String recoveryItemReason(String recoveryMode) {
    return switch (recoveryMode) {
      case "defer" -> "recovery_defer_preserve_risk";
      case "compress" -> "recovery_compress_scope_reduced";
      default -> "recovery_replace_safe_small_block";
    };
  }

  private String recoveryInputSnapshotHash(
      GoalProfile profile,
      GoalDailyPlan sourceDailyPlan,
      String sourceEvent,
      String preferredPolicy,
      List<String> affectedRefs) {
    return sha256Prefixed(Map.of(
        "goal_profile_id", profile.getGoalProfileId().toString(),
        "goal_revision", Integer.toString(profile.getRevision()),
        "source_daily_plan_id", sourceDailyPlan.getDailyPlanId().toString(),
        "source_event", sourceEvent,
        "preferred_policy", preferredPolicy,
        "affected_refs", String.join(",", affectedRefs),
        "daily_minutes", Integer.toString(profile.getDailyMinutes()),
        "rule_version", RECOVERY_RULE_VERSION));
  }

  private void writeRecoveryReplay(GoalRecoveryPlanDecision decision, GoalDailyPlan dailyPlan, Instant now) {
    String outputHash = sha256Prefixed(Map.of(
        "decision_id", decision.getDecisionId().toString(),
        "daily_plan_id", dailyPlan.getDailyPlanId().toString(),
        "recovery_mode", decision.getRecoveryMode(),
        "reason_code", decision.getReasonCode(),
        "total_minutes", Integer.toString(dailyPlan.getTotalMinutes()),
        "rule_version", decision.getRuleVersion()));
    String replayHash = sha256Prefixed(Map.of(
        "input", decision.getInputSnapshotHash(),
        "output", outputHash,
        "expected_decision", decision.getRecoveryMode(),
        "reason_code", decision.getReasonCode(),
        "rule_version", decision.getRuleVersion()));
    replayAudits.save(new PlannerReplayAudit(
        UUID.randomUUID(),
        decision.getUserId(),
        "missed_day_recovery",
        "recovery_decision:" + decision.getDecisionId(),
        decision.getInputSnapshotHash(),
        outputHash,
        decision.getRecoveryMode(),
        decision.getReasonCode(),
        decision.getRuleVersion(),
        replayHash,
        now));
  }

  private PlannerReplayAudit writeCheckpointPlanReplay(
      GoalProfile profile,
      GoalOutcomeCheckpoint checkpoint,
      CheckpointInput input,
      CheckpointCadencePolicy.Decision taskDecision,
      GoalAutopilotControl control,
      PlanFacts planFactsBefore,
      GoalProgressForecast forecast,
      PlanUpdateSignalView signal,
      Instant now) {
    String inputHash = checkpointPlanInputSnapshotHash(
        profile, checkpoint, input, taskDecision, control, planFactsBefore);
    String outputHash = sha256Prefixed(Map.of(
        "checkpoint_id", checkpoint.getCheckpointId().toString(),
        "result_status", checkpoint.getResultStatus(),
        "confidence_band", checkpoint.getConfidenceBand(),
        "forecast_id", forecast.getForecastId().toString(),
        "forecast_state", forecast.getForecastState(),
        "risk_reason_code", forecast.getRiskReasonCode(),
        "signal_type", signal.signalType(),
        "reason_code", signal.reasonCode(),
        "rule_version", CHECKPOINT_PLAN_RULE_VERSION));
    String replayHash = sha256Prefixed(Map.of(
        "input", inputHash,
        "output", outputHash,
        "expected_decision", signal.signalType(),
        "reason_code", signal.reasonCode(),
        "rule_version", CHECKPOINT_PLAN_RULE_VERSION));
    return replayAudits.save(new PlannerReplayAudit(
        UUID.randomUUID(),
        profile.getUserId(),
        "checkpoint_plan_update",
        "checkpoint:" + checkpoint.getCheckpointId(),
        inputHash,
        outputHash,
        signal.signalType(),
        signal.reasonCode(),
        CHECKPOINT_PLAN_RULE_VERSION,
        replayHash,
        now));
  }

  private String checkpointPlanInputSnapshotHash(
      GoalProfile profile,
      GoalOutcomeCheckpoint checkpoint,
      CheckpointInput input,
      CheckpointCadencePolicy.Decision taskDecision,
      GoalAutopilotControl control,
      PlanFacts planFactsBefore) {
    TreeMap<String, String> snapshot = new TreeMap<>();
    snapshot.put("user_id", profile.getUserId().toString());
    snapshot.put("goal_profile_id", profile.getGoalProfileId().toString());
    snapshot.put("goal_revision", Integer.toString(profile.getRevision()));
    snapshot.put("checkpoint_id", checkpoint.getCheckpointId().toString());
    snapshot.put("checkpoint_type", checkpoint.getCheckpointType());
    snapshot.put("requested_result_status", cleanOrDefault(input.resultStatus(), "recorded"));
    snapshot.put("result_status", checkpoint.getResultStatus());
    snapshot.put("confidence_band", checkpoint.getConfidenceBand());
    snapshot.put("score_hint", nullableHashValue(input.scoreHint()));
    snapshot.put("transcript_hash", redactedInputHash(input.transcript()));
    snapshot.put("audio_ref_hash", redactedInputHash(input.audioRef()));
    snapshot.put("task_state", taskDecision.checkpointState());
    snapshot.put("task_due_status", taskDecision.dueStatus());
    snapshot.put("task_rule_version", taskDecision.ruleVersion());
    snapshot.put("support_status", profile.getSupportStatus());
    snapshot.put("control_status", control.getControlStatus());
    snapshot.put("plan_missing_before", Boolean.toString(planFactsBefore.missingPlan()));
    snapshot.put("plan_stale_before", Boolean.toString(planFactsBefore.stalePlan()));
    snapshot.put("recovery_required_before", Boolean.toString(planFactsBefore.recoveryRequired()));
    snapshot.put("rule_version", CHECKPOINT_PLAN_RULE_VERSION);
    return sha256Prefixed(snapshot);
  }

  private String redactedInputHash(String value) {
    String cleaned = clean(value);
    return cleaned == null ? "<null>" : sha256Prefixed(cleaned);
  }

  private RecoveryPlanResult recoveryPlanResult(GoalRecoveryPlanDecision decision) {
    GoalDailyPlan dailyPlan = dailyPlans.findById(decision.getDailyPlanId())
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Recovery daily plan was not found."));
    return new RecoveryPlanResult(
        new RecoveryPlanDecisionView(
            decision.getDecisionId(),
            decision.getGoalProfileId(),
            decision.getDailyPlanId(),
            decision.getSourceEvent(),
            decision.getRecoveryMode(),
            fromJson(decision.getAffectedPlanItemRefsJson(), STRING_LIST),
            decision.getInputSnapshotHash(),
            decision.getReasonCode(),
            decision.getRuleVersion(),
            decision.getCreatedAt()),
        dailyPlanView(dailyPlan),
        new PlanUpdateSignalView("recovery_replan", decision.getReasonCode()));
  }

  private GoalMasteryTransitionDecision applyMasteryTransition(
      GoalProfile profile, GoalPlanItem item, GoalDiagnosticAssessment diagnostic, String outcome, Instant now) {
    boolean successfulRetrieval = "completed".equals(outcome);
    return applyMasteryTransition(
        profile,
        "plan_item",
        item.getPlanItemId().toString(),
        baselineMasteryLevel(profile),
        "L5",
        confidenceScore(diagnostic.getConfidenceBand(), successfulRetrieval),
        List.of(
            "diagnostic:" + diagnostic.getDiagnosticAssessmentId(),
            "plan_item:" + item.getPlanItemId(),
            "outcome:" + outcome),
        successfulRetrieval ? 3 : 2,
        successfulRetrieval ? 0 : 2,
        !successfulRetrieval,
        false,
        false,
        false,
        now);
  }

  private GoalMasteryTransitionDecision applyCheckpointMasteryTransition(
      GoalProfile profile, GoalOutcomeCheckpoint checkpoint, String confidenceBand, Instant now) {
    boolean checkpointRegression = "low".equals(confidenceBand);
    return applyMasteryTransition(
        profile,
        "checkpoint",
        checkpoint.getCheckpointId().toString(),
        baselineMasteryLevel(profile),
        "L5",
        confidenceScore(confidenceBand, !checkpointRegression),
        List.of(
            "checkpoint:" + checkpoint.getCheckpointId(),
            "checkpoint_status:" + checkpoint.getResultStatus(),
            "confidence:" + confidenceBand),
        checkpointRegression ? 2 : 3,
        checkpointRegression ? 2 : 0,
        false,
        checkpointRegression,
        false,
        false,
        now);
  }

  private GoalMasteryTransitionDecision applyMasteryTransition(
      GoalProfile profile,
      String itemType,
      String itemRef,
      String previousLevel,
      String targetLevel,
      double confidence,
      List<String> evidenceRefs,
      int acceptedEvidenceCount,
      int recentFailures,
      boolean retrievalRegression,
      boolean checkpointRegression,
      boolean fatigueProtected,
      boolean contradictoryEvidence,
      Instant now) {
    String memoryItemStateId = masteryMemoryItemStateId(profile, itemType, itemRef, previousLevel);
    MasteryTransitionPolicy.Decision policyDecision = masteryTransitionPolicy.evaluate(new MasteryTransitionPolicy.Input(
        previousLevel,
        targetLevel,
        confidence,
        evidenceRefs,
        acceptedEvidenceCount,
        recentFailures,
        retrievalRegression,
        checkpointRegression,
        fatigueProtected,
        contradictoryEvidence,
        profile.getSupportStatus(),
        false));
    String inputHash = masteryTransitionInputSnapshotHash(
        profile,
        memoryItemStateId,
        itemType,
        itemRef,
        previousLevel,
        targetLevel,
        confidence,
        evidenceRefs,
        acceptedEvidenceCount,
        recentFailures,
        retrievalRegression,
        checkpointRegression,
        fatigueProtected,
        contradictoryEvidence);
    GoalMasteryTransitionDecision existing = masteryTransitions
        .findByUserIdAndGoalProfileIdAndGoalRevisionAndMemoryItemStateIdAndInputSnapshotHashAndRuleVersion(
            profile.getUserId(),
            profile.getGoalProfileId(),
            profile.getRevision(),
            memoryItemStateId,
            inputHash,
            MasteryTransitionPolicy.RULE_VERSION)
        .orElse(null);
    if (existing != null) {
      return existing;
    }
    GoalMasteryTransitionDecision transition = masteryTransitions.save(new GoalMasteryTransitionDecision(
        UUID.randomUUID(),
        profile.getUserId(),
        profile.getGoalProfileId(),
        profile.getRevision(),
        memoryItemStateId,
        itemType,
        itemRef,
        policyDecision.previousLevel(),
        policyDecision.proposedLevel(),
        policyDecision.acceptedLevel(),
        policyDecision.direction(),
        toJson(policyDecision.evidenceRefs()),
        policyDecision.confidence(),
        policyDecision.reasonCode(),
        policyDecision.ruleVersion(),
        inputHash,
        now));
    writeMasteryTransitionReplay(transition, now);
    return transition;
  }

  private String baselineMasteryLevel(GoalProfile profile) {
    return masteryInitialStates.findByGoalProfileId(profile.getGoalProfileId()).stream()
        .findFirst()
        .map(GoalMasteryInitialState::getInitialLevel)
        .orElse("L2");
  }

  private double confidenceScore(String confidenceBand, boolean positiveEvidence) {
    double base = switch (cleanOrDefault(confidenceBand, "low")) {
      case "high" -> 0.84;
      case "medium" -> 0.74;
      default -> 0.60;
    };
    return positiveEvidence ? base : Math.min(base, 0.72);
  }

  private String masteryMemoryItemStateId(
      GoalProfile profile, String itemType, String itemRef, String previousLevel) {
    return UUID.nameUUIDFromBytes((
            profile.getUserId()
                + ":"
                + profile.getGoalProfileId()
                + ":"
                + profile.getRevision()
                + ":"
                + itemType
                + ":"
                + itemRef
                + ":"
                + previousLevel
                + ":"
                + MasteryTransitionPolicy.RULE_VERSION)
        .getBytes(StandardCharsets.UTF_8)).toString();
  }

  private String masteryTransitionInputSnapshotHash(
      GoalProfile profile,
      String memoryItemStateId,
      String itemType,
      String itemRef,
      String previousLevel,
      String targetLevel,
      double confidence,
      List<String> evidenceRefs,
      int acceptedEvidenceCount,
      int recentFailures,
      boolean retrievalRegression,
      boolean checkpointRegression,
      boolean fatigueProtected,
      boolean contradictoryEvidence) {
    TreeMap<String, String> snapshot = new TreeMap<>();
    snapshot.put("user_id", profile.getUserId().toString());
    snapshot.put("goal_profile_id", profile.getGoalProfileId().toString());
    snapshot.put("goal_revision", Integer.toString(profile.getRevision()));
    snapshot.put("memory_item_state_id", memoryItemStateId);
    snapshot.put("item_type", itemType);
    snapshot.put("item_ref", itemRef);
    snapshot.put("previous_level", previousLevel);
    snapshot.put("target_level", targetLevel);
    snapshot.put("confidence", Double.toString(confidence));
    snapshot.put("evidence_refs", String.join(",", evidenceRefs));
    snapshot.put("accepted_evidence_count", Integer.toString(acceptedEvidenceCount));
    snapshot.put("recent_failures", Integer.toString(recentFailures));
    snapshot.put("retrieval_regression", Boolean.toString(retrievalRegression));
    snapshot.put("checkpoint_regression", Boolean.toString(checkpointRegression));
    snapshot.put("fatigue_protected", Boolean.toString(fatigueProtected));
    snapshot.put("contradictory_evidence", Boolean.toString(contradictoryEvidence));
    snapshot.put("support_status", profile.getSupportStatus());
    snapshot.put("rule_version", MasteryTransitionPolicy.RULE_VERSION);
    return sha256Prefixed(snapshot);
  }

  private void writeMasteryTransitionReplay(GoalMasteryTransitionDecision transition, Instant now) {
    String outputHash = sha256Prefixed(Map.of(
        "previous_level", transition.getPreviousLevel(),
        "proposed_level", transition.getProposedLevel(),
        "accepted_level", transition.getAcceptedLevel(),
        "direction", transition.getDirection(),
        "reason_code", transition.getReasonCode(),
        "rule_version", transition.getRuleVersion()));
    String replayHash = sha256Prefixed(Map.of(
        "input", transition.getInputSnapshotHash(),
        "output", outputHash,
        "expected_decision", transition.getDirection(),
        "reason_code", transition.getReasonCode(),
        "rule_version", transition.getRuleVersion()));
    replayAudits.save(new PlannerReplayAudit(
        UUID.randomUUID(),
        transition.getUserId(),
        "mastery_transition",
        "mastery_transition:" + transition.getTransitionId(),
        transition.getInputSnapshotHash(),
        outputHash,
        transition.getDirection(),
        transition.getReasonCode(),
        transition.getRuleVersion(),
        replayHash,
        now));
  }

  private String memoryPolicyControlStatus(GoalProfile profile, GoalAutopilotControl control) {
    if ("paused".equals(control.getControlStatus())) {
      return "paused";
    }
    String status = controlView(control, controlReason(profile, control)).controlStatus();
    return "blocked_by_policy".equals(status) ? "blocked_by_policy" : "active";
  }

  private List<MemoryCurvePolicy.ItemInput> memoryPolicyItems(GoalProfile profile, ItemPolicyDecisionInput input) {
    if (input.items() != null && !input.items().isEmpty()) {
      return input.items().stream().map(this::memoryPolicyItem).toList();
    }
    GoalDailyPlan dailyPlan = requireDailyPlan(profile);
    List<String> refs = input.itemRefs() == null ? List.of() : input.itemRefs();
    return planItems.findByDailyPlanIdOrderByOrderIndexAsc(dailyPlan.getDailyPlanId()).stream()
        .filter(item -> refs.isEmpty() || refs.contains(item.getPlanItemId().toString()))
        .map(this::memoryPolicyItem)
        .toList();
  }

  private MemoryCurvePolicy.ItemInput memoryPolicyItem(MemoryItemPolicyInput input) {
    String itemType = cleanOrDefault(input.itemType(), "plan_item");
    String itemRef = cleanRequired(input.itemRef(), "item_ref");
    String interleavingGroup = cleanOrDefault(input.interleavingGroup(), itemType);
    String masteryLevel = cleanOrDefault(input.currentMasteryLevel(), "L2");
    List<String> evidenceRefs = input.evidenceRefs() == null ? List.of() : input.evidenceRefs().stream()
        .filter(ref -> ref != null && !ref.isBlank())
        .map(String::trim)
        .toList();
    return new MemoryCurvePolicy.ItemInput(
        itemType,
        itemRef,
        interleavingGroup,
        masteryLevel,
        evidenceRefs,
        input.lastReviewedAt(),
        Math.max(0, input.exposureCount() == null ? 0 : input.exposureCount()),
        Math.max(0, input.overlearningCount() == null ? 0 : input.overlearningCount()),
        input.forgettingRisk() == null ? 0 : input.forgettingRisk(),
        input.retrievalSuccess(),
        Math.max(0, input.recentFailures() == null ? 0 : input.recentFailures()),
        cleanOrDefault(input.pressureLevel(), "standard"),
        input.estimatedMinutes() == null ? 5 : input.estimatedMinutes());
  }

  private MemoryCurvePolicy.ItemInput memoryPolicyItem(GoalPlanItem item) {
    double risk = switch (item.getMemoryRisk()) {
      case "high" -> 0.72;
      case "medium" -> 0.50;
      default -> 0.25;
    };
    Boolean retrievalSuccess = switch (item.getStatus()) {
      case "completed" -> true;
      case "skipped", "deferred" -> false;
      default -> null;
    };
    return new MemoryCurvePolicy.ItemInput(
        "plan_item",
        item.getPlanItemId().toString(),
        cleanOrDefault(item.getReasonCode(), item.getItemType()),
        "L2",
        List.of(item.getPlanItemId().toString()),
        null,
        "completed".equals(item.getStatus()) ? 1 : 0,
        0,
        risk,
        retrievalSuccess,
        Boolean.FALSE.equals(retrievalSuccess) ? 1 : 0,
        item.getPressureLevel(),
        item.getDurationMinutes());
  }

  private MemoryItemPolicyStateView memoryItemPolicyStateView(
      GoalProfile profile, MemoryCurvePolicy.Decision decision) {
    String stateId = UUID.nameUUIDFromBytes((
            profile.getUserId()
                + ":"
                + profile.getGoalProfileId()
                + ":"
                + profile.getRevision()
                + ":"
                + decision.itemRef()
                + ":"
                + MEMORY_RULE_VERSION)
        .getBytes(StandardCharsets.UTF_8)).toString();
    return new MemoryItemPolicyStateView(
        stateId,
        profile.getUserId(),
        decision.itemType(),
        decision.itemRef(),
        decision.interleavingGroup(),
        decision.currentMasteryLevel(),
        decision.evidenceRefs(),
        decision.lastReviewedAt(),
        decision.exposureCount(),
        decision.overlearningCount(),
        decision.forgettingRisk(),
        decision.dueDecision(),
        decision.nextDueAt(),
        decision.reasonCode(),
        decision.ruleVersion());
  }

  private PlannerReplayAudit writeMemoryPolicyReplay(
      GoalProfile profile,
      String controlStatus,
      Instant policyEvaluatedAt,
      int dailyBudget,
      List<MemoryCurvePolicy.ItemInput> itemInputs,
      List<MemoryItemPolicyStateView> decisions,
      Instant now) {
    String inputHash = sha256Prefixed(Map.of(
        "user_id", profile.getUserId().toString(),
        "goal_profile_id", profile.getGoalProfileId().toString(),
        "goal_revision", Integer.toString(profile.getRevision()),
        "control_status", controlStatus,
        "evaluated_at", policyEvaluatedAt.toString(),
        "daily_time_budget_minutes", Integer.toString(dailyBudget),
        "policy_version", MEMORY_RULE_VERSION,
        "items", memoryPolicyInputSnapshot(itemInputs)));
    String outputHash = sha256Prefixed(Map.of(
        "policy_version", MEMORY_RULE_VERSION,
        "decisions", memoryPolicyOutputSnapshot(decisions)));
    String expectedDecision = primaryMemoryDecision(decisions);
    String reasonCode = primaryMemoryReason(decisions, expectedDecision);
    String replayHash = sha256Prefixed(Map.of(
        "input", inputHash,
        "output", outputHash,
        "expected_decision", expectedDecision,
        "reason_code", reasonCode,
        "rule_version", MEMORY_RULE_VERSION));
    return replayAudits.save(new PlannerReplayAudit(
        UUID.randomUUID(),
        profile.getUserId(),
        "item_policy",
        "item_policy:" + profile.getGoalProfileId(),
        inputHash,
        outputHash,
        expectedDecision,
        reasonCode,
        MEMORY_RULE_VERSION,
        replayHash,
        now));
  }

  private String memoryPolicyInputSnapshot(List<MemoryCurvePolicy.ItemInput> items) {
    return toJson(items.stream()
        .map(this::memoryPolicyInputRow)
        .toList());
  }

  private TreeMap<String, String> memoryPolicyInputRow(MemoryCurvePolicy.ItemInput item) {
    TreeMap<String, String> row = new TreeMap<>();
    row.put("item_type", item.itemType());
    row.put("item_ref", item.itemRef());
    row.put("interleaving_group", nullableHashValue(item.interleavingGroup()));
    row.put("current_mastery_level", item.currentMasteryLevel());
    row.put("evidence_refs", String.join(",", item.evidenceRefs()));
    row.put("last_reviewed_at", item.lastReviewedAt() == null ? "<null>" : item.lastReviewedAt().toString());
    row.put("exposure_count", Integer.toString(item.exposureCount()));
    row.put("overlearning_count", Integer.toString(item.overlearningCount()));
    row.put("forgetting_risk", Double.toString(item.forgettingRisk()));
    row.put("retrieval_success", nullableHashValue(item.retrievalSuccess()));
    row.put("recent_failures", Integer.toString(item.recentFailures()));
    row.put("pressure_level", nullableHashValue(item.pressureLevel()));
    row.put("estimated_minutes", Integer.toString(item.estimatedMinutes()));
    return row;
  }

  private String memoryPolicyOutputSnapshot(List<MemoryItemPolicyStateView> decisions) {
    return toJson(decisions.stream()
        .map(decision -> new TreeMap<>(Map.of(
            "memory_item_state_id", decision.memoryItemStateId(),
            "item_ref", decision.itemRef(),
            "forgetting_risk", decision.forgettingRisk(),
            "due_decision", decision.dueDecision(),
            "reason_code", decision.reasonCode(),
            "next_due_at", decision.nextDueAt() == null ? "<null>" : decision.nextDueAt().toString(),
            "rule_version", decision.ruleVersion())))
        .toList());
  }

  private String primaryMemoryDecision(List<MemoryItemPolicyStateView> decisions) {
    return List.of("review_due", "blocked_by_control", "defer_budget", "skip_overlearning_cap", "interleave_alternative", "review_not_due")
        .stream()
        .filter(candidate -> decisions.stream().anyMatch(decision -> candidate.equals(decision.dueDecision())))
        .findFirst()
        .orElse("no_items");
  }

  private String primaryMemoryReason(List<MemoryItemPolicyStateView> decisions, String expectedDecision) {
    return decisions.stream()
        .filter(decision -> expectedDecision.equals(decision.dueDecision()))
        .map(MemoryItemPolicyStateView::reasonCode)
        .findFirst()
        .orElse("no_items");
  }

  private NotificationOutboxService.PlannerReplayAuditView replayAuditView(PlannerReplayAudit audit) {
    return new NotificationOutboxService.PlannerReplayAuditView(
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

  private MasteryTransitionDecisionView masteryTransitionView(GoalMasteryTransitionDecision transition) {
    return new MasteryTransitionDecisionView(
        transition.getTransitionId(),
        transition.getUserId(),
        transition.getMemoryItemStateId(),
        transition.getPreviousLevel(),
        transition.getProposedLevel(),
        transition.getAcceptedLevel(),
        transition.getDirection(),
        fromJson(transition.getEvidenceRefsJson(), STRING_LIST),
        transition.getConfidence(),
        transition.getReasonCode(),
        transition.getRuleVersion(),
        transition.getCreatedAt());
  }

  private AutopilotActionView nextActionOrNull(GoalProfile profile) {
    try {
      GoalDailyPlan dailyPlan = latestDailyPlan(profile);
      return actionView(requireNextItem(dailyPlan), "ready");
    } catch (ApiException ignored) {
      return null;
    }
  }

  private GoalProgressProjectionView unavailableProgressProjection(UUID userId, String state, String reason, Instant now) {
    return new GoalProgressProjectionView(
        UUID.nameUUIDFromBytes((
                "goal-progress-projection:" + userId + ":none:" + state + ":" + reason + ":" + PROGRESS_PROJECTION_RULE_VERSION)
            .getBytes(StandardCharsets.UTF_8)).toString(),
        state,
        reason,
        null,
        null,
        null,
        null,
        progressSurfaceFragments(state, reason, null, null, null),
        List.of(),
        PROGRESS_PROJECTION_RULE_VERSION,
        now);
  }

  private String progressProjectionState(
      GoalProfile profile,
      String controlStatus,
      String controlReason,
      GoalProgressForecast forecast,
      PlanFacts facts) {
    if ("unsupported".equals(profile.getSupportStatus()) || "unsupported".equals(profile.getStatus())) {
      return "unsupported";
    }
    if (facts.stalePlan() || (forecast != null && "stale_plan".equals(forecast.getForecastState()))) {
      return "stale_plan";
    }
    if ("paused".equals(controlStatus) || "blocked_by_policy".equals(controlStatus) || !"eligible".equals(controlReason)) {
      return "control_blocked";
    }
    if (forecast == null || "unavailable".equals(forecast.getForecastState())) {
      return "unavailable";
    }
    if ("deleted".equals(forecast.getForecastState())) {
      return "deleted";
    }
    if ("low_confidence".equals(forecast.getForecastState()) || "low".equals(forecast.getConfidenceBand())) {
      return "low_confidence";
    }
    if ("partial".equals(profile.getSupportStatus())
        || "limited".equals(forecast.getForecastState())
        || facts.recoveryRequired()) {
      return "limited";
    }
    return "ready";
  }

  private String progressProjectionDowngradeReason(
      GoalProfile profile,
      String controlReason,
      GoalProgressForecast forecast,
      PlanFacts facts,
      String state) {
    return switch (state) {
      case "ready" -> null;
      case "unsupported" -> "unsupported_goal";
      case "deleted" -> "deleted_goal";
      case "stale_plan" -> "stale_plan";
      case "control_blocked" -> "eligible".equals(controlReason) ? "control_blocked" : controlReason;
      case "unavailable" -> forecast == null ? "forecast_unavailable" : cleanOrDefault(forecast.getEtaUnavailableReason(), "unavailable");
      case "low_confidence" -> "low_confidence";
      case "limited" -> {
        if ("partial".equals(profile.getSupportStatus())) {
          yield "partial_goal_limited";
        }
        if (facts.recoveryRequired()) {
          yield "recovery_required";
        }
        yield forecast == null ? "limited_projection" : cleanOrDefault(forecast.getRiskReasonCode(), "limited_projection");
      }
      default -> state;
    };
  }

  private String progressProjectionId(
      UUID userId,
      GoalProfile profile,
      GoalAutopilotControl control,
      AutopilotActionView action,
      GoalProgressForecast forecast,
      GoalOutcomeCheckpoint checkpoint,
      String state,
      String downgradeReason) {
    return UUID.nameUUIDFromBytes((
            "goal-progress-projection:"
                + userId
                + ":"
                + profile.getGoalProfileId()
                + ":"
                + profile.getRevision()
                + ":"
                + nullableHashValue(control == null ? null : control.getControlId())
                + ":"
                + nullableHashValue(action == null ? null : action.planItemId())
                + ":"
                + nullableHashValue(forecast == null ? null : forecast.getForecastId())
                + ":"
                + nullableHashValue(checkpoint == null ? null : checkpoint.getCheckpointId())
                + ":"
                + state
                + ":"
                + nullableHashValue(downgradeReason)
                + ":"
                + PROGRESS_PROJECTION_RULE_VERSION)
        .getBytes(StandardCharsets.UTF_8)).toString();
  }

  private List<String> progressProjectionSourceRefs(
      GoalProfile profile,
      GoalAutopilotControl control,
      AutopilotActionView action,
      GoalProgressForecast forecast,
      GoalOutcomeCheckpoint checkpoint) {
    List<String> refs = new ArrayList<>();
    refs.add("goal_profile:" + profile.getGoalProfileId());
    refs.add("goal_revision:" + profile.getRevision());
    if (control != null) {
      refs.add("control:" + control.getControlId());
    }
    if (action != null) {
      refs.add("plan_item:" + action.planItemId());
    }
    if (forecast != null) {
      refs.add("forecast:" + forecast.getForecastId());
    }
    if (checkpoint != null) {
      refs.add("checkpoint:" + checkpoint.getCheckpointId());
    }
    return refs;
  }

  private Instant progressProjectionUpdatedAt(GoalAutopilotControl control, GoalProgressForecast forecast, Instant fallback) {
    Instant updatedAt = fallback;
    if (forecast != null && forecast.getUpdatedAt() != null && forecast.getUpdatedAt().isAfter(updatedAt)) {
      updatedAt = forecast.getUpdatedAt();
    }
    if (control != null && control.getUpdatedAt() != null && control.getUpdatedAt().isAfter(updatedAt)) {
      updatedAt = control.getUpdatedAt();
    }
    return updatedAt;
  }

  private GoalProgressNextActionFragmentView progressNextActionFragment(AutopilotActionView action) {
    return new GoalProgressNextActionFragmentView(
        action.actionId(),
        action.planItemId(),
        action.actionType(),
        action.title(),
        action.reasonCode(),
        action.expectedDurationMinutes(),
        action.status());
  }

  private GoalProgressForecastFragmentView progressForecastFragment(GoalProgressForecast forecast) {
    return new GoalProgressForecastFragmentView(
        forecast.getForecastId(),
        forecast.getForecastState(),
        forecast.getGapSummary(),
        forecast.getEtaDate(),
        forecast.getEtaRangeStart() == null || forecast.getEtaRangeEnd() == null
            ? null
            : new ForecastEtaRangeView(forecast.getEtaRangeStart(), forecast.getEtaRangeEnd()),
        forecast.getEtaUnavailableReason(),
        forecast.getConfidenceBand(),
        forecast.getRiskLevel(),
        forecast.getRiskReasonCode(),
        forecast.getNextCheckpointDate(),
        fromJson(forecast.getClaimGuardJson(), CLAIM_GUARD),
        forecast.getUpdatedAt());
  }

  private GoalProgressCheckpointFragmentView progressCheckpointFragment(GoalOutcomeCheckpoint checkpoint) {
    return new GoalProgressCheckpointFragmentView(
        checkpoint.getCheckpointId(),
        checkpoint.getResultStatus(),
        checkpoint.getConfidenceBand(),
        checkpoint.getSummary(),
        checkpoint.getPlanUpdateSignal(),
        checkpoint.getReasonCode());
  }

  private List<GoalProgressSurfaceFragmentView> progressSurfaceFragments(
      String state,
      String downgradeReason,
      AutopilotActionView action,
      GoalProgressForecast forecast,
      GoalOutcomeCheckpoint checkpoint) {
    boolean eligible = Set.of("ready", "limited", "low_confidence").contains(state);
    String actionRef = eligible && action != null ? "plan_item:" + action.planItemId() : null;
    String forecastRef = eligible && forecast != null ? "forecast:" + forecast.getForecastId() : null;
    String checkpointRef = eligible && checkpoint != null ? "checkpoint:" + checkpoint.getCheckpointId() : null;
    return List.of(
        new GoalProgressSurfaceFragmentView(
            "home",
            state,
            eligible,
            downgradeReason,
            actionRef,
            forecastRef,
            checkpointRef,
            eligible ? safeProjectionFields(true, true, true, action != null, forecast != null, checkpoint != null) : List.of()),
        new GoalProgressSurfaceFragmentView(
            "queue",
            state,
            eligible,
            downgradeReason,
            actionRef,
            forecastRef,
            checkpointRef,
            eligible ? safeProjectionFields(true, false, false, action != null, forecast != null, checkpoint != null) : List.of()),
        new GoalProgressSurfaceFragmentView(
            "wiki",
            state,
            eligible,
            downgradeReason,
            null,
            forecastRef,
            checkpointRef,
            eligible ? safeProjectionFields(false, true, true, false, forecast != null, checkpoint != null) : List.of()));
  }

  private List<String> safeProjectionFields(
      boolean includeAction,
      boolean includeCheckpointDate,
      boolean includeClaimGuard,
      boolean actionAvailable,
      boolean forecastAvailable,
      boolean checkpointAvailable) {
    List<String> fields = new ArrayList<>();
    if (includeAction && actionAvailable) {
      fields.add("next_action");
    }
    if (forecastAvailable) {
      fields.add("gap_summary");
      fields.add("risk_level");
      fields.add("risk_reason_code");
      if (includeCheckpointDate) {
        fields.add("next_checkpoint_date");
      }
      if (includeClaimGuard) {
        fields.add("claim_guard");
      }
    }
    if (checkpointAvailable) {
      fields.add("checkpoint_summary");
    }
    return fields;
  }

  private SummaryView summaryView(
      GoalProfile profile,
      SupportDecision support,
      GoalDiagnosticAssessment diagnostic,
      GoalBackplan backplan,
      GoalDailyPlan dailyPlan,
      AutopilotActionView action,
      GoalProgressForecast forecast,
      GoalOutcomeCheckpoint checkpoint) {
    EntitlementDepthView entitlementDepth = entitlementDepthView(profile, diagnostic);
    return new SummaryView(
        goalProfileView(profile),
        support,
        diagnosticView(diagnostic),
        entitlementDepth,
        backplan == null ? null : backplanView(backplan),
        dailyPlan == null ? null : dailyPlanView(dailyPlan),
        action,
        forecastView(forecast, entitlementDepth, profile.getUserId()),
        checkpoint == null ? null : checkpointView(checkpoint));
  }

  private GoalProfileView goalProfileView(GoalProfile profile) {
    return new GoalProfileView(
        profile.getGoalProfileId(),
        profile.getGoalType(),
        profile.getTargetScore(),
        profile.getTargetAbility(),
        profile.getDeadline(),
        profile.getDailyMinutes(),
        profile.getIntensityPreference(),
        profile.getSupportStatus(),
        profile.getStatus(),
        profile.getRevision());
  }

  private DiagnosticView diagnosticView(GoalDiagnosticAssessment diagnostic) {
    return new DiagnosticView(
        diagnostic.getDiagnosticAssessmentId(),
        diagnostic.getStatus(),
        diagnostic.getConfidenceBand(),
        diagnostic.getSampleCount(),
        fromJson(diagnostic.getRubricScoresJson(), RUBRIC_LIST),
        fromJson(diagnostic.getWeaknessTagsJson(), WEAKNESS_LIST),
        fromJson(diagnostic.getClaimGuardJson(), CLAIM_GUARD));
  }

  private WeeklyBackplanView backplanView(GoalBackplan backplan) {
    return new WeeklyBackplanView(
        backplan.getWeeklyBackplanId(),
        backplan.getPlanVersion(),
        backplan.getStartDate(),
        backplan.getEndDate(),
        backplan.getMilestone(),
        backplan.getSessionCount(),
        List.of(backplan.getReviewWindows().split(",")),
        backplan.getCheckpointDueDate(),
        backplan.getStatus());
  }

  private DailyPlanView dailyPlanView(GoalDailyPlan dailyPlan) {
    return new DailyPlanView(
        dailyPlan.getDailyPlanId(),
        dailyPlan.getPlanDate(),
        dailyPlan.getTotalMinutes(),
        dailyPlan.getStatus(),
        dailyPlan.getLimitationMessage(),
        planItems.findByDailyPlanIdOrderByOrderIndexAsc(dailyPlan.getDailyPlanId()).stream().map(this::planItemView).toList(),
        new MemoryCurvePolicyView(
            dailyPlan.getMemoryPolicyVersion(),
            dailyPlan.getForgettingRisk(),
            dailyPlan.getNextReviewIntervalDays(),
            dailyPlan.getOverlearningCap(),
            dailyPlan.getInterleavingRule()));
  }

  private PlanItemView planItemView(GoalPlanItem item) {
    return new PlanItemView(
        item.getPlanItemId(),
        item.getItemType(),
        item.getTitle(),
        item.getReasonCode(),
        item.getDurationMinutes(),
        item.getStatus(),
        item.getMemoryRisk(),
        item.getPressureLevel());
  }

  private AutopilotActionView actionView(GoalPlanItem item, String status) {
    String actionType = switch (item.getItemType()) {
      case "review" -> "review_due";
      case "checkpoint" -> "checkpoint_due";
      case "recovery" -> "recovery";
      default -> "start_training";
    };
    return new AutopilotActionView(
        UUID.nameUUIDFromBytes(item.getPlanItemId().toString().getBytes()).toString(),
        item.getPlanItemId(),
        actionType,
        item.getTitle(),
        item.getReasonCode(),
        item.getDurationMinutes(),
        "completed".equals(status) ? "completed" : "ready",
        "Start with the highest-priority item selected by the planner.");
  }

  private ForecastView forecastView(GoalProgressForecast forecast) {
    return new ForecastView(
        forecast.getForecastId(),
        forecast.getSourceGoalRevision(),
        forecast.getForecastState(),
        forecast.getGapSummary(),
        forecast.getEtaDate(),
        forecast.getEtaRangeStart() == null || forecast.getEtaRangeEnd() == null
            ? null
            : new ForecastEtaRangeView(forecast.getEtaRangeStart(), forecast.getEtaRangeEnd()),
        forecast.getEtaWindow(),
        forecast.getEtaUnavailableReason(),
        forecast.getConfidenceBand(),
        forecast.getRiskLevel(),
        forecast.getRiskReason(),
        forecast.getRiskReasonCode(),
        forecast.getNextCheckpointDate(),
        fromJson(forecast.getClaimGuardJson(), CLAIM_GUARD),
        new ForecastExplanationView(
            forecast.getExplanationKey(),
            forecast.getExplanationSource(),
            forecast.getAiExplanationUnavailableReason(),
            true),
        forecast.getUpdatedAt());
  }

  private ForecastView forecastView(GoalProgressForecast forecast, EntitlementDepthView entitlementDepth) {
    return forecastView(forecast, entitlementDepth, null);
  }

  private ForecastView forecastView(GoalProgressForecast forecast, EntitlementDepthView entitlementDepth, UUID userId) {
    String downgradeReason = fullDepthDowngradeReason(userId, entitlementDepth);
    if (downgradeReason == null) {
      return forecastView(forecast);
    }
    return new ForecastView(
        forecast.getForecastId(),
        forecast.getSourceGoalRevision(),
        "unavailable",
        "Goal progress is unavailable because full-depth goal autopilot is downgraded.",
        null,
        null,
        "not_available:unavailable",
        downgradeReason,
        forecast.getConfidenceBand(),
        "high",
        "full-depth goal autopilot is downgraded",
        downgradeReason,
        forecast.getNextCheckpointDate(),
        fromJson(forecast.getClaimGuardJson(), CLAIM_GUARD),
        new ForecastExplanationView(
            forecast.getExplanationKey(),
            "deterministic_policy",
            downgradeReason,
            true),
        forecast.getUpdatedAt());
  }

  private CheckpointView checkpointView(GoalOutcomeCheckpoint checkpoint) {
    return new CheckpointView(
        checkpoint.getCheckpointId(),
        checkpoint.getCheckpointType(),
        checkpoint.getCadence(),
        checkpoint.getResultStatus(),
        checkpoint.getConfidenceBand(),
        checkpoint.getSummary(),
        checkpoint.getPlanUpdateSignal(),
        checkpoint.getReasonCode());
  }

  private CheckpointTaskDecisionView checkpointTaskView(
      CheckpointCadencePolicy.Decision decision, EntitlementDepthView entitlementDepth) {
    return new CheckpointTaskDecisionView(
        decision.checkpointState(),
        decision.dueStatus(),
        decision.dueDate(),
        decision.nextDueDate(),
        decision.cadence(),
        decision.limitationReason(),
        decision.supportStatus(),
        decision.contentCoverage(),
        decision.task() == null ? null : checkpointTaskDefinitionView(decision.task()),
        entitlementDepth,
        decision.ruleVersion());
  }

  private CheckpointTaskDefinitionView checkpointTaskDefinitionView(CheckpointCadencePolicy.TaskDefinition task) {
    return new CheckpointTaskDefinitionView(
        task.taskId(),
        task.taskType(),
        task.cadence(),
        task.goalType(),
        task.promptRef(),
        task.estimatedDurationMinutes(),
        task.requiredEvidence(),
        task.rubricRef(),
        task.supportStatus(),
        task.limitationReason(),
        task.aiDepth(),
        task.scoringBoundary());
  }

  private EntitlementDepthView entitlementDepthView(GoalProfile profile, GoalDiagnosticAssessment diagnostic) {
    GoalAutopilotEntitlementPolicy.Decision decision = entitlementDepthDecision(profile, diagnostic);
    return new EntitlementDepthView(
        decision.depthState(),
        decision.allowedDepth(),
        decision.diagnosticDepth(),
        decision.diagnosticSampleLimit(),
        decision.plannerDepth(),
        decision.plannerHorizonDays(),
        decision.plannerSessionLimit(),
        decision.checkpointDepth(),
        decision.checkpointCadence(),
        decision.explanationDepth(),
        decision.providerCandidateAllowed(),
        decision.preciseEtaAllowed(),
        decision.limitationReason(),
        decision.sourceEntitlementRef(),
        decision.ruleVersion());
  }

  private GoalAutopilotEntitlementPolicy.Decision entitlementDepthDecision(
      GoalProfile profile, GoalDiagnosticAssessment diagnostic) {
    var latestEntitlement = commercialFoundationService.latestEntitlement(profile.getUserId());
    EntitlementSnapshot entitlement = latestEntitlement
        .orElseGet(() -> commercialFoundationService.defaultFreeEntitlement(profile.getUserId()));
    String sourceRef = latestEntitlement
        .map(snapshot -> "entitlement:" + snapshot.getEntitlementSnapshotId())
        .orElse("entitlement:default_free");
    return entitlementPolicy.decide(new GoalAutopilotEntitlementPolicy.Input(
        entitlement.getPlan(),
        entitlement.getStatus(),
        entitlement.getValidUntil(),
        sourceRef,
        profile.getSupportStatus(),
        diagnostic.getConfidenceBand(),
        depthQuotaAvailable(entitlement),
        costBudgetAvailable(entitlement),
        Instant.now(clock)));
  }

  private String fullDepthDowngradeReason(UUID userId, EntitlementDepthView entitlementDepth) {
    String reason = stableDowngradeReason(entitlementDepth);
    if ("quota_exhausted".equals(reason)
        || "cost_budget_limited".equals(reason)
        || "entitlement_required".equals(reason)) {
      return reason;
    }
    if (userId != null
        && "full".equals(entitlementDepth.allowedDepth())
        && (usageLedgerExhausted(userId, "ai") || usageLedgerExhausted(userId, "scoring"))) {
      return "quota_exhausted";
    }
    return null;
  }

  private String stableDowngradeReason(EntitlementDepthView entitlementDepth) {
    return stableDowngradeReason(entitlementDepth.limitationReason(), "blocked".equals(entitlementDepth.depthState()));
  }

  private String stableDowngradeReason(String reason) {
    return stableDowngradeReason(reason, false);
  }

  private String stableDowngradeReason(String reason, boolean entitlementBlocked) {
    String cleaned = clean(reason);
    if ("quota_exhausted".equals(cleaned) || "cost_budget_limited".equals(cleaned)) {
      return cleaned;
    }
    if (entitlementBlocked && isEntitlementBlockedReason(cleaned)) {
      return "entitlement_required";
    }
    return cleaned == null ? "unavailable" : cleaned;
  }

  private boolean isEntitlementBlockedReason(String reason) {
    return reason != null
        && (reason.startsWith("entitlement_blocked_") || "unknown_entitlement_blocked".equals(reason));
  }

  private boolean usageLedgerExhausted(UUID userId, String usageFamily) {
    String period = YearMonth.now(clock.withZone(ZoneOffset.UTC)).toString();
    return usageLedgers.findByUserIdAndUsageFamilyAndPeriod(userId, usageFamily, period)
        .map(ledger -> !ledger.canReserve(1))
        .orElse(false);
  }

  private boolean depthQuotaAvailable(EntitlementSnapshot entitlement) {
    try {
      Map<String, Object> quotas = quotaLimits(entitlement);
      return quotaLimit(quotas, "ai") > 0
          && quotaLimit(quotas, "scoring") > 0
          && quotaLimit(quotas, "training") > 0;
    } catch (Exception ignored) {
      return false;
    }
  }

  private boolean costBudgetAvailable(EntitlementSnapshot entitlement) {
    try {
      Map<String, Object> quotas = quotaLimits(entitlement);
      if (quotas.containsKey("cost_budget")) {
        return quotaLimit(quotas, "cost_budget") > 0;
      }
      if (quotas.containsKey("cost")) {
        return quotaLimit(quotas, "cost") > 0;
      }
      return true;
    } catch (Exception ignored) {
      return false;
    }
  }

  private Map<String, Object> quotaLimits(EntitlementSnapshot entitlement) throws Exception {
    return objectMapper.readValue(entitlement.getQuotaLimits(), OBJECT_MAP);
  }

  private int quotaLimit(Map<String, Object> quotas, String family) {
    Object value = quotas.get(family);
    if (value instanceof Number number) {
      return number.intValue();
    }
    return 0;
  }

  private SupportDecision supportDecisionFrom(GoalProfile profile) {
    return new SupportDecision(
        UUID.nameUUIDFromBytes((profile.getGoalProfileId() + ":support").getBytes()).toString(),
        profile.getSupportStatus(),
        "unsupported".equals(profile.getSupportStatus()) ? "goal_type_not_supported" : "rubric_and_content_available",
        profile.getLimitationMessage(),
        !"unsupported".equals(profile.getSupportStatus()),
        "unsupported".equals(profile.getSupportStatus()) ? "none" : "sufficient_for_local_plan");
  }

  private String riskFor(GoalDiagnosticAssessment diagnostic, boolean conservative) {
    if (conservative || "low".equals(diagnostic.getConfidenceBand())) {
      return "high";
    }
    return "high".equals(diagnostic.getConfidenceBand()) ? "low" : "medium";
  }

  private int sessionCount(GoalProfile profile, boolean partial) {
    int base = Math.max(3, profile.getDailyMinutes() / 8);
    return partial ? Math.min(base, 3) : Math.min(base, 6);
  }

  private String milestoneFor(GoalDiagnosticAssessment diagnostic, GoalProfile profile) {
    if ("low".equals(diagnostic.getConfidenceBand())) {
      return "collect more reliable diagnostic evidence and stabilize basic retrieval";
    }
    return "stabilize fluency under goal-specific follow-up pressure";
  }

  private String gapSummary(GoalProfile profile, GoalDiagnosticAssessment diagnostic, boolean preciseEtaAllowed) {
    if (!preciseEtaAllowed) {
      return "Goal gap is estimated conservatively until confidence or support improves.";
    }
    return "About 2 product-rubric bands below target in fluency and scenario fit.";
  }

  private String confidenceAfterCheckpoint(CheckpointInput input, GoalDiagnosticAssessment diagnostic) {
    String transcript = clean(input.transcript());
    if (transcript != null && transcript.length() >= 120) {
      return "high".equals(diagnostic.getConfidenceBand()) ? "high" : "medium";
    }
    return "low";
  }

  private String checkpointSummary(CheckpointInput input, GoalDiagnosticAssessment diagnostic) {
    String requestedStatus = cleanOrDefault(input.resultStatus(), "recorded");
    if ("failed".equals(requestedStatus)) {
      return "Checkpoint failed; risk state was updated without changing goal completion or ETA precision.";
    }
    if ("skipped".equals(requestedStatus)) {
      return "Checkpoint was skipped; recovery planning is required before precise forecast updates.";
    }
    if ("low".equals(confidenceAfterCheckpoint(input, diagnostic))) {
      return "Checkpoint recorded with low confidence; more evidence is required before precise forecast updates.";
    }
    return "Checkpoint recorded. Fluency improved, while example depth remains the main training target.";
  }

  private ClaimGuardView claimGuard(boolean goalCompletionAllowed) {
    return new ClaimGuardView(false, goalCompletionAllowed, "product_internal_progress_only");
  }

  private void recordGoalMetric(
      GoalProfile profile,
      String eventType,
      String status,
      String reasonCode,
      String sourcePath,
      String targetRef,
      String requestId) {
    recordGoalMetric(profile.getUserId(), eventType, status, reasonCode, sourcePath, targetRef, requestId);
  }

  private void recordGoalMetric(
      UUID userId,
      String eventType,
      String status,
      String reasonCode,
      String sourcePath,
      String targetRef,
      String requestId) {
    telemetryService.record(userId, eventType, status, reasonCode, sourcePath, targetRef, requestId);
  }

  private String exceptionReason(RuntimeException exception) {
    if (exception instanceof ApiException apiException) {
      Object reasonCode = apiException.getDetails().get("reason_code");
      if (reasonCode != null) {
        return reasonCode.toString();
      }
      return apiException.getCode();
    }
    return exception.getClass().getSimpleName();
  }

  private void audit(UUID userId, String eventType, String targetRef, String requestId, Instant now) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "user",
        userId.toString(),
        eventType,
        targetRef,
        "{\"data\":\"redacted\",\"schema_version\":1}",
        requestId,
        now));
  }

  private String toJson(Object value) {
    try {
      return objectMapper.writeValueAsString(value);
    } catch (Exception e) {
      throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "CONFLICT", "Could not serialize goal autopilot state.");
    }
  }

  private <T> T fromJson(String json, TypeReference<T> type) {
    try {
      return objectMapper.readValue(json, type);
    } catch (Exception e) {
      throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "CONFLICT", "Could not read goal autopilot state.");
    }
  }

  private String cleanRequired(String value, String field) {
    String cleaned = clean(value);
    if (cleaned == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", field + " is required.");
    }
    return cleaned;
  }

  private String clean(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    return value.trim();
  }

  private String cleanOrDefault(String value, String fallback) {
    String cleaned = clean(value);
    return cleaned == null ? fallback : cleaned;
  }

  public record GoalInput(
      String goalType,
      Double targetScore,
      String targetAbility,
      LocalDate deadline,
      Integer dailyMinutes,
      String intensityPreference,
      List<DiagnosticSampleInput> diagnosticSamples,
      String quietHoursStart,
      String quietHoursEnd,
      boolean notificationConsent) {}

  public record DiagnosticSampleInput(String sampleRef, String transcript, String audioRef, Integer durationSeconds) {}

  public record ControlSettingsInput(
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      Boolean notificationConsent,
      String intensityOverride,
      String missedDayPolicy) {}

  public record ReminderEligibilityInput(
      String planItemId,
      String reminderSlot,
      String currentTime,
      String platformPermission) {}

  public record RecoveryReplanInput(String sourceEvent, UUID planItemId, String preferredPolicy) {}

  public record ItemPolicyDecisionInput(
      String policyVersion,
      List<String> itemRefs,
      Integer dailyTimeBudgetMinutes,
      List<MemoryItemPolicyInput> items) {}

  public record MemoryItemPolicyInput(
      String itemType,
      String itemRef,
      String interleavingGroup,
      String currentMasteryLevel,
      List<String> evidenceRefs,
      Instant lastReviewedAt,
      Integer exposureCount,
      Integer overlearningCount,
      Double forgettingRisk,
      Boolean retrievalSuccess,
      Integer recentFailures,
      String pressureLevel,
      Integer estimatedMinutes) {}

  public record CheckpointInput(String checkpointType, String transcript, String audioRef, Double scoreHint, String resultStatus) {}

  public record GoalProgressProjectionView(
      String projectionId,
      String projectionState,
      String downgradeReason,
      GoalProgressGoalFragmentView goal,
      GoalProgressNextActionFragmentView nextAction,
      GoalProgressForecastFragmentView progress,
      GoalProgressCheckpointFragmentView latestCheckpoint,
      List<GoalProgressSurfaceFragmentView> surfaceFragments,
      List<String> sourceRefs,
      String ruleVersion,
      Instant updatedAt) {}

  public record GoalProgressGoalFragmentView(
      UUID goalProfileId,
      String goalType,
      String supportStatus,
      String status,
      int revision) {}

  public record GoalProgressNextActionFragmentView(
      String actionId,
      UUID planItemId,
      String actionType,
      String title,
      String reasonCode,
      int expectedDurationMinutes,
      String status) {}

  public record GoalProgressForecastFragmentView(
      UUID forecastId,
      String forecastState,
      String gapSummary,
      LocalDate etaDate,
      ForecastEtaRangeView etaRange,
      String etaUnavailableReason,
      String confidenceBand,
      String riskLevel,
      String riskReasonCode,
      LocalDate nextCheckpointDate,
      ClaimGuardView claimGuard,
      Instant updatedAt) {}

  public record GoalProgressCheckpointFragmentView(
      UUID checkpointId,
      String resultStatus,
      String confidenceBand,
      String summary,
      String planUpdateSignal,
      String reasonCode) {}

  public record GoalProgressSurfaceFragmentView(
      String surface,
      String displayState,
      boolean eligible,
      String downgradeReason,
      String nextActionRef,
      String forecastRef,
      String checkpointRef,
      List<String> safeFields) {}

  public record SummaryView(
      GoalProfileView goalProfile,
      SupportDecision supportDecision,
      DiagnosticView diagnostic,
      EntitlementDepthView entitlementDepth,
      WeeklyBackplanView weeklyBackplan,
      DailyPlanView dailyPlan,
      AutopilotActionView nextAction,
      ForecastView forecast,
      CheckpointView latestCheckpoint) {}

  public record PlanResult(
      WeeklyBackplanView weeklyBackplan,
      DailyPlanView dailyPlan,
      AutopilotActionView nextAction,
      ForecastView forecast,
      EntitlementDepthView entitlementDepth) {}

  public record ActionResult(AutopilotActionView action, ForecastView forecast, PlanUpdateSignalView planUpdateSignal) {}

  public record ForecastResult(ForecastView forecast, EntitlementDepthView entitlementDepth) {}

  public record RecoveryPlanResult(
      RecoveryPlanDecisionView recoveryDecision,
      DailyPlanView dailyPlan,
      PlanUpdateSignalView planUpdateSignal) {}

  public record ItemPolicyDecisionResult(
      List<MemoryItemPolicyStateView> decisions,
      NotificationOutboxService.PlannerReplayAuditView replayAudit) {}

  public record MasteryTransitionDecisionView(
      UUID transitionId,
      UUID userId,
      String memoryItemStateId,
      String previousLevel,
      String proposedLevel,
      String acceptedLevel,
      String direction,
      List<String> evidenceRefs,
      double confidence,
      String reasonCode,
      String ruleVersion,
      Instant createdAt) {}

  public record ControlResult(
      ControlView control,
      boolean nextActionChanged,
      boolean reminderEligibilityChanged,
      boolean replanRequired,
      String reasonCode,
      NotificationEligibilityDecisionView reminderEligibility,
      PlanUpdateSignalView planUpdateSignal) {}

  public record GoalAutopilotDataGovernanceExport(
      String exportFamily,
      String ruleVersion,
      Instant generatedAt,
      List<DataFamilyExportRecord> dataFamilies,
      List<RetentionRuleView> retentionRules,
      List<String> deletionTables,
      List<String> retainedRedactedTables,
      List<String> omittedSensitiveFields,
      String userHash,
      boolean redactedExportOnly,
      String deletionProcessor) {}

  public record DataFamilyExportRecord(
      String dataClass,
      long recordCount,
      List<String> sourceRefs,
      List<String> safeFields,
      List<String> redactedFields,
      List<String> omittedFields,
      String exportBehavior) {}

  public record ControlDataGovernanceExport(
      String exportFamily,
      String ruleVersion,
      List<ControlExportRecord> controls,
      List<ControlIdempotencyExportRecord> idempotencyRecords,
      List<RetentionRuleView> retentionRules,
      List<String> deletionTables,
      boolean redactedAuditOnly,
      String notificationOutboxStatus) {}

  public record ControlExportRecord(
      UUID controlId,
      UUID userId,
      UUID goalProfileId,
      String controlStatus,
      Instant pausedAt,
      String pauseReason,
      Instant resumedAt,
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      boolean notificationConsent,
      String intensityOverride,
      String missedDayPolicy,
      String ruleVersion,
      Instant createdAt,
      Instant updatedAt) {}

  public record ControlIdempotencyExportRecord(
      UUID replayId,
      UUID goalProfileId,
      int goalRevision,
      String operation,
      String requestHash,
      Instant createdAt,
      boolean idempotencyKeyRedacted,
      boolean responseJsonRedacted) {}

  public record RetentionRuleView(String dataClass, String action, String trigger, String minimization) {}

  public record CheckpointResult(
      CheckpointView checkpoint,
      ForecastView forecast,
      EntitlementDepthView entitlementDepth,
      PlanUpdateSignalView planUpdateSignal) {}

  public record CheckpointTaskDecisionView(
      String checkpointState,
      String dueStatus,
      LocalDate dueDate,
      LocalDate nextDueDate,
      String cadence,
      String limitationReason,
      String supportStatus,
      String contentCoverage,
      CheckpointTaskDefinitionView task,
      EntitlementDepthView entitlementDepth,
      String ruleVersion) {}

  public record CheckpointTaskDefinitionView(
      String taskId,
      String taskType,
      String cadence,
      String goalType,
      String promptRef,
      int estimatedDurationMinutes,
      List<String> requiredEvidence,
      String rubricRef,
      String supportStatus,
      String limitationReason,
      String aiDepth,
      String scoringBoundary) {}

  public record EntitlementDepthView(
      String depthState,
      String allowedDepth,
      String diagnosticDepth,
      int diagnosticSampleLimit,
      String plannerDepth,
      int plannerHorizonDays,
      int plannerSessionLimit,
      String checkpointDepth,
      String checkpointCadence,
      String explanationDepth,
      boolean providerCandidateAllowed,
      boolean preciseEtaAllowed,
      String limitationReason,
      String sourceEntitlementRef,
      String ruleVersion) {}

  private record ReminderCommercialGate(boolean entitlementAllowed, boolean quotaAvailable) {}

  public record GoalProfileView(
      UUID goalProfileId,
      String goalType,
      Double targetScore,
      String targetAbility,
      LocalDate deadline,
      int dailyMinutes,
      String intensityPreference,
      String supportStatus,
      String status,
      int revision) {}

  public record ControlView(
      UUID controlId,
      UUID userId,
      UUID goalProfileId,
      String controlStatus,
      Instant pausedAt,
      String pauseReason,
      Instant resumedAt,
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      boolean notificationConsent,
      String intensityOverride,
      String missedDayPolicy,
      Instant updatedAt,
      String ruleVersion) {}

  public record NotificationEligibilityDecisionView(
      String decisionId,
      UUID controlId,
      UUID userId,
      UUID goalProfileId,
      UUID planItemId,
      boolean eligible,
      String reasonCode,
      Instant nextAllowedAt,
      String explanationKey,
      Instant evaluatedAt,
      String ruleVersion) {}

  public record RecoveryPlanDecisionView(
      UUID decisionId,
      UUID goalProfileId,
      UUID dailyPlanId,
      String sourceEvent,
      String recoveryMode,
      List<String> affectedPlanItemRefs,
      String inputSnapshotHash,
      String reasonCode,
      String ruleVersion,
      Instant createdAt) {}

  public record MemoryItemPolicyStateView(
      String memoryItemStateId,
      UUID userId,
      String itemType,
      String itemRef,
      String interleavingGroup,
      String currentMasteryLevel,
      List<String> evidenceRefs,
      Instant lastReviewedAt,
      int exposureCount,
      int overlearningCount,
      String forgettingRisk,
      String dueDecision,
      Instant nextDueAt,
      String reasonCode,
      String ruleVersion) {}

  public record SupportDecision(
      String decisionId,
      String supportStatus,
      String reasonCode,
      String limitationMessage,
      boolean rubricAvailable,
      String contentCoverage) {}

  public record DiagnosticView(
      UUID diagnosticAssessmentId,
      String status,
      String confidenceBand,
      int sampleCount,
      List<RubricScoreView> rubricScores,
      List<WeaknessTagView> weaknessTags,
      ClaimGuardView claimGuard) {}

  public record RubricScoreView(String dimension, double score, double confidence, String evidenceRef) {}

  public record WeaknessTagView(
      String tag, String severity, String dimension, String recommendedTrainingDirection, String evidenceRef) {}

  public record ClaimGuardView(boolean officialScoreEquivalence, boolean goalCompletionClaimAllowed, String allowedClaim) {}

  public record WeeklyBackplanView(
      UUID weeklyBackplanId,
      String planVersion,
      LocalDate startDate,
      LocalDate endDate,
      String milestone,
      int sessionCount,
      List<String> reviewWindows,
      LocalDate checkpointDueDate,
      String status) {}

  public record DailyPlanView(
      UUID dailyPlanId,
      LocalDate planDate,
      int totalMinutes,
      String status,
      String limitationMessage,
      List<PlanItemView> items,
      MemoryCurvePolicyView memoryPolicy) {}

  public record PlanItemView(
      UUID planItemId,
      String itemType,
      String title,
      String reasonCode,
      int durationMinutes,
      String status,
      String memoryRisk,
      String pressureLevel) {}

  public record MemoryCurvePolicyView(
      String policyVersion, String forgettingRisk, int nextReviewIntervalDays, int overlearningCap, String interleavingRule) {}

  public record AutopilotActionView(
      String actionId,
      UUID planItemId,
      String actionType,
      String title,
      String reasonCode,
      int expectedDurationMinutes,
      String status,
      String explanation) {}

  public record ForecastView(
      UUID forecastId,
      int sourceGoalRevision,
      String forecastState,
      String gapSummary,
      LocalDate etaDate,
      ForecastEtaRangeView etaRange,
      String etaWindow,
      String etaUnavailableReason,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      String riskReasonCode,
      LocalDate nextCheckpointDate,
      ClaimGuardView claimGuard,
      ForecastExplanationView explanation,
      Instant updatedAt) {}

  public record ForecastEtaRangeView(LocalDate startDate, LocalDate endDate) {}

  public record ForecastExplanationView(String key, String source, String fallbackReason, boolean candidateOnly) {}

  public record CheckpointView(
      UUID checkpointId,
      String checkpointType,
      String cadence,
      String resultStatus,
      String confidenceBand,
      String summary,
      String planUpdateSignal,
      String reasonCode) {}

  public record PlanUpdateSignalView(
      String signalType,
      String reasonCode,
      UUID sourceCheckpointId,
      String ruleVersion,
      String inputSnapshotHash,
      UUID replayAuditId) {
    public PlanUpdateSignalView(String signalType, String reasonCode) {
      this(signalType, reasonCode, null, null, null, null);
    }
  }

  private record PlanFacts(boolean missingPlan, boolean stalePlan, boolean recoveryRequired) {}
}
