package com.speakeasy.goal;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GoalAutopilotService {
  private static final Collection<String> ACTIVE_GOAL_STATUSES =
      List.of("active", "partial", "unsupported", "needs_more_diagnostic");
  private static final Collection<String> ACTIVE_PLAN_STATUSES = List.of("active", "partial");
  private static final Collection<String> ACTIVE_DAILY_STATUSES = List.of("ready", "partial", "recovery_required");
  private static final Set<String> SUPPORTED_GOALS =
      Set.of("ielts_speaking", "toefl_speaking", "business_meeting", "job_interview", "onboarding_introduction");
  private static final TypeReference<List<RubricScoreView>> RUBRIC_LIST = new TypeReference<>() {};
  private static final TypeReference<List<WeaknessTagView>> WEAKNESS_LIST = new TypeReference<>() {};
  private static final TypeReference<ClaimGuardView> CLAIM_GUARD = new TypeReference<>() {};

  private final UserAccountRepository users;
  private final GoalProfileRepository goalProfiles;
  private final GoalDiagnosticAssessmentRepository diagnostics;
  private final GoalMasteryInitialStateRepository masteryInitialStates;
  private final GoalBackplanRepository backplans;
  private final GoalDailyPlanRepository dailyPlans;
  private final GoalPlanItemRepository planItems;
  private final GoalProgressForecastRepository forecasts;
  private final GoalOutcomeCheckpointRepository checkpoints;
  private final AuditLogRepository auditLogs;
  private final ObjectMapper objectMapper;
  private final Clock clock;

  public GoalAutopilotService(
      UserAccountRepository users,
      GoalProfileRepository goalProfiles,
      GoalDiagnosticAssessmentRepository diagnostics,
      GoalMasteryInitialStateRepository masteryInitialStates,
      GoalBackplanRepository backplans,
      GoalDailyPlanRepository dailyPlans,
      GoalPlanItemRepository planItems,
      GoalProgressForecastRepository forecasts,
      GoalOutcomeCheckpointRepository checkpoints,
      AuditLogRepository auditLogs,
      ObjectMapper objectMapper,
      Clock clock) {
    this.users = users;
    this.goalProfiles = goalProfiles;
    this.diagnostics = diagnostics;
    this.masteryInitialStates = masteryInitialStates;
    this.backplans = backplans;
    this.dailyPlans = dailyPlans;
    this.planItems = planItems;
    this.forecasts = forecasts;
    this.checkpoints = checkpoints;
    this.auditLogs = auditLogs;
    this.objectMapper = objectMapper;
    this.clock = clock;
  }

  @Transactional
  public SummaryView createGoal(UUID userId, GoalInput input, String requestId) {
    requireUser(userId);
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
    if (!Set.of("gentle", "standard", "intensive").contains(intensity)) {
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
    GoalDiagnosticAssessment diagnostic = diagnostics.save(buildDiagnostic(profile, input.diagnosticSamples(), support, now));
    saveInitialMasteryStates(profile, diagnostic, now);
    GoalProgressForecast forecast = upsertForecast(profile, diagnostic, "goal_intake", null, now);
    audit(userId, "goal_autopilot_goal_saved", "goal_profile:" + profile.getGoalProfileId(), requestId, now);
    return summaryView(
        profile, support, diagnostic, latestBackplan(profile), latestDailyPlanOrNull(profile), nextActionOrNull(profile), forecast, latestCheckpoint(profile));
  }

  @Transactional(readOnly = true)
  public SummaryView summary(UUID userId) {
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

  @Transactional
  public PlanResult generatePlan(UUID userId, boolean forceReplan, String reasonCode, String requestId) {
    GoalProfile profile = requireActiveGoal(userId);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    if ("unsupported".equals(profile.getSupportStatus())) {
      throw new ApiException(
          HttpStatus.CONFLICT,
          "CONFLICT",
          "Unsupported goals cannot generate a full goal autopilot plan.",
          Map.of("support_status", profile.getSupportStatus(), "reason_code", "unsupported_goal"));
    }
    Instant now = Instant.now(clock);
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
        partial ? "Conservative plan because goal support or diagnostic confidence is limited." : "",
        risk,
        "high".equals(risk) ? 1 : 3,
        now));
    createDefaultPlanItems(profile, dailyPlan, risk, partial, now);
    GoalProgressForecast forecast = upsertForecast(profile, diagnostic, "plan_generated", null, now);
    audit(userId, "goal_autopilot_plan_generated", "goal_profile:" + profile.getGoalProfileId(), requestId, now);
    return new PlanResult(backplanView(backplan), dailyPlanView(dailyPlan), actionView(requireNextItem(dailyPlan), "ready"), forecastView(forecast));
  }

  @Transactional(readOnly = true)
  public DailyPlanView dailyPlan(UUID userId) {
    GoalProfile profile = requireActiveGoal(userId);
    GoalDailyPlan dailyPlan = requireDailyPlan(profile);
    return dailyPlanView(dailyPlan);
  }

  @Transactional(readOnly = true)
  public ActionResult nextAction(UUID userId) {
    GoalProfile profile = requireActiveGoal(userId);
    GoalDailyPlan dailyPlan = requireDailyPlan(profile);
    GoalProgressForecast forecast = requireForecast(profile);
    return new ActionResult(actionView(requireNextItem(dailyPlan), "ready"), forecastView(forecast), new PlanUpdateSignalView("none", "no_replan_needed"));
  }

  @Transactional
  public ActionResult completeAction(UUID userId, UUID planItemId, String outcome, String requestId) {
    GoalPlanItem item = planItems.findByPlanItemIdAndUserId(planItemId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Plan item was not found."));
    String normalizedOutcome = clean(outcome);
    if (!Set.of("completed", "skipped", "deferred").contains(normalizedOutcome)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "outcome is invalid.");
    }
    GoalProfile profile = requireActiveGoal(userId);
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
    GoalProgressForecast forecast = upsertForecast(profile, diagnostic, normalizedOutcome, signal.reasonCode(), now);
    audit(userId, "goal_autopilot_action_" + normalizedOutcome, "plan_item:" + planItemId, requestId, now);
    GoalPlanItem current = planItems.findFirstByDailyPlanIdAndStatusInOrderByOrderIndexAsc(
            dailyPlan.getDailyPlanId(), List.of("active", "pending"))
        .orElse(item);
    return new ActionResult(actionView(current, current.getStatus()), forecastView(forecast), signal);
  }

  @Transactional(readOnly = true)
  public ForecastView forecast(UUID userId) {
    GoalProfile profile = requireActiveGoal(userId);
    return forecastView(requireForecast(profile));
  }

  @Transactional
  public CheckpointResult submitCheckpoint(UUID userId, CheckpointInput input, String requestId) {
    GoalProfile profile = requireActiveGoal(userId);
    GoalDiagnosticAssessment diagnostic = requireDiagnostic(profile);
    String checkpointType = cleanOrDefault(input.checkpointType(), "weekly_mock");
    if (!Set.of("weekly_mock", "biweekly_mock", "business_task").contains(checkpointType)) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "checkpoint_type is invalid.");
    }
    Instant now = Instant.now(clock);
    String confidence = confidenceAfterCheckpoint(input, diagnostic);
    String summary = checkpointSummary(input, diagnostic);
    GoalOutcomeCheckpoint checkpoint = checkpoints.save(new GoalOutcomeCheckpoint(
        UUID.randomUUID(),
        profile.getGoalProfileId(),
        userId,
        checkpointType,
        "biweekly_mock".equals(checkpointType) ? "biweekly" : "weekly",
        "low".equals(confidence) ? "low_confidence" : "recorded",
        confidence,
        summary,
        "checkpoint_replan",
        "checkpoint_updated_gap",
        now));
    markPlansStale(profile.getGoalProfileId(), "checkpoint_updated_gap", now);
    GoalProgressForecast forecast = upsertForecast(profile, diagnostic, "checkpoint", confidence, now);
    audit(userId, "goal_autopilot_checkpoint_recorded", "checkpoint:" + checkpoint.getCheckpointId(), requestId, now);
    return new CheckpointResult(
        checkpointView(checkpoint), forecastView(forecast), new PlanUpdateSignalView("checkpoint_replan", "checkpoint_updated_gap"));
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
    boolean preciseEtaAllowed =
        "supported".equals(profile.getSupportStatus()) && !"low".equals(confidence) && !"unsupported".equals(profile.getStatus());
    LocalDate today = LocalDate.now(clock);
    LocalDate eta = preciseEtaAllowed ? profile.getDeadline().minusDays(Math.min(7, Math.max(0, profile.getDailyMinutes() / 10))) : null;
    String etaWindow = preciseEtaAllowed
        ? eta.minusDays(7) + ".." + eta.plusDays(7)
        : "not_available_until_confidence_improves";
    String risk = riskFor(diagnostic, !preciseEtaAllowed);
    String riskReason = switch (source) {
      case "completed" -> "latest action completed; keep the memory curve active";
      case "skipped", "deferred" -> "missed or deferred work requires recovery planning";
      case "checkpoint" -> "checkpoint evidence updated the goal gap";
      default -> "checkpoint evidence is not available yet";
    };
    GoalProgressForecast forecast = forecasts.findFirstByGoalProfileIdOrderByUpdatedAtDesc(profile.getGoalProfileId())
        .orElseGet(() -> new GoalProgressForecast(
            UUID.randomUUID(),
            profile.getGoalProfileId(),
            profile.getUserId(),
            "",
            null,
            "",
            "low",
            "high",
            "",
            today.plusDays(7),
            toJson(claimGuard(false)),
            now));
    forecast.update(
        gapSummary(profile, diagnostic, preciseEtaAllowed),
        eta,
        etaWindow,
        confidence,
        risk,
        riskReason,
        today.plusDays("partial".equals(profile.getSupportStatus()) ? 14 : 7),
        toJson(claimGuard(false)),
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

  private GoalPlanItem requireNextItem(GoalDailyPlan dailyPlan) {
    return planItems.findFirstByDailyPlanIdAndStatusInOrderByOrderIndexAsc(dailyPlan.getDailyPlanId(), List.of("active", "pending"))
        .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT, "CONFLICT", "No active plan item is available."));
  }

  private AutopilotActionView nextActionOrNull(GoalProfile profile) {
    try {
      GoalDailyPlan dailyPlan = latestDailyPlan(profile);
      return actionView(requireNextItem(dailyPlan), "ready");
    } catch (ApiException ignored) {
      return null;
    }
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
    return new SummaryView(
        goalProfileView(profile),
        support,
        diagnosticView(diagnostic),
        backplan == null ? null : backplanView(backplan),
        dailyPlan == null ? null : dailyPlanView(dailyPlan),
        action,
        forecastView(forecast),
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
        forecast.getGapSummary(),
        forecast.getEtaDate(),
        forecast.getEtaWindow(),
        forecast.getConfidenceBand(),
        forecast.getRiskLevel(),
        forecast.getRiskReason(),
        forecast.getNextCheckpointDate(),
        fromJson(forecast.getClaimGuardJson(), CLAIM_GUARD));
  }

  private CheckpointView checkpointView(GoalOutcomeCheckpoint checkpoint) {
    return new CheckpointView(
        checkpoint.getCheckpointId(),
        checkpoint.getCheckpointType(),
        checkpoint.getCadence(),
        checkpoint.getResultStatus(),
        checkpoint.getConfidenceBand(),
        checkpoint.getSummary());
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
    if ("low".equals(confidenceAfterCheckpoint(input, diagnostic))) {
      return "Checkpoint recorded with low confidence; more evidence is required before precise forecast updates.";
    }
    return "Checkpoint recorded. Fluency improved, while example depth remains the main training target.";
  }

  private ClaimGuardView claimGuard(boolean goalCompletionAllowed) {
    return new ClaimGuardView(false, goalCompletionAllowed, "product_internal_progress_only");
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

  public record CheckpointInput(String checkpointType, String transcript, String audioRef, Double scoreHint) {}

  public record SummaryView(
      GoalProfileView goalProfile,
      SupportDecision supportDecision,
      DiagnosticView diagnostic,
      WeeklyBackplanView weeklyBackplan,
      DailyPlanView dailyPlan,
      AutopilotActionView nextAction,
      ForecastView forecast,
      CheckpointView latestCheckpoint) {}

  public record PlanResult(
      WeeklyBackplanView weeklyBackplan,
      DailyPlanView dailyPlan,
      AutopilotActionView nextAction,
      ForecastView forecast) {}

  public record ActionResult(AutopilotActionView action, ForecastView forecast, PlanUpdateSignalView planUpdateSignal) {}

  public record CheckpointResult(CheckpointView checkpoint, ForecastView forecast, PlanUpdateSignalView planUpdateSignal) {}

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
      String gapSummary,
      LocalDate etaDate,
      String etaWindow,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      LocalDate nextCheckpointDate,
      ClaimGuardView claimGuard) {}

  public record CheckpointView(
      UUID checkpointId, String checkpointType, String cadence, String resultStatus, String confidenceBand, String summary) {}

  public record PlanUpdateSignalView(String signalType, String reasonCode) {}
}
